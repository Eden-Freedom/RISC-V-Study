`timescale 1ns / 1ps
// Standalone Timer IRQ test: TB -> target bus inputs; target -> ready/rdata/irq.
// Internal state is observed only. No CPU, soc_top, or interrupt handler is used.
module tb_timer_irq;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg req_i = 1'b0;
    reg we_i = 1'b0;
    reg [31:0] addr_i = 32'd0;
    reg [31:0] wdata_i = 32'd0;
    reg [3:0] wstrb_i = 4'd0;
    wire ready_o;
    wire [31:0] rdata_o;
    wire irq_o;

    // Direct target-test offsets; no system address decoder is instantiated.
    localparam [31:0] CTRL = 32'h0;
    localparam [31:0] LIMIT = 32'h4;
    localparam [31:0] COUNT = 32'h8;
    localparam [31:0] STATUS = 32'hC;

    integer errors = 0;
    reg [8*100-1:0] current_case;
    reg expected_en;
    reg expected_irq_en;
    reg [31:0] expected_limit;
    reg [31:0] expected_count;
    reg expected_done;

    always #10 clk = ~clk;

    timer_target dut (
        .clk(clk), .rst_n(rst_n), .req_i(req_i), .we_i(we_i),
        .addr_i(addr_i), .wdata_i(wdata_i), .wstrb_i(wstrb_i),
        .ready_o(ready_o), .rdata_o(rdata_o), .irq_o(irq_o)
    );

    task check;
        input condition;
        input [8*100-1:0] label;
        begin
            // Unknown values must fail rather than skip a check.
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s / %0s time=%0t", current_case, label, $time);
                $display("  req=%b we=%b addr=%08h wdata=%08h mask=%b ready=%b rdata=%08h irq=%b",
                         req_i,we_i,addr_i,wdata_i,wstrb_i,ready_o,rdata_o,irq_o);
                $display("  en=%b irq_en=%b limit=%0d count=%0d done=%b",
                         dut.en_reg,dut.irq_en_reg,dut.limit_reg,dut.cnt_value_o,dut.cnt_done_o);
            end
        end
    endtask

    // One call spans exactly one rising edge. Every expected result is supplied
    // explicitly; no expected IRQ is calculated by copying the DUT's AND equation.
    task access_cycle;
        input [8*100-1:0] label;
        input reset_n_value;
        input request_value;
        input write_value;
        input [31:0] address_value;
        input [31:0] data_value;
        input [3:0] strobe_value;
        input [31:0] expected_read_before;
        input [31:0] expected_read_after;
        input en_after;
        input irq_en_after;
        input [31:0] limit_after;
        input [31:0] count_after;
        input done_after;
        input irq_before;
        input irq_after;
        begin
            @(negedge clk);
            current_case = label;
            rst_n = reset_n_value;
            req_i = request_value;
            we_i = write_value;
            addr_i = address_value;
            wdata_i = data_value;
            wstrb_i = strobe_value;
            #1;
            check(ready_o === request_value,"ready before edge");
            check(rdata_o === expected_read_before,"read response before edge");
            check(irq_o === irq_before,"IRQ before edge uses old saved configuration");
            check(dut.en_reg === expected_en,"count enable holds before edge");
            check(dut.irq_en_reg === expected_irq_en,"IRQ enable holds before edge");
            check(dut.limit_reg === expected_limit,"limit holds before edge");
            check(dut.cnt_value_o === expected_count,"count holds before edge");
            check(dut.cnt_done_o === expected_done,"expiry before edge");

            @(posedge clk);
            #1; // Settle nonblocking updates and their combinational consequences.
            check(ready_o === request_value,"ready after edge");
            check(rdata_o === expected_read_after,"read response after edge");
            check(irq_o === irq_after,"IRQ changes in the same edge, without an extra cycle");
            check(dut.en_reg === en_after,"saved count enable after edge");
            check(dut.irq_en_reg === irq_en_after,"saved IRQ enable after edge");
            check(dut.limit_reg === limit_after,"saved limit after edge");
            check(dut.cnt_value_o === count_after,"count after edge");
            check(dut.cnt_done_o === done_after,"expiry after edge");

            expected_en = en_after;
            expected_irq_en = irq_en_after;
            expected_limit = limit_after;
            expected_count = count_after;
            expected_done = done_after;
        end
    endtask

    initial begin
        current_case = "initial synchronous reset";
        repeat (2) @(posedge clk);
        #1;
        check(dut.en_reg === 1'b0,"reset clears count enable");
        check(dut.irq_en_reg === 1'b0,"reset clears IRQ enable");
        check(dut.limit_reg === 32'd1,"reset restores limit one");
        check(dut.cnt_value_o === 32'd0,"reset clears count");
        check(dut.cnt_done_o === 1'b0,"reset count is below limit one");
        check(irq_o === 1'b0,"no IRQ after reset");
        check(ready_o === 1'b0 && rdata_o === 32'd0,"idle bus response after reset");
        expected_en=0; expected_irq_en=0; expected_limit=1;
        expected_count=0; expected_done=0;

        // Arguments after label:
        // rst_n,req,we,addr,wdata,mask, read_before,read_after,
        // en_after,irq_en_after,limit_after,count_after,done_after, irq_before,irq_after.
        access_cycle("reset CTRL readback",
            1,1,0,CTRL,0,0, 0,0, 0,0,1,0,0, 0,0);
        access_cycle("TB writes limit three into target LIMIT configuration",
            1,1,1,LIMIT,3,4'b1111, 0,0, 0,0,3,0,0, 0,0);
        access_cycle("CTRL=3 starts counter while device IRQ remains masked",
            1,1,1,CTRL,3,4'b0001, 0,0, 1,0,3,0,0, 0,0);
        access_cycle("COUNT read samples zero then changes to one",
            1,1,0,COUNT,0,0, 0,1, 1,0,3,1,0, 0,0);
        access_cycle("idle bus permits second count without requesting IRQ",
            1,0,0,COUNT,0,0, 0,0, 1,0,3,2,0, 0,0);
        access_cycle("STATUS becomes one at expiry while IRQ remains zero",
            1,1,0,STATUS,0,0, 0,1, 1,0,3,3,1, 0,0);
        access_cycle("expired COUNT remains three with IRQ masked",
            1,1,0,COUNT,0,0, 3,3, 1,0,3,3,1, 0,0);

        access_cycle("CTRL=5 enables IRQ on existing expiry without recounting",
            1,1,1,CTRL,5,4'b0001, 0,0, 1,1,3,3,1, 0,1);
        access_cycle("CTRL read returns saved enables five",
            1,1,0,CTRL,0,0, 5,5, 1,1,3,3,1, 1,1);
        access_cycle("no request but apparent CTRL clear fields cannot drop IRQ",
            1,0,1,CTRL,2,4'b1111, 0,0, 1,1,3,3,1, 1,1);
        access_cycle("idle LIMIT address and data changes do not gate IRQ",
            1,0,1,LIMIT,32'hFFFFFFFF,4'b1111, 0,0, 1,1,3,3,1, 1,1);
        access_cycle("idle STATUS address: zero read response but IRQ stays high",
            1,0,0,STATUS,0,0, 0,0, 1,1,3,3,1, 1,1);

        access_cycle("CTRL=1 masks IRQ but preserves expired count",
            1,1,1,CTRL,1,4'b0001, 0,0, 1,0,3,3,1, 1,0);
        access_cycle("masked CTRL read returns one",
            1,1,0,CTRL,0,0, 1,1, 1,0,3,3,1, 0,0);
        access_cycle("STATUS remains one even though IRQ is masked",
            1,1,0,STATUS,0,0, 1,1, 1,0,3,3,1, 0,0);
        access_cycle("CTRL=5 reasserts IRQ without a new count interval",
            1,1,1,CTRL,5,4'b0001, 0,0, 1,1,3,3,1, 0,1);
        access_cycle("CTRL=2 with second-byte-only mask has no effect",
            1,1,1,CTRL,2,4'b0010, 0,0, 1,1,3,3,1, 1,1);
        access_cycle("CTRL=2 with zero mask has no effect",
            1,1,1,CTRL,2,4'b0000, 0,0, 1,1,3,3,1, 1,1);
        access_cycle("CTRL=2 with no request has no effect",
            1,0,1,CTRL,2,4'b0001, 0,0, 1,1,3,3,1, 1,1);
        access_cycle("valid CTRL=2 clears and disables in the current edge",
            1,1,1,CTRL,2,4'b0001, 0,0, 0,0,3,0,0, 1,0);
        access_cycle("after clear CTRL reads zero, not the command value two",
            1,1,0,CTRL,0,0, 0,0, 0,0,3,0,0, 0,0);
        access_cycle("after clear COUNT reads zero",
            1,1,0,COUNT,0,0, 0,0, 0,0,3,0,0, 0,0);

        // Clear/start with both enables: IRQ must wait until actual expiry.
        access_cycle("CTRL=7 clears and starts with device IRQ enabled",
            1,1,1,CTRL,7,4'b1111, 0,0, 1,1,3,0,0, 0,0);
        access_cycle("CTRL reads five rather than seven while count becomes one",
            1,1,0,CTRL,0,0, 5,5, 1,1,3,1,0, 0,0);
        access_cycle("COUNT read one to two, IRQ not yet asserted",
            1,1,0,COUNT,0,0, 1,2, 1,1,3,2,0, 0,0);
        access_cycle("count reaches three and IRQ asserts at the same edge",
            1,1,0,STATUS,0,0, 0,1, 1,1,3,3,1, 0,1);
        access_cycle("newly asserted IRQ persists with no bus activity",
            1,0,0,CTRL,0,0, 0,0, 1,1,3,3,1, 1,1);

        // Synchronous reset: lowering rst_n at negedge must not drop IRQ early.
        access_cycle("reset of active IRQ takes effect at posedge, not negedge",
            0,0,0,CTRL,0,0, 0,0, 0,0,1,0,0, 1,0);
        access_cycle("release reset: saved enables stay cleared",
            1,1,0,CTRL,0,0, 0,0, 0,0,1,0,0, 0,0);

        // Zero limit: done=1 at count zero; IRQ still depends on saved enables.
        access_cycle("disabled LIMIT=0 sets expiry but cannot assert IRQ",
            1,1,1,LIMIT,0,4'b1111, 0,0, 0,0,0,0,1, 0,0);
        access_cycle("zero-limit STATUS reads one with IRQ zero",
            1,1,0,STATUS,0,0, 1,1, 0,0,0,0,1, 0,0);
        access_cycle("CTRL=4 enables only device IRQ; count-enable gate blocks request",
            1,1,1,CTRL,4,4'b0001, 0,0, 0,1,0,0,1, 0,0);
        access_cycle("CTRL reads four while zero-limit IRQ remains blocked",
            1,1,0,CTRL,0,0, 4,4, 0,1,0,0,1, 0,0);
        access_cycle("zero-limit CTRL=5 immediately asserts IRQ at count zero",
            1,1,1,CTRL,5,4'b0001, 0,0, 1,1,0,0,1, 0,1);
        access_cycle("zero-limit CTRL=7 clears count but cannot remove expiry or IRQ",
            1,1,1,CTRL,7,4'b0001, 0,0, 1,1,0,0,1, 1,1);
        access_cycle("zero-limit CTRL read still returns five",
            1,1,0,CTRL,0,0, 5,5, 1,1,0,0,1, 1,1);
        access_cycle("zero-limit STATUS and IRQ both remain one",
            1,1,0,STATUS,0,0, 1,1, 1,1,0,0,1, 1,1);
        access_cycle("zero-limit CTRL=2 drops IRQ while done stays one",
            1,1,1,CTRL,2,4'b0001, 0,0, 0,0,0,0,1, 1,0);
        access_cycle("after disable STATUS remains one but IRQ is zero",
            1,1,0,STATUS,0,0, 1,1, 0,0,0,0,1, 0,0);
        access_cycle("after disable CTRL reads zero",
            1,1,0,CTRL,0,0, 0,0, 0,0,0,0,1, 0,0);
        access_cycle("final idle bus: no request, expiry one, IRQ zero",
            1,0,1,CTRL,7,4'b1111, 0,0, 0,0,0,0,1, 0,0);

        if (errors == 0) begin
            $display("PASS: timer IRQ checks passed");
            $finish;
        end else
            $fatal(1,"FAIL: timer IRQ checks failed (%0d errors)",errors);
    end

    initial begin
        #10000;
        $fatal(1,"FAIL: timer IRQ timeout");
    end
endmodule

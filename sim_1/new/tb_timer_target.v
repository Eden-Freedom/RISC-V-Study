`timescale 1ns / 1ps
// TB -> timer_target bus inputs; timer_target -> TB ready/read response.
// Only DUT inputs are driven. Hierarchical references below are observations.
module tb_timer_target;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg req_i = 1'b0;
    reg we_i = 1'b0;
    reg [31:0] addr_i = 32'd0;
    reg [31:0] wdata_i = 32'd0;
    reg [3:0] wstrb_i = 4'd0;
    wire ready_o;
    wire [31:0] rdata_o;

    // Direct target-test offsets, not assigned system Timer base addresses.
    localparam [31:0] CTRL = 32'h0;
    localparam [31:0] LIMIT = 32'h4;
    localparam [31:0] COUNT = 32'h8;
    localparam [31:0] STATUS = 32'hC;

    integer errors = 0;
    reg [8*100-1:0] current_case;
    reg expected_en;
    reg [31:0] expected_limit;
    reg [31:0] expected_count;
    reg expected_done;

    always #10 clk = ~clk;

    timer_target dut (
        .clk(clk), .rst_n(rst_n),
        .req_i(req_i), .we_i(we_i), .addr_i(addr_i),
        .wdata_i(wdata_i), .wstrb_i(wstrb_i),
        .ready_o(ready_o), .rdata_o(rdata_o)
    );

    task check;
        input condition;
        input [8*100-1:0] label;
        begin
            // An X/Z predicate also fails; it must not silently skip a check.
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s / %0s time=%0t", current_case, label, $time);
                $display("  req=%b we=%b addr=%08h data=%08h strb=%b ready=%b rdata=%08h",
                         req_i, we_i, addr_i, wdata_i, wstrb_i, ready_o, rdata_o);
                $display("  en=%b limit=%08h count=%08h done=%b clear=%b",
                         dut.en_reg, dut.limit_reg, dut.cnt_value_o,
                         dut.cnt_done_o, dut.clear_pulse);
            end
        end
    endtask

    // Every call spans exactly one sampling/completion edge.
    // Expectations are explicit per stimulus, not computed using DUT rules.
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
        input [31:0] limit_after;
        input [31:0] count_after;
        input done_after;
        input expected_clear;
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
            check(ready_o === request_value, "ready before edge");
            check(rdata_o === expected_read_before, "read response before edge");
            check(dut.en_reg === expected_en, "enable holds before edge");
            check(dut.limit_reg === expected_limit, "limit holds before edge");
            check(dut.cnt_value_o === expected_count, "count holds before edge");
            check(dut.cnt_done_o === expected_done, "expiry before edge");
            check(dut.clear_pulse === expected_clear, "current transfer clear command");

            @(posedge clk);
            #1; // Allow configuration/counter nonblocking updates to settle.
            check(ready_o === request_value, "ready after edge");
            check(rdata_o === expected_read_after, "read response after edge");
            check(dut.en_reg === en_after, "stored enable after edge");
            check(dut.limit_reg === limit_after, "stored limit after edge");
            check(dut.cnt_value_o === count_after, "counter after edge");
            check(dut.cnt_done_o === done_after, "expiry after edge");
            check(dut.clear_pulse === expected_clear, "clear remains defined until inputs change");

            expected_en = en_after;
            expected_limit = limit_after;
            expected_count = count_after;
            expected_done = done_after;
        end
    endtask

    initial begin
        current_case = "initial synchronous reset";
        repeat (2) @(posedge clk);
        #1;
        check(dut.en_reg === 1'b0, "reset disables timer");
        check(dut.limit_reg === 32'd1, "reset limit is one");
        check(dut.cnt_value_o === 32'd0, "reset clears counter");
        check(dut.cnt_done_o === 1'b0, "reset state is below the limit");
        check(dut.clear_pulse === 1'b0, "reset idle has no clear command");
        check(ready_o === 1'b0 && rdata_o === 32'd0, "idle response is zero");
        expected_en = 0;
        expected_limit = 1;
        expected_count = 0;
        expected_done = 0;

        // Argument groups after the label:
        // rst_n, req, we, address, data, mask,
        // rdata_before, rdata_after, en_after, limit_after, count_after, done_after, clear.
        access_cycle("read reset CTRL",
            1,1,0,CTRL,0,0, 0,0, 0,1,0,0,0);
        access_cycle("read reset LIMIT",
            1,1,0,LIMIT,0,0, 1,1, 0,1,0,0,0);
        access_cycle("read reset COUNT",
            1,1,0,COUNT,0,0, 0,0, 0,1,0,0,0);
        access_cycle("read reset STATUS",
            1,1,0,STATUS,0,0, 0,0, 0,1,0,0,0);

        // While disabled, write/read configuration without counter progress.
        access_cycle("full-word LIMIT write updates all four bytes",
            1,1,1,LIMIT,32'h12345678,4'b1111, 0,0, 0,32'h12345678,0,0,0);
        access_cycle("read full-word LIMIT",
            1,1,0,LIMIT,0,0, 32'h12345678,32'h12345678, 0,32'h12345678,0,0,0);
        access_cycle("LIMIT mask 0101 updates bytes zero and two together",
            1,1,1,LIMIT,32'hAABBCCDD,4'b0101, 0,0, 0,32'h12BB56DD,0,0,0);
        access_cycle("read mixed-byte LIMIT",
            1,1,0,LIMIT,0,0, 32'h12BB56DD,32'h12BB56DD, 0,32'h12BB56DD,0,0,0);
        access_cycle("zero LIMIT mask preserves every byte",
            1,1,1,LIMIT,32'hFFFFFFFF,4'b0000, 0,0, 0,32'h12BB56DD,0,0,0);
        access_cycle("LIMIT mask 1010 updates the other two bytes together",
            1,1,1,LIMIT,32'hAABBCCDD,4'b1010, 0,0, 0,32'hAABBCCDD,0,0,0);
        access_cycle("read LIMIT after both byte groups",
            1,1,0,LIMIT,0,0, 32'hAABBCCDD,32'hAABBCCDD, 0,32'hAABBCCDD,0,0,0);
        access_cycle("CTRL second-byte mask cannot enable or clear",
            1,1,1,CTRL,3,4'b0010, 0,0, 0,32'hAABBCCDD,0,0,0);
        access_cycle("CTRL zero mask cannot enable or clear",
            1,1,1,CTRL,3,4'b0000, 0,0, 0,32'hAABBCCDD,0,0,0);
        access_cycle("no request blocks write controls and clear command",
            1,0,1,CTRL,3,4'b1111, 0,0, 0,32'hAABBCCDD,0,0,0);
        access_cycle("idle LIMIT address does not expose stored data",
            1,0,0,LIMIT,0,0, 0,0, 0,32'hAABBCCDD,0,0,0);

        // A/B/C/D example: clear/start, read changing count, idle, reach expiry.
        access_cycle("configure limit three while disabled",
            1,1,1,LIMIT,3,4'b1111, 0,0, 0,3,0,0,0);
        access_cycle("A: CTRL=3 clears count and saves enable in this edge",
            1,1,1,CTRL,3,4'b0001, 0,0, 1,3,0,0,1);
        access_cycle("B: COUNT read changes from zero to one across edge",
            1,1,0,COUNT,0,0, 0,1, 1,3,1,0,0);
        access_cycle("C: no bus request, but counter advances to two",
            1,0,0,COUNT,0,0, 0,0, 1,3,2,0,0);
        access_cycle("D: STATUS changes from zero to one at expiry",
            1,1,0,STATUS,0,0, 0,1, 1,3,3,1,0);
        access_cycle("CTRL read exposes enable only, not the old clear command",
            1,1,0,CTRL,0,0, 1,1, 1,3,3,1,0);
        access_cycle("expired COUNT read remains three",
            1,1,0,COUNT,0,0, 3,3, 1,3,3,1,0);
        access_cycle("expiry holds with no bus traffic",
            1,0,0,STATUS,0,0, 0,0, 1,3,3,1,0);
        access_cycle("COUNT write cannot replace counter or change configuration",
            1,1,1,COUNT,32'hFFFFFFFF,4'b1111, 0,0, 1,3,3,1,0);
        access_cycle("STATUS write cannot clear expiry or change configuration",
            1,1,1,STATUS,32'hFFFFFFFF,4'b1111, 0,0, 1,3,3,1,0);

        access_cycle("CTRL=2 clears in this edge and saves disabled state",
            1,1,1,CTRL,2,4'b0001, 0,0, 0,3,0,0,1);
        access_cycle("CTRL clear-command bit always reads zero",
            1,1,0,CTRL,0,0, 0,0, 0,3,0,0,0);
        access_cycle("disabled COUNT remains zero after command withdrawal",
            1,1,0,COUNT,0,0, 0,0, 0,3,0,0,0);
        access_cycle("STATUS below threshold after clearing",
            1,1,0,STATUS,0,0, 0,0, 0,3,0,0,0);

        // CTRL=1 changes saved enable after this edge; no early first count.
        access_cycle("CTRL=1: counter samples old disabled enable",
            1,1,1,CTRL,1,4'b0001, 0,0, 1,3,0,0,0);
        access_cycle("next edge starts counting after enable write",
            1,1,0,COUNT,0,0, 0,1, 1,3,1,0,0);
        access_cycle("masked CTRL=2 neither disables nor clears active counter",
            1,1,1,CTRL,2,4'b0010, 0,0, 1,3,2,0,0);
        access_cycle("ignored COUNT write still permits normal count increment",
            1,1,1,COUNT,0,4'b1111, 0,0, 1,3,3,1,0);

        // A configuration write and the child counter sample OLD registers together.
        access_cycle("stop and clear before reconfiguration",
            1,1,1,CTRL,2,4'b0001, 0,0, 0,3,0,0,1);
        access_cycle("configure limit five",
            1,1,1,LIMIT,5,4'b1111, 0,0, 0,5,0,0,0);
        access_cycle("enable while old enable is zero",
            1,1,1,CTRL,1,4'b0001, 0,0, 1,5,0,0,0);
        access_cycle("ignored STATUS write still permits normal counting",
            1,1,1,STATUS,32'hFFFFFFFF,4'b1111, 0,0, 1,5,1,0,0);
        access_cycle("LIMIT=1 write: count uses old limit five, then expires at two",
            1,1,1,LIMIT,1,4'b1111, 0,0, 1,1,2,1,0);
        access_cycle("read count above newly lowered threshold",
            1,1,0,COUNT,0,0, 2,2, 1,1,2,1,0);
        access_cycle("read expiry from current threshold comparison",
            1,1,0,STATUS,0,0, 1,1, 1,1,2,1,0);

        // Reset must wait for the clock and dominate a simultaneous CTRL write.
        access_cycle("synchronous reset overrides valid CTRL=3 write",
            0,1,1,CTRL,3,4'b1111, 0,0, 0,1,0,0,1);
        access_cycle("after reset CTRL is disabled and command is not stored",
            1,1,0,CTRL,0,0, 0,0, 0,1,0,0,0);
        access_cycle("after reset LIMIT returns one",
            1,1,0,LIMIT,0,0, 1,1, 0,1,0,0,0);
        access_cycle("final idle response",
            1,0,0,COUNT,0,0, 0,0, 0,1,0,0,0);

        if (errors == 0) begin
            $display("PASS: timer target checks passed");
            $finish;
        end else
            $fatal(1, "FAIL: timer target checks failed (%0d errors)", errors);
    end

    initial begin
        #20000;
        $fatal(1, "FAIL: timer target timeout");
    end
endmodule

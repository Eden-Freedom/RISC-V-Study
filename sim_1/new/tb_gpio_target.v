`timescale 1ns / 1ps
// Standalone GPIO checks. Inputs change at negedge; writes finish at posedge.
module tb_gpio_target;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg req_i = 1'b0;
    reg we_i = 1'b0;
    reg [31:0] addr_i = 32'h10000000;
    reg [31:0] wdata_i = 32'd0;
    reg [3:0] wstrb_i = 4'd0;
    wire ready_o;
    wire [31:0] rdata_o;
    wire [7:0] gpio_out_o;

    integer errors = 0;
    reg [7:0] expected_out;
    always #10 clk = ~clk;

    gpio_target dut (
        .clk(clk), .rst_n(rst_n),
        .req_i(req_i), .we_i(we_i), .addr_i(addr_i),
        .wdata_i(wdata_i), .wstrb_i(wstrb_i),
        .ready_o(ready_o), .rdata_o(rdata_o), .gpio_out_o(gpio_out_o)
    );

    task check;
        input condition;
        input [8*90-1:0] label;
        begin
            // Case inequality also fails checks containing X or Z.
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s time=%0t addr=%08h req=%b we=%b strb=%b ready=%b rdata=%08h gpio=%02h",
                         label, $time, addr_i, req_i, we_i, wstrb_i,
                         ready_o, rdata_o, gpio_out_o);
            end
        end
    endtask

    // One stimulus spans exactly one completion edge. Expected values are
    // supplied explicitly rather than generated from the DUT's decode rules.
    task access_cycle;
        input [8*70-1:0] label;
        input reset_n_value;
        input request_value;
        input write_value;
        input [31:0] address_value;
        input [31:0] data_value;
        input [3:0] strobe_value;
        input [31:0] expected_read;
        input [7:0] expected_after;
        begin
            @(negedge clk);
            rst_n = reset_n_value;
            req_i = request_value;
            we_i = write_value;
            addr_i = address_value;
            wdata_i = data_value;
            wstrb_i = strobe_value;
            #1;
            $display("CHECK: %0s", label);
            check(ready_o === request_value, "combinational ready follows request");
            check(rdata_o === expected_read, "combinational read response");
            check(gpio_out_o === expected_out, "output holds before the rising edge");

            @(posedge clk);
            #1; // Let nonblocking register updates settle.
            check(gpio_out_o === expected_after, "output after the completion/reset edge");
            check(ready_o === request_value, "ready remains defined after the edge");
            check(rdata_o === expected_read, "read response after the edge");
            expected_out = expected_after;
        end
    endtask

    initial begin
        // The output register is not initialized by the TB. Synchronous reset
        // must clear it at a real rising edge before checking its value.
        @(posedge clk);
        #1;
        check(gpio_out_o === 8'h00, "initial synchronous reset clears output");
        check(ready_o === 1'b0, "no request during initial reset");
        check(rdata_o === 32'd0, "idle read response during reset");
        expected_out = 8'h00;

        access_cycle("word write: keep only low byte A5",
                     1, 1, 1, 32'h10000000, 32'h123456A5, 4'b1111, 32'd0, 8'hA5);
        access_cycle("read back zero-extended A5",
                     1, 1, 0, 32'h10000000, 32'd0, 4'b0000, 32'h000000A5, 8'hA5);
        access_cycle("idle with write controls and different address/data",
                     1, 0, 1, 32'h1000000C, 32'hFFFFFFFF, 4'b1111, 32'd0, 8'hA5);
        access_cycle("idle read of output word still returns zero",
                     1, 0, 0, 32'h10000000, 32'h87654321, 4'b0000, 32'd0, 8'hA5);

        // SB at byte offset 1: EX would place the byte in wdata[15:8].
        access_cycle("second-byte write cannot change low-byte output",
                     1, 1, 1, 32'h10000001, 32'h00005A00, 4'b0010, 32'd0, 8'hA5);
        access_cycle("zero byte mask ignores write",
                     1, 1, 1, 32'h10000000, 32'hFFFFFFFF, 4'b0000, 32'd0, 8'hA5);
        access_cycle("low-byte write updates output to 3C",
                     1, 1, 1, 32'h10000000, 32'h0000003C, 4'b0001, 32'd0, 8'h3C);
        access_cycle("read back 3C",
                     1, 1, 0, 32'h10000000, 32'd0, 4'b0000, 32'h0000003C, 8'h3C);

        access_cycle("reserved word 04: write ignored",
                     1, 1, 1, 32'h10000004, 32'hFFFFFFFF, 4'b1111, 32'd0, 8'h3C);
        access_cycle("reserved word 04: read zero",
                     1, 1, 0, 32'h10000004, 32'd0, 4'b0000, 32'd0, 8'h3C);
        access_cycle("reserved word 08: write ignored",
                     1, 1, 1, 32'h10000008, 32'hFFFFFFFF, 4'b1111, 32'd0, 8'h3C);
        access_cycle("reserved word 08: read zero",
                     1, 1, 0, 32'h10000008, 32'd0, 4'b0000, 32'd0, 8'h3C);
        access_cycle("reserved word 0C: write ignored",
                     1, 1, 1, 32'h1000000C, 32'hFFFFFFFF, 4'b1111, 32'd0, 8'h3C);
        access_cycle("reserved word 0C: read zero",
                     1, 1, 0, 32'h1000000C, 32'd0, 4'b0000, 32'd0, 8'h3C);

        // Output is nonzero before reset; reset must wait for posedge and
        // override the otherwise valid write of 5A on that same edge.
        access_cycle("synchronous reset has priority over valid write",
                     0, 1, 1, 32'h10000000, 32'h0000005A, 4'b0001, 32'd0, 8'h00);
        access_cycle("release reset and withdraw request",
                     1, 0, 1, 32'h10000000, 32'hFFFFFFFF, 4'b1111, 32'd0, 8'h00);
        access_cycle("read zero after reset",
                     1, 1, 0, 32'h10000000, 32'd0, 4'b0000, 32'd0, 8'h00);

        if (errors == 0) begin
            $display("PASS: GPIO target checks passed");
            $finish;
        end else
            $fatal(1, "FAIL: GPIO target checks failed (%0d errors)", errors);
    end

    initial begin
        #5000;
        $fatal(1, "FAIL: GPIO target timeout");
    end
endmodule
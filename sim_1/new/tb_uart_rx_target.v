`timescale 1ns / 1ps

module tb_uart_rx_target;
    localparam integer CLKS_PER_BIT = 4;
    localparam [31:0] STATUS = 32'h1000_0024;
    localparam [31:0] RXDATA = 32'h1000_0028;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg rx_i = 1'b1;
    reg req_i = 1'b0;
    reg [31:0] addr_i = 32'd0;
    wire ready_o;
    wire [31:0] rdata_o;
    wire tx_o;

    always #5 clk = ~clk;

    uart_tx_target dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_i(rx_i),
        .req_i(req_i),
        .we_i(1'b0),
        .addr_i(addr_i),
        .wdata_i(32'd0),
        .wstrb_i(4'd0),
        .ready_o(ready_o),
        .rdata_o(rdata_o),
        .tx_o(tx_o)
    );

    task drive_bit;
        input value;
        begin
            @(negedge clk);
            rx_i = value;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task drive_start_and_data;
        input [7:0] byte_to_send;
        integer i;
        begin
            drive_bit(1'b0);
            for (i = 0; i < 8; i = i + 1) begin
                drive_bit(byte_to_send[i]);
            end
        end
    endtask

    task check_read;
        input [31:0] address;
        input [31:0] expected;
        begin
            @(negedge clk);
            req_i = 1'b1;
            addr_i = address;

            // Observe the value transferred before the DUT updates the buffer.
            @(posedge clk);
            if (ready_o !== 1'b1 || rdata_o !== expected) begin
                $fatal(1, "read %h at %0t: ready=%b data=%h expected=%h",
                       address, $time, ready_o, rdata_o, expected);
            end

            @(negedge clk);
            req_i = 1'b0;
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        check_read(RXDATA, 32'd0);

        drive_start_and_data(8'h96);
        drive_bit(1'b1);
        check_read(STATUS, 32'd2);
        check_read(STATUS, 32'd2);

        // The full buffer must keep 96 when A5 arrives.
        drive_start_and_data(8'hA5);
        drive_bit(1'b1);

        drive_start_and_data(8'h3C);
        @(negedge clk);
        rx_i = 1'b1;
        repeat (3) @(posedge clk);
        #1;
        if (dut.rx_valid !== 1'b1 || dut.rx_data !== 8'h3C) begin
            $fatal(1, "expected RX to publish 3C on the third stop-bit edge");
        end

        // This read completes on the fourth stop-bit edge, when the buffer
        // consumes rx_valid and can replace the outgoing 96 with 3C.
        check_read(RXDATA, 32'h0000_0096);
        check_read(STATUS, 32'd2);
        check_read(RXDATA, 32'h0000_003C);
        check_read(STATUS, 32'd0);
        check_read(RXDATA, 32'd0);

        $display("PASS: UART RX target checks passed");
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "UART RX target test timed out");
    end
endmodule

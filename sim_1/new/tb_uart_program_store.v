`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 15:45:15
// Design Name: 
// Module Name: tb_uart_program_store
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_uart_program_store;
    localparam integer CLKS_PER_BIT = 4;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg uart_rx_i = 1'b1;
    reg [31:0] fetch_addr_i = 32'd0;
    wire [31:0] instr_o;
    wire full_o;

    uart_program_store dut (
        .clk(clk),
        .rst_n(rst_n),
        .fetch_addr_i(fetch_addr_i),
        .uart_rx_i(uart_rx_i),
        .instr_o(instr_o),
        .full_o(full_o)
    );

    always #5 clk = ~clk;

    task drive_bit;
        input value;
        begin
            @(negedge clk);
            uart_rx_i = value;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task send_byte;
        input [7:0] data;
        integer bit_index;
        begin
            drive_bit(1'b0);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                drive_bit(data[bit_index]);
            end
            drive_bit(1'b1);
        end
    endtask

    task expect_not_full;
        begin
            if (full_o !== 1'b0) begin
                $fatal(1, "At %0t expected full_o=0, got %b", $time, full_o);
            end
        end
    endtask

    task check_loaded_word;
        input [31:0] address;
        input [31:0] expected;
        begin
            fetch_addr_i = address;

            // send_byte 在停止位第 4 个上升沿返回。再等一沿完成存储写入。
            @(posedge clk);
            #1;
            if (instr_o !== expected) begin
                $fatal(1, "At %0t fetch %h: expected %h, got %h",
                       $time, address, expected, instr_o);
            end
            expect_not_full;
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        expect_not_full;
        rst_n = 1'b1;

        send_byte(8'h93);
        send_byte(8'h00);
        send_byte(8'h70);
        send_byte(8'h00);
        check_loaded_word(32'h0000_0000, 32'h0070_0093);

        send_byte(8'h6F);
        send_byte(8'h00);
        send_byte(8'h00);
        send_byte(8'h00);
        check_loaded_word(32'h0000_0004, 32'h0000_006F);

        $display("PASS: UART program store checks passed");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "UART program store test timed out");
    end
endmodule

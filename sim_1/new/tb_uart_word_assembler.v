`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 15:00:53
// Design Name: 
// Module Name: tb_uart_word_assembler
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


module tb_uart_word_assembler;
    localparam [31:0] FIRST_WORD  = 32'h0070_0093;
    localparam [31:0] SECOND_WORD = 32'h89AB_CDEF;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg byte_valid_i = 1'b0;
    reg [7:0] byte_data_i = 8'd0;
    wire word_valid_o;
    wire [31:0] word_data_o;

    uart_word_assembler dut (
        .clk(clk),
        .rst_n(rst_n),
        .byte_valid_i(byte_valid_i),
        .byte_data_i(byte_data_i),
        .word_valid_o(word_valid_o),
        .word_data_o(word_data_o)
    );

    always #5 clk = ~clk;

    task drive_and_check;
        input valid;
        input [7:0] data;
        input expected_valid;
        input [31:0] expected_word;
        begin
            @(negedge clk);
            byte_valid_i = valid;
            byte_data_i = data;

            @(posedge clk);
            #1;
            if (word_valid_o !== expected_valid || word_data_o !== expected_word) begin
                $fatal(1, "At %0t input valid=%b byte=%h: expected valid=%b word=%h, got valid=%b word=%h",
                       $time, valid, data, expected_valid, expected_word, word_valid_o, word_data_o);
            end
        end
    endtask

    initial begin
        @(posedge clk);
        #1;
        if (word_valid_o !== 1'b0 || word_data_o !== 32'd0) begin
            $fatal(1, "Reset expected valid=0 word=0, got valid=%b word=%h",
                   word_valid_o, word_data_o);
        end
        @(negedge clk);
        rst_n = 1'b1;

        drive_and_check(1'b1, 8'h93, 1'b0, 32'd0);
        drive_and_check(1'b1, 8'h00, 1'b0, 32'd0);
        drive_and_check(1'b1, 8'h70, 1'b0, 32'd0);

        // 已收三字节。空拍上的数据变化不应触发发布或被计入。
        drive_and_check(1'b0, 8'hFF, 1'b0, 32'd0);
        drive_and_check(1'b0, 8'hA5, 1'b0, 32'd0);
        drive_and_check(1'b1, 8'h00, 1'b1, FIRST_WORD);
        drive_and_check(1'b0, 8'h00, 1'b0, FIRST_WORD);

        // 连续送第二组字节，前三拍保持上一组完整字。
        drive_and_check(1'b1, 8'hEF, 1'b0, FIRST_WORD);
        drive_and_check(1'b1, 8'hCD, 1'b0, FIRST_WORD);
        drive_and_check(1'b1, 8'hAB, 1'b0, FIRST_WORD);
        drive_and_check(1'b1, 8'h89, 1'b1, SECOND_WORD);
        drive_and_check(1'b0, 8'h00, 1'b0, SECOND_WORD);

        $display("PASS: UART word assembler checks passed");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "UART word assembler test timed out");
    end
endmodule

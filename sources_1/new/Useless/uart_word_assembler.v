`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 14:44:51
// Design Name: 
// Module Name: uart_word_assembler
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


module uart_word_assembler(
    input wire clk,
    input wire rst_n,
    input wire byte_valid_i,
    input wire [7:0] byte_data_i,
    output reg word_valid_o,
    output reg [31:0]word_data_o
    );

    reg [23:0] word_data_reg;//只保存前三个字节，第四个字节来的时候直接发出去
    reg [1:0] byte_cnt;//记录当前是第几个字节

    always @(posedge clk ) begin
        if(!rst_n) begin
            word_data_reg <= 24'd0;
            byte_cnt <= 2'd0;
            word_valid_o <= 1'b0;
            word_data_o <= 32'd0;
        end
        else begin
            word_valid_o <= 1'b0;
            if(byte_valid_i) begin
                case(byte_cnt)
                    2'd0: begin
                        word_data_reg[7:0] <= byte_data_i;
                        byte_cnt <= byte_cnt + 1'b1;
                    end
                    2'd1: begin
                        word_data_reg[15:8] <= byte_data_i;
                        byte_cnt <= byte_cnt + 1'b1;
                    end
                    2'd2: begin
                        word_data_reg[23:16] <= byte_data_i;
                        byte_cnt <= byte_cnt + 1'b1;
                    end
                    2'd3: begin
                        word_data_o  <= {byte_data_i, word_data_reg};
                        word_valid_o <= 1'b1;
                        byte_cnt     <= 2'd0;
                    end
                endcase

            end
        end
    end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/17 16:18:04
// Design Name: 
// Module Name: pc_reg
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

//程序计数器
module pc_reg(
    input wire clk,
    input wire rst_n,
    input wire pc_brench_flag_i,
    input wire [31:0] pc_brench_addr_i,
    input wire pc_stall_i,

    output reg [31:0] pc_o
    );

    always@(posedge clk) begin
        if(!rst_n) begin
            pc_o <= 32'h00000000;
        end else if(pc_brench_flag_i) begin
            pc_o <= pc_brench_addr_i;
        end else if(pc_stall_i) begin
            pc_o <= pc_o;
        end else begin
            pc_o <= pc_o + 32'h00000004;
        end
    end
endmodule

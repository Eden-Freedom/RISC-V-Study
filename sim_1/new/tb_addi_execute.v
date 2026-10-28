`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 15:47:48
// Design Name: 
// Module Name: tb_addi_execute
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


module tb_addi_execute();

reg is_addi_i;
reg [31:0] imm_i;
reg [31:0] rs1_data_i;
reg [4:0] rd_addr_i;
wire wr_en_o;
wire [4:0] wr_addr_o;
wire [31:0] wr_data_o;

initial begin
    is_addi_i = 0;
    imm_i = 32'h00000000;
    rs1_data_i = 32'h00000000;
    rd_addr_i = 5'd0;
    #10
    is_addi_i = 1;
    imm_i = 32'h00000005;
    rs1_data_i = 32'h00000000;
    rd_addr_i = 5'd1;
    #10
    is_addi_i = 1;
    imm_i = 32'hffffffff;
    rs1_data_i = 32'h00000005;
    rd_addr_i = 5'd2;
    #10
    is_addi_i = 1;
    imm_i = 32'h00000001;
    rs1_data_i = 32'hffffffff;
    rd_addr_i = 5'd3;
    #10
    is_addi_i = 0;
    imm_i = 32'h00000009;
    rs1_data_i = 32'h00000007;
    rd_addr_i = 5'd4;
    #10
    $finish;
    end

initial begin
    $monitor("time =%dns,is_addi_i = %b,imm_i = %h,rs1_data_i = %h,rd_addr_i = %d,wr_en_o = %b,wr_addr_o = %d,wr_data_o = %h",$time,is_addi_i,imm_i,rs1_data_i,rd_addr_i,wr_en_o,wr_addr_o,wr_data_o);
end

addi_execute u_addi_execute(
    .is_addi_i(is_addi_i),
    .imm_i(imm_i),
    .rs1_data_i(rs1_data_i),
    .rd_addr_i(rd_addr_i),
    .wr_en_o(wr_en_o),
    .wr_addr_o(wr_addr_o),
    .wr_data_o(wr_data_o)
);
endmodule

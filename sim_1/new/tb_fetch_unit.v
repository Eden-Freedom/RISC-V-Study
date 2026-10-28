`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 10:17:23
// Design Name: 
// Module Name: tb_fetch_unit
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


module tb_fetch_unit();

reg clk;
reg rst_n;
wire [31:0] pc_o;
wire [31:0] instr_o;

wire [31:0] imm_o;
wire [4:0] rs1_addr_o;
wire [4:0] rs2_addr_o;
wire [4:0] rd_addr_o;
wire is_addi_o;
wire is_add_o;
wire [31:0] rs1_data_o;
wire [31:0] rs2_data_o;

initial begin
    clk = 0;
end

always #10 clk = ~clk;

initial begin
    rst_n = 0;
    #25 rst_n = 1;
end

initial begin
    $monitor("time =%dns,rst_n = %b,pc_o = %h,instr_o = %h,imm_o = %h,rs1_addr_o = %d,rs2_addr_o = %d,rd_addr_o = %d,is_addi_o = %b,is_add_o = %b",
              $time,rst_n,pc_o,instr_o,imm_o,rs1_addr_o,rs2_addr_o,rd_addr_o,is_addi_o,is_add_o);
    #100 $finish;
end

fetch_unit u_fetch_unit(
    .clk(clk),
    .rst_n(rst_n),
    .pc_o(pc_o),
    .instr_o(instr_o)
);

addi_decode u_addi_decode(
    .instr_i(instr_o),
    .imm_o(imm_o),
    .rs1_addr_o(rs1_addr_o),
    .rs2_addr_o(rs2_addr_o),
    .rd_addr_o(rd_addr_o),
    .is_addi_o(is_addi_o),
    .is_add_o(is_add_o)
);

// regfile u_regfile(
//     .clk(clk),
//     .rst_n(rst_n),
//     .wr_en_i(is_addi_o),
//     .wr_addr_i(rd_addr_o),
//     .wr_data_i(imm_o),
//     .rs1_addr_i(rs1_addr_o),
//     .rs1_data_o(rs1_data_o),
//     .rs2_addr_i(rs2_addr_o),
//     .rs2_data_o(rs2_data_o)
// );
endmodule

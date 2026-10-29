`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 10:12:53
// Design Name: 
// Module Name: fetch_unit
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

//取指
module fetch_unit(
    input wire clk,
    input wire rst_n,
    input wire pc_brench_flag_i,
    input wire [31:0] pc_brench_addr_i,
    input wire pc_stall_i,

    output wire [31:0] pc_o,
    output wire [31:0] instr_o
    );

    pc_reg  pc_reg_inst (
    .clk(clk),
    .rst_n(rst_n),
    .pc_o(pc_o),
    .pc_brench_flag_i(pc_brench_flag_i),
    .pc_brench_addr_i(pc_brench_addr_i),
    .pc_stall_i(pc_stall_i)
  );
  imem imem_inst(
    .addr_i(pc_o),
    .instr_o(instr_o)
  );
endmodule

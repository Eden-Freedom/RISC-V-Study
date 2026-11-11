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
module fetch_unit#(
  parameter USE_EXTERNAL_INSTR = 0
)(
    input wire clk,
    input wire rst_n,
    input wire pc_brench_flag_i,
    input wire [31:0] pc_brench_addr_i,
    input wire pc_stall_i,

    input wire[31:0] external_instr_i,

    output wire [31:0] pc_o,
    output reg [31:0] instr_o
    );

    wire [31:0]imem_instr_o;

    always @(*) begin
      if(USE_EXTERNAL_INSTR) begin
        instr_o = external_instr_i;
      end
      else begin
        instr_o = imem_instr_o;
    end
  end


    pc_reg  pc_reg_inst (
    .clk(clk),
    .rst_n(rst_n),
    .pc_o(pc_o),
    .pc_brench_flag_i(pc_brench_flag_i),
    .pc_brench_addr_i(pc_brench_addr_i),
    .pc_stall_i(pc_stall_i)
  );

  instruction_rom instruction_rom_inst(
    .addr_i(pc_o),
    .instr_o(imem_instr_o)
  );
endmodule

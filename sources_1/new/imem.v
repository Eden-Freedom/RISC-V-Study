`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 09:58:34
// Design Name: 
// Module Name: imem
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

//指令存储
`timescale 1ns / 1ps

module imem (
    input  wire [31:0] addr_i,
    output reg  [31:0] instr_o
);

always @(*) begin
  case (addr_i)

  // LUI及其结果的rs1旁路
  32'h00000000: instr_o = 32'h123450B7; // LUI  x1,0x12345   => 12345000
  32'h00000004: instr_o = 32'h00108113; // ADDI x2,x1,1      => 12345001

  // LUI边界
  32'h00000008: instr_o = 32'h800001B7; // LUI  x3,0x80000   => 80000000
  32'h0000000C: instr_o = 32'h00000237; // LUI  x4,0         => 00000000
  32'h00000010: instr_o = 32'hFFFFF2B7; // LUI  x5,0xFFFFF   => FFFFF000

  // AUIPC及其结果的rs2旁路
  32'h00000014: instr_o = 32'h00001317; // AUIPC x6,1        => 00001014
  32'h00000018: instr_o = 32'h006003B3; // ADD   x7,x0,x6    => 00001014

  // AUIPC零立即数及高位边界
  32'h0000001C: instr_o = 32'h00000417; // AUIPC x8,0        => 0000001C
  32'h00000020: instr_o = 32'h80000497; // AUIPC x9,0x80000  => 80000020
  32'h00000024: instr_o = 32'hFFFFF517; // AUIPC x10,0xFFFFF => FFFFF024

  // 相同U字段，LUI与AUIPC结果不同
  32'h00000028: instr_o = 32'h000015B7; // LUI   x11,1       => 00001000
  32'h0000002C: instr_o = 32'h00001617; // AUIPC x12,1       => 0000102C

  // AUIPC结果的rs1旁路
  32'h00000030: instr_o = 32'hFFF60693; // ADDI x13,x12,-1   => 0000102B

  // LUI写x0，下一条同时读取两路x0
  32'h00000034: instr_o = 32'hABCDE037; // LUI x0,0xABCDE，结果应丢弃
  32'h00000038: instr_o = 32'h00000733; // ADD x14,x0,x0     => 00000000

  // AUIPC写x0，下一条同时读取两路x0
  32'h0000003C: instr_o = 32'h00001017; // AUIPC x0,1，结果0000103C应丢弃
  32'h00000040: instr_o = 32'h000007B3; // ADD x15,x0,x0     => 00000000

  // 完成标志
  32'h00000044: instr_o = 32'h0000006F; // JAL x0,0

  default: instr_o = 32'h00000000;
endcase

end

endmodule

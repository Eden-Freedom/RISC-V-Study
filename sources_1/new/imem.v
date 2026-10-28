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

  // 初始化：x1=000005A5，x2=FFFFFFFF
  32'h00000000: instr_o = 32'h5A500093; // ADDI x1,x0,1445
  32'h00000004: instr_o = 32'hFFF00113; // ADDI x2,x0,-1

  // XORI
  32'h00000008: instr_o = 32'h0000C513; // XORI x10,x1,0      => 000005A5
  32'h0000000C: instr_o = 32'h3C30C513; // XORI x10,x1,963    => 00000666
  32'h00000010: instr_o = 32'hFFF0C513; // XORI x10,x1,-1     => FFFFFA5A
  32'h00000014: instr_o = 32'hFFF14513; // XORI x10,x2,-1     => 00000000
  32'h00000018: instr_o = 32'h80004513; // XORI x10,x0,-2048  => FFFFF800
  32'h0000001C: instr_o = 32'h7FF04513; // XORI x10,x0,2047   => 000007FF

  // ORI
  32'h00000020: instr_o = 32'h0000E513; // ORI x10,x1,0       => 000005A5
  32'h00000024: instr_o = 32'h3C30E513; // ORI x10,x1,963     => 000007E7
  32'h00000028: instr_o = 32'h8000E513; // ORI x10,x1,-2048   => FFFFFDA5
  32'h0000002C: instr_o = 32'hFFF06513; // ORI x10,x0,-1      => FFFFFFFF
  32'h00000030: instr_o = 32'h7FF06513; // ORI x10,x0,2047    => 000007FF

  // ANDI
  32'h00000034: instr_o = 32'h0000F513; // ANDI x10,x1,0      => 00000000
  32'h00000038: instr_o = 32'h3C30F513; // ANDI x10,x1,963    => 00000181
  32'h0000003C: instr_o = 32'hFFF0F513; // ANDI x10,x1,-1     => 000005A5
  32'h00000040: instr_o = 32'h80017513; // ANDI x10,x2,-2048  => FFFFF800
  32'h00000044: instr_o = 32'h7FF17513; // ANDI x10,x2,2047   => 000007FF

  // 紧邻依赖链
  32'h00000048: instr_o = 32'h3C30CA13; // XORI x20,x1,963    => 00000666
  32'h0000004C: instr_o = 32'h080A6A93; // ORI  x21,x20,128   => 000006E6
  32'h00000050: instr_o = 32'h0FFAFB13; // ANDI x22,x21,255   => 000000E6
  32'h00000054: instr_o = 32'h01600BB3; // ADD  x23,x0,x22    => 000000E6

  // XORI写x0，下一条读取两路x0
  32'h00000058: instr_o = 32'hFFF0C013; // XORI x0,x1,-1，结果FFFFFA5A应丢弃
  32'h0000005C: instr_o = 32'h00000C33; // ADD x24,x0,x0      => 00000000

  // ORI写x0，下一条读取两路x0
  32'h00000060: instr_o = 32'hFFF06013; // ORI x0,x0,-1，结果FFFFFFFF应丢弃
  32'h00000064: instr_o = 32'h00000CB3; // ADD x25,x0,x0      => 00000000

  // ANDI写x0，下一条读取两路x0
  32'h00000068: instr_o = 32'h80017013; // ANDI x0,x2,-2048，结果FFFFF800应丢弃
  32'h0000006C: instr_o = 32'h00000D33; // ADD x26,x0,x0      => 00000000

  // 程序终点
  32'h00000070: instr_o = 32'h0000006F; // JAL x0,0

  default: instr_o = 32'h00000000;
endcase

end

endmodule

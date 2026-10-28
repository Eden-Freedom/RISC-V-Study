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
  32'h00000000: instr_o = 32'h04000093; // 00 ADDI x1,x0,64
  32'h00000004: instr_o = 32'h80FF8137; // 04 LUI  x2,0x80FF8
  32'h00000008: instr_o = 32'hF0110113; // 08 ADDI x2,x2,-255
  32'h0000000C: instr_o = 32'h0020A023; // 0C SW   x2,0(x1)
  
  32'h00000010: instr_o = 32'h00008183; // 10 LB   x3,0(x1)
  32'h00000014: instr_o = 32'h00118213; // 14 ADDI x4,x3,1
  32'h00000018: instr_o = 32'h0010C283; // 18 LBU  x5,1(x1)
  32'h0000001C: instr_o = 32'h00208303; // 1C LB   x6,2(x1)
  32'h00000020: instr_o = 32'h0030C383; // 20 LBU  x7,3(x1)
  
  32'h00000024: instr_o = 32'h00009403; // 24 LH   x8,0(x1)
  32'h00000028: instr_o = 32'h0000D483; // 28 LHU  x9,0(x1)
  32'h0000002C: instr_o = 32'h00209503; // 2C LH   x10,2(x1)
  32'h00000030: instr_o = 32'h0020D583; // 30 LHU  x11,2(x1)
  
  32'h00000034: instr_o = 32'h0AA00613; // 34 ADDI x12,x0,0xAA
  32'h00000038: instr_o = 32'h0BB00693; // 38 ADDI x13,x0,0xBB
  32'h0000003C: instr_o = 32'h0CC00713; // 3C ADDI x14,x0,0xCC
  32'h00000040: instr_o = 32'h0DD00793; // 40 ADDI x15,x0,0xDD
  
  32'h00000044: instr_o = 32'h00001837; // 44 LUI  x16,1
  32'h00000048: instr_o = 32'h12280813; // 48 ADDI x16,x16,0x122 => 0x1122
  32'h0000004C: instr_o = 32'h000038B7; // 4C LUI  x17,3
  32'h00000050: instr_o = 32'h34488893; // 50 ADDI x17,x17,0x344 => 0x3344
  
  32'h00000054: instr_o = 32'h00C08023; // 54 SB   x12,0(x1)
  32'h00000058: instr_o = 32'h00D080A3; // 58 SB   x13,1(x1)
  32'h0000005C: instr_o = 32'h00E08123; // 5C SB   x14,2(x1)
  32'h00000060: instr_o = 32'h00F081A3; // 60 SB   x15,3(x1)
  
  32'h00000064: instr_o = 32'h01009023; // 64 SH   x16,0(x1)
  32'h00000068: instr_o = 32'h01109123; // 68 SH   x17,2(x1)
  
  32'h0000006C: instr_o = 32'h00C0006F; // 6C JAL  x0,12
  
  32'h00000070: instr_o = 32'h00C08023; // 70 SB   x12,0(x1)，错误路径
  32'h00000074: instr_o = 32'h01009123; // 74 SH   x16,2(x1)，错误路径
  
  32'h00000078: instr_o = 32'h0000A903; // 78 LW   x18,0(x1)
  32'h0000007C: instr_o = 32'h00190993; // 7C ADDI x19,x18,1
  32'h00000080: instr_o = 32'h0000006F; // 80 JAL  x0,0

  default:     instr_o = 32'h00000000;
endcase

end

endmodule

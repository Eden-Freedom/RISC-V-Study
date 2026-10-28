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
  32'h00000000: instr_o = 32'hFFF00093; // ADDI x1,x0,-1; rd result = FFFFFFFF
  32'h00000004: instr_o = 32'h80000137; // LUI x2,0x80000; rd result = 80000000
  32'h00000008: instr_o = 32'hFFF10193; // ADDI x3,x2,-1; rd result = 7FFFFFFF
  32'h0000000C: instr_o = 32'h00200213; // ADDI x4,x0,2; rd result = 00000002
  32'h00000010: instr_o = 32'h00300293; // ADDI x5,x0,3; rd result = 00000003
  32'h00000014: instr_o = 32'h00700313; // ADDI x6,x0,7; rd result = 00000007
  32'h00000018: instr_o = 32'h026283B3; // MUL x7,x5,x6; rd result = 00000015
  32'h0000001C: instr_o = 32'h00138413; // ADDI x8,x7,1; rd result = 00000016; MUL -> ADDI rs1
  32'h00000020: instr_o = 32'h026294B3; // MULH x9,x5,x6; rd result = 00000000
  32'h00000024: instr_o = 32'h0262A533; // MULHSU x10,x5,x6; rd result = 00000000
  32'h00000028: instr_o = 32'h0262B5B3; // MULHU x11,x5,x6; rd result = 00000000
  32'h0000002C: instr_o = 32'h021083B3; // MUL x7,x1,x1; rd result = 00000001
  32'h00000030: instr_o = 32'h02109433; // MULH x8,x1,x1; rd result = 00000000
  32'h00000034: instr_o = 32'h0210A4B3; // MULHSU x9,x1,x1; rd result = FFFFFFFF
  32'h00000038: instr_o = 32'h00900533; // ADD x10,x0,x9; rd result = FFFFFFFF; MULHSU -> ADD rs2
  32'h0000003C: instr_o = 32'h0210B5B3; // MULHU x11,x1,x1; rd result = FFFFFFFE
  32'h00000040: instr_o = 32'h00158613; // ADDI x12,x11,1; rd result = FFFFFFFF; MULHU -> ADDI
  32'h00000044: instr_o = 32'h021103B3; // MUL x7,x2,x1; rd result = 80000000
  32'h00000048: instr_o = 32'h02111433; // MULH x8,x2,x1; rd result = 00000000
  32'h0000004C: instr_o = 32'h021124B3; // MULHSU x9,x2,x1; rd result = 80000000
  32'h00000050: instr_o = 32'h02113533; // MULHU x10,x2,x1; rd result = 7FFFFFFF
  32'h00000054: instr_o = 32'h0220A5B3; // MULHSU x11,x1,x2; rd result = FFFFFFFF; swap SU sources
  32'h00000058: instr_o = 32'h022103B3; // MUL x7,x2,x2; rd result = 00000000
  32'h0000005C: instr_o = 32'h02211433; // MULH x8,x2,x2; rd result = 40000000
  32'h00000060: instr_o = 32'h022124B3; // MULHSU x9,x2,x2; rd result = C0000000
  32'h00000064: instr_o = 32'h02213533; // MULHU x10,x2,x2; rd result = 40000000
  32'h00000068: instr_o = 32'h023183B3; // MUL x7,x3,x3; rd result = 00000001
  32'h0000006C: instr_o = 32'h02319433; // MULH x8,x3,x3; rd result = 3FFFFFFF
  32'h00000070: instr_o = 32'h0231A4B3; // MULHSU x9,x3,x3; rd result = 3FFFFFFF
  32'h00000074: instr_o = 32'h0231B533; // MULHU x10,x3,x3; rd result = 3FFFFFFF
  32'h00000078: instr_o = 32'h021003B3; // MUL x7,x0,x1; rd result = 00000000
  32'h0000007C: instr_o = 32'h02009433; // MULH x8,x1,x0; rd result = 00000000
  32'h00000080: instr_o = 32'h022024B3; // MULHSU x9,x0,x2; rd result = 00000000
  32'h00000084: instr_o = 32'h02013533; // MULHU x10,x2,x0; rd result = 00000000
  32'h00000088: instr_o = 32'h00100693; // ADDI x13,x0,1; rd result = 00000001
  32'h0000008C: instr_o = 32'h02D083B3; // MUL x7,x1,x13; rd result = FFFFFFFF; ADDI -> MUL rs2
  32'h00000090: instr_o = 32'h02439433; // MULH x8,x7,x4; rd result = FFFFFFFF; MUL -> MULH rs1
  32'h00000094: instr_o = 32'h00240713; // ADDI x14,x8,2; rd result = 00000001; MULH -> ADDI
  32'h00000098: instr_o = 32'hFFE00693; // ADDI x13,x0,-2; rd result = FFFFFFFE
  32'h0000009C: instr_o = 32'h0246A4B3; // MULHSU x9,x13,x4; rd result = FFFFFFFF; ADDI -> MULHSU rs1
  32'h000000A0: instr_o = 32'h02923533; // MULHU x10,x4,x9; rd result = 00000001; MULHSU -> MULHU rs2
  32'h000000A4: instr_o = 32'h026505B3; // MUL x11,x10,x6; rd result = 00000007; MULHU -> MUL rs1
  32'h000000A8: instr_o = 32'h00B00633; // ADD x12,x0,x11; rd result = 00000007; MUL -> ADD rs2
  32'h000000AC: instr_o = 32'h02628033; // MUL x0,x5,x6; rd result = 00000015
  32'h000000B0: instr_o = 32'h000007B3; // ADD x15,x0,x0; rd result = 00000000; x0 probe
  32'h000000B4: instr_o = 32'h02409033; // MULH x0,x1,x4; rd result = FFFFFFFF
  32'h000000B8: instr_o = 32'h00000833; // ADD x16,x0,x0; rd result = 00000000; x0 probe
  32'h000000BC: instr_o = 32'h02112033; // MULHSU x0,x2,x1; rd result = 80000000
  32'h000000C0: instr_o = 32'h000008B3; // ADD x17,x0,x0; rd result = 00000000; x0 probe
  32'h000000C4: instr_o = 32'h0210B033; // MULHU x0,x1,x1; rd result = FFFFFFFE
  32'h000000C8: instr_o = 32'h00000933; // ADD x18,x0,x0; rd result = 00000000; x0 probe
  32'h000000CC: instr_o = 32'h05500993; // ADDI x19,x0,85; rd result = 00000055
  32'h000000D0: instr_o = 32'h00C00A6F; // JAL x20,12; rd result = 000000D4
  32'h000000D4: instr_o = 32'h026289B3; // MUL x19,x5,x6; WRONG PATH: must not execute
  32'h000000D8: instr_o = 32'h0210B9B3; // MULHU x19,x1,x1; WRONG PATH: must not execute
  32'h000000DC: instr_o = 32'h00198A93; // ADDI x21,x19,1; rd result = 00000056
  32'h000000E0: instr_o = 32'h0240AB33; // MULHSU x22,x1,x4; rd result = FFFFFFFF
  32'h000000E4: instr_o = 32'h001B0B93; // ADDI x23,x22,1; rd result = 00000000; MULHSU -> ADDI
  32'h000000E8: instr_o = 32'h0000006F; // JAL x0,0; rd result = 000000EC; DONE
  default: instr_o = 32'h00000000;
endcase

end

endmodule

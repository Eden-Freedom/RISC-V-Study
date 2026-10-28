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
  if      (addr_i == 32'h00000000) instr_o = 32'h04400093; // ADDI x1,x0,68
  else if (addr_i == 32'h00000004) instr_o = 32'h02A00113; // ADDI x2,x0,42
  else if (addr_i == 32'h00000008) instr_o = 32'hFE20AE23; // SW   x2,-4(x1)
  else if (addr_i == 32'h0000000C) instr_o = 32'hFFC0A183; // LW   x3,-4(x1)
  else if (addr_i == 32'h00000010) instr_o = 32'h00118213; // ADDI x4,x3,1
  else if (addr_i == 32'h00000014) instr_o = 32'h0040A023; // SW   x4,0(x1)
  else if (addr_i == 32'h00000018) instr_o = 32'h0000A283; // LW   x5,0(x1)
  else if (addr_i == 32'h0000001C) instr_o = 32'h00500333; // ADD  x6,x0,x5
  else if (addr_i == 32'h00000020) instr_o = 32'h0080006F; // JAL  x0,8
  else if (addr_i == 32'h00000024) instr_o = 32'hFE00AE23; // SW   x0,-4(x1) 错误路径
  else if (addr_i == 32'h00000028) instr_o = 32'hFFC0A383; // LW   x7,-4(x1) 跳转目标
  else if (addr_i == 32'h0000002C) instr_o = 32'h0000006F; // JAL  x0,0 完成点
  else                              instr_o = 32'h00000000;

end

endmodule

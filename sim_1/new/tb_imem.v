`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 09:59:44
// Design Name: 
// Module Name: tb_imem
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


module tb_imem();

reg [31:0] addr;
wire [31:0] instr;

imem imem_inst(
    .addr_i(addr),
    .instr_o(instr)
);

initial begin
    addr = 32'h00000000;
    #10;
    addr = 32'h00000004;
    #10;
    addr = 32'h00000008;
    #10;
    addr = 32'h0000000c;
    #10;
    addr = 32'h00000010;
    #10;
    addr = 32'h00000014;
end
initial begin
    $monitor("time = %d, addr = %h, instr = %h",$time, addr, instr);
    #80;
    $finish;
end

endmodule

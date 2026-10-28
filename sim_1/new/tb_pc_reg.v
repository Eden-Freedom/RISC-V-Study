`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/17 16:42:01
// Design Name: 
// Module Name: tb_pc_reg
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


module tb_pc_reg();

    reg clk;
    reg rst_n;
    wire [31:0] pc_o;

    initial begin
        clk = 0;
    end

    always #10 clk = ~clk;

    initial begin
        rst_n = 0;
        #25 rst_n = 1;
    end

    initial begin
        $monitor("time = %d,rst_n = %b,pc_o = %h",$time,rst_n,pc_o);
        #80 $finish;
    end

    pc_reg u_pc_reg(
        .clk(clk),
        .rst_n(rst_n),
        .pc_o(pc_o)
    );
    
endmodule

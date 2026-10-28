`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 11:53:05
// Design Name: 
// Module Name: tb_regfile
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


module tb_regfile();

reg clk;
reg rst_n;
reg wr_en_i;
reg [4:0] wr_addr_i;
reg [31:0] wr_data_i;
reg [4:0] rs1_addr_i;
reg [4:0] rs2_addr_i;
wire [31:0] rs1_data_o;
wire [31:0] rs2_data_o;

initial begin
    clk = 0;
end

always #10 clk = ~clk;

initial begin
    rst_n = 0;
    wr_en_i = 0;
    wr_addr_i = 5'd0;
    wr_data_i = 32'h00000000;
    rs1_addr_i = 5'd0;
    rs2_addr_i = 5'd0;
    #25 rst_n = 1;
    #25
    wr_en_i = 1;
    wr_addr_i = 5'd1;
    wr_data_i = 32'd5;
    #20
    wr_addr_i = 5'd0;
    wr_data_i = 32'd123;
    #20
    wr_en_i = 0;
    rs1_addr_i = 5'd0;
    #10
    rs2_addr_i = 5'd1;
    #10
    $finish;
end

initial begin
    $monitor("time =%dns,rst_n = %b,wr_en_i = %b,wr_addr_i = %d,wr_data_i = %d,rs1_addr_i = %d,rs2_addr_i = %d,rs1_data_o = %d,rs2_data_o = %d",$time,rst_n,wr_en_i,wr_addr_i,wr_data_i,rs1_addr_i,rs2_addr_i,rs1_data_o,rs2_data_o);
end

regfile u_regfile(
    .clk(clk),
    .rst_n(rst_n),
    .wr_en_i(wr_en_i),
    .wr_addr_i(wr_addr_i),
    .wr_data_i(wr_data_i),
    .rs1_addr_i(rs1_addr_i),
    .rs1_data_o(rs1_data_o),
    .rs2_addr_i(rs2_addr_i),
    .rs2_data_o(rs2_data_o)
);
endmodule

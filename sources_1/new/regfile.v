`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 11:33:22
// Design Name: 
// Module Name: regfile
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


module regfile(
    input wire clk,
    input wire rst_n,

    input wire wr_en_i,
    input wire [4:0] wr_addr_i,
    input wire [31:0] wr_data_i,

    input wire [4:0] rs1_addr_i,
    output reg [31:0] rs1_data_o,
    
    input wire [4:0] rs2_addr_i,
    output reg [31:0] rs2_data_o
    );

    reg [31:0] reg_file [31:0];
    integer i;

    //写逻辑
    always@(posedge clk)begin
        if(!rst_n)begin
            for(i = 1; i < 32; i = i + 1)begin
                reg_file[i] <= 32'h00000000;
            end
        end
        else if(wr_en_i && wr_addr_i != 5'd0)begin
            reg_file[wr_addr_i] <= wr_data_i;
        end
        end


    //读逻辑
    always@(*)begin
        if(rs1_addr_i == 5'd0)//x0一定为0
            rs1_data_o = 32'h0;
        else
            rs1_data_o = reg_file[rs1_addr_i];
    end

    always@(*)begin
        if(rs2_addr_i == 5'd0)
            rs2_data_o = 32'h0;
        else
            rs2_data_o = reg_file[rs2_addr_i];
    end

    
endmodule

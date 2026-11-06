`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 11:57:20
// Design Name: 
// Module Name: program_mem
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


module program_mem(
    //取指接口
    input wire [31:0] fetch_addr_i,
    output reg [31:0] instr_o,

    //装载接口
    input wire clk,
    input wire load_we_i,
    input wire [31:0] load_addr_i,
    input wire [31:0] load_data_i
    );

    reg [31:0] mem [0:63];

    always @(*) begin
        if(fetch_addr_i[1:0] == 2'b00) begin
            instr_o = mem[fetch_addr_i[7:2]];
        end
        else begin
            instr_o = 32'd0;
        end
    end

    always @(posedge clk) begin
        if(load_we_i && load_addr_i[1:0] == 2'b00) begin
            mem[load_addr_i[7:2]] <= load_data_i;
        end
    end
endmodule

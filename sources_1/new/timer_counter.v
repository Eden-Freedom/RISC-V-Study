`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/04 19:39:39
// Design Name: 
// Module Name: timer_counter
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


module timer_counter(
    input wire clk,
    input wire rst_n,
    input wire en_i,
    input wire clear_i,
    input wire [31:0] limit_i,

    output wire cnt_done_o,
    output wire [31:0] cnt_value_o
    );

    reg [31:0] cnt_reg;
    assign cnt_value_o = cnt_reg;
    assign cnt_done_o = (cnt_reg >= limit_i);

    always @(posedge clk) begin
        if(!rst_n)begin
            cnt_reg <= 32'b0;
        end
        else if(clear_i)begin
            cnt_reg <= 32'b0;
        end
        else if(en_i && !cnt_done_o)begin
            cnt_reg <= cnt_reg + 1;
        end
    end

    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 15:55:22
// Design Name: 
// Module Name: if_id
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


module if_id(
    input wire clk,
    input wire rst_n,
    input wire valid_i,
    input wire flush_ifid_i,
    input wire [31:0] pc_ifid_i,
    input wire [31:0] instr_ifid_i,
    output reg valid_o,
    output reg [31:0] pc_ifid_o,
    output reg [31:0] instr_ifid_o
);


always @(posedge clk) begin
    if (!rst_n) begin
        valid_o <= 1'b0;
        pc_ifid_o <= 32'h0;
        instr_ifid_o <= 32'h0;
    end
    else if (flush_ifid_i) begin
        valid_o <= 1'b0;
        pc_ifid_o <= 32'h0;
        instr_ifid_o <= 32'h0;
    end
    else  begin
        valid_o <= valid_i;
        pc_ifid_o <= pc_ifid_i;
        instr_ifid_o <= instr_ifid_i;
    end
end
endmodule

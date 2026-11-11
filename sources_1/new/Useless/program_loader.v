`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 15:08:05
// Design Name: 
// Module Name: program_loader
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


module program_loader(
    input wire clk,
    input wire rst_n,
    input wire word_valid_i,
    input wire [31:0] word_data_i,
    output wire load_we_o,
    output wire [31:0] load_addr_o,
    output wire [31:0] load_data_o,
    output wire full_o

    );

    reg [8:0] next_addr;

    assign load_addr_o = {23'h0, next_addr};
    assign load_data_o = word_data_i;
    assign load_we_o = (rst_n && word_valid_i && !full_o);
    assign full_o = (next_addr == 9'h100);

    always @(posedge clk ) begin
        if(!rst_n) begin
            next_addr <= 9'd0;
        end
        else begin
            if(word_valid_i && !full_o) begin
                next_addr <= next_addr + 9'd4;
            end
    end
end
endmodule

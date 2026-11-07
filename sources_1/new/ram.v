`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/21 19:50:06
// Design Name: 
// Module Name: ram
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


module ram#(
    parameter ADDR_WIDTH = 5,
    parameter SYNC_READ = 0
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] ram_wr_addr_i,
    input wire [ADDR_WIDTH-1:0] ram_rd_addr_i,
    input wire [31:0] ram_wr_data_i,
    input wire ram_wr_en_i,
    input wire ram_rd_en_i,
    input wire [3:0] ram_wr_sel_i,
    output reg [31:0] ram_rd_data_o
    );

    reg [31:0] memory[0:(1 << ADDR_WIDTH)-1];

    

    generate
        if (SYNC_READ) begin : gen_sync_ram
            always @(posedge clk) begin
                if (ram_rd_en_i) begin
                    ram_rd_data_o <= memory[ram_rd_addr_i];
                end
            end

            always @(posedge clk) begin
                if (rst_n && ram_wr_en_i) begin
                    if (ram_wr_sel_i[0])
                        memory[ram_wr_addr_i][7:0] <= ram_wr_data_i[7:0];
                    if (ram_wr_sel_i[1])
                        memory[ram_wr_addr_i][15:8] <= ram_wr_data_i[15:8];
                    if (ram_wr_sel_i[2])
                        memory[ram_wr_addr_i][23:16] <= ram_wr_data_i[23:16];
                    if (ram_wr_sel_i[3])
                        memory[ram_wr_addr_i][31:24] <= ram_wr_data_i[31:24];
                end
            end
        end else begin : gen_legacy_ram
    integer i;

    //读逻辑
    always@(*)begin
        if(ram_rd_en_i)begin
            ram_rd_data_o = memory[ram_rd_addr_i];
        end else begin
            ram_rd_data_o = 32'h0;
        end
    end

    //写逻辑
    always@(posedge clk)begin
        if(!rst_n)begin
            for(i = 0; i < 32; i = i + 1)begin
                memory[i] <= 32'h00000000;
            end
        end
        else if(ram_wr_en_i)begin
            if(ram_wr_sel_i[0])begin
                memory[ram_wr_addr_i][7:0] <= ram_wr_data_i[7:0];
            end
            if(ram_wr_sel_i[1])begin
                memory[ram_wr_addr_i][15:8] <= ram_wr_data_i[15:8];
            end
            if(ram_wr_sel_i[2])begin
                memory[ram_wr_addr_i][23:16] <= ram_wr_data_i[23:16];
            end
            if(ram_wr_sel_i[3])begin
                memory[ram_wr_addr_i][31:24] <= ram_wr_data_i[31:24];
            end
        end
    end
end
endgenerate
endmodule

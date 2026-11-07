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
    input wire [31:0] load_data_i,

        // CPU 执行 load 指令时使用的数据读口
    input wire [31:0] data_addr_i,
    output reg [31:0] data_word_o
    );

    reg [31:0] mem [0:1023];

    always @(*) begin
        if (fetch_addr_i[31:12] == 20'd0 && fetch_addr_i[1:0] == 2'b00) begin
            instr_o = mem[fetch_addr_i[11:2]];
        end
        else begin
            instr_o = 32'd0;
        end
    end

    always @(posedge clk) begin
        if (load_we_i && load_addr_i[31:12] == 20'd0 && load_addr_i[1:0] == 2'b00) begin
            mem[load_addr_i[11:2]] <= load_data_i;
        end
    end

    always @(*) begin
        if (data_addr_i[31:12] == 20'd0) begin
            // 返回地址所在的整个 32 位字
            data_word_o = mem[data_addr_i[11:2]];
        end
        else begin
            data_word_o = 32'd0;
        end
    end
endmodule

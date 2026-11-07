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


module program_mem #(
    parameter USE_BRAM_PROGRAM = 0
)(
    input  wire        fetch_en_i,
    input  wire [31:0] fetch_addr_i,
    output reg  [31:0] instr_o,

    input  wire        clk,
    input  wire        load_we_i,
    input  wire [31:0] load_addr_i,
    input  wire [31:0] load_data_i,

    input  wire        data_rd_en_i,
    input  wire [31:0] data_addr_i,
    output reg  [31:0] data_word_o
);

    localparam BYTE_ADDR_WIDTH = USE_BRAM_PROGRAM ? 15 : 12;
    localparam WORD_COUNT = 1 << (BYTE_ADDR_WIDTH - 2);

    reg [31:0] mem [0:WORD_COUNT-1];

    wire fetch_addr_valid;
    wire load_write;
    wire data_addr_valid;

    assign fetch_addr_valid = (fetch_addr_i[31:BYTE_ADDR_WIDTH] == 0) &&
                              (fetch_addr_i[1:0] == 2'b00);
    assign load_write = load_we_i &&
                        (load_addr_i[31:BYTE_ADDR_WIDTH] == 0) &&
                        (load_addr_i[1:0] == 2'b00);
    assign data_addr_valid = (data_addr_i[31:BYTE_ADDR_WIDTH] == 0);

    generate
        if (USE_BRAM_PROGRAM) begin : gen_bram
            wire [12:0] port_a_addr;
            reg  [31:0] fetch_word;
            reg         fetch_addr_valid_q;

            // A 口共用同一个字地址。下载写入优先，运行时用于取指。
            assign port_a_addr = load_write ? load_addr_i[14:2]
                                            : fetch_addr_i[14:2];

            always @(posedge clk) begin
                if (load_write) begin
                    mem[port_a_addr] <= load_data_i;
                end
                else if (fetch_en_i) begin
                    fetch_word <= mem[port_a_addr];
                    fetch_addr_valid_q <= fetch_addr_valid;
                end
            end

            always @(*) begin
                if (fetch_addr_valid_q)
                    instr_o = fetch_word;
                else
                    instr_o = 32'd0;
            end

            // B 口把镜像里的一个字读入输出寄存器。
            always @(posedge clk) begin
                if (data_rd_en_i && data_addr_valid) begin
                    data_word_o <= mem[data_addr_i[14:2]];
                end
            end
        end
        else begin : gen_legacy
            always @(*) begin
                if (fetch_addr_valid)
                    instr_o = mem[fetch_addr_i[11:2]];
                else
                    instr_o = 32'd0;
            end

            always @(posedge clk) begin
                if (load_write)
                    mem[load_addr_i[11:2]] <= load_data_i;
            end

            always @(*) begin
                if (data_addr_valid)
                    data_word_o = mem[data_addr_i[11:2]];
                else
                    data_word_o = 32'd0;
            end
        end
    endgenerate
endmodule

`timescale 1ns / 1ps

module uart_download (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        download_en_i,
    input  wire        byte_valid_i,
    input  wire [7:0]  byte_data_i,

    output wire        load_we_o,
    output wire [31:0] load_addr_o,
    output wire [31:0] load_data_o
);

    localparam [8:0] END_ADDR = 9'h100;

    reg [1:0]  byte_index;
    reg [23:0] byte_buf;
    reg [8:0]  next_addr;

    wire accept_byte;

    // 下载模式下，只接收存储器还有空间时送来的有效字节。
    assign accept_byte = rst_n && download_en_i && byte_valid_i
                         && (next_addr < END_ADDR);

    // 第四字节有效时，当前输入与前三字节组成一个完整字。
    assign load_we_o   = accept_byte && (byte_index == 2'd3);
    assign load_addr_o = {23'd0, next_addr};
    assign load_data_o = {byte_data_i, byte_buf};

    always @(posedge clk) begin
        if (!rst_n || !download_en_i) begin
            byte_index <= 2'd0;
            byte_buf   <= 24'd0;
            next_addr  <= 9'd0;
        end
        else if (accept_byte) begin
            if (load_we_o) begin
                // program_mem 在这个沿写入当前字，地址同时推进到下一字。
                byte_index <= 2'd0;
                next_addr  <= next_addr + 9'd4;
            end
            else begin
                // 前三个字节按低位到高位保存。
                case (byte_index)
                    2'd0: byte_buf[7:0]   <= byte_data_i;
                    2'd1: byte_buf[15:8]  <= byte_data_i;
                    2'd2: byte_buf[23:16] <= byte_data_i;
                endcase
                byte_index <= byte_index + 2'd1;
            end
        end
    end

endmodule
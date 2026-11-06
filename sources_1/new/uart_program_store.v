`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 15:32:12
// Design Name: 
// Module Name: uart_program_store
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


module uart_program_store(
    input wire  clk,
    input wire rst_n,
    input wire[31:0] fetch_addr_i,
    input wire uart_rx_i,

    output wire [31:0] instr_o,
    output wire full_o
    );

wire rx_valid_o;
wire [7:0] rx_data_o;

wire assembler_word_valid_o;
wire [31:0] assembler_word_data_o;

wire load_we_o;
wire [31:0] load_addr_o;
wire [31:0] load_data_o;


//接收指令
    uart_rx  uart_rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx_i(uart_rx_i),
    .valid_o(rx_valid_o),
    .data_o(rx_data_o)
  );

//组装指令
  uart_word_assembler  uart_word_assembler_inst (
    .clk(clk),
    .rst_n(rst_n),
    .byte_valid_i(rx_valid_o),
    .byte_data_i(rx_data_o),
    .word_valid_o(assembler_word_valid_o),
    .word_data_o(assembler_word_data_o)
  );


//装载指令
  program_loader  program_loader_inst (
    .clk(clk),
    .rst_n(rst_n),
    .word_valid_i(assembler_word_valid_o),
    .word_data_i(assembler_word_data_o),
    .load_we_o(load_we_o),
    .load_addr_o(load_addr_o),
    .load_data_o(load_data_o),
    .full_o(full_o)
  );


//存储指令
  program_mem  program_mem_inst (
    .fetch_addr_i(fetch_addr_i),
    .instr_o(instr_o),
    .clk(clk),
    .load_we_i(load_we_o),
    .load_addr_i(load_addr_o),
    .load_data_i(load_data_o)
  );












endmodule

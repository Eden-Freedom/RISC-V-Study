`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 15:55:35
// Design Name: 
// Module Name: uart_tx_target
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


module uart_tx_target (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req_i,
    input  wire        we_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire [ 3:0] wstrb_i,
    output reg         ready_o,
    output wire [31:0] rdata_o,
    output wire        tx_o
);


  wire tx_busy;
  wire tx_start;
  wire tx_write;


  assign tx_write = req_i && we_i && (addr_i[3:2] == 2'b00) && wstrb_i[0];
  assign tx_start = tx_write && ready_o;

  always @(*) begin
    if (!req_i) ready_o = 1'b0;
    else if (tx_write) ready_o = !tx_busy;  // 要交付字节，等发送器空闲
    else ready_o = 1'b1;  // 例如读取 STATUS，目标可以直接回应
  end


  assign rdata_o = (req_i && !we_i && (addr_i[3:2] == 2'b01)) ? {31'b0, tx_busy} : 32'b0;



  uart_tx uart_tx_inst (
      .clk(clk),
      .rst_n(rst_n),
      .start_i(tx_start),
      .data_i(wdata_i[7:0]),
      .busy_o(tx_busy),
      .tx_o(tx_o)
  );



endmodule

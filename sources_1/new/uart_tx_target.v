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


module uart_tx_target 
#(
  parameter CLK_PRE_BIT = 4,
  parameter USE_UPSTREAM_MAP = 0
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req_i,
    input  wire        we_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire [ 3:0] wstrb_i,
    input wire         rx_i,
    output reg         ready_o,
    output reg [31:0] rdata_o,
    output wire        tx_o,

    output wire        rx_valid_o,
    output wire [7:0]  rx_data_o

);

wire rx_valid;
wire [7:0] rx_data;

reg [7:0] rx_byte;
reg rx_pending;

assign rx_valid_o = rx_valid;
assign rx_data_o = rx_data;


  wire tx_busy;
  wire tx_start;
  wire tx_write;


  wire tx_addr_hit;

  assign tx_addr_hit = USE_UPSTREAM_MAP
                     ? (addr_i[3:0] == 4'hC)
                     : (addr_i[3:2] == 2'b00);

  assign tx_write = req_i && we_i && tx_addr_hit && wstrb_i[0];
  assign tx_start = tx_write && ready_o;

  always @(*) begin
    if (!req_i) ready_o = 1'b0;
    else if (tx_write) ready_o = !tx_busy;  // 要交付字节，等发送器空闲
    else ready_o = 1'b1;  // 例如读取 STATUS，目标可以直接回应
  end





  uart_tx #(
    .CLK_PRE_BIT(CLK_PRE_BIT)
  )uart_tx_inst (
      .clk(clk),
      .rst_n(rst_n),
      .start_i(tx_start),
      .data_i(wdata_i[7:0]),
      .busy_o(tx_busy),
      .tx_o(tx_o)
  );




  always @(*) begin
    rdata_o = 32'd0;

    if (req_i && !we_i) begin
        if (addr_i[3:2] == 2'b01) begin
            // STATUS：bit 1 是待取标志，bit 0 是发送忙标志。
            rdata_o = {30'd0, rx_pending, tx_busy};
        end
        else if (addr_i[3:0] == 4'h8) begin
            // RXDATA：请补上有字节时的返回值。
            if (rx_pending) begin
                rdata_o = {24'd0, rx_byte};
            end
        end
    end
end

wire  rx_pop;//CPU 已经成功读走一个 UART 接收字节

assign rx_pop = req_i && !we_i && (addr_i[3:0] == 4'h8) && rx_pending && ready_o;

always @(posedge clk ) begin
    if(!rst_n)begin
        rx_pending <= 1'b0;
        rx_byte <= 8'b0;
    end
    else if(rx_valid && (!rx_pending || rx_pop))begin
        rx_pending <= 1'b1;
        rx_byte <= rx_data;
    end
    else if(rx_pop)begin
        rx_pending <= 1'b0;
        rx_byte <= rx_byte;
    end    
end
  uart_rx #(
    .CLK_PRE_BIT(CLK_PRE_BIT)
  )uart_rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx_i(rx_i),
    .valid_o(rx_valid),
    .data_o(rx_data)
  );




endmodule

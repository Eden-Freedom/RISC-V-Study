`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 20:05:21
// Design Name: 
// Module Name: board_top
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


module board_top(

input wire clk,
input wire rst_n,
input wire uart_rx_i,
input wire download_en_i,
output wire [7:0] gpio_out_o,
output wire uart_tx_o
    );

    localparam USE_UART_DOWNLOAD = 1;
    localparam CLK_PRE_BIT = 434;


    (* ASYNC_REG = "TRUE" *) reg rst_n_sync1, rst_n_sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_n_sync1 <= 1'b0;
            rst_n_sync2 <= 1'b0;
        end
        else begin
            rst_n_sync1 <= 1'b1;
            rst_n_sync2 <= rst_n_sync1;
        end
    end

    (* ASYNC_REG = "TRUE" *) reg download_en_sync1, download_en_sync2;
    (* ASYNC_REG = "TRUE" *) reg uart_rx_sync1, uart_rx_sync2;

    always @(posedge clk) begin
        download_en_sync1 <= download_en_i;
        download_en_sync2 <= download_en_sync1;
    
        uart_rx_sync1 <= uart_rx_i;
        uart_rx_sync2 <= uart_rx_sync1;
    end




    soc_top # (
    .USE_UART_DOWNLOAD(USE_UART_DOWNLOAD),
    .CLK_PRE_BIT(CLK_PRE_BIT)
  )
  soc_top_inst (
    .clk(clk),
    .rst_n(rst_n_sync2),
    .irq_external_i(1'b0),
    .uart_rx_i(uart_rx_sync2),
    .spi_miso_i(1'b0),
    .download_en_i(download_en_sync2),
    .gpio_out_o(gpio_out_o),
    .uart_tx_o(uart_tx_o),
    .spi_mosi_o(),
    .spi_sclk_o(),
    .spi_cs_n_o()
  );
endmodule

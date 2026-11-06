`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/04 19:18:42
// Design Name: 
// Module Name: soc_top
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


module soc_top #(
  parameter USE_UART_DOWNLOAD = 1,
  parameter CLK_PRE_BIT = 434
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       irq_external_i,
    input  wire       uart_rx_i,
    input  wire       spi_miso_i,
    input  wire       download_en_i,
    output wire [7:0] gpio_out_o,
    output wire       uart_tx_o,
    output wire       spi_mosi_o,
    output wire       spi_sclk_o,
    output wire       spi_cs_n_o
);



  wire        gpio_ready_o;
  wire [31:0] gpio_rdata_o;
  wire        timer_ready_o;
  wire [31:0] timer_rdata_o;
  wire        uart_tx_ready_o;
  wire [31:0] uart_tx_rdata_o;
  wire        spi_ready_o;
  wire [31:0] spi_rdata_o;

  wire        bus2dev_req_o;
  wire        bus2dev_we_o;
  wire [31:0] bus2dev_addr_o;
  wire [31:0] bus2dev_wdata_o;
  wire [ 3:0] bus2dev_wstrb_o;

  reg         gpio_req;
  reg         timer_req;
  reg         uart_tx_req;
  reg         spi_req;

  reg         dev_ready_o;
  reg  [31:0] dev_rdata_o;

  wire        timer_irq_o;
  wire        irq2cpu;

  wire        rx_valid_o;
  wire [7:0]  rx_data_o;

  wire [31:0] instr_o;
  wire [31:0] fetch_addr_o;


  wire        load_we_o;
wire [31:0] load_addr_o;
wire [31:0] load_data_o;
wire        download_active;
wire        cpu_rst_n;

assign download_active = USE_UART_DOWNLOAD && download_en_i;
assign cpu_rst_n       = rst_n && !download_active;

  always @(*) begin

    gpio_req    = 1'b0;
    timer_req   = 1'b0;
    uart_tx_req = 1'b0;
    spi_req     = 1'b0;
    dev_ready_o = 1'b0;
    dev_rdata_o = 32'd0;
    case (bus2dev_addr_o[5:4])
      2'b00: begin
        gpio_req    = bus2dev_req_o;
        dev_ready_o = gpio_ready_o;
        dev_rdata_o = gpio_rdata_o;
      end
      2'b01: begin
        timer_req   = bus2dev_req_o;
        dev_ready_o = timer_ready_o;
        dev_rdata_o = timer_rdata_o;
      end
      2'b10: begin
        uart_tx_req = bus2dev_req_o;
        dev_ready_o = uart_tx_ready_o;
        dev_rdata_o = uart_tx_rdata_o;
      end
      2'b11: begin
        spi_req     = bus2dev_req_o;
        dev_ready_o = spi_ready_o;
        dev_rdata_o = spi_rdata_o;
      end
      default: begin
        gpio_req    = 1'b0;
        timer_req   = 1'b0;
        uart_tx_req = 1'b0;
        spi_req     = 1'b0;
        dev_ready_o = 1'b0;
        dev_rdata_o = 32'b0;
      end
    endcase
  end


  assign irq2cpu = timer_irq_o || irq_external_i;

  pipeline_core #(
    .USE_EXTERNAL_PROGRAM(USE_UART_DOWNLOAD)
  )pipeline_core_inst (
      .clk(clk),
      .rst_n(cpu_rst_n),
      .irq_external_i(irq2cpu),
      .external_instr_i(instr_o),
      .dev2bus_ready_i(dev_ready_o),
      .dev2bus_rdata_i(dev_rdata_o),
      .bus2dev_req_o(bus2dev_req_o),
      .bus2dev_we_o(bus2dev_we_o),
      .bus2dev_addr_o(bus2dev_addr_o),
      .bus2dev_wdata_o(bus2dev_wdata_o),
      .bus2dev_wstrb_o(bus2dev_wstrb_o),
      .fetch_addr_o(fetch_addr_o)
  );


  gpio_target gpio_target_inst (
      .clk(clk),
      .rst_n(rst_n),
      .req_i(gpio_req),
      .we_i(bus2dev_we_o),
      .addr_i(bus2dev_addr_o),
      .wdata_i(bus2dev_wdata_o),
      .wstrb_i(bus2dev_wstrb_o),
      .ready_o(gpio_ready_o),
      .rdata_o(gpio_rdata_o),
      .gpio_out_o(gpio_out_o)
  );

  timer_target timer_target_inst (
      .clk(clk),
      .rst_n(rst_n),
      .req_i(timer_req),
      .we_i(bus2dev_we_o),
      .addr_i(bus2dev_addr_o),
      .wdata_i(bus2dev_wdata_o),
      .wstrb_i(bus2dev_wstrb_o),
      .ready_o(timer_ready_o),
      .rdata_o(timer_rdata_o),
      .irq_o(timer_irq_o)
  );

  uart_tx_target #(
    .CLK_PRE_BIT(CLK_PRE_BIT)
  )uart_tx_target_inst (
      .clk(clk),
      .rst_n(rst_n),
      .req_i(uart_tx_req),
      .we_i(bus2dev_we_o),
      .addr_i(bus2dev_addr_o),
      .wdata_i(bus2dev_wdata_o),
      .wstrb_i(bus2dev_wstrb_o),
      .ready_o(uart_tx_ready_o),
      .rdata_o(uart_tx_rdata_o),
      .tx_o(uart_tx_o),
      .rx_i(uart_rx_i),

      .rx_valid_o(rx_valid_o),
      .rx_data_o(rx_data_o)
  );

  spi_target spi_target_inst (
      .clk(clk),
      .rst_n(rst_n),
      .req_i(spi_req),
      .we_i(bus2dev_we_o),
      .miso_i(spi_miso_i),
      .addr_i(bus2dev_addr_o),
      .wdata_i(bus2dev_wdata_o),
      .wstrb_i(bus2dev_wstrb_o),
      .ready_o(spi_ready_o),
      .cs_n_o(spi_cs_n_o),
      .sclk_o(spi_sclk_o),
      .mosi_o(spi_mosi_o),
      .rdata_o(spi_rdata_o)
  );

  uart_program_downloader  uart_program_downloader_inst (
    .clk(clk),
    .rst_n(rst_n),
    .download_en_i(download_active),
    .byte_valid_i(rx_valid_o),
    .byte_data_i(rx_data_o),
    .load_we_o(load_we_o),
    .load_addr_o(load_addr_o),
    .load_data_o(load_data_o)
  );


  //存储指令
  program_mem  program_mem_inst (
    .fetch_addr_i(fetch_addr_o),
    .instr_o(instr_o),
    .clk(clk),
    .load_we_i(load_we_o),
    .load_addr_i(load_addr_o),
    .load_data_i(load_data_o)
  );
endmodule

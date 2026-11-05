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


module soc_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       irq_external_i,
    input wire uart_rx_i,
    output wire [7:0] gpio_out_o,
    output wire       uart_tx_o
);



  wire        gpio_ready_o;
  wire [31:0] gpio_rdata_o;
  wire        timer_ready_o;
  wire [31:0] timer_rdata_o;
  wire        uart_tx_ready_o;
  wire [31:0] uart_tx_rdata_o;

  wire        bus2dev_req_o;
  wire        bus2dev_we_o;
  wire [31:0] bus2dev_addr_o;
  wire [31:0] bus2dev_wdata_o;
  wire [ 3:0] bus2dev_wstrb_o;

  reg         gpio_req;
  reg         timer_req;
  reg         uart_tx_req;

  reg         dev_ready_o;
  reg  [31:0] dev_rdata_o;

  wire        timer_irq_o;
  wire        irq2cpu;


  always @(*) begin

    gpio_req    = 1'b0;
    timer_req   = 1'b0;
    uart_tx_req = 1'b0;
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
      default: begin
        gpio_req    = 1'b0;
        timer_req   = 1'b0;
        uart_tx_req = 1'b0;
        dev_ready_o = 1'b0;
        dev_rdata_o = 32'b0;
      end
    endcase
  end


  assign irq2cpu = timer_irq_o || irq_external_i;

  pipeline_core pipeline_core_inst (
      .clk(clk),
      .rst_n(rst_n),
      .irq_external_i(irq2cpu),
      .dev2bus_ready_i(dev_ready_o),
      .dev2bus_rdata_i(dev_rdata_o),
      .bus2dev_req_o(bus2dev_req_o),
      .bus2dev_we_o(bus2dev_we_o),
      .bus2dev_addr_o(bus2dev_addr_o),
      .bus2dev_wdata_o(bus2dev_wdata_o),
      .bus2dev_wstrb_o(bus2dev_wstrb_o)
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

  uart_tx_target uart_tx_target_inst (
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
      .rx_i(uart_rx_i)
  );
endmodule

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


module soc_top(
    input wire clk,
    input wire rst_n,
    input wire irq_external_i,
    output wire [7:0] gpio_out_o
    );



    wire gpio_ready_o;
    wire [31:0] gpio_rdata_o;
    wire timer_ready_o;
    wire [31:0] timer_rdata_o;

    wire bus2dev_req_o;
    wire bus2dev_we_o;
    wire [31:0] bus2dev_addr_o;
    wire [31:0] bus2dev_wdata_o;
    wire [3:0] bus2dev_wstrb_o;

    wire gpio_req;
    wire timer_req;

    wire dev_ready_o;
    wire [31:0] dev_rdata_o;

    wire timer_irq_o;
    wire irq2cpu;

    assign dev_ready_o = (bus2dev_addr_o[4]) ? timer_ready_o : gpio_ready_o;
    assign dev_rdata_o = (bus2dev_addr_o[4]) ? timer_rdata_o : gpio_rdata_o;
    assign gpio_req = bus2dev_req_o && !bus2dev_addr_o[4];
    assign timer_req = bus2dev_req_o && bus2dev_addr_o[4];


    assign irq2cpu = timer_irq_o || irq_external_i;

    pipeline_core  pipeline_core_inst (
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


  gpio_target  gpio_target_inst (
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

  timer_target  timer_target_inst (
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
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 11:17:19
// Design Name: 
// Module Name: spi_target
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


module spi_target (
    input wire        clk,
    input wire        rst_n,
    input wire        req_i,
    input wire        we_i,
    input wire        miso_i,
    input wire [31:0] addr_i,
    input wire [31:0] wdata_i,
    input wire [ 3:0] wstrb_i,

    output reg         ready_o,
    output wire        cs_n_o,
    output wire        sclk_o,
    output wire        mosi_o,
    output reg  [31:0] rdata_o


);

  localparam [3:0] XFER_OFFSET = 4'h0;  //写最低字节启动交换，读回 0
  localparam [3:0] STATUS_OFFSET = 4'h4;  //bit 0 返回 spi_busy，bit 1 返回 done_pending
  localparam [3:0] RXDATA_OFFSET = 4'h8;  //低 8 位返回 spi_rx_data，高位补零

  wire       spi_start;
  wire       spi_busy;
  wire       spi_done;
  wire [7:0] spi_rx_data;

  wire       xfer_write;

  reg        done_pending;


  assign xfer_write = req_i && we_i && (addr_i[3:0] == XFER_OFFSET) && wstrb_i[0];

  always @(*) begin
    if (!req_i) begin
      ready_o = 1'b0;
    end
    else if (xfer_write && spi_busy) begin
      ready_o = 1'b0;
    end
    else begin
      ready_o = 1'b1;
    end
  end
  assign spi_start = xfer_write && ready_o;

  always @(posedge clk) begin
    if (!rst_n) begin
      done_pending <= 1'b0;
    end
    else if (spi_start) begin
      done_pending <= 1'b0;
    end
    else if (spi_done) begin
      done_pending <= 1'b1;
    end
  end

  always @(*) begin
    rdata_o = 32'd0;
    if (req_i && !we_i) begin
      if (addr_i[3:0] == STATUS_OFFSET) begin
        rdata_o = {30'd0, done_pending, spi_busy};
      end
      else if (addr_i[3:0] == RXDATA_OFFSET) begin
        rdata_o = {24'd0, spi_rx_data};
      end
    end
    else begin
      rdata_o = 32'd0;
    end
  end

  spi_master spi_master_inst (
      .clk(clk),
      .rst_n(rst_n),
      .start_i(spi_start),
      .miso_i(miso_i),
      .tx_data_i(wdata_i[7:0]),
      .cs_n_o(cs_n_o),
      .sclk_o(sclk_o),
      .mosi_o(mosi_o),
      .busy_o(spi_busy),
      .done_o(spi_done),
      .rx_data_o(spi_rx_data)
  );
endmodule

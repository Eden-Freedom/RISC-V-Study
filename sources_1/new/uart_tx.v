`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 11:37:38
// Design Name: 
// Module Name: uart_tx
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


module uart_tx #(
  parameter CLK_PRE_BIT = 4
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start_i,
    input  wire [7:0] data_i,
    output wire       busy_o,
    output reg        tx_o
);

  //localparam CLK_PRE_BIT = 4;  //每个bit保持4个时钟周期，便于仿真
  localparam IDLE = 2'b00;
  localparam START = 2'b01;
  localparam DATA = 2'b10;
  localparam STOP = 2'b11;

  reg [1:0] state, nstate;
  reg [31:0] bit_count_time;
  reg [3:0] bit_count;
  wire bit_tick;

  reg [7:0] data_reg;//为了避免正在发送的帧还没发送完的时候时候，发送方改变了发送的数据，所以需要存下来

  assign bit_tick = (state != IDLE) && (bit_count_time == CLK_PRE_BIT - 1);

  always @(posedge clk) begin
    if (!rst_n) bit_count_time <= 32'b0;
    else if (bit_tick || (state == IDLE)) bit_count_time <= 32'b0;
    else if (busy_o) bit_count_time <= bit_count_time + 32'b1;
  end

  always @(posedge clk) begin
    if (!rst_n || (state !== DATA)) begin
      bit_count <= 4'b0;
    end
    else if (state == DATA && bit_tick && bit_count < 4'd7) bit_count <= bit_count + 4'b1;
  end


  always @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
    end
    else begin
      state <= nstate;
    end
  end

  always @(*) begin
    case (state)
      IDLE: begin
        if (start_i) nstate = START;
        else nstate = IDLE;
      end
      START: begin
        if (bit_tick) begin
          nstate = DATA;
        end
        else begin
          nstate = START;
        end
      end
      DATA: begin
        if (bit_tick && bit_count == 4'd7) begin
          nstate = STOP;
        end
        else begin
          nstate = DATA;
        end
      end
      STOP: begin
        if (bit_tick) begin
          nstate = IDLE;
        end
        else begin
          nstate = STOP;
        end
      end
    endcase
  end

  assign busy_o = (state != IDLE);

  always @(posedge clk) begin
    if (!rst_n) begin
      data_reg <= 8'b0;
    end
    else if (state == IDLE && start_i) begin
      data_reg <= data_i;
    end
  end

  always @(*) begin
    case (state)
      IDLE: begin
        tx_o = 1'b1;
      end
      START: begin
        tx_o = 1'b0;
      end
      DATA: begin
        tx_o = data_reg[bit_count];
      end
      STOP: begin
        tx_o = 1'b1;
      end
    endcase
  end



endmodule

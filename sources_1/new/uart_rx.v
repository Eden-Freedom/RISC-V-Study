`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 19:32:22
// Design Name: 
// Module Name: uart_rx
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


module uart_rx (
    input wire clk,
    input wire rst_n,
    input wire rx_i,

    output reg valid_o,
    output reg [7:0] data_o
);

  localparam CLK_PRE_BIT = 4;  //每个bit保持4个时钟周期，便于仿真
  localparam IDLE = 2'b00;
  localparam START = 2'b01;
  localparam DATA = 2'b10;
  localparam STOP = 2'b11;

  reg [1:0] state, nstate;
  reg [31:0] bit_count_time;
  reg [ 3:0] bit_count;
  wire start_sample, data_sample, stop_sample;

  assign start_sample = (state == START) && (bit_count_time == CLK_PRE_BIT / 2 - 1);//第三拍再检查是否是0，加上IDLE才是三拍，所以这里只有两拍
  assign data_sample = (state == DATA) && (bit_count_time == CLK_PRE_BIT - 1);
  assign stop_sample = (state == STOP) && (bit_count_time == CLK_PRE_BIT - 1);

  always @(posedge clk) begin
    if (!rst_n) begin
      bit_count_time <= 32'b0;
    end else if (start_sample || data_sample || stop_sample || state == IDLE) begin
      bit_count_time <= 32'b0;
    end else if (state != IDLE) begin
      bit_count_time <= bit_count_time + 32'b1;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      bit_count <= 4'b0;
    end else if (state == DATA && data_sample && bit_count == 4'd7) begin
      bit_count <= 4'b0;
    end else if (state == DATA && data_sample && bit_count < 4'd7) begin
      bit_count <= bit_count + 4'b1;
    end
  end


  always @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      state <= nstate;
    end
  end

  always @(*) begin
    nstate = state;
    case (state)
      IDLE: begin
        if (!rx_i) begin
          nstate = START;
        end else begin
          nstate = IDLE;
        end
      end
      START: begin
        if (start_sample) begin
          if (!rx_i) begin
            nstate = DATA;
          end else begin
            nstate = IDLE;
          end
        end else begin
          nstate = START;
        end
      end
      DATA: begin
        if (data_sample && bit_count == 4'd7) begin
          nstate = STOP;
        end else begin
          nstate = DATA;
        end
      end
      STOP: begin
        if (bit_count_time == CLK_PRE_BIT - 1) begin
          nstate = IDLE;
        end else begin
          nstate = STOP;
        end
      end
      default: begin
        nstate = IDLE;
      end
    endcase
  end

  reg [7:0] data_reg;

  always @(posedge clk) begin
    if (!rst_n) begin
      data_reg <= 8'b0;
      data_o   <= 8'b0;
      valid_o  <= 1'b0;

    end else begin
      valid_o <= 1'b0;

      if (data_sample) begin
        data_reg[bit_count] <= rx_i;
      end

      if (stop_sample && rx_i == 1'b1) begin
        data_o  <= data_reg;
        valid_o <= 1'b1;
      end
    end
  end




endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 20:37:08
// Design Name: 
// Module Name: div_unit
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


module div_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start_i,
    input  wire [31:0] dividend_i,   //被除数
    input  wire [31:0] divisor_i,    //除数
    output reg  [31:0] quotient_o,   //商
    output reg  [31:0] remainder_o,  //余数
    output reg         busy_o,       //忙信号
    output reg         done_o        //完成信号

);




  reg [31:0] q_reg;
  reg [31:0] r_reg;
  reg [31:0] d_reg;

  reg [31:0] q_next;
  reg [31:0] r_next;

  reg [32:0] trial;
  reg [32:0] rem_work;

  reg [ 4:0] cnt;

  always @(*) begin

    trial    = {r_reg, q_reg[31]};

    rem_work = trial;
    q_next   = {q_reg[30:0], 1'b0};

    if (trial >= {1'b0, d_reg}) begin
      q_next[0] = 1'b1;
      rem_work  = trial - {1'b0, d_reg};
    end

    r_next = rem_work[31:0];
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      q_reg       <= 32'h0;
      r_reg       <= 32'h0000;
      d_reg       <= 32'h0000;
      cnt         <= 5'b0;

      quotient_o  <= 32'h0;
      remainder_o <= 32'h0;
      busy_o      <= 1'b0;
      done_o      <= 1'b0;
    end
    else begin
      // 默认不报告完成，只有末轮覆盖为1
      done_o <= 1'b0;

      if (busy_o) begin
        // 每个忙碌的上升沿保存一轮结果
        q_reg <= q_next;
        r_reg <= r_next;

        if (cnt == 5'b11111) begin
          // 第四轮：输出本轮计算出的新结果
          quotient_o  <= q_next;
          remainder_o <= r_next;
          busy_o      <= 1'b0;
          done_o      <= 1'b1;
        end
        else begin
          cnt <= cnt + 5'b00001;
        end
      end
      else if (start_i) begin
        // 只在空闲时受理请求
        q_reg  <= dividend_i;
        r_reg  <= 32'h0;
        d_reg  <= divisor_i;
        cnt    <= 5'b0;
        busy_o <= 1'b1;
      end
    end
  end


endmodule

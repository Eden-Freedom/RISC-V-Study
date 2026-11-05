`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/04 20:11:29
// Design Name: 
// Module Name: timer_target
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


module timer_target (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req_i,
    input  wire        we_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire [ 3:0] wstrb_i,
    output wire        ready_o,
    output reg [31:0] rdata_o,
    output wire irq_o
);


  wire        ctrl_hit;
  wire        limit_hit;


  reg [31:0] limit_reg;
  reg en_reg;
  reg irq_en_reg;

  wire clear_pulse;
  wire cnt_done_o;
  wire [31:0] cnt_value_o;

  wire req_done;
  wire write_flag;

  assign ready_o = req_i;
  assign req_done = req_i && ready_o;
  assign write_flag = req_done && we_i;

  assign ctrl_hit = (addr_i[3:2] == 2'b00);
  assign limit_hit = (addr_i[3:2] == 2'b01);

  assign irq_o = en_reg && irq_en_reg && cnt_done_o;


  assign clear_pulse = write_flag  // 本次写访问完成
      && ctrl_hit  // 地址选中了 CTRL
      && wstrb_i[0]  // 允许写入 CTRL 的最低字节
      && wdata_i[1];  // 该字节中的清零命令位为1


      //写寄存器逻辑
  always @(posedge clk) begin
    if(!rst_n)begin
        en_reg <= 1'b0;
        limit_reg <= 32'b1;
        irq_en_reg <= 1'b0;
    end
    else begin
        //写数据的bit0是计数使能，bit1是清零标志，bit2是保存CPU发来的中断允许使能
        if(write_flag && ctrl_hit && wstrb_i[0])begin
        en_reg <= wdata_i[0];
        irq_en_reg <= wdata_i[2];
        end

        if(write_flag && limit_hit) begin
            if (wstrb_i[0]) limit_reg[7:0]   <= wdata_i[7:0];
            if (wstrb_i[1]) limit_reg[15:8]  <= wdata_i[15:8];
            if (wstrb_i[2]) limit_reg[23:16] <= wdata_i[23:16];
            if (wstrb_i[3]) limit_reg[31:24] <= wdata_i[31:24];
        end
      end
  end

  //读寄存器逻辑
  always@(*)begin
    rdata_o = 32'b0;
    if(req_done && !we_i)begin  
        case(addr_i[3:2])
          2'b00: rdata_o = {29'b0,irq_en_reg,1'b0, en_reg};
          2'b01: rdata_o = limit_reg;
          2'b10: rdata_o = cnt_value_o;
          2'b11: rdata_o = {31'b0, cnt_done_o};
          default: rdata_o = 32'b0;
        endcase
    end
    else
        rdata_o = 32'b0;
  end


  timer_counter timer_counter_inst (
      .clk(clk),
      .rst_n(rst_n),
      .en_i(en_reg),
      .clear_i(clear_pulse),
      .limit_i(limit_reg),
      .cnt_done_o(cnt_done_o),
      .cnt_value_o(cnt_value_o)
  );
endmodule

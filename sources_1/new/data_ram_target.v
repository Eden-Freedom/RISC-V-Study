`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/03 15:13:43
// Design Name: 
// Module Name: data_ram_target
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


module data_ram_target (
    input wire clk,
    input wire rst_n,

    input wire req_i,  //请求读写信号

    input wire        we_i,     //1:写入，0:读取
    input wire [31:0] addr_i,
    input wire [31:0] wdata_i,
    input wire [ 3:0] wstrb_i,  //写字节选择

    output wire        ready_o,
    output wire [31:0] rdata_o
);

  reg  pending_reg;
  wire done;
  wire ram_wr_hit;
  wire ram_rd_hit;
  wire ram_wr_en;
  wire ram_rd_en;


  assign ready_o = pending_reg;
  assign done    = ready_o && req_i;

  always @(posedge clk) begin
    if (!rst_n) begin
      pending_reg <= 1'b0;
    end
    else if (!pending_reg && req_i) begin
      pending_reg <= 1'b1;
    end
    else if (done) begin
      pending_reg <= 1'b0;
    end
  end
//由于不同的地址会造成写入data_ram还是写入GPIO输出恶寄存器，因此需要增加条件进行判断
  assign ram_wr_hit = (addr_i[31:7] == 25'd0);
  assign ram_rd_hit = (addr_i[31:7] == 25'd0);
  assign ram_wr_en  = ram_wr_hit & we_i & done;
  assign ram_rd_en  = ram_rd_hit & ~we_i & done;

  data_ram data_ram_inst (
      .clk(clk),
      .rst_n(rst_n),
      .ram_wr_addr_i(addr_i[6:2]),
      .ram_rd_addr_i(addr_i[6:2]),
      .ram_wr_data_i(wdata_i),
      .ram_wr_en_i(ram_wr_en),
      .ram_rd_en_i(ram_rd_en),
      .ram_wr_sel_i(wstrb_i),
      .ram_rd_data_o(rdata_o)
  );

endmodule

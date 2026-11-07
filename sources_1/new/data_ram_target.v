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


module data_ram_target#(
  parameter USE_UPSTREAM_MAP = 0
)  (
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
// //由于不同的地址会造成写入ram还是写入GPIO输出恶寄存器，因此需要增加条件进行判断
//   assign ram_wr_hit = (addr_i[31:7] == 25'd0);
//   assign ram_rd_hit = (addr_i[31:7] == 25'd0);
//   assign ram_wr_en  = ram_wr_hit & we_i & done;
//   assign ram_rd_en  = ram_rd_hit & ~we_i & done;

//   ram ram_inst (
//       .clk(clk),
//       .rst_n(rst_n),
//       .ram_wr_addr_i(addr_i[6:2]),
//       .ram_rd_addr_i(addr_i[6:2]),
//       .ram_wr_data_i(wdata_i),
//       .ram_wr_en_i(ram_wr_en),
//       .ram_rd_en_i(ram_rd_en),
//       .ram_wr_sel_i(wstrb_i),
//       .ram_rd_data_o(rdata_o)
//   );

  localparam RAM_ADDR_WIDTH = USE_UPSTREAM_MAP ? 12 : 5;

  wire [RAM_ADDR_WIDTH-1:0] ram_word_addr;
  wire [31:0] ram_rdata;

  assign ram_word_addr = addr_i[RAM_ADDR_WIDTH+1:2];

  assign ram_wr_hit = USE_UPSTREAM_MAP
                    ? (addr_i[31:14] == 18'h04000)
                    : (addr_i[31:7] == 25'd0);
  assign ram_rd_hit = ram_wr_hit;

  // 写入仍在请求完成的上升沿发生。
  assign ram_wr_en = ram_wr_hit && we_i && done;

  // 同步 RAM 在接收请求时读，组合 RAM 在完成时读。
  assign ram_rd_en = ram_rd_hit && !we_i &&
                     (USE_UPSTREAM_MAP ? (rst_n && req_i && !pending_reg)
                                       : done);

  assign rdata_o = (ram_rd_hit && !we_i && done) ? ram_rdata : 32'd0;

  ram #(
      .ADDR_WIDTH(RAM_ADDR_WIDTH),
      .SYNC_READ(USE_UPSTREAM_MAP)
  ) ram_inst (
      .clk(clk),
      .rst_n(rst_n),
      .ram_wr_addr_i(ram_word_addr),
      .ram_rd_addr_i(ram_word_addr),
      .ram_wr_data_i(wdata_i),
      .ram_wr_en_i(ram_wr_en),
      .ram_rd_en_i(ram_rd_en),
      .ram_wr_sel_i(wstrb_i),
      .ram_rd_data_o(ram_rdata)
  );

endmodule

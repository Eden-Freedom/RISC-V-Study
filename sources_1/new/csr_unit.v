`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/30 10:22:43
// Design Name: 
// Module Name: csr_unit
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


module csr_unit (
    input wire        clk,
    input wire        rst_n,
    input wire        csr_wr_en_i,
    input wire        csr_rd_en_i,
    input wire [2:0]       csr_type_i,
    input wire [11:0] csr_wr_addr_i,
    input wire [31:0] csr_src_data_i,

    input  wire [11:0] csr_rd_addr_i,
    output reg  [31:0] csr_rdata_o
);

  reg     [31:0] mscratch_reg;
  integer        i;

  //写逻辑
  always @(posedge clk) begin
    if (rst_n == 1'b0) begin
      mscratch_reg <= 32'h00000000;
    end
    else if (csr_wr_en_i == 1'b1 && csr_wr_addr_i == 12'h340) begin
      case (csr_type_i)
      3'b001,3'b101:begin
        mscratch_reg <= csr_src_data_i;
      end
      3'b010,3'b110:begin
        mscratch_reg <= mscratch_reg |csr_src_data_i;
      end
      3'b011,3'b111:begin
        mscratch_reg <= mscratch_reg & ~csr_src_data_i;
      end

      default:begin
        mscratch_reg <= mscratch_reg;
      end
      endcase
    end
  end

  //读逻辑
  always @(*) begin
    if (csr_rd_en_i == 1'b1) begin
      if (csr_rd_addr_i == 12'h340) begin
        csr_rdata_o = mscratch_reg;
      end
      else begin
        csr_rdata_o = 32'h00000000;
      end
    end
    else begin
      csr_rdata_o = 32'h00000000;
    end
  end

endmodule

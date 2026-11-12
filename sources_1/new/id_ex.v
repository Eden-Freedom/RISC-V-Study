`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 16:52:07
// Design Name: 
// Module Name: id_ex
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

`include "cpu_op_defs.vh"
module id_ex(
    input wire clk,
    input wire rst_n,
    input wire valid_idex_i,
    input wire flush_idex_i,
    input wire stall_idex_i,
    input wire [31:0] pc_idex_i,
    input wire [31:0] rs1_data_idex_i,
    input wire [31:0] rs2_data_idex_i,
    input wire [31:0] immi_data_idex_i,
    input wire [31:0] immb_data_idex_i,
    input wire [31:0] immj_data_idex_i,
    input wire [31:0] immu_data_idex_i,
    input wire [31:0] imms_data_idex_i,
    input wire [31:0] imm_csr_idex_i,
    input wire [11:0] csr_addr_idex_i,
    input wire [4:0] rd_addr_idex_i,

    input wire [5:0] op_idex_i,

    input wire is_illegal_idex_i,

    output reg valid_idex_o,
    output reg [31:0] pc_idex_o,
    output reg [31:0] rs1_data_idex_o,
    output reg [31:0] rs2_data_idex_o,
    output reg [31:0] immi_data_idex_o,
    output reg [31:0] immb_data_idex_o,
    output reg [31:0] immj_data_idex_o,
    output reg [31:0] immu_data_idex_o,
    output reg [31:0] imms_data_idex_o,
    output reg [31:0] imm_csr_idex_o,
    output reg [11:0] csr_addr_idex_o,
    output reg [4:0] rd_addr_idex_o,

    output reg [5:0] op_idex_o,

    output reg is_illegal_idex_o
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_idex_o <= 1'b0;
            pc_idex_o <= 32'h0;
            rs1_data_idex_o <= 32'h0;
            rs2_data_idex_o <= 32'h0;
            immi_data_idex_o <= 32'h0;
            immb_data_idex_o <= 32'h0;
            immj_data_idex_o <= 32'h0;
            immu_data_idex_o <= 32'h0;
            imms_data_idex_o <= 32'h0;
            imm_csr_idex_o <= 32'h0;
            csr_addr_idex_o <= 12'h0;
            rd_addr_idex_o <= 5'h0;

            op_idex_o <= `CPU_OP_NONE;

            is_illegal_idex_o <= 1'b0;

        end 
        else if (flush_idex_i) begin
            valid_idex_o <= 1'b0;
            pc_idex_o <= 32'h0;
            rs1_data_idex_o <= 32'h0;
            rs2_data_idex_o <= 32'h0;
            immi_data_idex_o <= 32'h0;
            immb_data_idex_o <= 32'h0;
            immj_data_idex_o <= 32'h0;
            immu_data_idex_o <= 32'h0;
            imms_data_idex_o <= 32'h0;
            imm_csr_idex_o <= 32'h0;
            csr_addr_idex_o <= 12'h0;
            rd_addr_idex_o <= 5'h0;

            op_idex_o <= `CPU_OP_NONE;

            is_illegal_idex_o <= 1'b0;

        end 
        else if (stall_idex_i) begin
            valid_idex_o <= valid_idex_o;
            pc_idex_o <= pc_idex_o;
            rs1_data_idex_o <= rs1_data_idex_o;
            rs2_data_idex_o <= rs2_data_idex_o;
            immi_data_idex_o <= immi_data_idex_o;
            immb_data_idex_o <= immb_data_idex_o;
            immj_data_idex_o <= immj_data_idex_o;
            immu_data_idex_o <= immu_data_idex_o;
            imms_data_idex_o <= imms_data_idex_o;
            imm_csr_idex_o <= imm_csr_idex_o;
            csr_addr_idex_o <= csr_addr_idex_o;
            rd_addr_idex_o <= rd_addr_idex_o;

            op_idex_o <= op_idex_o;

            is_illegal_idex_o <= is_illegal_idex_o;
        end
        else begin
            valid_idex_o <= valid_idex_i;
            pc_idex_o <= pc_idex_i;
            rs1_data_idex_o <= rs1_data_idex_i;
            rs2_data_idex_o <= rs2_data_idex_i;
            immi_data_idex_o <= immi_data_idex_i;
            immb_data_idex_o <= immb_data_idex_i;
            immj_data_idex_o <= immj_data_idex_i;
            immu_data_idex_o <= immu_data_idex_i;
            imms_data_idex_o <= imms_data_idex_i;
            imm_csr_idex_o <= imm_csr_idex_i;
            csr_addr_idex_o <= csr_addr_idex_i;
            rd_addr_idex_o <= rd_addr_idex_i;

            op_idex_o <= op_idex_i;

            is_illegal_idex_o <= is_illegal_idex_i;
        end
    end
endmodule

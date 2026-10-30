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

    input wire is_addi_idex_i,
    input wire is_xori_idex_i,
    input wire is_ori_idex_i,
    input wire is_andi_idex_i,
    input wire is_slli_idex_i,
    input wire is_srli_idex_i,
    input wire is_srai_idex_i,
    input wire is_slti_idex_i,
    input wire is_sltiu_idex_i,

    input wire is_sub_idex_i,
    input wire is_add_idex_i,
    input wire is_xor_idex_i,
    input wire is_or_idex_i,
    input wire is_and_idex_i,
    input wire is_sll_idex_i,
    input wire is_srl_idex_i,
    input wire is_sra_idex_i,
    input wire is_slt_idex_i,
    input wire is_sltu_idex_i,

    
    input wire is_beq_idex_i,
    input wire is_bne_idex_i,
    input wire is_blt_idex_i,
    input wire is_bge_idex_i,
    input wire is_bltu_idex_i,
    input wire is_bgeu_idex_i,

    input wire is_jal_idex_i,
    input wire is_jalr_idex_i,

    input wire is_lui_idex_i,
    input wire is_auipc_idex_i,

    input wire is_sw_idex_i,
    input wire is_sb_idex_i,
    input wire is_sh_idex_i,
    
    input wire is_lw_idex_i,
    input wire is_lb_idex_i,
    input wire is_lbu_idex_i,
    input wire is_lh_idex_i,
    input wire is_lhu_idex_i,

    input wire is_mul_idex_i,
    input wire is_mulh_idex_i,
    input wire is_mulhsu_idex_i,
    input wire is_mulhu_idex_i,

    input wire is_div_idex_i,
    input wire is_divu_idex_i,
    input wire is_rem_idex_i,
    input wire is_remu_idex_i,

    input wire is_csrrw_idex_i,
    input wire is_csrrs_idex_i,
    input wire is_csrrc_idex_i,
    input wire is_csrrwi_idex_i,
    input wire is_csrrsi_idex_i,
    input wire is_csrrci_idex_i,

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

    output reg is_addi_idex_o,
    output reg is_xori_idex_o,
    output reg is_ori_idex_o,
    output reg is_andi_idex_o,
    output reg is_slli_idex_o,
    output reg is_srli_idex_o,
    output reg is_srai_idex_o,
    output reg is_slti_idex_o,
    output reg is_sltiu_idex_o,

    output reg is_sub_idex_o,
    output reg is_add_idex_o,
    output reg is_xor_idex_o,
    output reg is_or_idex_o,
    output reg is_and_idex_o,
    output reg is_sll_idex_o,
    output reg is_srl_idex_o,
    output reg is_sra_idex_o,
    output reg is_slt_idex_o,
    output reg is_sltu_idex_o,

    output reg is_beq_idex_o,
    output reg is_bne_idex_o,
    output reg is_blt_idex_o,
    output reg is_bge_idex_o,
    output reg is_bltu_idex_o,
    output reg is_bgeu_idex_o,

    output reg is_jal_idex_o,
    output reg is_jalr_idex_o,

    output reg is_lui_idex_o,
    output reg is_auipc_idex_o,

    output reg is_sw_idex_o,
    output reg is_sb_idex_o,
    output reg is_sh_idex_o,

    output reg is_lw_idex_o,
    output reg is_lb_idex_o,
    output reg is_lbu_idex_o,
    output reg is_lh_idex_o,
    output reg is_lhu_idex_o,

    output reg is_mul_idex_o,
    output reg is_mulh_idex_o,
    output reg is_mulhsu_idex_o,
    output reg is_mulhu_idex_o,

    output reg is_div_idex_o,
    output reg is_divu_idex_o,
    output reg is_rem_idex_o,
    output reg is_remu_idex_o,

    output reg is_csrrw_idex_o,
    output reg is_csrrs_idex_o,
    output reg is_csrrc_idex_o,
    output reg is_csrrwi_idex_o,
    output reg is_csrrsi_idex_o,
    output reg is_csrrci_idex_o
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

            is_addi_idex_o <= 1'b0;
            is_xori_idex_o <= 1'b0;
            is_ori_idex_o <= 1'b0;
            is_andi_idex_o <= 1'b0;
            is_slli_idex_o <= 1'b0;
            is_srli_idex_o <= 1'b0;
            is_srai_idex_o <= 1'b0;
            is_slti_idex_o <= 1'b0;
            is_sltiu_idex_o <= 1'b0;
            

            is_sub_idex_o <= 1'b0;
            is_add_idex_o <= 1'b0; 
            is_xor_idex_o <= 1'b0;
            is_or_idex_o <= 1'b0;
            is_and_idex_o <= 1'b0;
            is_sll_idex_o <= 1'b0;
            is_srl_idex_o <= 1'b0;
            is_sra_idex_o <= 1'b0;
            is_slt_idex_o <= 1'b0;
            is_sltu_idex_o <= 1'b0;

            is_beq_idex_o <= 1'b0;
            is_bne_idex_o <= 1'b0;
            is_blt_idex_o <= 1'b0;
            is_bge_idex_o <= 1'b0;
            is_bltu_idex_o <= 1'b0;
            is_bgeu_idex_o <= 1'b0;

            is_jal_idex_o <= 1'b0;
            is_jalr_idex_o <= 1'b0;

            is_lui_idex_o <= 1'b0;
            is_auipc_idex_o <= 1'b0;

            is_sw_idex_o <= 1'b0;
            is_sb_idex_o <= 1'b0;
            is_sh_idex_o <= 1'b0;

            is_lw_idex_o <= 1'b0;
            is_lb_idex_o <= 1'b0;
            is_lbu_idex_o <= 1'b0;
            is_lh_idex_o <= 1'b0;
            is_lhu_idex_o <= 1'b0;

            is_mul_idex_o <= 1'b0;
            is_mulh_idex_o <= 1'b0;
            is_mulhsu_idex_o <= 1'b0;
            is_mulhu_idex_o <= 1'b0;

            is_div_idex_o <= 1'b0;
            is_divu_idex_o <= 1'b0;
            is_rem_idex_o <= 1'b0;
            is_remu_idex_o <= 1'b0;

            is_csrrw_idex_o <= 1'b0;
            is_csrrs_idex_o <= 1'b0;
            is_csrrc_idex_o <= 1'b0;
            is_csrrwi_idex_o <= 1'b0;
            is_csrrsi_idex_o <= 1'b0;
            is_csrrci_idex_o <= 1'b0;

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

            is_addi_idex_o <= 1'b0;
            is_xori_idex_o <= 1'b0;
            is_ori_idex_o <= 1'b0;
            is_andi_idex_o <= 1'b0;
            is_slli_idex_o <= 1'b0;
            is_srli_idex_o <= 1'b0;
            is_srai_idex_o <= 1'b0;
            is_slti_idex_o <= 1'b0;
            is_sltiu_idex_o <= 1'b0;
            

            is_sub_idex_o <= 1'b0;
            is_add_idex_o <= 1'b0; 
            is_xor_idex_o <= 1'b0;
            is_or_idex_o <= 1'b0;
            is_and_idex_o <= 1'b0;
            is_sll_idex_o <= 1'b0;
            is_srl_idex_o <= 1'b0;
            is_sra_idex_o <= 1'b0;
            is_slt_idex_o <= 1'b0;
            is_sltu_idex_o <= 1'b0;

            is_beq_idex_o <= 1'b0;
            is_bne_idex_o <= 1'b0;
            is_blt_idex_o <= 1'b0;
            is_bge_idex_o <= 1'b0;
            is_bltu_idex_o <= 1'b0;
            is_bgeu_idex_o <= 1'b0;

            is_jal_idex_o <= 1'b0;
            is_jalr_idex_o <= 1'b0;

            is_lui_idex_o <= 1'b0;
            is_auipc_idex_o <= 1'b0;

            is_sw_idex_o <= 1'b0;
            is_sb_idex_o <= 1'b0;
            is_sh_idex_o <= 1'b0;

            is_lw_idex_o <= 1'b0;
            is_lb_idex_o <= 1'b0;
            is_lbu_idex_o <= 1'b0;
            is_lh_idex_o <= 1'b0;
            is_lhu_idex_o <= 1'b0;

            is_mul_idex_o <= 1'b0;
            is_mulh_idex_o <= 1'b0;
            is_mulhsu_idex_o <= 1'b0;
            is_mulhu_idex_o <= 1'b0;

            is_div_idex_o <= 1'b0;
            is_divu_idex_o <= 1'b0;
            is_rem_idex_o <= 1'b0;
            is_remu_idex_o <= 1'b0;

            is_csrrw_idex_o <= 1'b0;
            is_csrrs_idex_o <= 1'b0;
            is_csrrc_idex_o <= 1'b0;
            is_csrrwi_idex_o <= 1'b0;
            is_csrrsi_idex_o <= 1'b0;
            is_csrrci_idex_o <= 1'b0;

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

            is_addi_idex_o <= is_addi_idex_o;
            is_xori_idex_o <= is_xori_idex_o;
            is_ori_idex_o <= is_ori_idex_o;
            is_andi_idex_o <= is_andi_idex_o;
            is_slli_idex_o <= is_slli_idex_o;
            is_srli_idex_o <= is_srli_idex_o;
            is_srai_idex_o <= is_srai_idex_o;
            is_slti_idex_o <= is_slti_idex_o;
            is_sltiu_idex_o <= is_sltiu_idex_o;
            
            is_sub_idex_o <= is_sub_idex_o;
            is_add_idex_o <= is_add_idex_o;
            is_xor_idex_o <= is_xor_idex_o;
            is_or_idex_o <= is_or_idex_o;
            is_and_idex_o <= is_and_idex_o;
            is_sll_idex_o <= is_sll_idex_o;
            is_srl_idex_o <= is_srl_idex_o;
            is_sra_idex_o <= is_sra_idex_o;
            is_slt_idex_o <= is_slt_idex_o;
            is_sltu_idex_o <= is_sltu_idex_o;

            is_beq_idex_o <= is_beq_idex_o;
            is_bne_idex_o <= is_bne_idex_o;
            is_blt_idex_o <= is_blt_idex_o;
            is_bge_idex_o <= is_bge_idex_o;
            is_bltu_idex_o <= is_bltu_idex_o;
            is_bgeu_idex_o <= is_bgeu_idex_o;

            is_jal_idex_o <= is_jal_idex_o;
            is_jalr_idex_o <= is_jalr_idex_o;

            is_lui_idex_o <= is_lui_idex_o;
            is_auipc_idex_o <= is_auipc_idex_o;

            is_sw_idex_o <= is_sw_idex_o;
            is_sb_idex_o <= is_sb_idex_o;
            is_sh_idex_o <= is_sh_idex_o;

            is_lw_idex_o <= is_lw_idex_o;
            is_lb_idex_o <= is_lb_idex_o;
            is_lbu_idex_o <= is_lbu_idex_o;
            is_lh_idex_o <= is_lh_idex_o;
            is_lhu_idex_o <= is_lhu_idex_o;

            is_mul_idex_o <= is_mul_idex_o;
            is_mulh_idex_o <= is_mulh_idex_o;
            is_mulhsu_idex_o <= is_mulhsu_idex_o;
            is_mulhu_idex_o <= is_mulhu_idex_o;

            is_div_idex_o <= is_div_idex_o;
            is_divu_idex_o <= is_divu_idex_o;
            is_rem_idex_o <= is_rem_idex_o;
            is_remu_idex_o <= is_remu_idex_o;

            is_csrrw_idex_o <= is_csrrw_idex_o;
            is_csrrs_idex_o <= is_csrrs_idex_o;
            is_csrrc_idex_o <= is_csrrc_idex_o;
            is_csrrwi_idex_o <= is_csrrwi_idex_o;
            is_csrrsi_idex_o <= is_csrrsi_idex_o;
            is_csrrci_idex_o <= is_csrrci_idex_o;
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

            is_addi_idex_o <= is_addi_idex_i;
            is_xori_idex_o <= is_xori_idex_i;
            is_ori_idex_o <= is_ori_idex_i;
            is_andi_idex_o <= is_andi_idex_i;
            is_slli_idex_o <= is_slli_idex_i;
            is_srli_idex_o <= is_srli_idex_i;
            is_srai_idex_o <= is_srai_idex_i;
            is_slti_idex_o <= is_slti_idex_i;
            is_sltiu_idex_o <= is_sltiu_idex_i;
            
            is_sub_idex_o <= is_sub_idex_i;
            is_add_idex_o <= is_add_idex_i;
            is_xor_idex_o <= is_xor_idex_i;
            is_or_idex_o <= is_or_idex_i;
            is_and_idex_o <= is_and_idex_i;
            is_sll_idex_o <= is_sll_idex_i;
            is_srl_idex_o <= is_srl_idex_i;
            is_sra_idex_o <= is_sra_idex_i;
            is_slt_idex_o <= is_slt_idex_i;
            is_sltu_idex_o <= is_sltu_idex_i;

            is_beq_idex_o <= is_beq_idex_i;
            is_bne_idex_o <= is_bne_idex_i;
            is_blt_idex_o <= is_blt_idex_i;
            is_bge_idex_o <= is_bge_idex_i;
            is_bltu_idex_o <= is_bltu_idex_i;
            is_bgeu_idex_o <= is_bgeu_idex_i;

            is_jal_idex_o <= is_jal_idex_i;
            is_jalr_idex_o <= is_jalr_idex_i;

            is_lui_idex_o <= is_lui_idex_i;
            is_auipc_idex_o <= is_auipc_idex_i;

            is_sw_idex_o <= is_sw_idex_i;
            is_sb_idex_o <= is_sb_idex_i;
            is_sh_idex_o <= is_sh_idex_i;
            
            is_lw_idex_o <= is_lw_idex_i;
            is_lb_idex_o <= is_lb_idex_i;
            is_lbu_idex_o <= is_lbu_idex_i;
            is_lh_idex_o <= is_lh_idex_i;
            is_lhu_idex_o <= is_lhu_idex_i;

            is_mul_idex_o <= is_mul_idex_i;
            is_mulh_idex_o <= is_mulh_idex_i;
            is_mulhsu_idex_o <= is_mulhsu_idex_i;
            is_mulhu_idex_o <= is_mulhu_idex_i;

            is_div_idex_o <= is_div_idex_i;
            is_divu_idex_o <= is_divu_idex_i;
            is_rem_idex_o <= is_rem_idex_i;
            is_remu_idex_o <= is_remu_idex_i;

            is_csrrw_idex_o <= is_csrrw_idex_i;
            is_csrrs_idex_o <= is_csrrs_idex_i;
            is_csrrc_idex_o <= is_csrrc_idex_i;
            is_csrrwi_idex_o <= is_csrrwi_idex_i;
            is_csrrsi_idex_o <= is_csrrsi_idex_i;
            is_csrrci_idex_o <= is_csrrci_idex_i;
        end
    end
endmodule

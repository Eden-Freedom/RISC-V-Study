`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 16:02:15
// Design Name: 
// Module Name: addi_core
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


module addi_core(
    input wire clk,
    input wire rst_n,
    
    output wire [31:0] pc_o,
    output wire [31:0] instr_o,
    output wire wr_en,
    output wire [4:0] wr_addr,
    output wire [31:0] wr_data
    );

    //指令部分
    wire [4:0] rs1_addr_o;
    wire [4:0] rd_addr_o;
    wire is_addi_o;
    wire [31:0] rs1_data_o;
    wire [31:0] rs2_data_o;
    wire [4:0] rs2_addr_o;
    wire [31:0] imm_typei_o;
    wire [31:0] imm_typeu_o;
    wire [31:0] imm_typeb_o;
    wire [31:0] imm_typej_o;
    wire [31:0] imm_types_o;

    //数据部分
    wire ram_rd_en_o;
    wire ram_wr_en_o;
    wire [31:0] ram_rd_addr_o;
    wire [31:0] ram_rd_data_o;
    wire [31:0] ram_wr_addr_o;
    wire [31:0] ram_wr_data_o;
    wire [3:0] ram_wr_sel_o;


    //分支判断部分
    wire pc_brench_flag_o;
    wire [31:0] pc_brench_addr_o;


    wire is_add_o;
    wire is_sub_o;
    wire is_xor_o;
    wire is_or_o;
    wire is_and_o;
    wire is_sll_o;
    wire is_srl_o;
    wire is_sra_o;
    wire is_beq_o;
    wire is_bne_o;
    wire is_blt_o;
    wire is_bge_o;
    wire is_bltu_o;
    wire is_bgeu_o;
    wire is_jal_o;
    wire is_jalr_o;
    wire is_sw_o;
    wire is_lw_o;
    wire is_lb_o;
    wire is_lbu_o;
    wire is_lh_o;
    wire is_lhu_o;
    wire is_sb_o;



    fetch_unit fetch_unit_inst(
        .clk(clk),
        .rst_n(rst_n),
        .pc_brench_flag_i(pc_brench_flag_o),
        .pc_brench_addr_i(pc_brench_addr_o),
        .pc_o(pc_o),
        .instr_o(instr_o)
    );

    addi_decode addi_decode_inst(
        .instr_i(instr_o),
        .imm_typei_o(imm_typei_o),
        .imm_typeu_o(imm_typeu_o),
        .imm_typeb_o(imm_typeb_o),
        .imm_typej_o(imm_typej_o),
        .imm_types_o(imm_types_o),
        .rs1_addr_o(rs1_addr_o),
        .rs2_addr_o(rs2_addr_o),
        .rd_addr_o(rd_addr_o),
        .is_addi_o(is_addi_o),
        .is_add_o(is_add_o),
        .is_sub_o(is_sub_o),
        .is_xor_o(is_xor_o),
        .is_or_o(is_or_o),
        .is_and_o(is_and_o),
        .is_sll_o(is_sll_o),
        .is_srl_o(is_srl_o),
        .is_sra_o(is_sra_o),
        .is_slli_o(is_slli_o),
        .is_srli_o(is_srli_o),
        .is_srai_o(is_srai_o),
        .is_slt_o(is_slt_o),
        .is_sltu_o(is_sltu_o),
        .is_slti_o(is_slti_o),
        .is_sltiu_o(is_sltiu_o),
        .is_lui_o(is_lui_o),
        .is_auipc_o(is_auipc_o),
        .is_beq_o(is_beq_o),
        .is_bne_o(is_bne_o),
        .is_blt_o(is_blt_o),
        .is_bge_o(is_bge_o),
        .is_bltu_o(is_bltu_o),
        .is_bgeu_o(is_bgeu_o),
        .is_jal_o(is_jal_o),
        .is_jalr_o(is_jalr_o),
        .is_sw_o(is_sw_o),
        .is_lw_o(is_lw_o),
        .is_lb_o(is_lb_o),
        .is_lbu_o(is_lbu_o),
        .is_lh_o(is_lh_o),
        .is_lhu_o(is_lhu_o),
        .is_sb_o(is_sb_o),
        .is_sh_o(is_sh_o)
    );

    addi_execute addi_execute_inst(
        .pc_i(pc_o),
        .is_addi_i(is_addi_o),
        .is_add_i(is_add_o),
        .is_sub_i(is_sub_o),
        .is_xor_i(is_xor_o),
        .is_or_i(is_or_o),
        .is_and_i(is_and_o),
        .is_sll_i(is_sll_o),
        .is_srl_i(is_srl_o),
        .is_sra_i(is_sra_o),
        .is_slli_i(is_slli_o),
        .is_srli_i(is_srli_o),
        .is_srai_i(is_srai_o),
        .is_slt_i(is_slt_o),
        .is_sltu_i(is_sltu_o),
        .is_slti_i(is_slti_o),
        .is_sltiu_i(is_sltiu_o),
        .is_lui_i(is_lui_o),
        .is_auipc_i(is_auipc_o),
        .is_beq_i(is_beq_o),
        .is_bne_i(is_bne_o),
        .is_blt_i(is_blt_o),
        .is_bge_i(is_bge_o),
        .is_bltu_i(is_bltu_o),
        .is_bgeu_i(is_bgeu_o),
        .is_jal_i(is_jal_o),
        .is_jalr_i(is_jalr_o),
        .is_sw_i(is_sw_o),
        .is_lw_i(is_lw_o),
        .is_lb_i(is_lb_o),
        .is_lbu_i(is_lbu_o),
        .is_lh_i(is_lh_o),
        .is_lhu_i(is_lhu_o),
        .is_sb_i(is_sb_o),
        .is_sh_i(is_sh_o),
        .imm_typej_i(imm_typej_o),
        .imm_typei_i(imm_typei_o),
        .imm_typeu_i(imm_typeu_o),
        .imm_typeb_i(imm_typeb_o),
        .imm_types_i(imm_types_o),
        .rs1_data_i(rs1_data_o),
        .rs2_data_i(rs2_data_o),
        .rd_addr_i(rd_addr_o),
        .wr_en_o(wr_en),
        .wr_addr_o(wr_addr),
        .wr_data_o(wr_data),
        .pc_brench_flag_o(pc_brench_flag_o),
        .pc_brench_addr_o(pc_brench_addr_o),

        //数据读写部分
        .ram_wr_en_o(ram_wr_en_o),
        .ram_wr_sel_o(ram_wr_sel_o),
        .ram_wr_addr_o(ram_wr_addr_o),
        .ram_wr_data_o(ram_wr_data_o),
        .ram_rd_en_o(ram_rd_en_o),
        .ram_rd_addr_o(ram_rd_addr_o),
        .ram_rd_data_i(ram_rd_data_o)
    );

    ram  ram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ram_wr_addr_i(ram_wr_addr_o[6:2]),
        .ram_rd_addr_i(ram_rd_addr_o[6:2]),
        .ram_wr_data_i(ram_wr_data_o),
        .ram_wr_en_i(ram_wr_en_o),
        .ram_rd_en_i(ram_rd_en_o),
        .ram_wr_sel_i(ram_wr_sel_o),
        .ram_rd_data_o(ram_rd_data_o)
      );


    regfile regfile_inst(
        .clk(clk),
        .rst_n(rst_n),
        .wr_en_i(wr_en),
        .wr_addr_i(wr_addr),
        .wr_data_i(wr_data),
        .rs1_addr_i(rs1_addr_o),
        .rs1_data_o(rs1_data_o),
        .rs2_addr_i(rs2_addr_o),
        .rs2_data_o(rs2_data_o)
    );




endmodule

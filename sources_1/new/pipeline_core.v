`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 20:29:44
// Design Name: 
// Module Name: pipeline_core
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


module pipeline_core (
    input wire clk,
    input wire rst_n
    
);

  //fetch_unit

  wire [31:0] pc_o;//fetch_unit 输出，if_id 输入
  wire [31:0] instr_o;//fetch_unit 输出，if_id 输入

  //if_id
  wire        valid_ifid_o; //if_id输出，id_ex输入
  wire [31:0]       pc_ifid_o;//if_id输出，id_ex输入   
  wire [31:0] instr_ifid_o;//if_id输出，decode输入

  //addi_decode
  wire [31:0]       imm_typei_o;//decode输出，id_ex输入
  wire [31:0]       imm_typeb_o;//decode输出，id_ex输入
  wire [31:0]       imm_typej_o;//decode输出，id_ex输入
  wire [31:0]       imm_typeu_o;//decode输出，id_ex输入

  wire    [4:0]    rs1_addr_o;//decode输出，id_ex，regfile输入
  wire    [4:0]    rs2_addr_o;//decode输出，id_ex，regfile输入
  wire    [4:0]    rd_addr_o;//decode输出，id_ex输入
  wire        is_addi_o;//decode输出，id_ex输入
  wire        is_xori_o;//decode输出，id_ex输入
  wire        is_ori_o;//decode输出，id_ex输入
  wire        is_andi_o;//decode输出，id_ex输入
  wire        is_slli_o;//decode输出，id_ex输入
  wire        is_srli_o;//decode输出，id_ex输入
  wire        is_srai_o;//decode输出，id_ex输入
  wire        is_slti_o;//decode输出，id_ex输入
  wire        is_sltiu_o;//decode输出，id_ex输入

  wire        is_add_o;//decode输出，id_ex输入
  wire        is_sub_o;//decode输出，id_ex输入
  wire        is_xor_o;//decode输出，id_ex输入
  wire        is_or_o;//decode输出，id_ex输入
  wire        is_and_o;//decode输出，id_ex输入
  wire        is_sll_o;//decode输出，id_ex输入
  wire        is_srl_o;//decode输出，id_ex输入
  wire        is_sra_o;//decode输出，id_ex输入
  wire        is_slt_o;//decode输出，id_ex输入
  wire        is_sltu_o;//decode输出，id_ex输入

  wire        is_beq_o;//decode输出，id_ex输入
  wire        is_bne_o;//decode输出，id_ex输入
  wire        is_blt_o;//decode输出，id_ex输入
  wire        is_bge_o;//decode输出，id_ex输入
  wire        is_bltu_o;//decode输出，id_ex输入
  wire        is_bgeu_o;//decode输出，id_ex输入

  wire        is_jal_o;//decode输出，id_ex输入
  wire        is_jalr_o;//decode输出，id_ex输入

  wire        is_lui_o;//decode输出，id_ex输入
  wire        is_auipc_o;//decode输出，id_ex输入

  //id_ex
  wire        valid_idex_i;//id_ex输入，if_id，decode组合逻辑输出
  wire        valid_idex_o;//id_ex输出，ex输入
  wire [31:0] pc_idex_o;//id_ex输出
  wire [31:0] rs1_data_idex_o;//id_ex输出，ex输入
  wire [31:0] rs2_data_idex_o;//id_ex输出，ex输入
  wire [31:0] immi_data_idex_o;//id_ex输出，ex输入
  wire [31:0] immb_data_idex_o;//id_ex输出，ex输入
  wire [31:0] immj_data_idex_o;//id_ex输出，ex输入
  wire [31:0] immu_data_idex_o;//id_ex输出，ex输入
  wire [4:0] rd_addr_idex_o;//id_ex输出，ex输入

  wire        is_addi_idex_o;//id_ex输出 ex输入
  wire        is_xori_idex_o;//id_ex输出 ex输入
  wire        is_ori_idex_o;//id_ex输出 ex输入
  wire        is_andi_idex_o;//id_ex输出 ex输入
  wire        is_slli_idex_o;//id_ex输出 ex输入
  wire        is_srli_idex_o;//id_ex输出 ex输入
  wire        is_srai_idex_o;//id_ex输出 ex输入
  wire        is_slti_idex_o;//id_ex输出 ex输入
  wire        is_sltiu_idex_o;//id_ex输出 ex输入

  wire        is_sub_idex_o;//id_ex输出 ex输入
  wire        is_add_idex_o;//id_ex输出 ex输入
  wire        is_xor_idex_o;//id_ex输出 ex输入
  wire        is_or_idex_o;//id_ex输出 ex输入
  wire        is_and_idex_o;//id_ex输出 ex输入
  wire        is_sll_idex_o;//id_ex输出 ex输入
  wire        is_srl_idex_o;//id_ex输出 ex输入
  wire        is_sra_idex_o;//id_ex输出 ex输入
  wire        is_slt_idex_o;//id_ex输出 ex输入
  wire        is_sltu_idex_o;//id_ex输出 ex输入

  wire        is_beq_idex_o;//id_ex输出 ex输入
  wire        is_bne_idex_o;//id_ex输出 ex输入
  wire        is_blt_idex_o;//id_ex输出 ex输入
  wire        is_bge_idex_o;//id_ex输出 ex输入
  wire        is_bltu_idex_o;//id_ex输出 ex输入
  wire        is_bgeu_idex_o;//id_ex输出 ex输入

  wire        is_jal_idex_o;//id_ex输出 ex输入
  wire        is_jalr_idex_o;//id_ex输出 ex输入

  wire        is_lui_idex_o;//id_ex输出 ex输入
  wire        is_auipc_idex_o;//id_ex输出 ex输入
  //ex
  wire wr_en_ex_o;//ex输出，regfile输入
  wire [4:0] wr_addr_ex_o;//ex输出，regfile输入
  wire [31:0] wr_data_ex_o;//ex输出，regfile输入
  wire        pc_brench_flag_ex_o;//ex输出，fetch_unit输入
  wire [31:0] pc_brench_addr_ex_o;//ex输出，fetch_unit输入
  wire        clear_valid_ex_o;//ex输出，if_id输入,id_ex输入

  //regfile
  wire [31:0] rs1_data_o; //regfile输出，id_ex输入
  wire [31:0] rs2_data_o; //regfile输出，id_ex输入

  //旁路，解决数据冒险
  wire [31:0] rs1_data_forward_o;//id_ex输入
  wire [31:0] rs2_data_forward_o;//id_ex输入
  

  fetch_unit fetch_unit_inst (
      .clk(clk),
      .rst_n(rst_n),
      .pc_brench_flag_i(pc_brench_flag_ex_o),
      .pc_brench_addr_i(pc_brench_addr_ex_o),
      .pc_o(pc_o),
      .instr_o(instr_o)
  );




  if_id if_id_inst (
      .clk(clk),
      .rst_n(rst_n),
      .valid_i(1'b1),
      .flush_ifid_i(clear_valid_ex_o),
      .pc_ifid_i(pc_o),
      .instr_ifid_i(instr_o),
      .valid_o(valid_ifid_o),
      .pc_ifid_o(pc_ifid_o),
      .instr_ifid_o(instr_ifid_o)
  );

  addi_decode addi_decode_inst (
      .instr_i(instr_ifid_o),
      .imm_typei_o(imm_typei_o),
      .imm_typeu_o(imm_typeu_o),
      .imm_typeb_o(imm_typeb_o),
      .imm_typej_o(imm_typej_o),
      .imm_types_o(),

      .rs1_addr_o(rs1_addr_o),
      .rs2_addr_o(rs2_addr_o),
      .rd_addr_o(rd_addr_o),

      .is_addi_o(is_addi_o),
      .is_xori_o(is_xori_o),
      .is_ori_o(is_ori_o),
      .is_andi_o(is_andi_o),
      .is_slli_o(is_slli_o),
      .is_srli_o(is_srli_o),
      .is_srai_o(is_srai_o),
      .is_slti_o(is_slti_o),
      .is_sltiu_o(is_sltiu_o),

      .is_add_o(is_add_o),
      .is_sub_o(is_sub_o),
      .is_xor_o(is_xor_o),
      .is_or_o(is_or_o),
      .is_and_o(is_and_o),
      .is_sll_o(is_sll_o),
      .is_srl_o(is_srl_o),
      .is_sra_o(is_sra_o),
      .is_slt_o(is_slt_o),
      .is_sltu_o(is_sltu_o),

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

      .is_sw_o(),
      .is_lw_o(),
      .is_lb_o(),
      .is_lbu_o(),
      .is_lh_o(),
      .is_lhu_o(),
      .is_sb_o(),
      .is_sh_o()
  );

  assign rs1_data_forward_o = (rs1_addr_o == wr_addr_ex_o && wr_en_ex_o && wr_addr_ex_o != 5'h0) ? wr_data_ex_o : rs1_data_o;
  assign rs2_data_forward_o = (rs2_addr_o == wr_addr_ex_o && wr_en_ex_o && wr_addr_ex_o != 5'h0) ? wr_data_ex_o : rs2_data_o;
  assign valid_idex_i = valid_ifid_o & 
                       (is_addi_o | is_xori_o | is_ori_o | is_andi_o | is_slli_o | is_srli_o | is_srai_o | is_slti_o | is_sltiu_o |
                       is_add_o | is_sub_o | is_xor_o | is_or_o | is_and_o | is_sll_o | is_srl_o | is_sra_o | is_slt_o | is_sltu_o |
                       is_beq_o |  is_bne_o | is_blt_o | is_bge_o | is_bltu_o | is_bgeu_o |
                       is_jal_o | is_jalr_o | 
                       is_lui_o | is_auipc_o );
  id_ex id_ex_inst (
      .clk(clk),
      .rst_n(rst_n),
      .valid_idex_i(valid_idex_i),
      .flush_idex_i(clear_valid_ex_o),
      .pc_idex_i(pc_ifid_o),
      .rs1_data_idex_i(rs1_data_forward_o),
      .rs2_data_idex_i(rs2_data_forward_o),
      .immi_data_idex_i(imm_typei_o),//先用I立即数进行组合逻辑运算，后面再根据类型选择不同的立即数
      .immb_data_idex_i(imm_typeb_o),
      .immj_data_idex_i(imm_typej_o),
      .immu_data_idex_i(imm_typeu_o),
      .rd_addr_idex_i(rd_addr_o),

      .is_addi_idex_i(is_addi_o),
      .is_xori_idex_i(is_xori_o),
      .is_ori_idex_i(is_ori_o),
      .is_andi_idex_i(is_andi_o),
      .is_slli_idex_i(is_slli_o),
      .is_srli_idex_i(is_srli_o),
      .is_srai_idex_i(is_srai_o),
      .is_slti_idex_i(is_slti_o),
      .is_sltiu_idex_i(is_sltiu_o),

      .is_sub_idex_i(is_sub_o),
      .is_add_idex_i(is_add_o),
      .is_xor_idex_i(is_xor_o),
      .is_or_idex_i(is_or_o),
      .is_and_idex_i(is_and_o),
      .is_sll_idex_i(is_sll_o),
      .is_srl_idex_i(is_srl_o),
      .is_sra_idex_i(is_sra_o),
      .is_slt_idex_i(is_slt_o),
      .is_sltu_idex_i(is_sltu_o),

      .is_beq_idex_i(is_beq_o),
      .is_bne_idex_i(is_bne_o),
      .is_bge_idex_i(is_bge_o),
      .is_blt_idex_i(is_blt_o),
      .is_bltu_idex_i(is_bltu_o),
      .is_bgeu_idex_i(is_bgeu_o),

      .is_jal_idex_i(is_jal_o),
      .is_jalr_idex_i(is_jalr_o),

      .is_lui_idex_i(is_lui_o),
      .is_auipc_idex_i(is_auipc_o),

      .valid_idex_o(valid_idex_o),
      .pc_idex_o(pc_idex_o),
      .rs1_data_idex_o(rs1_data_idex_o),
      .rs2_data_idex_o(rs2_data_idex_o),
      .immi_data_idex_o(immi_data_idex_o),
      .immb_data_idex_o(immb_data_idex_o),
      .immj_data_idex_o(immj_data_idex_o),
      .immu_data_idex_o(immu_data_idex_o),
      .rd_addr_idex_o(rd_addr_idex_o),

      .is_addi_idex_o(is_addi_idex_o),
      .is_xori_idex_o(is_xori_idex_o),
      .is_ori_idex_o(is_ori_idex_o),
      .is_andi_idex_o(is_andi_idex_o),
      .is_slli_idex_o(is_slli_idex_o),
      .is_srli_idex_o(is_srli_idex_o),
      .is_srai_idex_o(is_srai_idex_o),
      .is_slti_idex_o(is_slti_idex_o),
      .is_sltiu_idex_o(is_sltiu_idex_o),

      .is_sub_idex_o(is_sub_idex_o),
      .is_add_idex_o(is_add_idex_o),
      .is_xor_idex_o(is_xor_idex_o),
      .is_or_idex_o(is_or_idex_o),
      .is_and_idex_o(is_and_idex_o),
      .is_sll_idex_o(is_sll_idex_o),
      .is_srl_idex_o(is_srl_idex_o),
      .is_sra_idex_o(is_sra_idex_o),
      .is_slt_idex_o(is_slt_idex_o),
      .is_sltu_idex_o(is_sltu_idex_o),

      .is_beq_idex_o(is_beq_idex_o),
      .is_bne_idex_o(is_bne_idex_o),
      .is_blt_idex_o(is_blt_idex_o),
      .is_bge_idex_o(is_bge_idex_o),
      .is_bltu_idex_o(is_bltu_idex_o),
      .is_bgeu_idex_o(is_bgeu_idex_o),

      .is_jal_idex_o(is_jal_idex_o),
      .is_jalr_idex_o(is_jalr_idex_o),

      .is_lui_idex_o(is_lui_idex_o),
      .is_auipc_idex_o(is_auipc_idex_o)
  );

  ex ex_inst (
      .valid_ex_i(valid_idex_o),
      .pc_ex_i(pc_idex_o),

      .is_addi_ex_i(is_addi_idex_o),
      .is_xori_ex_i(is_xori_idex_o),
      .is_ori_ex_i(is_ori_idex_o),
      .is_andi_ex_i(is_andi_idex_o),
      .is_slli_ex_i(is_slli_idex_o),
      .is_srli_ex_i(is_srli_idex_o),
      .is_srai_ex_i(is_srai_idex_o),
      .is_slti_ex_i(is_slti_idex_o),
      .is_sltiu_ex_i(is_sltiu_idex_o),

      .is_add_ex_i(is_add_idex_o),
      .is_sub_ex_i(is_sub_idex_o),
      .is_xor_ex_i(is_xor_idex_o),
      .is_or_ex_i(is_or_idex_o),
      .is_and_ex_i(is_and_idex_o),
      .is_sll_ex_i(is_sll_idex_o),
      .is_srl_ex_i(is_srl_idex_o),
      .is_sra_ex_i(is_sra_idex_o),
      .is_slt_ex_i(is_slt_idex_o),
      .is_sltu_ex_i(is_sltu_idex_o),

      .is_beq_ex_i(is_beq_idex_o),
      .is_bne_ex_i(is_bne_idex_o),
      .is_blt_ex_i(is_blt_idex_o),
      .is_bge_ex_i(is_bge_idex_o),
      .is_bltu_ex_i(is_bltu_idex_o),
      .is_bgeu_ex_i(is_bgeu_idex_o),

      .is_jal_ex_i(is_jal_idex_o),
      .is_jalr_ex_i(is_jalr_idex_o),

      .is_lui_ex_i(is_lui_idex_o),
      .is_auipc_ex_i(is_auipc_idex_o),

      .rs1_data_ex_i(rs1_data_idex_o),
      .rs2_data_ex_i(rs2_data_idex_o),
      .immi_data_ex_i(immi_data_idex_o),
      .immb_data_ex_i(immb_data_idex_o),
      .immj_data_ex_i(immj_data_idex_o),
      .immu_data_ex_i(immu_data_idex_o),
      .rd_addr_ex_i(rd_addr_idex_o),
      .wr_en_ex_o(wr_en_ex_o),
      .wr_addr_ex_o(wr_addr_ex_o),
      .wr_data_ex_o(wr_data_ex_o),

      .pc_brench_flag_ex_o(pc_brench_flag_ex_o),
      .pc_brench_addr_ex_o(pc_brench_addr_ex_o),

      .clear_valid_ex_o(clear_valid_ex_o)
  );

  regfile regfile_inst (
      .clk(clk),
      .rst_n(rst_n),
      .wr_en_i(wr_en_ex_o),
      .wr_addr_i(wr_addr_ex_o),
      .wr_data_i(wr_data_ex_o),
      .rs1_addr_i(rs1_addr_o),
      .rs2_addr_i(rs2_addr_o),
      .rs1_data_o(rs1_data_o),
      .rs2_data_o(rs2_data_o)
  );
endmodule

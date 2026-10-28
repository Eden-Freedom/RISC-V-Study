`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 11:07:23
// Design Name: 
// Module Name: addi_decode
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


module addi_decode (
    input  wire [31:0] instr_i,
    output wire [31:0] imm_typei_o,
    output wire [31:0] imm_typeu_o,
    output wire [31:0] imm_typeb_o,
    output wire [31:0] imm_typej_o,
    output wire [31:0] imm_types_o,
    output wire [ 4:0] rs1_addr_o,
    output wire [ 4:0] rs2_addr_o,
    output wire [ 4:0] rd_addr_o,
    output reg         is_addi_o,
    output reg         is_xori_o,
    output reg         is_ori_o,
    output reg         is_andi_o,
    output reg         is_add_o,
    output reg         is_sub_o,
    output reg         is_xor_o,
    output reg         is_or_o,
    output reg         is_and_o,
    output reg         is_sll_o,
    output reg         is_srl_o,
    output reg         is_sra_o,
    output reg         is_slli_o,
    output reg         is_srli_o,
    output reg         is_srai_o,
    output reg         is_slt_o,
    output reg         is_sltu_o,
    output reg         is_slti_o,
    output reg         is_sltiu_o,
    output reg         is_lui_o,
    output reg         is_auipc_o,
    output reg         is_beq_o,
    output reg         is_bne_o,
    output reg         is_blt_o,
    output reg         is_bge_o,
    output reg         is_bltu_o,
    output reg         is_bgeu_o,
    output reg         is_jal_o,
    output reg         is_jalr_o,
    output reg         is_sw_o,
    output reg         is_lw_o,
    output reg         is_lb_o,
    output reg         is_lbu_o,
    output reg         is_lh_o,
    output reg         is_lhu_o,
    output reg         is_sb_o,
    output reg         is_sh_o,

    output reg         is_mul_o,
    output reg         is_mulh_o,
    output reg         is_mulhsu_o,
    output reg         is_mulhu_o
    
);

  wire [6:0] opcode;
  wire [6:0] funct7;
  wire [2:0] funct3;

  assign opcode     = instr_i[6:0];
  assign funct7     = instr_i[31:25];
  assign funct3     = instr_i[14:12];

  assign imm_typei_o      = {{20{instr_i[31]}}, instr_i[31:20]};
  assign imm_typeu_o      = {instr_i[31:12], 12'b000000000000};//相当于手册上恶左移12位了，执行模块不用在左移
  assign imm_typeb_o      = {{19{instr_i[31]}},instr_i[31],instr_i[7],instr_i[30:25],instr_i[11:8],1'b0};
  assign imm_typej_o      = {{11{instr_i[31]}},instr_i[31],instr_i[19:12],instr_i[20],instr_i[30:21],1'b0};
  assign imm_types_o      = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
  assign rs1_addr_o = instr_i[19:15];
  assign rs2_addr_o = (opcode == 7'b0110011 || opcode == 7'b1100011 || opcode == 7'b0100011) ? instr_i[24:20] : 5'b00000;
  assign rd_addr_o  = instr_i[11:7];


  always @(*) begin
    is_addi_o = 1'b0;
    is_xori_o = 1'b0;
    is_ori_o = 1'b0;
    is_andi_o = 1'b0;
    is_add_o  = 1'b0;
    is_sub_o  = 1'b0;
    is_xor_o  = 1'b0;
    is_or_o   = 1'b0;
    is_and_o  = 1'b0;
    is_sll_o  = 1'b0;
    is_srl_o  = 1'b0;
    is_sra_o  = 1'b0;
    is_slli_o = 1'b0;
    is_srli_o = 1'b0;
    is_srai_o = 1'b0;
    is_slt_o  = 1'b0;
    is_sltu_o = 1'b0;
    is_slti_o = 1'b0;
    is_sltiu_o = 1'b0;
    is_lui_o = 1'b0;
    is_auipc_o = 1'b0;
    is_beq_o = 1'b0;
    is_bne_o = 1'b0;
    is_blt_o = 1'b0;
    is_bge_o = 1'b0;
    is_bltu_o = 1'b0;
    is_bgeu_o = 1'b0;
    is_jal_o = 1'b0;
    is_jalr_o = 1'b0;
    is_sw_o = 1'b0;
    is_lw_o = 1'b0;
    is_lb_o = 1'b0;
    is_lbu_o = 1'b0;
    is_lh_o = 1'b0;
    is_lhu_o = 1'b0;
    is_sb_o = 1'b0;
    is_sh_o = 1'b0;
    is_mul_o = 1'b0;
    is_mulh_o = 1'b0;
    is_mulhsu_o = 1'b0;
    is_mulhu_o = 1'b0;
    case (opcode)
      7'b0110011: begin//R型指令
        if (funct3 == 3'b000 && funct7 == 7'b0000000) begin
          is_add_o = 1'b1;
        end
        else if (funct3 == 3'b000 && funct7 == 7'b0100000) begin
          is_sub_o = 1'b1;
        end
        else if (funct3 == 3'b100 && funct7 == 7'b0000000) begin
          is_xor_o = 1'b1;
        end
        else if (funct3 == 3'b110 && funct7 == 7'b0000000) begin
          is_or_o = 1'b1;
        end
        else if (funct3 == 3'b111 && funct7 == 7'b0000000) begin
          is_and_o = 1'b1;
        end
        else if (funct3 == 3'b001 && funct7 == 7'b0000000) begin
          is_sll_o = 1'b1;
        end
        else if (funct3 == 3'b101 && funct7 == 7'b0000000) begin
          is_srl_o = 1'b1;
        end
        else if (funct3 == 3'b101 && funct7 == 7'b0100000) begin
          is_sra_o = 1'b1;
        end
        else if (funct3 == 3'b010 && funct7 == 7'b0000000) begin
          is_slt_o = 1'b1;
        end
        else if (funct3 == 3'b011 && funct7 == 7'b0000000) begin
          is_sltu_o = 1'b1;
        end
        else if (funct3 == 3'b000 && funct7 == 7'b0000001) begin
          is_mul_o = 1'b1;
        end
        else if (funct3 == 3'b001 && funct7 == 7'b0000001) begin
          is_mulh_o = 1'b1;
        end
        else if (funct3 == 3'b010 && funct7 == 7'b0000001) begin
          is_mulhsu_o = 1'b1;
        end
        else if (funct3 == 3'b011 && funct7 == 7'b0000001) begin
          is_mulhu_o = 1'b1;
        end
      end
      7'b0010011: begin//I型指令
        if (funct3 == 3'b000) begin
          is_addi_o = 1'b1;
        end
        else if (funct3 == 3'b100) begin
          is_xori_o = 1'b1;
        end
        else if (funct3 == 3'b110) begin
          is_ori_o = 1'b1;
        end
        else if (funct3 == 3'b111) begin
          is_andi_o = 1'b1;
        end
        else if (funct3 == 3'b001 && funct7 == 7'b0000000) begin
          is_slli_o = 1'b1;
        end
        else if (funct3 == 3'b101 && funct7 == 7'b0000000) begin
          is_srli_o = 1'b1;
        end
        else if (funct3 == 3'b101 && funct7 == 7'b0100000) begin
          is_srai_o = 1'b1;
        end
        else if (funct3 == 3'b010) begin
          is_slti_o = 1'b1;
        end
        else if (funct3 == 3'b011) begin
          is_sltiu_o = 1'b1;
        end

      end
      7'b0110111: begin//U型指令
        is_lui_o = 1'b1;
      end
      7'b0010111: begin//U型指令
        is_auipc_o = 1'b1;
      end
      7'b1100011:begin//B型指令
        if (funct3 == 3'b000) begin
          is_beq_o = 1'b1;
        end
        else if (funct3 == 3'b001) begin
          is_bne_o = 1'b1;
        end
        else if(funct3 == 3'b100) begin
          is_blt_o = 1'b1;
        end
        else if(funct3 == 3'b101) begin
          is_bge_o = 1'b1;
        end
        else if(funct3 == 3'b110) begin
          is_bltu_o = 1'b1;
        end
        else if(funct3 == 3'b111) begin
          is_bgeu_o = 1'b1;
        end
      end
      7'b1101111: begin//J型指令
        is_jal_o = 1'b1;
      end
      7'b1100111: begin//I型指令
        if(funct3 == 3'b000) begin
        is_jalr_o = 1'b1;
        end
      end
      7'b0100011:begin//S型指令
        if(funct3 == 3'b010)begin
          is_sw_o = 1'b1;
        end
        else if(funct3 == 3'b000)begin
          is_sb_o = 1'b1;
        end
        else if(funct3 == 3'b001)begin
          is_sh_o = 1'b1;
        end
      end
      7'b0000011:begin//I型指令数据加载
        if(funct3 == 3'b010)begin
          is_lw_o = 1'b1;
        end
        else if(funct3 == 3'b000)begin
          is_lb_o = 1'b1;
        end
        else if(funct3 == 3'b100)begin
          is_lbu_o = 1'b1;
        end
        else if(funct3 == 3'b001)begin
          is_lh_o = 1'b1;
        end
        else if(funct3 == 3'b101)begin
          is_lhu_o = 1'b1;
        end
      end
      default: begin
        is_addi_o = 1'b0;
        is_xori_o = 1'b0;
        is_ori_o = 1'b0;
        is_andi_o = 1'b0;
        is_add_o  = 1'b0;
        is_sub_o  = 1'b0;
        is_xor_o  = 1'b0;
        is_or_o   = 1'b0;
        is_and_o  = 1'b0;
        is_sll_o  = 1'b0;
        is_srl_o  = 1'b0;
        is_sra_o  = 1'b0;
        is_slli_o = 1'b0;
        is_srli_o = 1'b0;
        is_srai_o = 1'b0;
        is_slt_o  = 1'b0;
        is_sltu_o = 1'b0;
        is_slti_o = 1'b0;
        is_sltiu_o = 1'b0;
        is_lui_o = 1'b0;
        is_auipc_o = 1'b0;
        is_beq_o = 1'b0;
        is_bne_o = 1'b0;
        is_blt_o = 1'b0;
        is_bge_o = 1'b0;
        is_bltu_o = 1'b0;
        is_bgeu_o = 1'b0;
        is_jal_o = 1'b0;
        is_jalr_o = 1'b0;
        is_sw_o = 1'b0;
        is_lw_o = 1'b0;
        is_lb_o = 1'b0;
        is_lbu_o = 1'b0;
        is_lh_o = 1'b0;
        is_lhu_o = 1'b0;
        is_sb_o = 1'b0;
        is_sh_o = 1'b0;
        is_mul_o = 1'b0;
        is_mulh_o = 1'b0;
        is_mulhsu_o = 1'b0;
        is_mulhu_o = 1'b0;
      end
    endcase
  end
endmodule

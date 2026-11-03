`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 19:54:47
// Design Name: 
// Module Name: ex
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


module ex (

    input wire clk,
    input wire rst_n,
    input wire valid_ex_i,

    input wire is_addi_ex_i,
    input wire is_xori_ex_i,
    input wire is_ori_ex_i,
    input wire is_andi_ex_i,
    input wire is_slli_ex_i,
    input wire is_srli_ex_i,
    input wire is_srai_ex_i,
    input wire is_slti_ex_i,
    input wire is_sltiu_ex_i,

    input wire is_add_ex_i,
    input wire is_sub_ex_i,
    input wire is_xor_ex_i,
    input wire is_or_ex_i,
    input wire is_and_ex_i,
    input wire is_sll_ex_i,
    input wire is_srl_ex_i,
    input wire is_sra_ex_i,
    input wire is_slt_ex_i,
    input wire is_sltu_ex_i,

    input wire is_beq_ex_i,
    input wire is_bne_ex_i,
    input wire is_blt_ex_i,
    input wire is_bge_ex_i,
    input wire is_bltu_ex_i,
    input wire is_bgeu_ex_i,

    input wire is_jal_ex_i,
    input wire is_jalr_ex_i,

    input wire is_lui_ex_i,
    input wire is_auipc_ex_i,

    input wire is_sw_ex_i,
    input wire is_sb_ex_i,
    input wire is_sh_ex_i,

    input wire is_lw_ex_i,
    input wire is_lb_ex_i,
    input wire is_lbu_ex_i,
    input wire is_lh_ex_i,
    input wire is_lhu_ex_i,

    input wire is_mul_ex_i,
    input wire is_mulh_ex_i,
    input wire is_mulhsu_ex_i,
    input wire is_mulhu_ex_i,

    input wire is_div_ex_i,
    input wire is_divu_ex_i,
    input wire is_rem_ex_i,
    input wire is_remu_ex_i,

    input wire is_csrrw_ex_i,
    input wire is_csrrs_ex_i,
    input wire is_csrrc_ex_i,
    input wire is_csrrwi_ex_i,
    input wire is_csrrsi_ex_i,
    input wire is_csrrci_ex_i,

    input wire is_ecall_ex_i,
    input wire is_mret_ex_i,

    input wire is_illegal_ex_i,

    input wire irq_external_ex_i,

    input wire [31:0] pc_ex_i,
    input wire [31:0] rs1_data_ex_i,
    input wire [31:0] rs2_data_ex_i,
    input wire [31:0] immi_data_ex_i,
    input wire [31:0] immb_data_ex_i,
    input wire [31:0] immj_data_ex_i,
    input wire [31:0] immu_data_ex_i,
    input wire [31:0] imms_data_ex_i,
    input wire [31:0] imm_csr_ex_i,
    input wire [11:0] csr_addr_ex_i,
    input wire [ 4:0] rd_addr_ex_i,

    output reg        wr_en_ex_o,
    output reg [ 4:0] wr_addr_ex_o,
    output reg [31:0] wr_data_ex_o,

    output reg        pc_brench_flag_ex_o,
    output reg [31:0] pc_brench_addr_ex_o,
    output reg        clear_valid_ex_o,

    output reg        ram_wr_en_ex_o,
    output reg [31:0] ram_wr_addr_ex_o,
    output reg [31:0] ram_wr_data_ex_o,
    output reg [ 3:0] ram_wr_sel_ex_o,

    output reg         ram_rd_en_ex_o,
    output reg  [31:0] ram_rd_addr_ex_o,
    input  wire [31:0] ram_rd_data_ex_i,

    output reg stall_ex_o

);

  wire signed [32:0] mul_a;
  wire signed [32:0] mul_b;
  wire signed [65:0] mul_result;

  reg                signed_ex_o;
  reg         [31:0] dividend_ex_o;
  reg         [31:0] divisor_ex_o;
  reg                start_ex_o;
  wire               busy_div_o;
  wire               done_div_o;
  wire        [31:0] quotient_div_o;
  wire        [31:0] remainder_div_o;


  reg         [ 2:0] csr_type_ex_o;
  reg                csr_wr_en_ex_o;
  reg         [11:0] csr_wr_addr_ex_o;
  reg         [31:0] csr_wr_data_ex_o;
  reg                csr_rd_en_ex_o;
  reg         [11:0] csr_rd_addr_ex_o;
  wire        [31:0] csr_rdata_csr_o;

  reg                trap_enter_ex_o;
  reg         [31:0] trap_cause_ex_o;
  reg         [31:0] trap_pc_ex_o;
  wire        [31:0] csr_mtvec_o;

  reg                trap_return_ex_o;
  wire        [31:0] csr_mepc_o;

  reg                boundary_valid_reg;//当前是否处于可接收中断的指令边界
  reg         [31:0] resume_pc_reg;//	若在这里接收，返回后应执行的地址
  wire               irq_eligible_csr_o;
  wire irq_take;

  assign irq_take = boundary_valid_reg & irq_eligible_csr_o;


  //有符号乘法或者无符号乘法
  assign mul_a = (is_mulh_ex_i | is_mulhsu_ex_i)?{rs1_data_ex_i[31], rs1_data_ex_i} : {1'b0, rs1_data_ex_i};
  assign mul_b = (is_mulh_ex_i) ? {rs2_data_ex_i[31], rs2_data_ex_i} : {1'b0, rs2_data_ex_i};
  assign mul_result = mul_a * mul_b;

  always @(*) begin
    wr_en_ex_o          = 1'b0;
    wr_addr_ex_o        = 5'h0;
    wr_data_ex_o        = 32'h0;

    pc_brench_flag_ex_o = 1'b0;
    pc_brench_addr_ex_o = 32'h0;
    clear_valid_ex_o    = 1'b0;

    ram_wr_en_ex_o      = 1'b0;
    ram_wr_addr_ex_o    = 32'h0;
    ram_wr_data_ex_o    = 32'h0;
    ram_wr_sel_ex_o     = 4'b0000;

    ram_rd_en_ex_o      = 1'b0;
    ram_rd_addr_ex_o    = 32'h0;

    stall_ex_o          = 1'b0;
    start_ex_o          = 1'b0;
    signed_ex_o         = 1'b0;
    dividend_ex_o       = 32'h0;
    divisor_ex_o        = 32'h0;

    csr_type_ex_o       = 3'b000;
    csr_wr_en_ex_o      = 1'b0;
    csr_wr_addr_ex_o    = 12'h0;
    csr_wr_data_ex_o    = 32'h0;
    csr_rd_en_ex_o      = 1'b0;
    csr_rd_addr_ex_o    = 12'h0;

    trap_enter_ex_o     = 1'b0;
    trap_cause_ex_o     = 32'h0;
    trap_pc_ex_o        = 32'h0;
    trap_return_ex_o    = 1'b0;


    if(irq_take)begin
      trap_enter_ex_o = 1'b1;
      trap_cause_ex_o = 32'h8000_000B;
      trap_pc_ex_o = resume_pc_reg;

      pc_brench_flag_ex_o = 1'b1;
      pc_brench_addr_ex_o = csr_mtvec_o;
      clear_valid_ex_o = 1'b1;
    end
    else if (valid_ex_i) begin
      if (is_addi_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i + immi_data_ex_i;
      end
      else if (is_xori_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i ^ immi_data_ex_i;
      end
      else if (is_ori_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i | immi_data_ex_i;
      end
      else if (is_andi_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i & immi_data_ex_i;
      end
      else if (is_slli_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i << immi_data_ex_i[4:0];
      end
      else if (is_srli_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i >> immi_data_ex_i[4:0];
      end
      else if (is_srai_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = $signed(rs1_data_ex_i) >>> immi_data_ex_i[4:0];
      end
      else if (is_slti_ex_i) begin
        wr_en_ex_o = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = $signed(rs1_data_ex_i) < $signed(immi_data_ex_i) ? 32'h0000_0001 :
            32'h0000_0000;
      end
      else if (is_sltiu_ex_i) begin
        wr_en_ex_o = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = $unsigned(rs1_data_ex_i) < $unsigned(immi_data_ex_i) ? 32'h0000_0001 :
            32'h0000_0000;
      end


      else if (is_add_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i + rs2_data_ex_i;
      end
      else if (is_sub_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i - rs2_data_ex_i;
      end
      else if (is_xor_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i ^ rs2_data_ex_i;
      end
      else if (is_or_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i | rs2_data_ex_i;
      end
      else if (is_and_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i & rs2_data_ex_i;
      end
      else if (is_sll_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i << rs2_data_ex_i[4:0];
      end
      else if (is_srl_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = rs1_data_ex_i >> rs2_data_ex_i[4:0];
      end
      else if (is_sra_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = $signed(rs1_data_ex_i) >>> rs2_data_ex_i[4:0];
      end
      else if (is_slt_ex_i) begin
        wr_en_ex_o = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = $signed(rs1_data_ex_i) < $signed(rs2_data_ex_i) ? 32'h0000_0001 :
            32'h0000_0000;
      end
      else if (is_sltu_ex_i) begin
        wr_en_ex_o = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = $unsigned(rs1_data_ex_i) < $unsigned(rs2_data_ex_i) ? 32'h0000_0001 :
            32'h0000_0000;
      end


      else if (is_beq_ex_i) begin
        if (rs1_data_ex_i == rs2_data_ex_i) begin
          pc_brench_flag_ex_o = 1'b1;
          pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
          clear_valid_ex_o    = 1'b1;
        end
        else begin
          pc_brench_flag_ex_o = 1'b0;
          pc_brench_addr_ex_o = 32'h0;
          clear_valid_ex_o    = 1'b0;
        end
      end
      else if (is_bne_ex_i) begin
        if (rs1_data_ex_i != rs2_data_ex_i) begin
          pc_brench_flag_ex_o = 1'b1;
          pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
          clear_valid_ex_o    = 1'b1;
        end
        else begin
          pc_brench_flag_ex_o = 1'b0;
          pc_brench_addr_ex_o = 32'h0;
          clear_valid_ex_o    = 1'b0;
        end
      end
      else if (is_blt_ex_i) begin
        if ($signed(rs1_data_ex_i) < $signed(rs2_data_ex_i)) begin
          pc_brench_flag_ex_o = 1'b1;
          pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
          clear_valid_ex_o    = 1'b1;
        end
        else begin
          pc_brench_flag_ex_o = 1'b0;
          pc_brench_addr_ex_o = 32'h0;
          clear_valid_ex_o    = 1'b0;
        end
      end
      else if (is_bge_ex_i) begin
        if ($signed(rs1_data_ex_i) >= $signed(rs2_data_ex_i)) begin
          pc_brench_flag_ex_o = 1'b1;
          pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
          clear_valid_ex_o    = 1'b1;
        end
        else begin
          pc_brench_flag_ex_o = 1'b0;
          pc_brench_addr_ex_o = 32'h0;
          clear_valid_ex_o    = 1'b0;
        end
      end
      else if (is_bltu_ex_i) begin
        if ($unsigned(rs1_data_ex_i) < $unsigned(rs2_data_ex_i)) begin
          pc_brench_flag_ex_o = 1'b1;
          pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
          clear_valid_ex_o    = 1'b1;
        end
        else begin
          pc_brench_flag_ex_o = 1'b0;
          pc_brench_addr_ex_o = 32'h0;
          clear_valid_ex_o    = 1'b0;
        end
      end
      else if (is_bgeu_ex_i) begin
        if ($unsigned(rs1_data_ex_i) >= $unsigned(rs2_data_ex_i)) begin
          pc_brench_flag_ex_o = 1'b1;
          pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
          clear_valid_ex_o    = 1'b1;
        end
        else begin
          pc_brench_flag_ex_o = 1'b0;
          pc_brench_addr_ex_o = 32'h0;
          clear_valid_ex_o    = 1'b0;
        end
      end


      else if (is_jal_ex_i) begin
        wr_en_ex_o          = 1'b1;
        wr_addr_ex_o        = rd_addr_ex_i;
        wr_data_ex_o        = pc_ex_i + 32'h00000004;
        pc_brench_flag_ex_o = 1'b1;
        pc_brench_addr_ex_o = pc_ex_i + immj_data_ex_i;
        clear_valid_ex_o    = 1'b1;
      end
      else if (is_jalr_ex_i) begin
        wr_en_ex_o          = 1'b1;
        wr_addr_ex_o        = rd_addr_ex_i;
        wr_data_ex_o        = pc_ex_i + 32'h00000004;
        pc_brench_flag_ex_o = 1'b1;
        pc_brench_addr_ex_o = (rs1_data_ex_i + immi_data_ex_i) & 32'hFFFFFFFE;
        clear_valid_ex_o    = 1'b1;
      end

      else if (is_lui_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = immu_data_ex_i;
      end
      else if (is_auipc_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = pc_ex_i + immu_data_ex_i;
      end


      else if (is_sw_ex_i) begin
        ram_wr_en_ex_o   = 1'b1;
        ram_wr_addr_ex_o = rs1_data_ex_i + imms_data_ex_i;
        ram_wr_data_ex_o = rs2_data_ex_i;
        ram_wr_sel_ex_o  = 4'b1111;
      end
      else if (is_sb_ex_i) begin
        ram_wr_en_ex_o   = 1'b1;
        ram_wr_addr_ex_o = rs1_data_ex_i + imms_data_ex_i;
        case (ram_wr_addr_ex_o[1:0])
          2'b00: begin
            ram_wr_sel_ex_o       = 4'b0001;
            ram_wr_data_ex_o[7:0] = rs2_data_ex_i[7:0];
          end
          2'b01: begin
            ram_wr_sel_ex_o        = 4'b0010;
            ram_wr_data_ex_o[15:8] = rs2_data_ex_i[7:0];
          end
          2'b10: begin
            ram_wr_sel_ex_o         = 4'b0100;
            ram_wr_data_ex_o[23:16] = rs2_data_ex_i[7:0];
          end
          2'b11: begin
            ram_wr_sel_ex_o         = 4'b1000;
            ram_wr_data_ex_o[31:24] = rs2_data_ex_i[7:0];
          end
        endcase
      end
      else if (is_sh_ex_i) begin
        ram_wr_en_ex_o   = 1'b1;
        ram_wr_addr_ex_o = rs1_data_ex_i + imms_data_ex_i;
        case (ram_wr_addr_ex_o[1:0])
          2'b00: begin
            ram_wr_sel_ex_o        = 4'b0011;
            ram_wr_data_ex_o[15:0] = rs2_data_ex_i[15:0];
          end
          2'b10: begin
            ram_wr_sel_ex_o         = 4'b1100;
            ram_wr_data_ex_o[31:16] = rs2_data_ex_i[15:0];
          end
          default: begin
            ram_wr_sel_ex_o  = 4'b0000;
            ram_wr_data_ex_o = 32'h0;
          end
        endcase
      end
      else if (is_lw_ex_i) begin
        ram_rd_en_ex_o   = 1'b1;
        ram_rd_addr_ex_o = rs1_data_ex_i + immi_data_ex_i;
        wr_en_ex_o       = 1'b1;
        wr_addr_ex_o     = rd_addr_ex_i;
        wr_data_ex_o     = ram_rd_data_ex_i;
      end
      else if (is_lb_ex_i) begin
        ram_rd_en_ex_o   = 1'b1;
        ram_rd_addr_ex_o = rs1_data_ex_i + immi_data_ex_i;
        wr_en_ex_o       = 1'b1;
        wr_addr_ex_o     = rd_addr_ex_i;
        case (ram_rd_addr_ex_o[1:0])
          2'b00: begin
            wr_data_ex_o = {{24{ram_rd_data_ex_i[7]}}, ram_rd_data_ex_i[7:0]};
          end
          2'b01: begin
            wr_data_ex_o = {{24{ram_rd_data_ex_i[15]}}, ram_rd_data_ex_i[15:8]};
          end
          2'b10: begin
            wr_data_ex_o = {{24{ram_rd_data_ex_i[23]}}, ram_rd_data_ex_i[23:16]};
          end
          2'b11: begin
            wr_data_ex_o = {{24{ram_rd_data_ex_i[31]}}, ram_rd_data_ex_i[31:24]};
          end
        endcase
      end
      else if (is_lbu_ex_i) begin
        ram_rd_en_ex_o   = 1'b1;
        ram_rd_addr_ex_o = rs1_data_ex_i + immi_data_ex_i;
        wr_en_ex_o       = 1'b1;
        wr_addr_ex_o     = rd_addr_ex_i;
        case (ram_rd_addr_ex_o[1:0])
          2'b00: begin
            wr_data_ex_o = {24'h0, ram_rd_data_ex_i[7:0]};
          end
          2'b01: begin
            wr_data_ex_o = {24'h0, ram_rd_data_ex_i[15:8]};
          end
          2'b10: begin
            wr_data_ex_o = {24'h0, ram_rd_data_ex_i[23:16]};
          end
          2'b11: begin
            wr_data_ex_o = {24'h0, ram_rd_data_ex_i[31:24]};
          end
        endcase
      end
      else if (is_lh_ex_i) begin
        ram_rd_en_ex_o   = 1'b1;
        ram_rd_addr_ex_o = rs1_data_ex_i + immi_data_ex_i;
        wr_en_ex_o       = 1'b1;
        wr_addr_ex_o     = rd_addr_ex_i;
        case (ram_rd_addr_ex_o[1:0])
          2'b00: begin
            wr_data_ex_o = {{16{ram_rd_data_ex_i[15]}}, ram_rd_data_ex_i[15:0]};
          end
          2'b10: begin
            wr_data_ex_o = {{16{ram_rd_data_ex_i[31]}}, ram_rd_data_ex_i[31:16]};
          end
          default: begin
            wr_data_ex_o = 32'h0;
          end
        endcase
      end
      else if (is_lhu_ex_i) begin
        ram_rd_en_ex_o   = 1'b1;
        ram_rd_addr_ex_o = rs1_data_ex_i + immi_data_ex_i;
        wr_en_ex_o       = 1'b1;
        wr_addr_ex_o     = rd_addr_ex_i;
        case (ram_rd_addr_ex_o[1:0])
          2'b00: begin
            wr_data_ex_o = {16'h0, ram_rd_data_ex_i[15:0]};
          end
          2'b10: begin
            wr_data_ex_o = {16'h0, ram_rd_data_ex_i[31:16]};
          end
          default: begin
            wr_data_ex_o = 32'h0;
          end
        endcase
      end

      else if (is_mul_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = mul_result[31:0];
      end
      else if (is_mulh_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = mul_result[63:32];
      end
      else if (is_mulhsu_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = mul_result[63:32];
      end
      else if (is_mulhu_ex_i) begin
        wr_en_ex_o   = 1'b1;
        wr_addr_ex_o = rd_addr_ex_i;
        wr_data_ex_o = mul_result[63:32];
      end


      else if (is_div_ex_i) begin

        signed_ex_o   = is_div_ex_i;
        dividend_ex_o = rs1_data_ex_i;
        divisor_ex_o  = rs2_data_ex_i;

        if (!busy_div_o && !done_div_o) begin
          start_ex_o = 1'b1;
        end
        else begin
          start_ex_o = 1'b0;
        end


        if (!done_div_o) begin
          stall_ex_o = 1'b1;
        end
        else begin
          stall_ex_o = 1'b0;
        end

        if (done_div_o) begin
          wr_en_ex_o   = 1'b1;
          wr_addr_ex_o = rd_addr_ex_i;
          wr_data_ex_o = quotient_div_o;
        end
        else begin
          wr_en_ex_o   = 1'b0;
          wr_addr_ex_o = 5'h0;
          wr_data_ex_o = 32'h0;
        end
      end
      else if (is_divu_ex_i) begin
        signed_ex_o   = 1'b0;
        dividend_ex_o = rs1_data_ex_i;
        divisor_ex_o  = rs2_data_ex_i;
        if (!busy_div_o && !done_div_o) begin
          start_ex_o = 1'b1;
        end
        else begin
          start_ex_o = 1'b0;
        end
        if (!done_div_o) begin
          stall_ex_o = 1'b1;
        end
        else begin
          stall_ex_o = 1'b0;
        end
        if (done_div_o) begin
          wr_en_ex_o   = 1'b1;
          wr_addr_ex_o = rd_addr_ex_i;
          wr_data_ex_o = quotient_div_o;
        end
        else begin
          wr_en_ex_o   = 1'b0;
          wr_addr_ex_o = 5'h0;
          wr_data_ex_o = 32'h0;
        end
      end
      else if (is_rem_ex_i) begin
        signed_ex_o   = 1'b1;
        dividend_ex_o = rs1_data_ex_i;
        divisor_ex_o  = rs2_data_ex_i;
        if (!busy_div_o && !done_div_o) begin
          start_ex_o = 1'b1;
        end
        else begin
          start_ex_o = 1'b0;
        end
        if (!done_div_o) begin
          stall_ex_o = 1'b1;
        end
        else begin
          stall_ex_o = 1'b0;
        end
        if (done_div_o) begin
          wr_en_ex_o   = 1'b1;
          wr_addr_ex_o = rd_addr_ex_i;
          wr_data_ex_o = remainder_div_o;
        end
        else begin
          wr_en_ex_o   = 1'b0;
          wr_addr_ex_o = 5'h0;
          wr_data_ex_o = 32'h0;
        end
      end
      else if (is_remu_ex_i) begin
        signed_ex_o   = 1'b0;
        dividend_ex_o = rs1_data_ex_i;
        divisor_ex_o  = rs2_data_ex_i;
        if (!busy_div_o && !done_div_o) begin
          start_ex_o = 1'b1;
        end
        else begin
          start_ex_o = 1'b0;
        end
        if (!done_div_o) begin
          stall_ex_o = 1'b1;
        end
        else begin
          stall_ex_o = 1'b0;
        end
        if (done_div_o) begin
          wr_en_ex_o   = 1'b1;
          wr_addr_ex_o = rd_addr_ex_i;
          wr_data_ex_o = remainder_div_o;
        end
        else begin
          wr_en_ex_o   = 1'b0;
          wr_addr_ex_o = 5'h0;
          wr_data_ex_o = 32'h0;
        end
      end

      else if (is_csrrw_ex_i) begin
        csr_type_ex_o    = 3'b001;
        csr_wr_en_ex_o   = 1'b1;
        csr_wr_addr_ex_o = csr_addr_ex_i;
        csr_wr_data_ex_o = rs1_data_ex_i;
        if (rd_addr_ex_i != 5'h0) begin
          csr_rd_en_ex_o   = 1'b1;
          csr_rd_addr_ex_o = csr_addr_ex_i;
          wr_en_ex_o       = 1'b1;
          wr_addr_ex_o     = rd_addr_ex_i;
          wr_data_ex_o     = csr_rdata_csr_o;
        end
        else begin
          csr_rd_en_ex_o   = 1'b0;
          csr_rd_addr_ex_o = 12'h0;
          wr_en_ex_o       = 1'b0;
          wr_addr_ex_o     = 5'h0;
          wr_data_ex_o     = 32'h0;
        end
      end
      else if (is_csrrs_ex_i) begin
        csr_type_ex_o = 3'b010;
        if (imm_csr_ex_i != 32'h0) begin
          csr_wr_en_ex_o   = 1'b1;
          csr_wr_addr_ex_o = csr_addr_ex_i;
          csr_wr_data_ex_o = rs1_data_ex_i;
        end
        else begin
          csr_wr_en_ex_o   = 1'b0;
          csr_wr_addr_ex_o = 12'h0;
          csr_wr_data_ex_o = 32'h0;
        end
        csr_rd_en_ex_o   = 1'b1;
        csr_rd_addr_ex_o = csr_addr_ex_i;
        wr_en_ex_o       = 1'b1;
        wr_addr_ex_o     = rd_addr_ex_i;
        wr_data_ex_o     = csr_rdata_csr_o;
      end
      else if (is_csrrc_ex_i) begin
        csr_type_ex_o = 3'b011;
        if (imm_csr_ex_i != 32'h0) begin
          csr_wr_en_ex_o   = 1'b1;
          csr_wr_addr_ex_o = csr_addr_ex_i;
          csr_wr_data_ex_o = rs1_data_ex_i;
        end
        else begin
          csr_wr_en_ex_o   = 1'b0;
          csr_wr_addr_ex_o = 12'h0;
          csr_wr_data_ex_o = 32'h0;
        end
        csr_rd_en_ex_o   = 1'b1;
        csr_rd_addr_ex_o = csr_addr_ex_i;
        wr_en_ex_o       = 1'b1;
        wr_addr_ex_o     = rd_addr_ex_i;
        wr_data_ex_o     = csr_rdata_csr_o;
      end
      else if (is_csrrwi_ex_i) begin
        csr_type_ex_o    = 3'b101;
        csr_wr_en_ex_o   = 1'b1;
        csr_wr_addr_ex_o = csr_addr_ex_i;
        csr_wr_data_ex_o = imm_csr_ex_i;
        if (rd_addr_ex_i != 5'h0) begin
          csr_rd_en_ex_o   = 1'b1;
          csr_rd_addr_ex_o = csr_addr_ex_i;
          wr_en_ex_o       = 1'b1;
          wr_addr_ex_o     = rd_addr_ex_i;
          wr_data_ex_o     = csr_rdata_csr_o;
        end
        else begin
          csr_rd_en_ex_o   = 1'b0;
          csr_rd_addr_ex_o = 12'h0;
          wr_en_ex_o       = 1'b0;
          wr_addr_ex_o     = 5'h0;
          wr_data_ex_o     = 32'h0;
        end
      end
      else if (is_csrrsi_ex_i) begin
        csr_type_ex_o = 3'b110;
        if (imm_csr_ex_i != 32'h0) begin
          csr_wr_en_ex_o   = 1'b1;
          csr_wr_addr_ex_o = csr_addr_ex_i;
          csr_wr_data_ex_o = imm_csr_ex_i;
        end
        else begin
          csr_wr_en_ex_o   = 1'b0;
          csr_wr_addr_ex_o = 12'h0;
          csr_wr_data_ex_o = 32'h0;
        end
        csr_rd_en_ex_o   = 1'b1;
        csr_rd_addr_ex_o = csr_addr_ex_i;
        wr_en_ex_o       = 1'b1;
        wr_addr_ex_o     = rd_addr_ex_i;
        wr_data_ex_o     = csr_rdata_csr_o;
      end
      else if (is_csrrci_ex_i) begin
        csr_type_ex_o = 3'b111;
        if (imm_csr_ex_i != 32'h0) begin
          csr_wr_en_ex_o   = 1'b1;
          csr_wr_addr_ex_o = csr_addr_ex_i;
          csr_wr_data_ex_o = imm_csr_ex_i;
        end
        else begin
          csr_wr_en_ex_o   = 1'b0;
          csr_wr_addr_ex_o = 12'h0;
          csr_wr_data_ex_o = 32'h0;
        end
        csr_rd_en_ex_o   = 1'b1;
        csr_rd_addr_ex_o = csr_addr_ex_i;
        wr_en_ex_o       = 1'b1;
        wr_addr_ex_o     = rd_addr_ex_i;
        wr_data_ex_o     = csr_rdata_csr_o;
      end
      else if (is_ecall_ex_i) begin
        trap_enter_ex_o     = 1'b1;
        trap_cause_ex_o     = 32'd11;
        trap_pc_ex_o        = pc_ex_i;

        pc_brench_flag_ex_o = 1'b1;
        pc_brench_addr_ex_o = csr_mtvec_o;
        clear_valid_ex_o    = 1'b1;
      end
      else if (is_mret_ex_i) begin
        trap_return_ex_o    = 1'b1;

        pc_brench_flag_ex_o = 1'b1;
        pc_brench_addr_ex_o = csr_mepc_o;
        clear_valid_ex_o    = 1'b1;
      end

      else if (is_illegal_ex_i) begin
        trap_enter_ex_o     = 1'b1;
        trap_cause_ex_o     = 32'd2;
        trap_pc_ex_o        = pc_ex_i;

        pc_brench_flag_ex_o = 1'b1;
        pc_brench_addr_ex_o = csr_mtvec_o;
        clear_valid_ex_o    = 1'b1;
      end
    end
    else begin
      wr_en_ex_o          = 1'b0;
      wr_addr_ex_o        = 5'h0;
      wr_data_ex_o        = 32'h0;

      pc_brench_flag_ex_o = 1'b0;
      pc_brench_addr_ex_o = 32'h0;
      clear_valid_ex_o    = 1'b0;

      ram_wr_en_ex_o      = 1'b0;
      ram_wr_addr_ex_o    = 32'h0;
      ram_wr_data_ex_o    = 32'h0;
      ram_wr_sel_ex_o     = 4'b0000;

      ram_rd_en_ex_o      = 1'b0;
      ram_rd_addr_ex_o    = 32'h0;

      stall_ex_o          = 1'b0;
      start_ex_o          = 1'b0;
      signed_ex_o         = 1'b0;
      dividend_ex_o       = 32'h0;
      divisor_ex_o        = 32'h0;

      csr_type_ex_o       = 3'b000;
      csr_wr_en_ex_o      = 1'b0;
      csr_wr_addr_ex_o    = 12'h0;
      csr_wr_data_ex_o    = 32'h0;
      csr_rd_en_ex_o      = 1'b0;
      csr_rd_addr_ex_o    = 12'h0;

      trap_enter_ex_o     = 1'b0;
      trap_cause_ex_o     = 32'h0;
      trap_pc_ex_o        = 32'h0;
      trap_return_ex_o    = 1'b0;
    end
  end

//真实指令完成，就记录新的继续位置；
//真实指令还没完成，就暂时禁用边界；
//没有真实指令，就保留已有位置；
//真正进入处理程序，就撤销已经使用过的边界
  always@(posedge clk)begin
    if(!rst_n)begin
      boundary_valid_reg <= 1'b0;
      resume_pc_reg <= 32'h0;
    end
    else if(trap_enter_ex_o)begin
      boundary_valid_reg <= 1'b0;
      resume_pc_reg <= resume_pc_reg;
    end
    else if(valid_ex_i && !stall_ex_o)begin
      boundary_valid_reg <= 1'b1;
      resume_pc_reg <= pc_brench_flag_ex_o
                       ?pc_brench_addr_ex_o
                       :pc_ex_i + 32'd4;
    end
    else if(valid_ex_i && stall_ex_o)begin
      boundary_valid_reg <= 1'b0;
      resume_pc_reg <= resume_pc_reg;
    end
    else if(!valid_ex_i)begin
      boundary_valid_reg <= boundary_valid_reg;
      resume_pc_reg <= resume_pc_reg;
    end
  end

  div_rem_unit div_rem_unit_inst (
      .clk(clk),
      .rst_n(rst_n),
      .start_i(start_ex_o),
      .signed_i(signed_ex_o),
      .dividend_i(dividend_ex_o),
      .divisor_i(divisor_ex_o),
      .quotient_o(quotient_div_o),
      .remainder_o(remainder_div_o),
      .busy_o(busy_div_o),
      .done_o(done_div_o)
  );


  csr_unit csr_unit_inst (
      .clk(clk),
      .rst_n(rst_n),
      .trap_enter_i(trap_enter_ex_o),
      .trap_cause_i(trap_cause_ex_o),
      .trap_pc_i(trap_pc_ex_o),
      .trap_return_i(trap_return_ex_o),
      .csr_wr_en_i(csr_wr_en_ex_o),
      .csr_rd_en_i(csr_rd_en_ex_o),
      .csr_type_i(csr_type_ex_o),
      .csr_wr_addr_i(csr_wr_addr_ex_o),
      .csr_src_data_i(csr_wr_data_ex_o),
      .csr_rd_addr_i(csr_rd_addr_ex_o),
      .irq_external_i(irq_external_ex_i),
      .csr_rdata_o(csr_rdata_csr_o),
      .mtvec_o(csr_mtvec_o),
      .mepc_o(csr_mepc_o),
      .irq_eligible_o(irq_eligible_csr_o)
  );
endmodule

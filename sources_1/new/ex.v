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

    input wire [31:0] pc_ex_i,
    input wire [31:0] rs1_data_ex_i,
    input wire [31:0] rs2_data_ex_i,
    input wire [31:0] immi_data_ex_i,
    input wire [31:0] immb_data_ex_i,
    input wire [31:0] immj_data_ex_i,
    input wire [31:0] immu_data_ex_i,
    input wire [31:0] imms_data_ex_i,
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
    input  wire [31:0] ram_rd_data_ex_i
);

  wire signed [32:0] mul_a;
  wire signed [32:0] mul_b;
  wire signed [65:0] mul_result;

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

    if (valid_ex_i) begin
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
    end
  end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 11:07:23
// Design Name: 
// Module Name: decode
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
`include "cpu_defs.vh"
`include "cpu_op_defs.vh"
module decode (
    input  wire [31:0] instr_i,
    output wire [31:0] imm_typei_o,
    output wire [31:0] imm_typeu_o,
    output wire [31:0] imm_typeb_o,
    output wire [31:0] imm_typej_o,
    output wire [31:0] imm_types_o,
    output wire [31:0] imm_csr_o,
    output wire [11:0] csr_addr_o,
    output wire [ 4:0] rs1_addr_o,
    output wire [ 4:0] rs2_addr_o,
    output wire [ 4:0] rd_addr_o,


    output reg         [5:0] op_dc_o,

    output wire        is_illegal_o
);

  wire [6:0] opcode;
  wire [6:0] funct7;
  wire [2:0] funct3;

  wire instr_recognized;

  assign instr_recognized = (op_dc_o != `CPU_OP_NONE);

  assign is_illegal_o = ~instr_recognized;

  assign opcode     = instr_i[6:0];
  assign funct7     = instr_i[31:25];
  assign funct3     = instr_i[14:12];

  assign imm_typei_o      = {{20{instr_i[31]}}, instr_i[31:20]};
  assign imm_typeu_o      = {instr_i[31:12], 12'b000000000000};//相当于手册上恶左移12位了，执行模块不用在左移
  assign imm_typeb_o      = {{19{instr_i[31]}},instr_i[31],instr_i[7],instr_i[30:25],instr_i[11:8],1'b0};
  assign imm_typej_o      = {{11{instr_i[31]}},instr_i[31],instr_i[19:12],instr_i[20],instr_i[30:21],1'b0};
  assign imm_types_o      = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
  assign imm_csr_o      =  {27'b0, instr_i[19:15]};
  assign csr_addr_o      = instr_i[31:20];
  assign rs1_addr_o = instr_i[19:15];
  assign rs2_addr_o = (opcode == `INSTR_R_CODE || opcode == `INSTR_B_CODE || opcode == `INSTR_S_CODE) ? instr_i[24:20] : 5'b00000;
  assign rd_addr_o  = instr_i[11:7];


  always @(*) begin
    op_dc_o = `CPU_OP_NONE;
    case (opcode)
      `INSTR_R_CODE: begin//R型指令
          case (funct7)

          //普通寄存器组
          `F7_R_BASE: begin
            case (funct3)
            `F3_R_ADD_SUB: op_dc_o = `CPU_OP_ADD;
            `F3_R_SLL: op_dc_o = `CPU_OP_SLL;
            `F3_R_SLT: op_dc_o = `CPU_OP_SLT;
            `F3_R_SLTU: op_dc_o = `CPU_OP_SLTU;
            `F3_R_XOR: op_dc_o = `CPU_OP_XOR;
            `F3_R_SR: op_dc_o = `CPU_OP_SRL;
            `F3_R_OR: op_dc_o = `CPU_OP_OR;
            `F3_R_AND: op_dc_o = `CPU_OP_AND;
            default: op_dc_o = `CPU_OP_NONE;
            endcase
          end

          //SUB、SRA组
          `F7_R_SUB_SRA: begin
            case (funct3)
            `F3_R_ADD_SUB: op_dc_o = `CPU_OP_SUB;
            `F3_R_SR: op_dc_o = `CPU_OP_SRA;
            default: op_dc_o = `CPU_OP_NONE;
            endcase
          end
          
          //乘除法组
          `F7_R_M: begin
            case (funct3)
            `F3_M_MUL: op_dc_o = `CPU_OP_MUL;
            `F3_M_MULH: op_dc_o = `CPU_OP_MULH;
            `F3_M_MULHSU: op_dc_o = `CPU_OP_MULHSU;
            `F3_M_MULHU: op_dc_o = `CPU_OP_MULHU;
            `F3_M_DIV: op_dc_o = `CPU_OP_DIV;
            `F3_M_DIVU: op_dc_o = `CPU_OP_DIVU;
            `F3_M_REM: op_dc_o = `CPU_OP_REM;
            `F3_M_REMU: op_dc_o = `CPU_OP_REMU;
            default: op_dc_o = `CPU_OP_NONE;
            endcase
          end
          default: op_dc_o = `CPU_OP_NONE;
          endcase
      end
      `INSTR_I_CODE: begin
      case (funct3)
        `F3_I_ADDI:  op_dc_o = `CPU_OP_ADDI;
        `F3_I_SLTI:  op_dc_o = `CPU_OP_SLTI;
        `F3_I_SLTIU: op_dc_o = `CPU_OP_SLTIU;
        `F3_I_XORI:  op_dc_o = `CPU_OP_XORI;
        `F3_I_ORI:   op_dc_o = `CPU_OP_ORI;
        `F3_I_ANDI:  op_dc_o = `CPU_OP_ANDI;

        // SLLI：移位量在 instr[24:20]，高7位必须为零
        `F3_I_SLLI: begin
          case (funct7)
            `F7_I_SHIFT_LOGIC: op_dc_o = `CPU_OP_SLLI;
            default:          op_dc_o = `CPU_OP_NONE;
          endcase
        end

        // 右移指令由高7位区分逻辑右移和算术右移
        `F3_I_SR: begin
          case (funct7)
            `F7_I_SHIFT_LOGIC: op_dc_o = `CPU_OP_SRLI;
            `F7_I_SHIFT_ARITH: op_dc_o = `CPU_OP_SRAI;
            default:          op_dc_o = `CPU_OP_NONE;
          endcase
        end

        default: op_dc_o = `CPU_OP_NONE;
      endcase
    end

    `INSTR_LUI_CODE: begin
      op_dc_o = `CPU_OP_LUI;
    end

    `INSTR_AUIPC_CODE: begin
      op_dc_o = `CPU_OP_AUIPC;
    end

    `INSTR_B_CODE: begin
      case (funct3)
        `F3_B_BEQ:  op_dc_o = `CPU_OP_BEQ;
        `F3_B_BNE:  op_dc_o = `CPU_OP_BNE;
        `F3_B_BLT:  op_dc_o = `CPU_OP_BLT;
        `F3_B_BGE:  op_dc_o = `CPU_OP_BGE;
        `F3_B_BLTU: op_dc_o = `CPU_OP_BLTU;
        `F3_B_BGEU: op_dc_o = `CPU_OP_BGEU;
        default:   op_dc_o = `CPU_OP_NONE;
      endcase
    end

    `INSTR_JAL_CODE: begin
      op_dc_o = `CPU_OP_JAL;
    end

    `INSTR_JALR_CODE: begin
      case (funct3)
        `F3_JALR: op_dc_o = `CPU_OP_JALR;
        default:  op_dc_o = `CPU_OP_NONE;
      endcase
    end

    `INSTR_S_CODE: begin
      case (funct3)
        `F3_S_SB: op_dc_o = `CPU_OP_SB;
        `F3_S_SH: op_dc_o = `CPU_OP_SH;
        `F3_S_SW: op_dc_o = `CPU_OP_SW;
        default:  op_dc_o = `CPU_OP_NONE;
      endcase
    end

    `INSTR_LOAD_CODE: begin
      case (funct3)
        `F3_L_LB:  op_dc_o = `CPU_OP_LB;
        `F3_L_LH:  op_dc_o = `CPU_OP_LH;
        `F3_L_LW:  op_dc_o = `CPU_OP_LW;
        `F3_L_LBU: op_dc_o = `CPU_OP_LBU;
        `F3_L_LHU: op_dc_o = `CPU_OP_LHU;
        default:   op_dc_o = `CPU_OP_NONE;
      endcase
    end

    `INSTR_CSR_CODE: begin
      case (funct3)

        // 这一组按完整32位指令识别，不能只检查 funct3
        `F3_SYS_ENV: begin
          case (instr_i)
            `INSTR_ECALL_WORD: op_dc_o = `CPU_OP_ECALL;
            `INSTR_MRET_WORD:  op_dc_o = `CPU_OP_MRET;
            default:          op_dc_o = `CPU_OP_NONE;
          endcase
        end

        `F3_CSRRW:  op_dc_o = `CPU_OP_CSRRW;
        `F3_CSRRS:  op_dc_o = `CPU_OP_CSRRS;
        `F3_CSRRC:  op_dc_o = `CPU_OP_CSRRC;
        `F3_CSRRWI: op_dc_o = `CPU_OP_CSRRWI;
        `F3_CSRRSI: op_dc_o = `CPU_OP_CSRRSI;
        `F3_CSRRCI: op_dc_o = `CPU_OP_CSRRCI;

        default: op_dc_o = `CPU_OP_NONE;
      endcase
    end

    default: begin
      op_dc_o = `CPU_OP_NONE;
    end
  endcase
end
endmodule

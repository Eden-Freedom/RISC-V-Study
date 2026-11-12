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
  assign rs2_addr_o = (opcode == 7'b0110011 || opcode == 7'b1100011 || opcode == 7'b0100011) ? instr_i[24:20] : 5'b00000;
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
            endcase
          end

          //SUB、SRA组
          `F7_R_SUB_SRA: begin
            case (funct3)
            `F3_R_ADD_SUB: op_dc_o = `CPU_OP_SUB;
            `F3_R_SR: op_dc_o = `CPU_OP_SRA;
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
            endcase
          end

          endcase
      end
      7'b0010011: begin//I型指令
        if (funct3 == 3'b000) begin
          op_dc_o = `CPU_OP_ADDI;
        end
        else if (funct3 == 3'b100) begin
          op_dc_o = `CPU_OP_XORI;
        end
        else if (funct3 == 3'b110) begin
          op_dc_o = `CPU_OP_ORI;
        end
        else if (funct3 == 3'b111) begin
          op_dc_o = `CPU_OP_ANDI;
        end
        else if (funct3 == 3'b001 && funct7 == 7'b0000000) begin
          op_dc_o = `CPU_OP_SLLI;
        end
        else if (funct3 == 3'b101 && funct7 == 7'b0000000) begin
          op_dc_o = `CPU_OP_SRLI;
        end
        else if (funct3 == 3'b101 && funct7 == 7'b0100000) begin
          op_dc_o = `CPU_OP_SRAI;
        end
        else if (funct3 == 3'b010) begin
          op_dc_o = `CPU_OP_SLTI;
        end
        else if (funct3 == 3'b011) begin
          op_dc_o = `CPU_OP_SLTIU;
        end

      end
      7'b0110111: begin//U型指令
        op_dc_o = `CPU_OP_LUI;
      end
      7'b0010111: begin//U型指令
        op_dc_o = `CPU_OP_AUIPC;
      end
      7'b1100011:begin//B型指令
        if (funct3 == 3'b000) begin
          op_dc_o = `CPU_OP_BEQ;
        end
        else if (funct3 == 3'b001) begin
          op_dc_o = `CPU_OP_BNE;
        end
        else if(funct3 == 3'b100) begin
          op_dc_o = `CPU_OP_BLT;
        end
        else if(funct3 == 3'b101) begin
          op_dc_o = `CPU_OP_BGE;
        end
        else if(funct3 == 3'b110) begin
          op_dc_o = `CPU_OP_BLTU;
        end
        else if(funct3 == 3'b111) begin
          op_dc_o = `CPU_OP_BGEU;
        end
      end
      7'b1101111: begin//J型指令
        op_dc_o = `CPU_OP_JAL;
      end
      7'b1100111: begin//I型指令
        if(funct3 == 3'b000) begin
        op_dc_o = `CPU_OP_JALR;
        end
      end
      7'b0100011:begin//S型指令
        if(funct3 == 3'b010)begin
          op_dc_o = `CPU_OP_SW;
        end
        else if(funct3 == 3'b000)begin
          op_dc_o = `CPU_OP_SB;
        end
        else if(funct3 == 3'b001)begin
          op_dc_o = `CPU_OP_SH;
        end
      end
      7'b0000011:begin//I型指令数据加载
        if(funct3 == 3'b010)begin
          op_dc_o = `CPU_OP_LW;
        end
        else if(funct3 == 3'b000)begin
          op_dc_o = `CPU_OP_LB;
        end
        else if(funct3 == 3'b100)begin
          op_dc_o = `CPU_OP_LBU;
        end
        else if(funct3 == 3'b001)begin
          op_dc_o = `CPU_OP_LH;
        end
        else if(funct3 == 3'b101)begin
          op_dc_o = `CPU_OP_LHU;
        end
      end
      7'b1110011:begin//CSR型指令
        if(instr_i == 32'h00000073)begin
          op_dc_o = `CPU_OP_ECALL;
        end
        else if(instr_i == 32'h30200073)begin
          op_dc_o = `CPU_OP_MRET;
        end
        else if(funct3 == 3'b001)begin
          op_dc_o = `CPU_OP_CSRRW;
        end
        else if(funct3 == 3'b010)begin
          op_dc_o = `CPU_OP_CSRRS;
        end
        else if(funct3 == 3'b011)begin
          op_dc_o = `CPU_OP_CSRRC;
        end
        else if(funct3 == 3'b101)begin
          op_dc_o = `CPU_OP_CSRRWI;
          end
        else if(funct3 == 3'b110)begin
          op_dc_o = `CPU_OP_CSRRSI;
        end
        else if(funct3 == 3'b111)begin
          op_dc_o = `CPU_OP_CSRRCI;
        end
      end
      default: begin
        op_dc_o = `CPU_OP_NONE;
      end
    endcase
  end
endmodule

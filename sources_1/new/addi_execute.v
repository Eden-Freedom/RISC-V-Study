`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 15:38:22
// Design Name: 
// Module Name: addi_execute
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


module addi_execute(
    input wire [31:0] pc_i,
    input wire is_addi_i,
    input wire is_add_i,
    input wire is_sub_i,
    input wire is_xor_i,
    input wire is_or_i,
    input wire is_and_i,
    input wire is_sll_i,
    input wire is_srl_i,
    input wire is_sra_i,
    input wire is_slli_i,
    input wire is_srli_i,
    input wire is_srai_i,
    input wire is_slt_i,
    input wire is_sltu_i,
    input wire is_slti_i,
    input wire is_sltiu_i,
    input wire is_lui_i,
    input wire is_auipc_i,
    input wire is_beq_i,
    input wire is_bne_i,
    input wire is_blt_i,
    input wire is_bge_i,
    input wire is_bltu_i,
    input wire is_bgeu_i,
    input wire is_jal_i,
    input wire is_jalr_i,
    input wire is_sw_i,
    input wire is_lw_i,
    input wire is_lb_i,
    input wire is_lbu_i,
    input wire is_lh_i,
    input wire is_lhu_i,
    input wire is_sb_i,
    input wire is_sh_i,
    input wire [31:0] imm_typei_i,
    input wire [31:0] imm_typeu_i,
    input wire [31:0] imm_typeb_i,
    input wire [31:0] imm_typej_i,
    input wire [31:0] imm_types_i,
    input wire [31:0] rs1_data_i,
    input wire [4:0] rd_addr_i,
    input wire [31:0] rs2_data_i,

    input wire [31:0] ram_rd_data_i, //从数据存储模块读出的数据
    output reg ram_rd_en_o,//读取数据存储模块的使能
    output reg [31:0] ram_rd_addr_o,//读取数据存储模块的地址

    output reg ram_wr_en_o,//写入数据存储模块的使能
    output reg [3:0] ram_wr_sel_o,//写入数据存储模块的片选
    output reg [31:0] ram_wr_addr_o,//写入数据存储模块的地址
    output reg [31:0] ram_wr_data_o,//写入数据存储模块的数据


    output reg wr_en_o,//指令写使能
    output reg [4:0] wr_addr_o,//指令写地址
    output reg [31:0] wr_data_o,//指令写数据

    output reg pc_brench_flag_o,
    output reg [31:0] pc_brench_addr_o
    );

    always@(*)begin
        //指令写
        wr_en_o = 1'b0;
        wr_addr_o = 5'd0;
        wr_data_o = 32'h0;

        //数据写
        ram_wr_en_o = 1'b0;
        ram_wr_sel_o = 4'b0000;
        ram_wr_addr_o = 32'h0;
        ram_wr_data_o = 32'h0;

        //数据读
        ram_rd_en_o = 1'b0;
        ram_rd_addr_o = 32'h0;

        //分支判断
        pc_brench_flag_o = 1'b0;
        pc_brench_addr_o = pc_i + 32'h00000004;

        if(is_addi_i)begin
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i + imm_typei_i;
        end
        else if(is_add_i)begin
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i + rs2_data_i;
        end
        else if(is_sub_i)begin
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i - rs2_data_i;
        end
        else if(is_xor_i)begin
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i ^ rs2_data_i;
        end
        else if(is_or_i)begin
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i | rs2_data_i;
        end
        else if(is_and_i)begin
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i & rs2_data_i;
        end
        else if(is_sll_i)begin
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i << rs2_data_i[4:0];//RV32 的寄存器移位量只使用 rs2 的低 5 位
        end
        else if(is_srl_i)begin//无符号右移
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i >> rs2_data_i[4:0];
        end
        else if(is_sra_i)begin//有符号右移
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = $signed(rs1_data_i) >>> rs2_data_i[4:0];
        end
        else if(is_slli_i)begin//立即数左移
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i << imm_typei_i[4:0];
        end
        else if(is_srli_i)begin//无符号右移
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = rs1_data_i >> imm_typei_i[4:0];
        end
        else if(is_srai_i)begin//有符号右移
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = $signed(rs1_data_i) >>> imm_typei_i[4:0];
        end
        else if(is_slt_i)begin//有符号比较
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = $signed(rs1_data_i) < $signed(rs2_data_i) ? 32'h00000001 : 32'h00000000;
        end
        else if(is_sltu_i)begin//无符号比较
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = $unsigned(rs1_data_i) < $unsigned(rs2_data_i) ? 32'h00000001 : 32'h00000000;
        end
        else if(is_slti_i)begin//有符号比较
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = $signed(rs1_data_i) < $signed(imm_typei_i) ? 32'h00000001 : 32'h00000000;
        end
        else if(is_sltiu_i)begin//无符号比较，SLTIU 是无符号比较，但立即数仍然进行符号扩展
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = $unsigned(rs1_data_i) < $unsigned(imm_typei_i) ? 32'h00000001 : 32'h00000000;
        end
        else if(is_lui_i)begin//LUI 指令，立即数左移 12 位
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = imm_typeu_i;
        end
        else if(is_auipc_i)begin//AUIPC 指令，PC 相对偏移
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = pc_i + imm_typeu_i;
        end
        else if(is_beq_i)begin//BEQ 指令
            wr_en_o = 1'b0;
            wr_addr_o = 5'd0;
            wr_data_o = 32'h0;
            if(rs1_data_i == rs2_data_i)begin
                pc_brench_flag_o = 1'b1;
                pc_brench_addr_o = pc_i + imm_typeb_i;
            end else begin
                pc_brench_flag_o = 1'b0;
                pc_brench_addr_o = pc_i + 32'h00000004;
            end
        end
        else if(is_bne_i)begin//BNE 指令
            wr_en_o = 1'b0;
            wr_addr_o = 5'd0;
            wr_data_o = 32'h0;
            if(rs1_data_i != rs2_data_i)begin
                pc_brench_flag_o = 1'b1;
                pc_brench_addr_o = pc_i + imm_typeb_i;
            end else begin
                pc_brench_flag_o = 1'b0;
                pc_brench_addr_o = pc_i + 32'h00000004;
            end
        end
        else if(is_blt_i)begin
            wr_en_o = 1'b0;
            wr_addr_o = 5'd0;
            wr_data_o = 32'h0;
            if($signed(rs1_data_i) < $signed(rs2_data_i))begin
                pc_brench_flag_o = 1'b1;
                pc_brench_addr_o = pc_i + imm_typeb_i;
            end else begin
                pc_brench_flag_o = 1'b0;
                pc_brench_addr_o = pc_i + 32'h00000004;
            end
        end
        else if(is_bge_i)begin
            wr_en_o = 1'b0;
            wr_addr_o = 5'd0;
            wr_data_o = 32'h0;
            if($signed(rs1_data_i) >= $signed(rs2_data_i))begin
                pc_brench_flag_o = 1'b1;
                pc_brench_addr_o = pc_i + imm_typeb_i;
            end else begin
                pc_brench_flag_o = 1'b0;
                pc_brench_addr_o = pc_i + 32'h00000004;
            end
        end
        else if(is_bltu_i)begin
            wr_en_o = 1'b0;
            wr_addr_o = 5'd0;
            wr_data_o = 32'h0;
            if($unsigned(rs1_data_i) < $unsigned(rs2_data_i))begin
                pc_brench_flag_o = 1'b1;
                pc_brench_addr_o = pc_i + imm_typeb_i;
            end else begin
                pc_brench_flag_o = 1'b0;
                pc_brench_addr_o = pc_i + 32'h00000004;
            end
            end
            else if(is_bgeu_i)begin
                wr_en_o = 1'b0;
                wr_addr_o = 5'd0;
                wr_data_o = 32'h0;
                if($unsigned(rs1_data_i) >= $unsigned(rs2_data_i))begin
                    pc_brench_flag_o = 1'b1;
                    pc_brench_addr_o = pc_i + imm_typeb_i;
                end else begin
                    pc_brench_flag_o = 1'b0;
                    pc_brench_addr_o = pc_i + 32'h00000004;
            end
            end
        else if(is_jal_i)begin
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = pc_i + 32'h00000004;
            pc_brench_flag_o = 1'b1;
            pc_brench_addr_o = pc_i + imm_typej_i;
        end
        else if(is_jalr_i)begin
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            wr_data_o = pc_i + 32'h00000004;
            pc_brench_flag_o = 1'b1;
            pc_brench_addr_o = (rs1_data_i + imm_typei_i) & 32'hFFFFFFFE;//先把寄存器 rs1 的值与符号扩展的 I 型立即数相加，再清除结果的 bit 0复用 imm_typei
        end
        else if(is_sw_i)begin
            ram_wr_en_o = 1'b1;
            ram_wr_addr_o = rs1_data_i + imm_types_i;
            ram_wr_data_o = rs2_data_i;
            ram_wr_sel_o = 4'b1111;
        end
        else if(is_lw_i)begin//数据读出写入指令寄存器
            ram_rd_en_o = 1'b1;
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            ram_rd_addr_o = rs1_data_i + imm_typei_i;
            wr_data_o = ram_rd_data_i;
        end
        else if(is_lb_i)begin//数据读出写入指令寄存器
            ram_rd_en_o = 1'b1;
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            ram_rd_addr_o = rs1_data_i + imm_typei_i;
            case(ram_rd_addr_o[1:0])//根据地址的后两位进行片选，小端存储，低字节对应低地址
                2'b00: wr_data_o = {{24{ram_rd_data_i[7]}}, ram_rd_data_i[7:0]};
                2'b01: wr_data_o = {{24{ram_rd_data_i[15]}}, ram_rd_data_i[15:8]};
                2'b10: wr_data_o = {{24{ram_rd_data_i[23]}}, ram_rd_data_i[23:16]};
                2'b11: wr_data_o = {{24{ram_rd_data_i[31]}}, ram_rd_data_i[31:24]};
            endcase
        end
        else if(is_lbu_i)begin//数据读出写回通用寄存器
            ram_rd_en_o = 1'b1;
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            ram_rd_addr_o = rs1_data_i + imm_typei_i;
            case(ram_rd_addr_o[1:0])//根据地址的后两位进行片选
                2'b00: wr_data_o = {24'h0, ram_rd_data_i[7:0]};
                2'b01: wr_data_o = {24'h0, ram_rd_data_i[15:8]};
                2'b10: wr_data_o = {24'h0, ram_rd_data_i[23:16]};
                2'b11: wr_data_o = {24'h0, ram_rd_data_i[31:24]};
            endcase
        end
        else if(is_lh_i)begin//数据读出写回通用寄存器
            ram_rd_en_o = 1'b1;
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            ram_rd_addr_o = rs1_data_i + imm_typei_i;
            case(ram_rd_addr_o[1:0])//根据地址的后两位进行片选
               2'b00: wr_data_o = {{16{ram_rd_data_i[15]}}, ram_rd_data_i[15:0]};
               2'b10: wr_data_o = {{16{ram_rd_data_i[31]}}, ram_rd_data_i[31:16]};
               default: wr_data_o = 32'h0;
            endcase
        end
        else if(is_lhu_i)begin//数据读出写回通用寄存器
            ram_rd_en_o = 1'b1;
            wr_en_o = 1'b1;
            wr_addr_o = rd_addr_i;
            ram_rd_addr_o = rs1_data_i + imm_typei_i;
            case(ram_rd_addr_o[1:0])//根据地址的后两位进行片选
               2'b00: wr_data_o = {16'h0, ram_rd_data_i[15:0]};
               2'b10: wr_data_o = {16'h0, ram_rd_data_i[31:16]};
               default: wr_data_o = 32'h0;
            endcase
        end
        else if(is_sb_i)begin//数据存储
            ram_wr_en_o = 1'b1;
            ram_wr_addr_o = rs1_data_i + imm_types_i;
            case(ram_wr_addr_o[1:0])//根据地址的后两位进行片选，SB只使用rs2的低8位
                2'b00: begin
                    ram_wr_sel_o = 4'b0001;
                    ram_wr_data_o[7:0] = rs2_data_i[7:0];
                end
                2'b01: begin
                    ram_wr_sel_o = 4'b0010;
                    ram_wr_data_o[15:8] = rs2_data_i[7:0];
                end
                2'b10: begin
                    ram_wr_sel_o = 4'b0100;
                    ram_wr_data_o[23:16] = rs2_data_i[7:0];
                end
                2'b11: begin
                    ram_wr_sel_o = 4'b1000;
                    ram_wr_data_o[31:24] = rs2_data_i[7:0];
                end
            endcase
        end
        else if(is_sh_i)begin//数据存储
            ram_wr_en_o = 1'b1;
            ram_wr_addr_o = rs1_data_i + imm_types_i;
            case(ram_wr_addr_o[1:0])//根据地址的后两位进行片选，SH只使用rs2的低16位
                2'b00: begin
                    ram_wr_sel_o = 4'b0011;
                    ram_wr_data_o[15:0] = rs2_data_i[15:0];
                end
                2'b10: begin
                    ram_wr_sel_o = 4'b1100;
                    ram_wr_data_o[31:16] = rs2_data_i[15:0];
                end
                default: begin
                    ram_wr_sel_o = 4'b0000;
                    ram_wr_data_o = 32'h0;
                end
            endcase
        end
        else begin

        //指令写
        wr_en_o = 1'b0;
        wr_addr_o = 5'd0;
        wr_data_o = 32'h0;

        //数据写
        ram_wr_en_o = 1'b0;
        ram_wr_sel_o = 4'b0000;
        ram_wr_addr_o = 32'h0;
        ram_wr_data_o = 32'h0;

        //数据读
        ram_rd_en_o = 1'b0;
        ram_rd_addr_o = 32'h0;

        //分支判断
        pc_brench_flag_o = 1'b0;
        pc_brench_addr_o = pc_i + 32'h00000004;
        end
    end
endmodule

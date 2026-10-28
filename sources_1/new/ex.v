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


module ex(
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

    input wire [31:0] pc_ex_i,
    input wire [31:0] rs1_data_ex_i,
    input wire [31:0] rs2_data_ex_i,
    input wire [31:0] immi_data_ex_i,
    input wire [31:0] immb_data_ex_i,
    input wire [31:0] immj_data_ex_i,
    input wire [31:0] immu_data_ex_i,
    input wire [4:0] rd_addr_ex_i,
    
    output reg wr_en_ex_o,
    output reg [4:0] wr_addr_ex_o,
    output reg [31:0] wr_data_ex_o,

    output reg pc_brench_flag_ex_o,
    output reg [31:0] pc_brench_addr_ex_o,
    output reg clear_valid_ex_o
    );

    always @(*) begin
        wr_en_ex_o = 1'b0;
        wr_addr_ex_o = 5'h0;
        wr_data_ex_o = 32'h0;
        pc_brench_flag_ex_o = 1'b0;
        pc_brench_addr_ex_o = 32'h0;
        clear_valid_ex_o = 1'b0;
        if(valid_ex_i) begin
            if(is_addi_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i + immi_data_ex_i;
            end
            else if(is_xori_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i ^ immi_data_ex_i;
            end
            else if(is_ori_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i | immi_data_ex_i;
            end
            else if(is_andi_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i & immi_data_ex_i;
            end
            else if(is_slli_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i << immi_data_ex_i[4:0];
            end
            else if(is_srli_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i >> immi_data_ex_i[4:0];
            end
            else if(is_srai_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = $signed(rs1_data_ex_i) >>> immi_data_ex_i[4:0];
            end
            else if(is_slti_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = $signed(rs1_data_ex_i) < $signed(immi_data_ex_i) ? 32'h0000_0001 : 32'h0000_0000;
            end
            else if(is_sltiu_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = $unsigned(rs1_data_ex_i) < $unsigned(immi_data_ex_i) ? 32'h0000_0001 : 32'h0000_0000;
            end


            else if(is_add_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i + rs2_data_ex_i;
            end
            else if(is_sub_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i - rs2_data_ex_i;
            end
            else if(is_xor_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i ^ rs2_data_ex_i;
            end
            else if(is_or_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i | rs2_data_ex_i;
            end
            else if(is_and_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i & rs2_data_ex_i;
            end
            else if(is_sll_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i << rs2_data_ex_i[4:0];
            end
            else if(is_srl_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = rs1_data_ex_i >> rs2_data_ex_i[4:0];
            end
            else if(is_sra_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = $signed(rs1_data_ex_i) >>> rs2_data_ex_i[4:0];
            end
            else if(is_slt_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = $signed(rs1_data_ex_i) < $signed(rs2_data_ex_i) ? 32'h0000_0001 : 32'h0000_0000;
            end
            else if(is_sltu_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = $unsigned(rs1_data_ex_i) < $unsigned(rs2_data_ex_i) ? 32'h0000_0001 : 32'h0000_0000;
            end


            else if(is_beq_ex_i) begin
                if(rs1_data_ex_i == rs2_data_ex_i) begin
                    pc_brench_flag_ex_o = 1'b1;
                    pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
                    clear_valid_ex_o = 1'b1;
                end else begin
                    pc_brench_flag_ex_o = 1'b0;
                    pc_brench_addr_ex_o = 32'h0;
                    clear_valid_ex_o = 1'b0;
                end
            end
            else if(is_bne_ex_i) begin
                if(rs1_data_ex_i != rs2_data_ex_i) begin
                    pc_brench_flag_ex_o = 1'b1;
                    pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
                    clear_valid_ex_o = 1'b1;
                end else begin
                    pc_brench_flag_ex_o = 1'b0;
                    pc_brench_addr_ex_o = 32'h0;
                    clear_valid_ex_o = 1'b0;
                end
            end
            else if(is_blt_ex_i) begin
                if($signed(rs1_data_ex_i) < $signed(rs2_data_ex_i)) begin
                    pc_brench_flag_ex_o = 1'b1;
                    pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
                    clear_valid_ex_o = 1'b1;
                end else begin
                    pc_brench_flag_ex_o = 1'b0;
                    pc_brench_addr_ex_o = 32'h0;
                    clear_valid_ex_o = 1'b0;
                end
            end
            else if(is_bge_ex_i) begin
                if($signed(rs1_data_ex_i) >= $signed(rs2_data_ex_i)) begin
                    pc_brench_flag_ex_o = 1'b1;
                    pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
                    clear_valid_ex_o = 1'b1;
                end else begin
                    pc_brench_flag_ex_o = 1'b0;
                    pc_brench_addr_ex_o = 32'h0;
                    clear_valid_ex_o = 1'b0;
                end
            end
            else if(is_bltu_ex_i) begin
                if($unsigned(rs1_data_ex_i) < $unsigned(rs2_data_ex_i)) begin
                    pc_brench_flag_ex_o = 1'b1;
                    pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
                    clear_valid_ex_o = 1'b1;
                end else begin
                    pc_brench_flag_ex_o = 1'b0;
                    pc_brench_addr_ex_o = 32'h0;
                    clear_valid_ex_o = 1'b0;
                end
            end
            else if(is_bgeu_ex_i) begin
                if($unsigned(rs1_data_ex_i) >= $unsigned(rs2_data_ex_i)) begin
                    pc_brench_flag_ex_o = 1'b1;
                    pc_brench_addr_ex_o = pc_ex_i + immb_data_ex_i;
                    clear_valid_ex_o = 1'b1;
                end else begin
                    pc_brench_flag_ex_o = 1'b0;
                    pc_brench_addr_ex_o = 32'h0;
                    clear_valid_ex_o = 1'b0;
                end
            end


            else if(is_jal_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = pc_ex_i + 32'h00000004;
                pc_brench_flag_ex_o = 1'b1;
                pc_brench_addr_ex_o = pc_ex_i + immj_data_ex_i;
                clear_valid_ex_o = 1'b1;
            end
            else if(is_jalr_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = pc_ex_i + 32'h00000004;
                pc_brench_flag_ex_o = 1'b1;
                pc_brench_addr_ex_o = (rs1_data_ex_i + immi_data_ex_i) & 32'hFFFFFFFE;
                clear_valid_ex_o = 1'b1;
            end

            else if(is_lui_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = immu_data_ex_i;
            end
            else if(is_auipc_ex_i) begin
                wr_en_ex_o = 1'b1;
                wr_addr_ex_o = rd_addr_ex_i;
                wr_data_ex_o = pc_ex_i + immu_data_ex_i;
            end
        end


        else begin
            wr_en_ex_o = 1'b0;
            wr_addr_ex_o = 5'h0;
            wr_data_ex_o = 32'h0;
            pc_brench_flag_ex_o = 1'b0;
            pc_brench_addr_ex_o = 32'h0;
            clear_valid_ex_o = 1'b0;
        end
    end
endmodule

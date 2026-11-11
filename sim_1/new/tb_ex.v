`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 20:10:00
// Design Name: 
// Module Name: tb_ex
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for ex module (pure combinational, no clock)
//              - ADDI: 5 + 7 = 12
//              - ADD : 2 + 3 = 5
//              - SUB : 9 - 4 = 5
//              - invalid bundle: valid=0, controls=1, must NOT write back
//              - change inputs without waiting for a clock edge
// 
// Dependencies: ex.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_ex();

    //---------------------------------------------------------------
    // DUT 输入
    //---------------------------------------------------------------
    reg        valid_ex_i;
    reg        is_addi_ex_i;
    reg        is_add_ex_i;
    reg        is_sub_ex_i;
    reg [31:0] rs1_data_ex_i;
    reg [31:0] rs2_data_ex_i;
    reg [31:0] imm_data_ex_i;
    reg [4:0]  rd_addr_ex_i;

    //---------------------------------------------------------------
    // DUT 输出
    //---------------------------------------------------------------
    wire        wr_en_ex_o;
    wire [4:0]  wr_addr_ex_o;
    wire [31:0] wr_data_ex_o;

    integer errors;

    //---------------------------------------------------------------
    // 检查任务：全部用 !== 比较
    //---------------------------------------------------------------
    task check_out;
        input        exp_wr_en;
        input [4:0]  exp_wr_addr;
        input [31:0] exp_wr_data;
        begin
            if (wr_en_ex_o !== exp_wr_en) begin
                $display("FAIL [%0t] wr_en_ex_o: actual=%b expected=%b",
                         $time, wr_en_ex_o, exp_wr_en);
                errors = errors + 1;
            end
            if (wr_addr_ex_o !== exp_wr_addr) begin
                $display("FAIL [%0t] wr_addr_ex_o: actual=%h expected=%h",
                         $time, wr_addr_ex_o, exp_wr_addr);
                errors = errors + 1;
            end
            if (wr_data_ex_o !== exp_wr_data) begin
                $display("FAIL [%0t] wr_data_ex_o: actual=%h expected=%h",
                         $time, wr_data_ex_o, exp_wr_data);
                errors = errors + 1;
            end
        end
    endtask

    //---------------------------------------------------------------
    // 激励：纯组合逻辑，无时钟
    //---------------------------------------------------------------
    initial begin
        errors = 0;

        // 初值
        valid_ex_i    = 1'b0;
        is_addi_ex_i  = 1'b0;
        is_add_ex_i   = 1'b0;
        is_sub_ex_i   = 1'b0;
        rs1_data_ex_i = 32'h0;
        rs2_data_ex_i = 32'h0;
        imm_data_ex_i = 32'h0;
        rd_addr_ex_i  = 5'h0;
        #1;

        //-----------------------------------------------------------
        // 向量 1：ADDI  5 + 7 = 12
        //-----------------------------------------------------------
        valid_ex_i    = 1'b1;
        is_addi_ex_i  = 1'b1;
        is_add_ex_i   = 1'b0;
        is_sub_ex_i   = 1'b0;
        rs1_data_ex_i = 32'd5;
        rs2_data_ex_i = 32'd0;      // ADDI 不关心 rs2
        imm_data_ex_i = 32'd7;
        rd_addr_ex_i  = 5'd1;
        #1;
        check_out(1'b1, 5'd1, 32'd12);

        //-----------------------------------------------------------
        // 向量 2：ADD   2 + 3 = 5
        //-----------------------------------------------------------
        valid_ex_i    = 1'b1;
        is_addi_ex_i  = 1'b0;
        is_add_ex_i   = 1'b1;
        is_sub_ex_i   = 1'b0;
        rs1_data_ex_i = 32'd2;
        rs2_data_ex_i = 32'd3;
        imm_data_ex_i = 32'd0;      // ADD 不关心 imm
        rd_addr_ex_i  = 5'd2;
        #1;
        check_out(1'b1, 5'd2, 32'd5);

        //-----------------------------------------------------------
        // 向量 3：SUB   9 - 4 = 5
        //-----------------------------------------------------------
        valid_ex_i    = 1'b1;
        is_addi_ex_i  = 1'b0;
        is_add_ex_i   = 1'b0;
        is_sub_ex_i   = 1'b1;
        rs1_data_ex_i = 32'd9;
        rs2_data_ex_i = 32'd4;
        imm_data_ex_i = 32'd0;      // SUB 不关心 imm
        rd_addr_ex_i  = 5'd3;
        #1;
        check_out(1'b1, 5'd3, 32'd5);

        //-----------------------------------------------------------
        // 向量 4：invalid bundle
        // valid=0，但三个运算控制位都为 1，且输入都是非零值，
        // 必须完全不写回：wr_en=0, wr_addr=0, wr_data=0
        //-----------------------------------------------------------
        valid_ex_i    = 1'b0;
        is_addi_ex_i  = 1'b1;
        is_add_ex_i   = 1'b1;
        is_sub_ex_i   = 1'b1;
        rs1_data_ex_i = 32'hFFFF_0000;
        rs2_data_ex_i = 32'h0000_1111;
        imm_data_ex_i = 32'h2222_2222;
        rd_addr_ex_i  = 5'b11111;
        #1;
        check_out(1'b0, 5'h0, 32'h0);

        //-----------------------------------------------------------
        // 向量 5：不等待任何时钟沿，改变输入后立即检查输出更新
        // 从 invalid bundle 直接切到 ADDI 0x10 + 0x20 = 0x30
        //-----------------------------------------------------------
        valid_ex_i    = 1'b1;
        is_addi_ex_i  = 1'b1;
        is_add_ex_i   = 1'b0;
        is_sub_ex_i   = 1'b0;
        rs1_data_ex_i = 32'h0000_0010;
        rs2_data_ex_i = 32'h0;
        imm_data_ex_i = 32'h0000_0020;
        rd_addr_ex_i  = 5'd7;
        #1;
        check_out(1'b1, 5'd7, 32'h0000_0030);

        //-----------------------------------------------------------
        // 向量 6：不等待任何时钟沿，再次改变输入立即检查
        // ADDI → SUB 0x50 - 0x08 = 0x48
        //-----------------------------------------------------------
        valid_ex_i    = 1'b1;
        is_addi_ex_i  = 1'b0;
        is_add_ex_i   = 1'b0;
        is_sub_ex_i   = 1'b1;
        rs1_data_ex_i = 32'h0000_0050;
        rs2_data_ex_i = 32'h0000_0008;
        imm_data_ex_i = 32'h0;
        rd_addr_ex_i  = 5'd9;
        #1;
        check_out(1'b1, 5'd9, 32'h0000_0048);

        //-----------------------------------------------------------
        // 结果汇总
        //-----------------------------------------------------------
        #1;
        if (errors == 0) begin
            $display("PASS: all checks passed");
        end else begin
            $display("FAIL: %0d checks failed", errors);
        end
        $finish;
    end

    //---------------------------------------------------------------
    // DUT
    //---------------------------------------------------------------
    ex u_ex(
        .valid_ex_i    (valid_ex_i),
        .is_addi_ex_i  (is_addi_ex_i),
        .is_add_ex_i   (is_add_ex_i),
        .is_sub_ex_i   (is_sub_ex_i),
        .rs1_data_ex_i (rs1_data_ex_i),
        .rs2_data_ex_i (rs2_data_ex_i),
        .imm_data_ex_i (imm_data_ex_i),
        .rd_addr_ex_i  (rd_addr_ex_i),
        .wr_en_ex_o    (wr_en_ex_o),
        .wr_addr_ex_o  (wr_addr_ex_o),
        .wr_data_ex_o  (wr_data_ex_o)
    );

endmodule

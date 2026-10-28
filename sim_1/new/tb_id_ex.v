`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 17:30:00
// Design Name: 
// Module Name: tb_id_ex
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for id_ex pipeline register
//              - drive inputs on negedge, sample on posedge
//              - 3 distinct bundles to catch field crossing
//              - check bubble and hold-between-edges
// 
// Dependencies: id_ex.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_id_ex();

    reg        clk;
    reg        rst_n;

    reg        valid_idex_i;
    reg [31:0] pc_idex_i;
    reg [31:0] rs1_data_idex_i;
    reg [31:0] rs2_data_idex_i;
    reg [31:0] imm_data_idex_i;
    reg [4:0]  rd_addr_idex_i;
    reg        is_addi_idex_i;
    reg        is_sub_idex_i;
    reg        is_add_idex_i;

    wire        valid_idex_o;
    wire [31:0] pc_idex_o;
    wire [31:0] rs1_data_idex_o;
    wire [31:0] rs2_data_idex_o;
    wire [31:0] imm_data_idex_o;
    wire [4:0]  rd_addr_idex_o;
    wire        is_addi_idex_o;
    wire        is_sub_idex_o;
    wire        is_add_idex_o;

    integer errors;

    //---------------------------------------------------------------
    // 时钟：上升沿 10/30/50/...，下降沿 20/40/60/...
    //---------------------------------------------------------------
    initial clk = 1'b0;
    always #10 clk = ~clk;

    //---------------------------------------------------------------
    // 检查任务：用 !== 比较，全部匹配才不记错
    //---------------------------------------------------------------
    task check_bus;
        input        exp_valid;
        input [31:0] exp_pc;
        input [31:0] exp_rs1;
        input [31:0] exp_rs2;
        input [31:0] exp_imm;
        input [4:0]  exp_rd;
        input        exp_addi;
        input        exp_sub;
        input        exp_add;
        begin
            if (valid_idex_o !== exp_valid) begin
                $display("FAIL [%0t] valid_idex_o: actual=%b expected=%b",
                         $time, valid_idex_o, exp_valid);
                errors = errors + 1;
            end
            if (pc_idex_o !== exp_pc) begin
                $display("FAIL [%0t] pc_idex_o: actual=%h expected=%h",
                         $time, pc_idex_o, exp_pc);
                errors = errors + 1;
            end
            if (rs1_data_idex_o !== exp_rs1) begin
                $display("FAIL [%0t] rs1_data_idex_o: actual=%h expected=%h",
                         $time, rs1_data_idex_o, exp_rs1);
                errors = errors + 1;
            end
            if (rs2_data_idex_o !== exp_rs2) begin
                $display("FAIL [%0t] rs2_data_idex_o: actual=%h expected=%h",
                         $time, rs2_data_idex_o, exp_rs2);
                errors = errors + 1;
            end
            if (imm_data_idex_o !== exp_imm) begin
                $display("FAIL [%0t] imm_data_idex_o: actual=%h expected=%h",
                         $time, imm_data_idex_o, exp_imm);
                errors = errors + 1;
            end
            if (rd_addr_idex_o !== exp_rd) begin
                $display("FAIL [%0t] rd_addr_idex_o: actual=%h expected=%h",
                         $time, rd_addr_idex_o, exp_rd);
                errors = errors + 1;
            end
            if (is_addi_idex_o !== exp_addi) begin
                $display("FAIL [%0t] is_addi_idex_o: actual=%b expected=%b",
                         $time, is_addi_idex_o, exp_addi);
                errors = errors + 1;
            end
            if (is_sub_idex_o !== exp_sub) begin
                $display("FAIL [%0t] is_sub_idex_o: actual=%b expected=%b",
                         $time, is_sub_idex_o, exp_sub);
                errors = errors + 1;
            end
            if (is_add_idex_o !== exp_add) begin
                $display("FAIL [%0t] is_add_idex_o: actual=%b expected=%b",
                         $time, is_add_idex_o, exp_add);
                errors = errors + 1;
            end
        end
    endtask

    //---------------------------------------------------------------
    // 激励：下降沿驱动
    //---------------------------------------------------------------
    initial begin
        rst_n            = 1'b0;
        valid_idex_i     = 1'b0;
        pc_idex_i        = 32'h0;
        rs1_data_idex_i  = 32'h0;
        rs2_data_idex_i  = 32'h0;
        imm_data_idex_i  = 32'h0;
        rd_addr_idex_i   = 5'h0;
        is_addi_idex_i   = 1'b0;
        is_sub_idex_i    = 1'b0;
        is_add_idex_i    = 1'b0;

        @(negedge clk);   // 20ns：仍保持复位
        @(negedge clk);   // 40ns：释放复位，驱动 Bundle A
        rst_n = 1'b1;
        valid_idex_i    = 1'b1;
        pc_idex_i       = 32'h0000_0010;
        rs1_data_idex_i = 32'h1111_1111;
        rs2_data_idex_i = 32'h2222_2222;
        imm_data_idex_i = 32'h3333_3333;
        rd_addr_idex_i  = 5'b01010;
        is_addi_idex_i  = 1'b1;
        is_sub_idex_i   = 1'b0;
        is_add_idex_i   = 1'b0;

        @(negedge clk);   // 60ns：驱动 Bundle B（差异明显）
        valid_idex_i    = 1'b1;
        pc_idex_i       = 32'hFFFF_FFF0;
        rs1_data_idex_i = 32'hAAAA_AAAA;
        rs2_data_idex_i = 32'h5555_5555;
        imm_data_idex_i = 32'h9696_9696;
        rd_addr_idex_i  = 5'b10101;
        is_addi_idex_i  = 1'b0;
        is_sub_idex_i   = 1'b1;
        is_add_idex_i   = 1'b0;

        @(negedge clk);   // 80ns：驱动 Bubble
        valid_idex_i    = 1'b0;
        pc_idex_i       = 32'hB0B0_B0B0;
        rs1_data_idex_i = 32'hFEED_FACE;
        rs2_data_idex_i = 32'h8765_4321;
        imm_data_idex_i = 32'h0F0F_0F0F;
        rd_addr_idex_i  = 5'b10000;
        is_addi_idex_i  = 1'b0;
        is_sub_idex_i   = 1'b0;
        is_add_idex_i   = 1'b0;

        @(negedge clk);   // 100ns：驱动 Bundle C（第三组，进一步区分）
        valid_idex_i    = 1'b1;
        pc_idex_i       = 32'h1234_5678;
        rs1_data_idex_i = 32'hDEAD_BEEF;
        rs2_data_idex_i = 32'hCAFE_BABE;
        imm_data_idex_i = 32'h1357_9BDF;
        rd_addr_idex_i  = 5'b00011;
        is_addi_idex_i  = 1'b0;
        is_sub_idex_i   = 1'b0;
        is_add_idex_i   = 1'b1;

        @(negedge clk);   // 120ns：保持 Bundle C
        @(negedge clk);   // 140ns
        @(negedge clk);   // 160ns
    end

    //---------------------------------------------------------------
    // 检查：上升沿之后采样；下降沿驱动之后做"沿间保持"检查
    //---------------------------------------------------------------
    initial begin
        errors = 0;

        // t=11：复位值
        @(posedge clk); #1;
        check_bus(0, 32'h0, 32'h0, 32'h0, 32'h0, 5'h0, 1'b0, 1'b0, 1'b0);

        // t=31：仍复位
        @(posedge clk); #1;
        check_bus(0, 32'h0, 32'h0, 32'h0, 32'h0, 5'h0, 1'b0, 1'b0, 1'b0);

        // t=42：沿间保持 —— A 已驱动但还没到上升沿，输出仍为复位值
        @(negedge clk); #2;
        check_bus(0, 32'h0, 32'h0, 32'h0, 32'h0, 5'h0, 1'b0, 1'b0, 1'b0);

        // t=51：Bundle A 已捕获（检查字段没有串包）
        @(posedge clk); #1;
        check_bus(1,
                  32'h0000_0010, 32'h1111_1111, 32'h2222_2222,
                  32'h3333_3333, 5'b01010, 1'b1, 1'b0, 1'b0);

        // t=62：沿间保持 —— B 已驱动但还没到上升沿，输出仍为 A
        @(negedge clk); #2;
        check_bus(1,
                  32'h0000_0010, 32'h1111_1111, 32'h2222_2222,
                  32'h3333_3333, 5'b01010, 1'b1, 1'b0, 1'b0);

        // t=71：Bundle B 已捕获
        @(posedge clk); #1;
        check_bus(1,
                  32'hFFFF_FFF0, 32'hAAAA_AAAA, 32'h5555_5555,
                  32'h9696_9696, 5'b10101, 1'b0, 1'b1, 1'b0);

        // t=82：沿间保持 —— Bubble 已驱动但还没到上升沿，输出仍为 B
        @(negedge clk); #2;
        check_bus(1,
                  32'hFFFF_FFF0, 32'hAAAA_AAAA, 32'h5555_5555,
                  32'h9696_9696, 5'b10101, 1'b0, 1'b1, 1'b0);

        // t=91：Bubble 已捕获（valid=0，但其余字段仍应正确跟随）
        @(posedge clk); #1;
        check_bus(0,
                  32'hB0B0_B0B0, 32'hFEED_FACE, 32'h8765_4321,
                  32'h0F0F_0F0F, 5'b10000, 1'b0, 1'b0, 1'b0);

        // t=102：沿间保持 —— C 已驱动但还没到上升沿，输出仍为 Bubble
        @(negedge clk); #2;
        check_bus(0,
                  32'hB0B0_B0B0, 32'hFEED_FACE, 32'h8765_4321,
                  32'h0F0F_0F0F, 5'b10000, 1'b0, 1'b0, 1'b0);

        // t=111：Bundle C 已捕获
        @(posedge clk); #1;
        check_bus(1,
                  32'h1234_5678, 32'hDEAD_BEEF, 32'hCAFE_BABE,
                  32'h1357_9BDF, 5'b00011, 1'b0, 1'b0, 1'b1);

        // t=122：沿间保持 —— 输出仍为 C
        @(negedge clk); #2;
        check_bus(1,
                  32'h1234_5678, 32'hDEAD_BEEF, 32'hCAFE_BABE,
                  32'h1357_9BDF, 5'b00011, 1'b0, 1'b0, 1'b1);

        // t=131：下一个上升沿后输出仍为 C（输入未变）
        @(posedge clk); #1;
        check_bus(1,
                  32'h1234_5678, 32'hDEAD_BEEF, 32'hCAFE_BABE,
                  32'h1357_9BDF, 5'b00011, 1'b0, 1'b0, 1'b1);

        #10;
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
    id_ex u_id_ex(
        .clk             (clk),
        .rst_n           (rst_n),
        .valid_idex_i    (valid_idex_i),
        .pc_idex_i       (pc_idex_i),
        .rs1_data_idex_i (rs1_data_idex_i),
        .rs2_data_idex_i (rs2_data_idex_i),
        .imm_data_idex_i (imm_data_idex_i),
        .rd_addr_idex_i  (rd_addr_idex_i),
        .is_addi_idex_i  (is_addi_idex_i),
        .is_sub_idex_i   (is_sub_idex_i),
        .is_add_idex_i   (is_add_idex_i),
        .valid_idex_o    (valid_idex_o),
        .pc_idex_o       (pc_idex_o),
        .rs1_data_idex_o (rs1_data_idex_o),
        .rs2_data_idex_o (rs2_data_idex_o),
        .imm_data_idex_o (imm_data_idex_o),
        .rd_addr_idex_o  (rd_addr_idex_o),
        .is_addi_idex_o  (is_addi_idex_o),
        .is_sub_idex_o   (is_sub_idex_o),
        .is_add_idex_o   (is_add_idex_o)
    );

endmodule

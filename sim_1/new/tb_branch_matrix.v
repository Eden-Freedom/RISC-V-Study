`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_branch_matrix
// Description: Testbench for RISC-V branch instruction matrix coverage
//
//    rs1         rs2         BNE  BLT  BGE  BLTU BGEU
//    00000001    00000001    N    N    T    N    T
//    FFFFFFFF    00000001    T    T    N    N    T
//    00000001    FFFFFFFF    T    N    T    T    N
//
// 标记寄存器约定：
//   x10~x14 : 第 1 行 BNE/BLT/BGE/BLTU/BGEU 标记
//   x15~x19 : 第 2 行 BNE/BLT/BGE/BLTU/BGEU 标记
//   x20~x24 : 第 3 行 BNE/BLT/BGE/BLTU/BGEU 标记
//   marker=1 -> 分支未跳转 (N)
//   marker=0 -> 分支已跳转 (T)
//
// 完成判据：
//   程序最后一条 JAL x0,0 @0x84 是 EX 级解析的自循环，
//   PC 会在 84 -> 88 -> 8C -> 84 ... 周期性经过 0x84 而不会停驻。
//   因此用 sticky 标志记录“曾经出现 valid_idex_o=1 & is_jal_idex_o=1
//   & pc_idex_o=0x84”，等待结束后统一检查；超时未到达即失败。
//////////////////////////////////////////////////////////////////////////////////


module tb_branch_matrix();

reg clk;
reg rst_n;

integer errors;

//---------------------------------------------------------------
// 时钟：上升沿在 10/30/50/...，下降沿在 20/40/60/...
//---------------------------------------------------------------
initial clk = 1'b0;
always #10 clk = ~clk;

//---------------------------------------------------------------
// 检查 reg_file 数组（仅用于 x1..x31；不能用于 x0）
//---------------------------------------------------------------
task check_regfile;
input [4:0]  idx;
input [31:0] exp_val;
begin
    if (u_pipeline_core.regfile_inst.reg_file[idx] !== exp_val) begin
        $display("FAIL [%0t] x%0d: actual=%h expected=%h",
                 $time, idx,
                 u_pipeline_core.regfile_inst.reg_file[idx], exp_val);
        errors = errors + 1;
    end
end
endtask

//---------------------------------------------------------------
// JAL x0,0 @0x84 到达标志（sticky）
//---------------------------------------------------------------
reg reached_jal;

always @(posedge clk) begin
    if (!rst_n) begin
        reached_jal <= 1'b0;
    end
    else if (u_pipeline_core.valid_idex_o &&
             u_pipeline_core.is_jal_idex_o &&
             u_pipeline_core.pc_idex_o == 32'h00000084) begin
        if (!reached_jal)
            $display("[%0t] INFO: reached JAL x0,0 @0x84 (valid_idex_o=1)", $time);
        reached_jal <= 1'b1;
    end
end

task check_reached_jal;
begin
    if (!reached_jal) begin
        $display("FAIL [%0t] reached_jal: JAL x0,0 @0x84 never observed within timeout",
                 $time);
        errors = errors + 1;
    end
end
endtask

//---------------------------------------------------------------
// 激励与沿后检查
//---------------------------------------------------------------
initial begin
    rst_n  = 1'b0;
    errors = 0;

    // t=25ns：释放复位
    #25;
    rst_n = 1'b1;

    // 等待测试程序执行完（34 条指令 + 8 次 taken 分支开销 + 流水线填充）
    // 150 个周期留有充分余量
    repeat (150) @(posedge clk);
    #1;

    //-----------------------------------------------------------
    // 初值检查
    //-----------------------------------------------------------
    check_regfile(5'd1, 32'h00000001);
    check_regfile(5'd2, 32'h00000001);
    check_regfile(5'd3, 32'hFFFFFFFF);

    //-----------------------------------------------------------
    // 第 1 行：rs1=0x00000001, rs2=0x00000001
    // 期望：BNE=N, BLT=N, BGE=T, BLTU=N, BGEU=T
    //-----------------------------------------------------------
    check_regfile(5'd10, 32'h00000001); // BNE  N -> 标记写入
    check_regfile(5'd11, 32'h00000001); // BLT  N -> 标记写入
    check_regfile(5'd12, 32'h00000000); // BGE  T -> 跳过标记
    check_regfile(5'd13, 32'h00000001); // BLTU N -> 标记写入
    check_regfile(5'd14, 32'h00000000); // BGEU T -> 跳过标记

    //-----------------------------------------------------------
    // 第 2 行：rs1=0xFFFFFFFF, rs2=0x00000001
    // 期望：BNE=T, BLT=T, BGE=N, BLTU=N, BGEU=T
    //-----------------------------------------------------------
    check_regfile(5'd15, 32'h00000000); // BNE  T -> 跳过标记
    check_regfile(5'd16, 32'h00000000); // BLT  T -> 跳过标记
    check_regfile(5'd17, 32'h00000001); // BGE  N -> 标记写入
    check_regfile(5'd18, 32'h00000001); // BLTU N -> 标记写入
    check_regfile(5'd19, 32'h00000000); // BGEU T -> 跳过标记

    //-----------------------------------------------------------
    // 第 3 行：rs1=0x00000001, rs2=0xFFFFFFFF
    // 期望：BNE=T, BLT=N, BGE=T, BLTU=T, BGEU=N
    //-----------------------------------------------------------
    check_regfile(5'd20, 32'h00000000); // BNE  T -> 跳过标记
    check_regfile(5'd21, 32'h00000001); // BLT  N -> 标记写入
    check_regfile(5'd22, 32'h00000000); // BGE  T -> 跳过标记
    check_regfile(5'd23, 32'h00000000); // BLTU T -> 跳过标记
    check_regfile(5'd24, 32'h00000001); // BGEU N -> 标记写入

    //-----------------------------------------------------------
    // 完成判据：曾到达 JAL x0,0 @0x84
    //-----------------------------------------------------------
    check_reached_jal();

    //-----------------------------------------------------------
    // 汇总
    //-----------------------------------------------------------
    if (errors == 0) begin
        $display("PASS: all branch matrix checks passed");
    end else begin
        $display("FAIL: %0d checks failed", errors);
    end
    $finish;
end

//---------------------------------------------------------------
// DUT
//---------------------------------------------------------------
pipeline_core u_pipeline_core(
    .clk  (clk),
    .rst_n(rst_n)
);


endmodule
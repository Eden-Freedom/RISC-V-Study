`timescale 1ns / 1ps

// 程序来自 fetch_unit 内部的 instruction_rom，不由 TB 注入指令或 rs1 数据。
// 更换 instruction_rom.v 中的程序时，同步调整下面的提交顺序和预期值。
module tb_csr();

reg clk;
reg rst_n;
integer errors;

//---------------------------------------------------------------
// 时钟：上升沿在 10/30/50/...，下降沿在 20/40/60/...
//---------------------------------------------------------------
initial clk = 1'b0;
always #10 clk = ~clk;

//---------------------------------------------------------------
// 通用检查：使用 !==，未知值也判为失败
//---------------------------------------------------------------
task check;
input [8*64-1:0] item;
input [31:0] actual;
input [31:0] exp_val;
begin
    if (actual !== exp_val) begin
        $display("FAIL [%0t] %0s: actual=%h expected=%h",
                 $time, item, actual, exp_val);
        errors = errors + 1;
    end
end
endtask

task check_regfile;
input [4:0] idx;
input [31:0] exp_val;
reg [8*64-1:0] item;
begin
    // x0 不存放在数组中，必须通过读端口检查。
    $sformat(item, "x%0d", idx);
    check(item, u_pipeline_core.register_file_inst.reg_file[idx], exp_val);
end
endtask

task check_valid;
input valid_ifid_exp_val;
input valid_idex_exp_val;
begin
    check("valid_ifid_o", {31'b0, u_pipeline_core.valid_ifid_o},
          {31'b0, valid_ifid_exp_val});
    check("valid_idex_o", {31'b0, u_pipeline_core.valid_idex_o},
          {31'b0, valid_idex_exp_val});
end
endtask

//---------------------------------------------------------------
// 检查下一上升沿的提交，不等待指定 PC，确保指令连续执行。
// 沿前：ID/EX、EX 写回端口、CSR 旧值；沿后：实际 GPR 和 CSR。
//---------------------------------------------------------------
task check_commit;
input [31:0] exp_pc;
input [4:0] exp_rd;
input [31:0] exp_data;
input [31:0] exp_csr_old;
input [31:0] exp_csr_new;
input exp_csr_read;
input exp_csr_write;
begin
    @(posedge clk);
    check("commit valid", {31'b0, u_pipeline_core.valid_idex_o}, 32'd1);
    check("commit PC", u_pipeline_core.pc_idex_o, exp_pc);
    check("stall_ex_o", {31'b0, u_pipeline_core.stall_ex_o}, 32'd0);
    check("wr_en_ex_o", {31'b0, u_pipeline_core.wr_en_ex_o}, 32'd1);
    check("wr_addr_ex_o", {27'b0, u_pipeline_core.wr_addr_ex_o},
          {27'b0, exp_rd});
    check("wr_data_ex_o", u_pipeline_core.wr_data_ex_o, exp_data);
    check("mscratch before commit",
          u_pipeline_core.execute_unit_inst.csr_unit_inst.mscratch_reg, exp_csr_old);
    check("CSR read enable", {31'b0, u_pipeline_core.execute_unit_inst.csr_rd_en_ex_o},
          {31'b0, exp_csr_read});
    check("CSR write enable", {31'b0, u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o},
          {31'b0, exp_csr_write});
    if (exp_csr_read)
        check("CSR read address", {20'b0, u_pipeline_core.execute_unit_inst.csr_rd_addr_ex_o},
              32'h0000_0340);
    if (exp_csr_write)
        check("CSR write address", {20'b0, u_pipeline_core.execute_unit_inst.csr_wr_addr_ex_o},
              32'h0000_0340);

    #1;
    if (exp_rd != 5'd0)
        check_regfile(exp_rd, exp_data);
    check("mscratch after commit",
          u_pipeline_core.execute_unit_inst.csr_unit_inst.mscratch_reg, exp_csr_new);
end
endtask

//---------------------------------------------------------------
// 复位、流水线填充、连续程序及跳转冲刷自检
//---------------------------------------------------------------
initial begin
    rst_n = 1'b0;
    errors = 0;

    // t=15ns：同步复位已经经过一个上升沿。
    #15;
    // Fail immediately if Vivado reused a compiled ROM from another test.
    if (u_pipeline_core.instr_o !== 32'h03500093) begin
        $fatal(1, "CSR ROM mismatch at PC=0: actual=%08h expected=03500093. Fully recompile instruction_rom.v; restarting the old snapshot is insufficient.",
               u_pipeline_core.instr_o);
    end
    check_valid(1'b0, 1'b0);
    check("reset mscratch", u_pipeline_core.execute_unit_inst.csr_unit_inst.mscratch_reg,
          32'h0000_0000);
    check("reset GPR write", {31'b0, u_pipeline_core.wr_en_ex_o}, 32'd0);
    check("reset CSR write", {31'b0, u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o}, 32'd0);

    // t=25ns：释放复位；仅等待流水线自然填充，不在 ROM 中插 NOP。
    #10;
    rst_n = 1'b1;
    @(posedge clk); #1;
    check_valid(1'b1, 1'b0);
    @(posedge clk); #1;
    check_valid(1'b1, 1'b1);

    //                       PC          rd    写回旧值/ALU结果  CSR旧值       CSR新值       读    写
    check_commit(32'h0000_0000, 5'd1, 32'h0000_0035, 32'h0000_0000, 32'h0000_0000, 1'b0, 1'b0); // ADDI
    check_commit(32'h0000_0004, 5'd2, 32'h0000_0000, 32'h0000_0000, 32'h0000_0035, 1'b1, 1'b1); // CSRRW，ALU -> CSR
    check_commit(32'h0000_0008, 5'd3, 32'h0000_0035, 32'h0000_0035, 32'h0000_003F, 1'b1, 1'b1); // CSRRSI，连续 CSR
    check_commit(32'h0000_000C, 5'd4, 32'h0000_0035, 32'h0000_003F, 32'h0000_003F, 1'b0, 1'b0); // ADD，CSR -> ALU（rs2）
    check_commit(32'h0000_0010, 5'd5, 32'h0000_003F, 32'h0000_003F, 32'h0000_0035, 1'b1, 1'b1); // CSRRW，ALU -> CSR
    check_commit(32'h0000_0014, 5'd0, 32'h0000_0018, 32'h0000_0035, 32'h0000_0035, 1'b0, 1'b0); // JAL x0,target

    // JAL 提交沿后：错误路径的 ID、IF 指令必须同时失效。
    check_valid(1'b0, 1'b0);
    check("jump target PC", u_pipeline_core.pc_o, 32'h0000_0020);
    check("flushed CSR write", {31'b0, u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o}, 32'd0);

    // 两个冲刷/重新填充周期内，CSR 不允许写入或变化。
    @(posedge clk); #1;
    check_valid(1'b1, 1'b0);
    check("bubble CSR write", {31'b0, u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o}, 32'd0);
    check("bubble mscratch", u_pipeline_core.execute_unit_inst.csr_unit_inst.mscratch_reg,
          32'h0000_0035);
    @(posedge clk); #1;
    check_valid(1'b1, 1'b1);
    check("target CSR write suppressed", {31'b0, u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o}, 32'd0);
    check("target mscratch", u_pipeline_core.execute_unit_inst.csr_unit_inst.mscratch_reg,
          32'h0000_0035);

    check_commit(32'h0000_0020, 5'd6, 32'h0000_0035, 32'h0000_0035, 32'h0000_0035, 1'b1, 1'b0); // CSRRS rs1=x0，只读
    check_commit(32'h0000_0024, 5'd0, 32'h0000_0028, 32'h0000_0035, 32'h0000_0035, 1'b0, 1'b0); // done: JAL x0,done
    check_valid(1'b0, 1'b0);
    check("done PC", u_pipeline_core.pc_o, 32'h0000_0024);

    check_regfile(5'd1, 32'h0000_0035);
    check_regfile(5'd2, 32'h0000_0000);
    check_regfile(5'd3, 32'h0000_0035);
    check_regfile(5'd4, 32'h0000_0035);
    check_regfile(5'd5, 32'h0000_003F);
    check_regfile(5'd6, 32'h0000_0035);
    check("x0 rs1 address", {27'b0, u_pipeline_core.register_file_inst.rs1_addr_i}, 32'd0);
    check("x0 rs1 read", u_pipeline_core.register_file_inst.rs1_data_o, 32'd0);
    check("x0 rs2 address", {27'b0, u_pipeline_core.register_file_inst.rs2_addr_i}, 32'd0);
    check("x0 rs2 read", u_pipeline_core.register_file_inst.rs2_data_o, 32'd0);

    if (errors == 0) begin
        $display("PASS: CSR pipeline checks passed");
        $finish;
    end else begin
        $fatal(1, "FAIL: %0d CSR pipeline checks failed", errors);
    end
end

initial begin
    #2000;
    $fatal(1, "FAIL: CSR pipeline test timeout");
end

//---------------------------------------------------------------
// DUT：包含 IF、ID/EX、寄存器堆、旁路、EX 和 csr_unit
//---------------------------------------------------------------
pipeline_core u_pipeline_core(
    .clk  (clk),
    .rst_n(rst_n)
);

endmodule


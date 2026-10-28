`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 14:51:16
// Design Name: 
// Module Name: tb_store_load
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


module tb_store_load();

reg clk;
reg rst_n;

integer errors;
integer checked;
reg bad_path_seen;

localparam [31:0] DONE_PC = 32'h0000002C;

//---------------------------------------------------------------
// DUT
//---------------------------------------------------------------
pipeline_core u_pipeline_core (
    .clk  (clk),
    .rst_n(rst_n)
);

//---------------------------------------------------------------
// 时钟：上升沿10/30/50/...，下降沿20/40/60/...
//---------------------------------------------------------------
initial clk = 1'b0;
always #10 clk = ~clk;

//---------------------------------------------------------------
// 检查寄存器文件
//---------------------------------------------------------------
task check_regfile;
    input [4:0]  idx;
    input [31:0] exp_val;
    begin
        if (u_pipeline_core.regfile_inst.reg_file[idx] !== exp_val) begin
            $display("FAIL [%0t] x%0d: actual=%h expected=%h",
                     $time, idx,
                     u_pipeline_core.regfile_inst.reg_file[idx],
                     exp_val);
            errors = errors + 1;
        end
    end
endtask

//---------------------------------------------------------------
// 等待指定 PC 的有效 ID/EX 指令
//---------------------------------------------------------------
task wait_for_pc;
    input [31:0] exp_pc;
    begin
        @(negedge clk);

        while (!((u_pipeline_core.valid_idex_o === 1'b1) &&
                  (u_pipeline_core.pc_idex_o === exp_pc))) begin
            @(negedge clk);
        end
    end
endtask

//---------------------------------------------------------------
// 检查普通寄存器运算
//---------------------------------------------------------------
task check_reg_op;
    input [31:0] exp_pc;
    input [31:0] exp_rs1;
    input [31:0] exp_rs2;
    input [4:0]  exp_rd;
    input [31:0] exp_data;
    begin
        wait_for_pc(exp_pc);

        if (u_pipeline_core.rs1_data_idex_o !== exp_rs1) begin
            $display("FAIL [%0t] pc=%h rs1=%h expected=%h",
                     $time, exp_pc,
                     u_pipeline_core.rs1_data_idex_o, exp_rs1);
            errors = errors + 1;
        end

        if (u_pipeline_core.rs2_data_idex_o !== exp_rs2) begin
            $display("FAIL [%0t] pc=%h rs2=%h expected=%h",
                     $time, exp_pc,
                     u_pipeline_core.rs2_data_idex_o, exp_rs2);
            errors = errors + 1;
        end

        if (u_pipeline_core.wr_en_ex_o !== 1'b1 ||
            u_pipeline_core.wr_addr_ex_o !== exp_rd ||
            u_pipeline_core.wr_data_ex_o !== exp_data) begin
            $display("FAIL [%0t] pc=%h register write: en=%b addr=%0d data=%h",
                     $time, exp_pc,
                     u_pipeline_core.wr_en_ex_o,
                     u_pipeline_core.wr_addr_ex_o,
                     u_pipeline_core.wr_data_ex_o);
            errors = errors + 1;
        end

        if (u_pipeline_core.ram_wr_en_ex_o !== 1'b0 ||
            u_pipeline_core.ram_rd_en_ex_o !== 1'b0) begin
            $display("FAIL [%0t] pc=%h unexpected RAM access",
                     $time, exp_pc);
            errors = errors + 1;
        end

        if (u_pipeline_core.pc_brench_flag_ex_o !== 1'b0 ||
            u_pipeline_core.clear_valid_ex_o !== 1'b0) begin
            $display("FAIL [%0t] pc=%h unexpected redirect/flush",
                     $time, exp_pc);
            errors = errors + 1;
        end

        @(posedge clk);
        #1;
        check_regfile(exp_rd, exp_data);
        checked = checked + 1;
    end
endtask

//---------------------------------------------------------------
// 检查SW
//---------------------------------------------------------------
task check_store;
    input [31:0] exp_pc;
    input [31:0] exp_rs1;
    input [31:0] exp_rs2;
    input [31:0] exp_addr;
    input [31:0] exp_data;
    begin
        wait_for_pc(exp_pc);

        if (u_pipeline_core.rs1_data_idex_o !== exp_rs1 ||
            u_pipeline_core.rs2_data_idex_o !== exp_rs2) begin
            $display("FAIL [%0t] pc=%h store operands: rs1=%h rs2=%h",
                     $time, exp_pc,
                     u_pipeline_core.rs1_data_idex_o,
                     u_pipeline_core.rs2_data_idex_o);
            errors = errors + 1;
        end

        if (u_pipeline_core.wr_en_ex_o !== 1'b0 ||
            u_pipeline_core.wr_addr_ex_o !== 5'd0 ||
            u_pipeline_core.wr_data_ex_o !== 32'h0) begin
            $display("FAIL [%0t] pc=%h SW unexpectedly writes register",
                     $time, exp_pc);
            errors = errors + 1;
        end

        if (u_pipeline_core.ram_wr_en_ex_o !== 1'b1 ||
            u_pipeline_core.ram_wr_addr_ex_o !== exp_addr ||
            u_pipeline_core.ram_wr_data_ex_o !== exp_data ||
            u_pipeline_core.ram_wr_sel_ex_o !== 4'b1111) begin
            $display("FAIL [%0t] pc=%h SW: en=%b addr=%h data=%h sel=%b",
                     $time, exp_pc,
                     u_pipeline_core.ram_wr_en_ex_o,
                     u_pipeline_core.ram_wr_addr_ex_o,
                     u_pipeline_core.ram_wr_data_ex_o,
                     u_pipeline_core.ram_wr_sel_ex_o);
            errors = errors + 1;
        end

        if (u_pipeline_core.ram_rd_en_ex_o !== 1'b0) begin
            $display("FAIL [%0t] pc=%h SW unexpectedly reads RAM",
                     $time, exp_pc);
            errors = errors + 1;
        end

        @(posedge clk);
        #1;
        checked = checked + 1;
    end
endtask

//---------------------------------------------------------------
// 检查LW
//---------------------------------------------------------------
task check_load;
    input [31:0] exp_pc;
    input [31:0] exp_rs1;
    input [31:0] exp_rs2;
    input [31:0] exp_addr;
    input [4:0]  exp_rd;
    input [31:0] exp_data;
    begin
        wait_for_pc(exp_pc);

        if (u_pipeline_core.rs1_data_idex_o !== exp_rs1 ||
            u_pipeline_core.rs2_data_idex_o !== exp_rs2) begin
            $display("FAIL [%0t] pc=%h load operands: rs1=%h rs2=%h",
                     $time, exp_pc,
                     u_pipeline_core.rs1_data_idex_o,
                     u_pipeline_core.rs2_data_idex_o);
            errors = errors + 1;
        end

        if (u_pipeline_core.ram_rd_en_ex_o !== 1'b1 ||
            u_pipeline_core.ram_rd_addr_ex_o !== exp_addr ||
            u_pipeline_core.ram_rd_data_o !== exp_data) begin
            $display("FAIL [%0t] pc=%h LW: en=%b addr=%h data=%h",
                     $time, exp_pc,
                     u_pipeline_core.ram_rd_en_ex_o,
                     u_pipeline_core.ram_rd_addr_ex_o,
                     u_pipeline_core.ram_rd_data_o);
            errors = errors + 1;
        end

        if (u_pipeline_core.wr_en_ex_o !== 1'b1 ||
            u_pipeline_core.wr_addr_ex_o !== exp_rd ||
            u_pipeline_core.wr_data_ex_o !== exp_data) begin
            $display("FAIL [%0t] pc=%h LW writeback: en=%b addr=%0d data=%h",
                     $time, exp_pc,
                     u_pipeline_core.wr_en_ex_o,
                     u_pipeline_core.wr_addr_ex_o,
                     u_pipeline_core.wr_data_ex_o);
            errors = errors + 1;
        end

        @(posedge clk);
        #1;
        check_regfile(exp_rd, exp_data);
        checked = checked + 1;
    end
endtask

//---------------------------------------------------------------
// 检查JAL
//---------------------------------------------------------------
task check_jal;
    input [31:0] exp_pc;
    input [31:0] exp_target;
    input [31:0] exp_link;
    begin
        wait_for_pc(exp_pc);

        if (u_pipeline_core.wr_en_ex_o !== 1'b1 ||
            u_pipeline_core.wr_addr_ex_o !== 5'd0 ||
            u_pipeline_core.wr_data_ex_o !== exp_link) begin
            $display("FAIL [%0t] pc=%h JAL link: en=%b addr=%0d data=%h",
                     $time, exp_pc,
                     u_pipeline_core.wr_en_ex_o,
                     u_pipeline_core.wr_addr_ex_o,
                     u_pipeline_core.wr_data_ex_o);
            errors = errors + 1;
        end

        if (u_pipeline_core.pc_brench_flag_ex_o !== 1'b1 ||
            u_pipeline_core.pc_brench_addr_ex_o !== exp_target ||
            u_pipeline_core.clear_valid_ex_o !== 1'b1) begin
            $display("FAIL [%0t] pc=%h JAL redirect: flag=%b target=%h flush=%b",
                     $time, exp_pc,
                     u_pipeline_core.pc_brench_flag_ex_o,
                     u_pipeline_core.pc_brench_addr_ex_o,
                     u_pipeline_core.clear_valid_ex_o);
            errors = errors + 1;
        end

        @(posedge clk);
        #1;
        checked = checked + 1;
    end
endtask

//---------------------------------------------------------------
// 监控JAL错误路径 PC=0x24
//---------------------------------------------------------------
always @(negedge clk) begin
    if (rst_n &&
        u_pipeline_core.valid_idex_o === 1'b1 &&
        u_pipeline_core.pc_idex_o === 32'h00000024 &&
        !bad_path_seen) begin

        bad_path_seen = 1'b1;

        $display("FAIL [%0t] error-path SW at PC=0x24 reached EX",
                 $time);
        errors = errors + 1;
    end
end

//---------------------------------------------------------------
// 超时保护
//---------------------------------------------------------------
initial begin
    #5000;
    $display("FAIL: timeout, checked=%0d errors=%0d",
             checked, errors);
    $fatal(1, "memory/jump test timeout");
end

//---------------------------------------------------------------
// 激励与检查
//---------------------------------------------------------------
initial begin
    rst_n         = 1'b0;
    errors        = 0;
    checked       = 0;
    bad_path_seen = 1'b0;

    // 复位期间
    #15;

    if (u_pipeline_core.wr_en_ex_o !== 1'b0 ||
        u_pipeline_core.ram_wr_en_ex_o !== 1'b0 ||
        u_pipeline_core.ram_rd_en_ex_o !== 1'b0) begin
        $display("FAIL [%0t] outputs are not idle during reset", $time);
        errors = errors + 1;
    end

    // 释放复位
    #10;
    rst_n = 1'b1;

    // ADDI x1,x0,68
    check_reg_op(
        32'h00000000,
        32'h00000000,
        32'h00000000,
        5'd1,
        32'h00000044
    );

    // ADDI x2,x0,42
    check_reg_op(
        32'h00000004,
        32'h00000000,
        32'h00000000,
        5'd2,
        32'h0000002A
    );

    // SW x2,-4(x1): 68-4=64=0x40 -> memory[16]
    check_store(
        32'h00000008,
        32'h00000044,
        32'h0000002A,
        32'h00000040,
        32'h0000002A
    );

    // 检查store已经提交
    if (u_pipeline_core.ram_inst.memory[16] !== 32'h0000002A) begin
        $display("FAIL [%0t] memory[16]=%h expected=0000002A",
                 $time, u_pipeline_core.ram_inst.memory[16]);
        errors = errors + 1;
    end

    // LW x3,-4(x1)
    check_load(
        32'h0000000C,
        32'h00000044,
        32'h00000000,
        32'h00000040,
        5'd3,
        32'h0000002A
    );

    // ADDI x4,x3,1，检查LW->ADDI的rs1旁路
    check_reg_op(
        32'h00000010,
        32'h0000002A,
        32'h00000000,
        5'd4,
        32'h0000002B
    );

    // SW x4,0(x1)，检查ADDI->SW的rs2旁路
    check_store(
        32'h00000014,
        32'h00000044,
        32'h0000002B,
        32'h00000044,
        32'h0000002B
    );

    if (u_pipeline_core.ram_inst.memory[17] !== 32'h0000002B) begin
        $display("FAIL [%0t] memory[17]=%h expected=0000002B",
                 $time, u_pipeline_core.ram_inst.memory[17]);
        errors = errors + 1;
    end

    // LW x5,0(x1)
    check_load(
        32'h00000018,
        32'h00000044,
        32'h00000000,
        32'h00000044,
        5'd5,
        32'h0000002B
    );

    // ADD x6,x0,x5，检查LW->ADD的rs2旁路
    check_reg_op(
        32'h0000001C,
        32'h00000000,
        32'h0000002B,
        5'd6,
        32'h0000002B
    );

    // JAL x0,8，跳到0x28
    check_jal(
        32'h00000020,
        32'h00000028,
        32'h00000024
    );

    // 0x24 的错误路径应被flush；随后执行目标处LW
    check_load(
        32'h00000028,
        32'h00000044,
        32'h00000000,
        32'h00000040,
        5'd7,
        32'h0000002A
    );

    // 完成点：JAL x0,0
    check_jal(
        32'h0000002C,
        32'h0000002C,
        32'h00000030
    );

    if (bad_path_seen) begin
        $display("FAIL: JAL error-path instruction at PC=0x24 was executed");
        errors = errors + 1;
    end

    if (checked != 11) begin
        $display("FAIL: checked=%0d expected=11", checked);
        errors = errors + 1;
    end

    // 最终寄存器检查
    check_regfile(5'd1, 32'h00000044);
    check_regfile(5'd2, 32'h0000002A);
    check_regfile(5'd3, 32'h0000002A);
    check_regfile(5'd4, 32'h0000002B);
    check_regfile(5'd5, 32'h0000002B);
    check_regfile(5'd6, 32'h0000002B);
    check_regfile(5'd7, 32'h0000002A);

    // 错误路径没有把0写回memory[16]
    if (u_pipeline_core.ram_inst.memory[16] !== 32'h0000002A) begin
        $display("FAIL [%0t] error-path modified memory[16]=%h",
                 $time, u_pipeline_core.ram_inst.memory[16]);
        errors = errors + 1;
    end

    if (u_pipeline_core.ram_inst.memory[17] !== 32'h0000002B) begin
        $display("FAIL [%0t] memory[17]=%h expected=0000002B",
                 $time, u_pipeline_core.ram_inst.memory[17]);
        errors = errors + 1;
    end

    if (errors == 0) begin
        $display("PASS: all memory/jump checks passed, instructions=%0d",
                 checked);
    end
    else begin
        $display("FAIL: %0d checks failed", errors);
        $fatal(1, "memory/jump test failed");
    end

    $finish;
end


endmodule

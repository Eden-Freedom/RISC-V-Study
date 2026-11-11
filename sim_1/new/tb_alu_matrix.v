`timescale 1ns / 1ps

module tb_alu_matrix();

reg clk;
reg rst_n;

integer errors;
integer checked;

localparam [31:0] DONE_PC = 32'h00000118;

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
// 检查实际寄存器数组：仅用于x1..x31
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
// 检查EX写回输出
//---------------------------------------------------------------
task check_ex;
    input        exp_en;
    input [4:0]  exp_addr;
    input [31:0] exp_data;
    begin
        if (u_pipeline_core.wr_en_ex_o !== exp_en) begin
            $display("FAIL [%0t] EX pc=%h: wr_en=%b expected=%b",
                     $time, u_pipeline_core.pc_idex_o,
                     u_pipeline_core.wr_en_ex_o, exp_en);
            errors = errors + 1;
        end

        if (u_pipeline_core.wr_addr_ex_o !== exp_addr) begin
            $display("FAIL [%0t] EX pc=%h: wr_addr=%0d expected=%0d",
                     $time, u_pipeline_core.pc_idex_o,
                     u_pipeline_core.wr_addr_ex_o, exp_addr);
            errors = errors + 1;
        end

        if (u_pipeline_core.wr_data_ex_o !== exp_data) begin
            $display("FAIL [%0t] EX pc=%h: wr_data=%h expected=%h",
                     $time, u_pipeline_core.pc_idex_o,
                     u_pipeline_core.wr_data_ex_o, exp_data);
            errors = errors + 1;
        end
    end
endtask

//---------------------------------------------------------------
// 检查ID/EX锁存的两路操作数
//---------------------------------------------------------------
task check_idex;
    input [31:0] exp_rs1;
    input [31:0] exp_rs2;
    begin
        if (u_pipeline_core.rs1_data_idex_o !== exp_rs1) begin
            $display("FAIL [%0t] EX pc=%h: rs1=%h expected=%h",
                     $time, u_pipeline_core.pc_idex_o,
                     u_pipeline_core.rs1_data_idex_o, exp_rs1);
            errors = errors + 1;
        end

        if (u_pipeline_core.rs2_data_idex_o !== exp_rs2) begin
            $display("FAIL [%0t] EX pc=%h: rs2=%h expected=%h",
                     $time, u_pipeline_core.pc_idex_o,
                     u_pipeline_core.rs2_data_idex_o, exp_rs2);
            errors = errors + 1;
        end
    end
endtask

//---------------------------------------------------------------
// 检查真实x0读端口，不访问内部reg_file[0]
//---------------------------------------------------------------
task check_x0_read_ports;
    begin
        if (u_pipeline_core.regfile_inst.rs1_addr_i !== 5'd0 ||
            u_pipeline_core.regfile_inst.rs2_addr_i !== 5'd0) begin
            $display("FAIL [%0t] x0 probe: read addresses are not both zero",
                     $time);
            errors = errors + 1;
        end

        if (u_pipeline_core.regfile_inst.rs1_data_o !== 32'h0 ||
            u_pipeline_core.regfile_inst.rs2_data_o !== 32'h0) begin
            $display("FAIL [%0t] x0 probe: rs1=%h rs2=%h expected=0/0",
                     $time,
                     u_pipeline_core.regfile_inst.rs1_data_o,
                     u_pipeline_core.regfile_inst.rs2_data_o);
            errors = errors + 1;
        end
    end
endtask

//---------------------------------------------------------------
// 检查一条计算指令：EX输出 + 下一上升沿后的实际写回
//---------------------------------------------------------------
task check_step;
    input [31:0] exp_pc;
    input [4:0]  exp_rd;
    input [31:0] exp_data;
    begin
        // 在下降沿观察稳定的EX组合输出
        @(negedge clk);

        // 等待有效指令；独立超时块防止一直等待
        while (u_pipeline_core.valid_idex_o !== 1'b1)
            @(negedge clk);

        if (u_pipeline_core.pc_idex_o !== exp_pc) begin
            $display("FAIL [%0t] instruction PC: actual=%h expected=%h",
                     $time, u_pipeline_core.pc_idex_o, exp_pc);
            errors = errors + 1;
        end

        // 普通目标必须产生正确写回。
        // rd=x0时，也接受EX直接关闭写使能的实现。
        if (exp_rd != 5'd0) begin
            check_ex(1'b1, exp_rd, exp_data);
        end
        else if (u_pipeline_core.wr_en_ex_o === 1'b1) begin
            check_ex(1'b1, 5'd0, exp_data);
        end
        else if (u_pipeline_core.wr_en_ex_o !== 1'b0) begin
            $display("FAIL [%0t] x0 write enable contains X/Z", $time);
            errors = errors + 1;
        end

        // 直接检查紧邻依赖指令锁存到的操作数
        case (exp_pc)
            32'h00000104:
                check_idex(32'h00000006, 32'h00000001);

            32'h00000108:
                check_idex(32'hFFFFFFFF, 32'h00000007);

            32'h0000010C:
                check_idex(32'h00000007, 32'h00000007);

            32'h00000114:
                check_idex(32'h00000000, 32'h00000000);

            default: begin
            end
        endcase

        // 此时XOR x0,x1,x2在EX，ADD x31,x0,x0在ID。
        // 即使EX算出6，也不能旁路给读取x0的下一条指令。
        if (exp_pc == 32'h00000110) begin
            check_x0_read_ports();

            if (u_pipeline_core.rs1_data_forward_o !== 32'h0 ||
                u_pipeline_core.rs2_data_forward_o !== 32'h0) begin
                $display("FAIL [%0t] rd=x0 incorrectly forwarded: rs1=%h rs2=%h",
                         $time,
                         u_pipeline_core.rs1_data_forward_o,
                         u_pipeline_core.rs2_data_forward_o);
                errors = errors + 1;
            end
        end

        // 下一上升沿提交当前EX指令
        @(posedge clk);
        #1;

        if (exp_rd != 5'd0)
            check_regfile(exp_rd, exp_data);

        checked = checked + 1;
    end
endtask

//---------------------------------------------------------------
// 超时保护：20us
//---------------------------------------------------------------
initial begin
    #20000;
    $display("FAIL: timeout, checked=%0d errors=%0d", checked, errors);
    $fatal(1, "ALU matrix timeout");
end

//---------------------------------------------------------------
// 激励和逐条检查
//---------------------------------------------------------------
initial begin
    rst_n  = 1'b0;
    errors = 0;
    checked = 0;

    // t=15ns，复位期间检查EX默认输出
    #15;
    check_ex(1'b0, 5'd0, 32'h00000000);

    // t=25ns，释放复位
    #10;
    rst_n = 1'b1;

    // 初始化
    check_step(32'h00000000, 5'd1, 32'h0000000C);
    check_step(32'h00000004, 5'd2, 32'h0000000A);
    check_step(32'h00000008, 5'd3, 32'hFFFFFFFF);
    check_step(32'h0000000C, 5'd4, 32'h00000001);
    check_step(32'h00000010, 5'd5, 32'h0000001F);
    check_step(32'h00000014, 5'd6, 32'h00000020);
    check_step(32'h00000018, 5'd7, 32'h00000021);
    check_step(32'h0000001C, 5'd8, 32'h80000000);
    check_step(32'h00000020, 5'd9, 32'h7FFFFFFF);

    // 逻辑运算
    check_step(32'h00000024, 5'd10, 32'h00000008); // AND
    check_step(32'h00000028, 5'd10, 32'h0000000E); // OR
    check_step(32'h0000002C, 5'd10, 32'h00000006); // XOR
    check_step(32'h00000030, 5'd10, 32'h00000000); // XOR 相同操作数
    check_step(32'h00000034, 5'd10, 32'h0000000C); // OR 零
    check_step(32'h00000038, 5'd10, 32'h0000000C); // AND 全1
    check_step(32'h0000003C, 5'd10, 32'hFFFFFFFE); // XOR
    check_step(32'h00000040, 5'd10, 32'hFFFFFFFF); // OR

    // SLL：0、1、31、32、33
    check_step(32'h00000044, 5'd10, 32'h00000001);
    check_step(32'h00000048, 5'd10, 32'h00000002);
    check_step(32'h0000004C, 5'd10, 32'h80000000);
    check_step(32'h00000050, 5'd10, 32'h00000001);
    check_step(32'h00000054, 5'd10, 32'h00000002);

    // SRL：0、1、31、32、33
    check_step(32'h00000058, 5'd10, 32'h80000000);
    check_step(32'h0000005C, 5'd10, 32'h40000000);
    check_step(32'h00000060, 5'd10, 32'h00000001);
    check_step(32'h00000064, 5'd10, 32'h80000000);
    check_step(32'h00000068, 5'd10, 32'h40000000);

    // SRA：负数及正数
    check_step(32'h0000006C, 5'd10, 32'h80000000);
    check_step(32'h00000070, 5'd10, 32'hC0000000);
    check_step(32'h00000074, 5'd10, 32'hFFFFFFFF);
    check_step(32'h00000078, 5'd10, 32'h80000000);
    check_step(32'h0000007C, 5'd10, 32'hC0000000);
    check_step(32'h00000080, 5'd10, 32'h3FFFFFFF);

    // SLLI
    check_step(32'h00000084, 5'd10, 32'h00000001);
    check_step(32'h00000088, 5'd10, 32'h00000002);
    check_step(32'h0000008C, 5'd10, 32'h80000000);

    // SRLI
    check_step(32'h00000090, 5'd10, 32'h80000000);
    check_step(32'h00000094, 5'd10, 32'h40000000);
    check_step(32'h00000098, 5'd10, 32'h00000001);

    // SRAI
    check_step(32'h0000009C, 5'd10, 32'h80000000);
    check_step(32'h000000A0, 5'd10, 32'hC0000000);
    check_step(32'h000000A4, 5'd10, 32'hFFFFFFFF);
    check_step(32'h000000A8, 5'd10, 32'h3FFFFFFF);

    // SLT
    check_step(32'h000000AC, 5'd10, 32'h00000001);
    check_step(32'h000000B0, 5'd10, 32'h00000000);
    check_step(32'h000000B4, 5'd10, 32'h00000000);
    check_step(32'h000000B8, 5'd10, 32'h00000001);
    check_step(32'h000000BC, 5'd10, 32'h00000000);

    // SLTU
    check_step(32'h000000C0, 5'd10, 32'h00000000);
    check_step(32'h000000C4, 5'd10, 32'h00000001);
    check_step(32'h000000C8, 5'd10, 32'h00000000);
    check_step(32'h000000CC, 5'd10, 32'h00000000);
    check_step(32'h000000D0, 5'd10, 32'h00000001);

    // SLTI
    check_step(32'h000000D4, 5'd10, 32'h00000001);
    check_step(32'h000000D8, 5'd10, 32'h00000000);
    check_step(32'h000000DC, 5'd10, 32'h00000000);
    check_step(32'h000000E0, 5'd10, 32'h00000001);
    check_step(32'h000000E4, 5'd10, 32'h00000000);

    // SLTIU
    check_step(32'h000000E8, 5'd10, 32'h00000001);
    check_step(32'h000000EC, 5'd10, 32'h00000000);
    check_step(32'h000000F0, 5'd10, 32'h00000000);
    check_step(32'h000000F4, 5'd10, 32'h00000001);
    check_step(32'h000000F8, 5'd10, 32'h00000000);
    check_step(32'h000000FC, 5'd10, 32'h00000001);

    // 紧邻依赖
    check_step(32'h00000100, 5'd20, 32'h00000006);
    check_step(32'h00000104, 5'd21, 32'h00000007);
    check_step(32'h00000108, 5'd22, 32'h00000007);
    check_step(32'h0000010C, 5'd23, 32'h00000000);

    // x0写保护、读端口和旁路保护
    check_step(32'h00000110, 5'd0,  32'h00000006);
    check_step(32'h00000114, 5'd31, 32'h00000000);

    // 下一条有效EX应为结束循环
    @(negedge clk);

    if (u_pipeline_core.valid_idex_o !== 1'b1 ||
        u_pipeline_core.pc_idex_o !== DONE_PC ||
        u_pipeline_core.is_jal_idex_o !== 1'b1) begin
        $display("FAIL [%0t] completion: valid=%b pc=%h is_jal=%b",
                 $time,
                 u_pipeline_core.valid_idex_o,
                 u_pipeline_core.pc_idex_o,
                 u_pipeline_core.is_jal_idex_o);
        errors = errors + 1;
    end

    if (checked != 70) begin
        $display("FAIL: checked=%0d expected=70", checked);
        errors = errors + 1;
    end

    // 最终保留值：初始化常量不能被测试破坏
    check_regfile(5'd1,  32'h0000000C);
    check_regfile(5'd2,  32'h0000000A);
    check_regfile(5'd3,  32'hFFFFFFFF);
    check_regfile(5'd4,  32'h00000001);
    check_regfile(5'd5,  32'h0000001F);
    check_regfile(5'd6,  32'h00000020);
    check_regfile(5'd7,  32'h00000021);
    check_regfile(5'd8,  32'h80000000);
    check_regfile(5'd9,  32'h7FFFFFFF);
    check_regfile(5'd10, 32'h00000001);

    check_regfile(5'd20, 32'h00000006);
    check_regfile(5'd21, 32'h00000007);
    check_regfile(5'd22, 32'h00000007);
    check_regfile(5'd23, 32'h00000000);
    check_regfile(5'd31, 32'h00000000);

    if (errors == 0) begin
        $display("PASS: all ALU matrix checks passed, instructions=%0d",
                 checked);
    end
    else begin
        $display("FAIL: %0d checks failed", errors);
        $fatal(1, "ALU matrix failed");
    end

    $finish;
end

endmodule

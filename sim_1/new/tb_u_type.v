`timescale 1ns / 1ps

module tb_u_type();

reg clk;
reg rst_n;

integer errors;
integer checked;

localparam [31:0] DONE_PC = 32'h00000044;

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
// 检查真实x0读端口和旁路输出，不访问reg_file[0]
// 调用时，ID中的指令应同时读取两路x0
//---------------------------------------------------------------
task check_x0;
    begin
        if (u_pipeline_core.regfile_inst.rs1_addr_i !== 5'd0 ||
            u_pipeline_core.regfile_inst.rs2_addr_i !== 5'd0) begin
            $display("FAIL [%0t] x0 probe: read addresses are not both zero",
                     $time);
            errors = errors + 1;
        end

        if (u_pipeline_core.regfile_inst.rs1_data_o !== 32'h0 ||
            u_pipeline_core.regfile_inst.rs2_data_o !== 32'h0) begin
            $display("FAIL [%0t] x0 read: rs1=%h rs2=%h expected=0/0",
                     $time,
                     u_pipeline_core.regfile_inst.rs1_data_o,
                     u_pipeline_core.regfile_inst.rs2_data_o);
            errors = errors + 1;
        end

        if (u_pipeline_core.rs1_data_forward_o !== 32'h0 ||
            u_pipeline_core.rs2_data_forward_o !== 32'h0) begin
            $display("FAIL [%0t] x0 forwarding: rs1=%h rs2=%h expected=0/0",
                     $time,
                     u_pipeline_core.rs1_data_forward_o,
                     u_pipeline_core.rs2_data_forward_o);
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
        @(negedge clk);

        while (u_pipeline_core.valid_idex_o !== 1'b1)
            @(negedge clk);

        if (u_pipeline_core.pc_idex_o !== exp_pc) begin
            $display("FAIL [%0t] instruction PC: actual=%h expected=%h",
                     $time, u_pipeline_core.pc_idex_o, exp_pc);
            errors = errors + 1;
        end

        // rd=x0时，也接受EX直接关闭写使能的实现
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

        // 本程序中的计算指令均不应重定向PC或产生flush
        if (u_pipeline_core.pc_brench_flag_ex_o !== 1'b0 ||
            u_pipeline_core.clear_valid_ex_o !== 1'b0) begin
            $display("FAIL [%0t] unexpected redirect/flush at pc=%h",
                     $time, u_pipeline_core.pc_idex_o);
            errors = errors + 1;
        end

        // 直接核对紧邻依赖时锁存的操作数
        case (exp_pc)
            // LUI -> ADDI：rs1旁路
            32'h00000004:
                check_idex(32'h12345000, 32'h00000000);

            // AUIPC -> ADD：rs2旁路
            32'h00000018:
                check_idex(32'h00000000, 32'h00001014);

            // AUIPC -> ADDI：rs1旁路
            32'h00000030:
                check_idex(32'h0000102C, 32'h00000000);

            // 两次写x0后的读取
            32'h00000038:
                check_idex(32'h00000000, 32'h00000000);

            32'h00000040:
                check_idex(32'h00000000, 32'h00000000);

            default: begin
            end
        endcase

        // U型指令写x0在EX，下一条读取x0的ADD在ID
        if (exp_pc == 32'h00000034 ||
            exp_pc == 32'h0000003C)
            check_x0();

        // 上升沿写回，#1避开非阻塞赋值更新时刻
        @(posedge clk);
        #1;

        if (exp_rd != 5'd0)
            check_regfile(exp_rd, exp_data);

        checked = checked + 1;
    end
endtask

//---------------------------------------------------------------
// 超时保护：5us
//---------------------------------------------------------------
initial begin
    #5000;
    $display("FAIL: timeout, checked=%0d errors=%0d", checked, errors);
    $fatal(1, "U-type test timeout");
end

//---------------------------------------------------------------
// 激励与逐条检查
//---------------------------------------------------------------
initial begin
    rst_n   = 1'b0;
    errors  = 0;
    checked = 0;

    // t=15ns：复位期间
    #15;
    check_ex(1'b0, 5'd0, 32'h00000000);

    // t=25ns：释放复位
    #10;
    rst_n = 1'b1;

    // LUI及紧邻依赖
    check_step(32'h00000000, 5'd1,  32'h12345000);
    check_step(32'h00000004, 5'd2,  32'h12345001);

    // LUI边界
    check_step(32'h00000008, 5'd3,  32'h80000000);
    check_step(32'h0000000C, 5'd4,  32'h00000000);
    check_step(32'h00000010, 5'd5,  32'hFFFFF000);

    // AUIPC及紧邻依赖
    check_step(32'h00000014, 5'd6,  32'h00001014);
    check_step(32'h00000018, 5'd7,  32'h00001014);

    // AUIPC边界
    check_step(32'h0000001C, 5'd8,  32'h0000001C);
    check_step(32'h00000020, 5'd9,  32'h80000020);
    check_step(32'h00000024, 5'd10, 32'hFFFFF024);

    // 相同U字段的LUI/AUIPC及AUIPC旁路
    check_step(32'h00000028, 5'd11, 32'h00001000);
    check_step(32'h0000002C, 5'd12, 32'h0000102C);
    check_step(32'h00000030, 5'd13, 32'h0000102B);

    // LUI写x0及紧邻读取
    check_step(32'h00000034, 5'd0,  32'hABCDE000);
    check_step(32'h00000038, 5'd14, 32'h00000000);

    // AUIPC写x0及紧邻读取
    check_step(32'h0000003C, 5'd0,  32'h0000103C);
    check_step(32'h00000040, 5'd15, 32'h00000000);

    // 下一条有效EX应到达结束循环
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

    if (checked != 17) begin
        $display("FAIL: checked=%0d expected=17", checked);
        errors = errors + 1;
    end

    // 最终寄存器检查
    check_regfile(5'd1,  32'h12345000);
    check_regfile(5'd2,  32'h12345001);
    check_regfile(5'd3,  32'h80000000);
    check_regfile(5'd4,  32'h00000000);
    check_regfile(5'd5,  32'hFFFFF000);
    check_regfile(5'd6,  32'h00001014);
    check_regfile(5'd7,  32'h00001014);
    check_regfile(5'd8,  32'h0000001C);
    check_regfile(5'd9,  32'h80000020);
    check_regfile(5'd10, 32'hFFFFF024);
    check_regfile(5'd11, 32'h00001000);
    check_regfile(5'd12, 32'h0000102C);
    check_regfile(5'd13, 32'h0000102B);
    check_regfile(5'd14, 32'h00000000);
    check_regfile(5'd15, 32'h00000000);

    if (errors == 0) begin
        $display("PASS: all LUI/AUIPC checks passed, instructions=%0d",
                 checked);
    end
    else begin
        $display("FAIL: %0d checks failed", errors);
        $fatal(1, "U-type test failed");
    end

    $finish;
end

endmodule
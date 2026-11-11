`timescale 1ns / 1ps

// 真实 instruction_rom -> IF -> ID/EX -> EX -> CSR/PC，不强制任何指令或事件信号。
module tb_ecall_mret();

reg clk;
reg rst_n;
integer errors;
integer step;
integer enter_count;
integer return_count;
reg finished;
reg [31:0] expected_pc [0:10];

// 当前指令的预期控制与沿后状态，均由程序表显式指定。
reg exp_wen;
reg [4:0] exp_rd;
reg [31:0] exp_wdata;
reg exp_enter;
reg exp_return;
reg exp_redirect;
reg [31:0] exp_target;
reg exp_csr_write;
reg exp_csr_read;
reg [11:0] exp_csr_addr;
reg [31:0] exp_csr_source;
reg [31:0] exp_mstatus;
reg [31:0] exp_mtvec;
reg [31:0] exp_mepc;
reg [31:0] exp_mcause;

//---------------------------------------------------------------
// 时钟：上升沿 10/30/50/...，下降沿 20/40/60/...
//---------------------------------------------------------------
initial clk = 1'b0;
always #10 clk = ~clk;

//---------------------------------------------------------------
// 通用检查和寄存器堆检查，保持 tb_check.v 的 errors 累计风格
//---------------------------------------------------------------
task check;
input [8*64-1:0] item;
input [31:0] actual;
input [31:0] exp_val;
begin
    if (actual !== exp_val) begin
        $display("FAIL [%0t] step=%0d %0s: actual=%h expected=%h",
                 $time, step, item, actual, exp_val);
        errors = errors + 1;
    end
end
endtask

task check_regfile;
input [4:0] idx;
input [31:0] exp_val;
begin
    if (u_pipeline_core.register_file_inst.reg_file[idx] !== exp_val) begin
        $display("FAIL [%0t] x%0d: actual=%h expected=%h",
                 $time, idx,
                 u_pipeline_core.register_file_inst.reg_file[idx], exp_val);
        errors = errors + 1;
    end
end
endtask

task check_valid;
input exp_ifid;
input exp_idex;
begin
    check("valid_ifid_o", {31'b0,u_pipeline_core.valid_ifid_o}, {31'b0,exp_ifid});
    check("valid_idex_o", {31'b0,u_pipeline_core.valid_idex_o}, {31'b0,exp_idex});
end
endtask

// 不含延时，可在更新沿前检查旧状态，也可在 #1 后检查新状态。
task check_csr_state;
begin
    check("mstatus", u_pipeline_core.execute_unit_inst.csr_unit_inst.mstatus_reg, exp_mstatus);
    check("mtvec", u_pipeline_core.execute_unit_inst.csr_unit_inst.mtvec_reg, exp_mtvec);
    check("mepc", u_pipeline_core.execute_unit_inst.csr_unit_inst.mepc_reg, exp_mepc);
    check("mcause", u_pipeline_core.execute_unit_inst.csr_unit_inst.mcause_reg, exp_mcause);
    check("mscratch must remain zero",
          u_pipeline_core.execute_unit_inst.csr_unit_inst.mscratch_reg, 32'b0);
    check("mtvec hardware output", u_pipeline_core.execute_unit_inst.csr_mtvec_o, exp_mtvec);
    check("mepc hardware output", u_pipeline_core.execute_unit_inst.csr_mepc_o, exp_mepc);
end
endtask

// 无效 EX 包不能产生任何更新、事件或重定向。
task check_bubble;
begin
    check("GPR write in bubble", {31'b0,u_pipeline_core.wr_en_ex_o}, 32'd0);
    check("CSR write in bubble", {31'b0,u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o}, 32'd0);
    check("CSR read in bubble", {31'b0,u_pipeline_core.execute_unit_inst.csr_rd_en_ex_o}, 32'd0);
    check("entry in bubble", {31'b0,u_pipeline_core.execute_unit_inst.trap_enter_ex_o}, 32'd0);
    check("return in bubble", {31'b0,u_pipeline_core.execute_unit_inst.trap_return_ex_o}, 32'd0);
    check("redirect in bubble", {31'b0,u_pipeline_core.pc_brench_flag_ex_o}, 32'd0);
    check("flush in bubble", {31'b0,u_pipeline_core.clear_valid_ex_o}, 32'd0);
end
endtask

//---------------------------------------------------------------
// 独立程序预期：不使用 DUT 的计算结果生成预期值
//---------------------------------------------------------------
task prepare_expected;
begin
    exp_wen = 1'b0;
    exp_rd = 5'd0;
    exp_wdata = 32'b0;
    exp_enter = 1'b0;
    exp_return = 1'b0;
    exp_redirect = 1'b0;
    exp_target = 32'b0;
    exp_csr_write = 1'b0;
    exp_csr_read = 1'b0;
    exp_csr_addr = 12'b0;
    exp_csr_source = 32'b0;

    // 未列出的 CSR 状态保持上一条指令的预期结果。
    case (step)
        0: begin // 00 ADDI x1,x0,0x100
            exp_wen = 1'b1; exp_rd = 5'd1; exp_wdata = 32'h100;
        end
        1: begin // 04 CSRRW x0,mtvec,x1
            exp_csr_write = 1'b1; exp_csr_addr = 12'h305;
            exp_csr_source = 32'h100; exp_mtvec = 32'h100;
        end
        2: begin // 08 ADDI x2,x0,8
            exp_wen = 1'b1; exp_rd = 5'd2; exp_wdata = 32'd8;
        end
        3: begin // 0C CSRRW x0,mstatus,x2
            exp_csr_write = 1'b1; exp_csr_addr = 12'h300;
            exp_csr_source = 32'd8; exp_mstatus = 32'h1808;
        end
        4: begin // 10 ECALL：不写 GPR，也不走 CSR 指令写通道
            exp_enter = 1'b1; exp_redirect = 1'b1; exp_target = 32'h100;
            exp_mepc = 32'h10; exp_mcause = 32'd11; exp_mstatus = 32'h1880;
        end
        5: begin // 100 CSRRS x10,mepc,x0
            exp_wen = 1'b1; exp_rd = 5'd10; exp_wdata = 32'h10;
            exp_csr_read = 1'b1; exp_csr_addr = 12'h341;
        end
        6: begin // 104 ADDI x10,x10,4
            exp_wen = 1'b1; exp_rd = 5'd10; exp_wdata = 32'h14;
        end
        7: begin // 108 CSRRW x0,mepc,x10
            exp_csr_write = 1'b1; exp_csr_addr = 12'h341;
            exp_csr_source = 32'h14; exp_mepc = 32'h14;
        end
        8: begin // 10C MRET
            exp_return = 1'b1; exp_redirect = 1'b1; exp_target = 32'h14;
            exp_mstatus = 32'h1888;
        end
        9: begin // 14 ADDI x5,x0,7：仅返回后才执行
            exp_wen = 1'b1; exp_rd = 5'd5; exp_wdata = 32'd7;
        end
        10: begin // 18 JAL x0,0：当前 EX 写口仍给出链接值，寄存器堆忽略 x0
            exp_wen = 1'b1; exp_rd = 5'd0; exp_wdata = 32'h1C;
            exp_redirect = 1'b1; exp_target = 32'h18;
        end
    endcase
end
endtask

//---------------------------------------------------------------
// 复位、有效 EX 指令顺序及沿前/沿后检查
//---------------------------------------------------------------
initial begin
    rst_n = 1'b0;
    errors = 0;
    step = 0;
    enter_count = 0;
    return_count = 0;
    finished = 1'b0;
    exp_mstatus = 32'h1800;
    exp_mtvec = 32'b0;
    exp_mepc = 32'b0;
    exp_mcause = 32'b0;

    expected_pc[0] = 32'h00;
    expected_pc[1] = 32'h04;
    expected_pc[2] = 32'h08;
    expected_pc[3] = 32'h0C;
    expected_pc[4] = 32'h10;
    expected_pc[5] = 32'h100;
    expected_pc[6] = 32'h104;
    expected_pc[7] = 32'h108;
    expected_pc[8] = 32'h10C;
    expected_pc[9] = 32'h14;
    expected_pc[10] = 32'h18;

    #15; // 同步复位已经经过 t=10 的上升沿
    check_valid(1'b0,1'b0);
    check_csr_state;
    check_bubble;
    if (u_pipeline_core.instr_o !== 32'h10000093)
        $fatal(1, "ECALL ROM mismatch: recompile instruction_rom.v with this test program");

    #10; // t=25，在上升沿之间释放复位
    rst_n = 1'b1;

    while (!finished) begin
        @(posedge clk);
        // Active 区：仍为本次更新沿之前的 EX 包和 CSR 旧值。
        check_csr_state;
        check("stall_ex_o", {31'b0,u_pipeline_core.stall_ex_o}, 32'd0);
        check("RAM write must be zero", {31'b0,u_pipeline_core.ram_wr_en_ex_o}, 32'd0);

        if (u_pipeline_core.execute_unit_inst.trap_enter_ex_o === 1'b1)
            enter_count = enter_count + 1;
        if (u_pipeline_core.execute_unit_inst.trap_return_ex_o === 1'b1)
            return_count = return_count + 1;

        if (u_pipeline_core.valid_idex_o === 1'b1) begin
            check("valid EX instruction PC", u_pipeline_core.pc_idex_o, expected_pc[step]);
            prepare_expected;
            check("GPR write enable", {31'b0,u_pipeline_core.wr_en_ex_o}, {31'b0,exp_wen});
            if (exp_wen) begin
                check("GPR destination", {27'b0,u_pipeline_core.wr_addr_ex_o}, {27'b0,exp_rd});
                check("GPR write data", u_pipeline_core.wr_data_ex_o, exp_wdata);
            end
            check("entry event", {31'b0,u_pipeline_core.execute_unit_inst.trap_enter_ex_o}, {31'b0,exp_enter});
            check("return event", {31'b0,u_pipeline_core.execute_unit_inst.trap_return_ex_o}, {31'b0,exp_return});
            check("CSR instruction write", {31'b0,u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o}, {31'b0,exp_csr_write});
            check("CSR read enable", {31'b0,u_pipeline_core.execute_unit_inst.csr_rd_en_ex_o}, {31'b0,exp_csr_read});
            check("PC redirect", {31'b0,u_pipeline_core.pc_brench_flag_ex_o}, {31'b0,exp_redirect});
            check("pipeline flush", {31'b0,u_pipeline_core.clear_valid_ex_o}, {31'b0,exp_redirect});
            if (exp_redirect)
                check("redirect target", u_pipeline_core.pc_brench_addr_ex_o, exp_target);
            if (exp_csr_write) begin
                check("CSR write address", {20'b0,u_pipeline_core.execute_unit_inst.csr_wr_addr_ex_o}, {20'b0,exp_csr_addr});
                check("CSR source", u_pipeline_core.execute_unit_inst.csr_wr_data_ex_o, exp_csr_source);
            end
            if (exp_csr_read)
                check("CSR read address", {20'b0,u_pipeline_core.execute_unit_inst.csr_rd_addr_ex_o}, {20'b0,exp_csr_addr});
            if (exp_enter) begin
                check("ECALL saved PC source", u_pipeline_core.execute_unit_inst.trap_pc_ex_o, 32'h10);
                check("ECALL cause source", u_pipeline_core.execute_unit_inst.trap_cause_ex_o, 32'd11);
            end

            #1; // NBA 更新以及组合逻辑稳定后检查实际状态
            check_csr_state;
            if (exp_wen && exp_rd != 0)
                check_regfile(exp_rd,exp_wdata);
            if (step <= 8)
                check_regfile(5'd5,32'd0);
            if (exp_redirect) begin
                check("PC after redirect", u_pipeline_core.pc_o, exp_target);
                check_valid(1'b0,1'b0);
                check_bubble;
            end

            if (step == 10)
                finished = 1'b1;
            else
                step = step + 1;
        end else begin
            // 接受复位填充和冲刷气泡，但气泡不能产生任何副作用。
            check("known invalid EX", {31'b0,u_pipeline_core.valid_idex_o}, 32'd0);
            check_bubble;
            #1;
            check_csr_state;
        end
    end

    check("ECALL event count", enter_count, 32'd1);
    check("MRET event count", return_count, 32'd1);
    check_regfile(5'd1,32'h100);
    check_regfile(5'd2,32'd8);
    check_regfile(5'd5,32'd7);
    check_regfile(5'd10,32'h14);
    check("final mepc", u_pipeline_core.execute_unit_inst.csr_unit_inst.mepc_reg, 32'h14);
    check("final mcause", u_pipeline_core.execute_unit_inst.csr_unit_inst.mcause_reg, 32'd11);
    check("final mstatus", u_pipeline_core.execute_unit_inst.csr_unit_inst.mstatus_reg, 32'h1888);
    check("wrong-path CSR writes cancelled",
          u_pipeline_core.execute_unit_inst.csr_unit_inst.mscratch_reg, 32'b0);
    // 冲刷后的读地址为零，通过实际读口检查架构 x0。
    check("x0 rs1 address", {27'b0,u_pipeline_core.register_file_inst.rs1_addr_i}, 32'd0);
    check("x0 rs1 data", u_pipeline_core.register_file_inst.rs1_data_o, 32'd0);
    check("x0 rs2 address", {27'b0,u_pipeline_core.register_file_inst.rs2_addr_i}, 32'd0);
    check("x0 rs2 data", u_pipeline_core.register_file_inst.rs2_data_o, 32'd0);

    if (errors == 0) begin
        $display("PASS: ECALL/MRET pipeline checks passed");
        $finish;
    end else begin
        $display("FAIL: %0d ECALL/MRET checks failed", errors);
        $fatal(1,"ECALL/MRET pipeline self-check failed");
    end
end

initial begin
    #10000;
    $fatal(1,"FAIL: ECALL/MRET pipeline test timeout at step=%0d",step);
end

//---------------------------------------------------------------
// DUT：唯一激励是时钟和复位，所有事件来自实际指令
//---------------------------------------------------------------
pipeline_core u_pipeline_core(
    .clk(clk),
    .rst_n(rst_n)
);

endmodule

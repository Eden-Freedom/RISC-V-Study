`timescale 1ns / 1ps

// 直接验证 csr_unit，不依赖 instr_rom、EX 或完整流水线。
module tb_csr_irq();

reg clk;
reg rst_n;
reg csr_wr_en_i;
reg csr_rd_en_i;
reg [2:0] csr_type_i;
reg [11:0] csr_wr_addr_i;
reg [31:0] csr_src_data_i;
reg [11:0] csr_rd_addr_i;
reg trap_enter_i;
reg [31:0] trap_pc_i;
reg [31:0] trap_cause_i;
reg trap_return_i;
reg irq_external_i;
wire irq_eligible_o;
integer combination;
integer op_index;
reg [2:0] test_op;

wire [31:0] mtvec_o;
wire [31:0] mepc_o;
wire [31:0] csr_rdata_o;
integer errors;

//---------------------------------------------------------------
// 时钟：上升沿在 10/30/50/...，下降沿在 20/40/60/...
//---------------------------------------------------------------
initial clk = 1'b0;
always #10 clk = ~clk;

//---------------------------------------------------------------
// 通用检查：!== 同时检查数值不等和未知值
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

//---------------------------------------------------------------
// 组合读口检查：设置地址后等待稳定，不等待时钟沿
//---------------------------------------------------------------
task check_csr;
input [11:0] addr;
input [31:0] exp_val;
begin
    csr_rd_en_i = 1'b1;
    csr_rd_addr_i = addr;
    #1;
    if (csr_rdata_o !== exp_val) begin
        $display("FAIL [%0t] CSR[%h]: actual=%h expected=%h",
                 $time, addr, csr_rdata_o, exp_val);
        errors = errors + 1;
    end
end
endtask

// 同时检查五个 CSR 和两个独立硬件输出。
// 所有预期值由测试流程显式传入，不使用 DUT 的更新公式推算。
task check_state;
input [31:0] exp_mstatus;
input [31:0] exp_mtvec;
input [31:0] exp_mscratch;
input [31:0] exp_mepc;
input [31:0] exp_mcause;
begin
    check_csr(12'h300, exp_mstatus);
    check_csr(12'h305, exp_mtvec);
    check_csr(12'h340, exp_mscratch);
    check_csr(12'h341, exp_mepc);
    check_csr(12'h342, exp_mcause);
    check("mtvec_o", mtvec_o, exp_mtvec);
    check("mepc_o", mepc_o, exp_mepc);
end
endtask

//---------------------------------------------------------------
// 清除更新请求：不修改读口或已经保存的状态
//---------------------------------------------------------------
task clear_requests;
begin
    csr_wr_en_i = 1'b0;
    trap_enter_i = 1'b0;
    trap_return_i = 1'b0;
end
endtask

//---------------------------------------------------------------
// CSR 指令写通道：负沿驱动，只覆盖一个更新上升沿
//---------------------------------------------------------------
task write_csr;
input [11:0] addr;
input [2:0] op;
input [31:0] src;
begin
    @(negedge clk);
    clear_requests;
    csr_wr_en_i = 1'b1;
    csr_wr_addr_i = addr;
    csr_type_i = op;
    csr_src_data_i = src;

    @(posedge clk); #1;
    @(negedge clk);
    csr_wr_en_i = 1'b0;
end
endtask

//---------------------------------------------------------------
// 异常入口/返回：先撤销事件，再做耗时的多寄存器读检查
//---------------------------------------------------------------
task enter_trap;
input [31:0] pc;
input [31:0] cause;
begin
    @(negedge clk);
    clear_requests;
    csr_type_i = 3'b000; // 事件更新不依赖 CSR 指令类型合法
    trap_enter_i = 1'b1;
    trap_pc_i = pc;
    trap_cause_i = cause;
    @(posedge clk); #1;
    @(negedge clk);
    trap_enter_i = 1'b0;
end
endtask

task return_trap;
begin
    @(negedge clk);
    clear_requests;
    trap_return_i = 1'b1;
    @(posedge clk); #1;
    @(negedge clk);
    trap_return_i = 1'b0;
end
endtask

//---------------------------------------------------------------
// 初始化、激励与检查
//---------------------------------------------------------------
// 检查新CSR和资格；预期由激励表明确给定。
task check_irq;
input [31:0] exp_mie;
input [31:0] exp_mip;
input exp_eligible;
begin
    check_csr(12'h304, exp_mie);
    check_csr(12'h344, exp_mip);
    check("irq_eligible_o", {31'b0,irq_eligible_o}, {31'b0,exp_eligible});
end
endtask

initial begin
    errors = 0;
    rst_n = 1'b0;
    clear_requests;
    csr_rd_en_i = 1'b0;
    csr_type_i = 3'b000;
    csr_wr_addr_i = 12'b0;
    csr_src_data_i = 32'b0;
    csr_rd_addr_i = 12'b0;
    trap_pc_i = 32'b0;
    trap_cause_i = 32'b0;
    // 复位不应替外部来源清请求；mip在复位期间仍反映输入。
    irq_external_i = 1'b1;
    #15;
    check_irq(32'h0, 32'h800, 1'b0);
    check_state(32'h1800, 32'h0, 32'h0, 32'h0, 32'h0);
    @(negedge clk);
    rst_n = 1'b1;
    irq_external_i = 1'b0;
    #1;
    check_irq(32'h0, 32'h0, 1'b0);

    // 初始化其他CSR，之后核对新增访问不会破坏它们。
    write_csr(12'h305, 3'b001, 32'h100);
    write_csr(12'h340, 3'b001, 32'h55);
    write_csr(12'h341, 3'b001, 32'h44);
    write_csr(12'h342, 3'b001, 32'd2);

    // mie：WRITE/SET/CLEAR的六种操作类型及只保留bit11。
    write_csr(12'h304, 3'b001, 32'hFFFFFFFF);
    check_irq(32'h800, 32'h0, 1'b0);
    write_csr(12'h304, 3'b011, 32'hFFFFF7FF);
    check_csr(12'h304, 32'h800); // 清其他位不影响MEIE
    write_csr(12'h304, 3'b011, 32'h800);
    check_csr(12'h304, 32'h0);
    write_csr(12'h304, 3'b010, 32'hFFFFFFFF);
    check_csr(12'h304, 32'h800);
    write_csr(12'h304, 3'b101, 32'hFFFFF7FF);
    check_csr(12'h304, 32'h0);
    write_csr(12'h304, 3'b110, 32'hFFFFFFFF);
    check_csr(12'h304, 32'h800);
    write_csr(12'h304, 3'b111, 32'h800);
    check_csr(12'h304, 32'h0);
    write_csr(12'h304, 3'b001, 32'h800);

    // 非法类型、未知地址、无写使能都不能改变mie。
    write_csr(12'h304, 3'b000, 32'h0);
    write_csr(12'h304, 3'b100, 32'h0);
    write_csr(12'hFFF, 3'b001, 32'hFFFFFFFF);
    check_csr(12'h304, 32'h800);
    @(negedge clk);
    clear_requests;
    csr_wr_addr_i = 12'h304;
    csr_type_i = 3'b001;
    csr_src_data_i = 32'h0;
    @(posedge clk); #1;
    check_csr(12'h304, 32'h800);
    check_state(32'h1800, 32'h100, 32'h55, 32'h44, 32'd2);

    // 三个条件的完整真值表：只有111具备资格。
    // 先在负沿撤销外部请求，完成许可写入后再施加本行请求。
    for (combination = 0; combination < 8; combination = combination + 1) begin
        @(negedge clk);
        irq_external_i = 1'b0;
        write_csr(12'h300, 3'b001, combination[1] ? 32'h8 : 32'h0);
        write_csr(12'h304, 3'b001, combination[0] ? 32'h800 : 32'h0);
        @(negedge clk);
        irq_external_i = combination[2];
        #1;
        check_irq(combination[0] ? 32'h800 : 32'h0,
                  combination[2] ? 32'h800 : 32'h0,
                  combination == 7);
    end
    // 最后一行状态：请求=1、MEIE=1、MIE=1。
    check_state(32'h1808, 32'h100, 32'h55, 32'h44, 32'd2);

    // 关闭读口不能屏蔽资格；同一负沿之后撤销请求，无需更新沿。
    @(negedge clk);
    csr_rd_en_i = 1'b0;
    #1;
    check("disabled read", csr_rdata_o, 32'h0);
    check("eligible with read disabled", {31'b0,irq_eligible_o}, 32'd1);
    irq_external_i = 1'b0;
    #1;
    check("eligible withdrawn before clock", {31'b0,irq_eligible_o}, 32'd0);
    check_csr(12'h344, 32'h0);
    irq_external_i = 1'b1;
    #1;
    check_irq(32'h800, 32'h800, 1'b1);

    // 软件对mip的六种写操作均忽略；高、低输入各验证一次。
    for (combination = 0; combination < 2; combination = combination + 1) begin
        @(negedge clk);
        irq_external_i = combination[0];
        for (op_index = 0; op_index < 6; op_index = op_index + 1) begin
            case (op_index)
                0: test_op = 3'b001;
                1: test_op = 3'b010;
                2: test_op = 3'b011;
                3: test_op = 3'b101;
                4: test_op = 3'b110;
                5: test_op = 3'b111;
            endcase
            write_csr(12'h344, test_op, combination == 0 ? 32'hFFFFFFFF : 32'h0);
            check_irq(32'h800, combination == 0 ? 32'h0 : 32'h800,
                      combination == 1);
            check_state(32'h1808, 32'h100, 32'h55, 32'h44, 32'd2);
        end
    end

    // 资格只是组合条件：保持多个沿不会自动生成入口或更改CSR。
    repeat (3) @(posedge clk);
    #1;
    check_irq(32'h800, 32'h800, 1'b1);
    check_state(32'h1808, 32'h100, 32'h55, 32'h44, 32'd2);

    // 单元TB手动施加入/返事件；原因11沿用原单元测试样例，
    // 此处不代表CPU已接入外部中断入口或自动生成中断原因。
    enter_trap(32'hA0, 32'd11);
    check_irq(32'h800, 32'h800, 1'b0);
    check_state(32'h1880, 32'h100, 32'h55, 32'hA0, 32'd11);
    return_trap;
    check_irq(32'h800, 32'h800, 1'b1);
    check_state(32'h1888, 32'h100, 32'h55, 32'hA0, 32'd11);

    // MIE原本为0时，返回也不能无条件开放资格。
    write_csr(12'h300, 3'b001, 32'h0);
    enter_trap(32'hA4, 32'd2);
    check_irq(32'h800, 32'h800, 1'b0);
    check_csr(12'h300, 32'h1800);
    return_trap;
    check_irq(32'h800, 32'h800, 1'b0);
    check_csr(12'h300, 32'h1880);

    // 入口 > 返回和mie写：尝试清MEIE，最终仍应保留。
    write_csr(12'h300, 3'b001, 32'h8);
    @(negedge clk);
    clear_requests;
    trap_enter_i = 1'b1;
    trap_return_i = 1'b1;
    trap_pc_i = 32'hB0;
    trap_cause_i = 32'd2;
    csr_wr_en_i = 1'b1;
    csr_wr_addr_i = 12'h304;
    csr_type_i = 3'b001;
    csr_src_data_i = 32'h0;
    @(posedge clk); #1;
    @(negedge clk);
    clear_requests; // 外部请求必须仍然保持为1
    check_irq(32'h800, 32'h800, 1'b0);
    check_state(32'h1880, 32'h100, 32'h55, 32'hB0, 32'd2);

    // 返回 > mie写：恢复MIE而不接受同时发生的MEIE清零。
    @(negedge clk);
    trap_return_i = 1'b1;
    csr_wr_en_i = 1'b1;
    csr_wr_addr_i = 12'h304;
    csr_type_i = 3'b001;
    csr_src_data_i = 32'h0;
    @(posedge clk); #1;
    @(negedge clk);
    clear_requests;
    check_irq(32'h800, 32'h800, 1'b1);
    check_state(32'h1888, 32'h100, 32'h55, 32'hB0, 32'd2);

    // 同步复位优先级及mie复位；请求来源仍保持高电平。
    @(negedge clk);
    rst_n = 1'b0;
    trap_enter_i = 1'b1;
    trap_return_i = 1'b1;
    csr_wr_en_i = 1'b1;
    csr_wr_addr_i = 12'h304;
    csr_type_i = 3'b001;
    csr_src_data_i = 32'hFFFFFFFF;
    #1;
    check_csr(12'h304, 32'h800); // 沿前尚未复位
    @(posedge clk); #1;
    @(negedge clk);
    clear_requests;
    check_irq(32'h0, 32'h800, 1'b0);
    check_state(32'h1800, 32'h0, 32'h0, 32'h0, 32'h0);
    @(negedge clk);
    rst_n = 1'b1;
    irq_external_i = 1'b0;
    #1;
    check_irq(32'h0, 32'h0, 1'b0);

    if (errors == 0) begin
        $display("PASS: CSR IRQ unit checks passed");
        $finish;
    end else begin
        $fatal(1,"FAIL: %0d CSR IRQ unit checks failed",errors);
    end
end

initial begin
    #20000;
    $fatal(1,"FAIL: CSR IRQ unit test timeout");
end

csr_unit u_csr_unit (
    .clk(clk),
    .rst_n(rst_n),
    .csr_wr_en_i(csr_wr_en_i),
    .csr_rd_en_i(csr_rd_en_i),
    .csr_type_i(csr_type_i),
    .csr_wr_addr_i(csr_wr_addr_i),
    .csr_src_data_i(csr_src_data_i),
    .trap_enter_i(trap_enter_i),
    .trap_pc_i(trap_pc_i),
    .trap_cause_i(trap_cause_i),
    .trap_return_i(trap_return_i),
    .irq_external_i(irq_external_i),
    .irq_eligible_o(irq_eligible_o),
    .mtvec_o(mtvec_o),
    .mepc_o(mepc_o),
    .csr_rd_addr_i(csr_rd_addr_i),
    .csr_rdata_o(csr_rdata_o)
);
endmodule

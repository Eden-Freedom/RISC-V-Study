`timescale 1ns / 1ps

// 直接验证 csr_unit，不依赖 instruction_rom、EX 或完整流水线。
module tb_csr_unit();

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
initial begin
    errors = 0;
    rst_n = 1'b0;
    csr_wr_en_i = 1'b0;
    csr_rd_en_i = 1'b0;
    csr_type_i = 3'b000;
    csr_wr_addr_i = 12'b0;
    csr_src_data_i = 32'b0;
    csr_rd_addr_i = 12'b0;
    trap_enter_i = 1'b0;
    trap_return_i = 1'b0;
    trap_pc_i = 32'b0;
    trap_cause_i = 32'b0;

    // t=15ns：已经经过一个同步复位上升沿。
    #15;
    check_state(32'h1800, 32'h0, 32'h0, 32'h0, 32'h0);
    @(negedge clk);
    rst_n = 1'b1;

    // ----------------------------------------------------------
    // 字段限制：只有 MIE/MPIE 可变，MPP 固定为 3。
    // ----------------------------------------------------------
    write_csr(12'h300, 3'b001, 32'hFFFFFFFF);
    check_csr(12'h300, 32'h1888);

    // 尝试 CLEAR MPP，固定字段不能被清除。
    write_csr(12'h300, 3'b011, 32'h00001800);
    check_csr(12'h300, 32'h1888);
    write_csr(12'h300, 3'b011, 32'hFFFFFFFF);
    check_csr(12'h300, 32'h1800);
    write_csr(12'h300, 3'b010, 32'h00000088);
    check_csr(12'h300, 32'h1888);
    // 立即数型仍由外部提供已选择/扩展的源数据。
    write_csr(12'h300, 3'b111, 32'h00000008);
    check_csr(12'h300, 32'h1880);

    // ----------------------------------------------------------
    // 地址对齐和普通 32 位存储。
    // ----------------------------------------------------------
    write_csr(12'h305, 3'b001, 32'h00000103);
    check_csr(12'h305, 32'h00000100);
    write_csr(12'h341, 3'b001, 32'h00000027);
    check_csr(12'h341, 32'h00000024);
    write_csr(12'h340, 3'b001, 32'h00000055);
    write_csr(12'h342, 3'b001, 32'h000000A5);
    check_state(32'h1880, 32'h100, 32'h55, 32'h24, 32'hA5);

    // 关闭读口后，独立硬件输出仍保留当前地址。
    csr_rd_addr_i = 12'h305;
    csr_rd_en_i = 1'b0;
    #1;
    check("disabled CSR read", csr_rdata_o, 32'h0);
    check("mtvec with read disabled", mtvec_o, 32'h100);
    check("mepc with read disabled", mepc_o, 32'h24);

    // ----------------------------------------------------------
    // 无效访问：非法类型、未实现地址、写使能关闭。
    // ----------------------------------------------------------
    write_csr(12'h300, 3'b000, 32'hFFFFFFFF);
    write_csr(12'h340, 3'b100, 32'hFFFFFFFF);
    write_csr(12'hFFF, 3'b001, 32'hFFFFFFFF);
    check_state(32'h1880, 32'h100, 32'h55, 32'h24, 32'hA5);
    check_csr(12'hFFF, 32'h0);

    @(negedge clk);
    clear_requests;
    csr_type_i = 3'b001;
    csr_wr_addr_i = 12'h340;
    csr_src_data_i = 32'hDEADBEEF;
    @(posedge clk); #1;
    check_state(32'h1880, 32'h100, 32'h55, 32'h24, 32'hA5);

    // ----------------------------------------------------------
    // MIE=1：入口保存许可，返回恢复；配置和临时数据保持。
    // ----------------------------------------------------------
    write_csr(12'h300, 3'b001, 32'h00000008);
    check_csr(12'h300, 32'h1808);
    enter_trap(32'h00000023, 32'd11);
    check_state(32'h1880, 32'h100, 32'h55, 32'h20, 32'd11);
    return_trap;
    check_state(32'h1888, 32'h100, 32'h55, 32'h20, 32'd11);

    // MIE=0：返回不能无条件打开中断。
    write_csr(12'h300, 3'b001, 32'h00000000);
    enter_trap(32'h00000043, 32'd11);
    check_state(32'h1800, 32'h100, 32'h55, 32'h40, 32'd11);

    // 模拟处理程序通过 CSR 指令调整返回地址。
    write_csr(12'h341, 3'b001, 32'h00000045);
    check_csr(12'h341, 32'h44);
    return_trap;
    check_state(32'h1880, 32'h100, 32'h55, 32'h44, 32'd11);

    // ----------------------------------------------------------
    // 入口 > 返回、CSR 指令写：同时请求时，只执行入口。
    // 软件试图改 mscratch，验证优先级覆盖整个单元。
    // ----------------------------------------------------------
    write_csr(12'h300, 3'b001, 32'h00000008);
    @(negedge clk);
    trap_enter_i = 1'b1;
    trap_return_i = 1'b1;
    trap_pc_i = 32'h00000083;
    trap_cause_i = 32'd3;
    csr_wr_en_i = 1'b1;
    csr_type_i = 3'b001;
    csr_wr_addr_i = 12'h340;
    csr_src_data_i = 32'hAA;
    @(posedge clk); #1;
    @(negedge clk);
    clear_requests;
    check_state(32'h1880, 32'h100, 32'h55, 32'h80, 32'd3);

    // 返回 > CSR 指令写：返回恢复许可，但不接受 mscratch 写。
    write_csr(12'h300, 3'b001, 32'h00000000);
    @(negedge clk);
    trap_return_i = 1'b1;
    csr_wr_en_i = 1'b1;
    csr_type_i = 3'b001;
    csr_wr_addr_i = 12'h340;
    csr_src_data_i = 32'hAA;
    @(posedge clk); #1;
    @(negedge clk);
    clear_requests;
    check_state(32'h1880, 32'h100, 32'h55, 32'h80, 32'd3);

    // ----------------------------------------------------------
    // 复位 > 全部请求；低有效同步复位只在上升沿更新。
    // ----------------------------------------------------------
    @(negedge clk);
    rst_n = 1'b0;
    trap_enter_i = 1'b1;
    trap_return_i = 1'b1;
    trap_pc_i = 32'h000000B3;
    trap_cause_i = 32'd11;
    csr_wr_en_i = 1'b1;
    csr_type_i = 3'b001;
    csr_wr_addr_i = 12'h300;
    csr_src_data_i = 32'hFFFFFFFF;
    #1;
    check("synchronous reset before edge",
          u_csr_unit.mscratch_reg, 32'h55);
    @(posedge clk); #1;
    @(negedge clk);
    clear_requests;
    check_state(32'h1800, 32'h0, 32'h0, 32'h0, 32'h0);

    @(negedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);
    #1;
    check_state(32'h1800, 32'h0, 32'h0, 32'h0, 32'h0);

    if (errors == 0) begin
        $display("PASS: CSR unit checks passed");
        $finish;
    end else begin
        $display("FAIL: %0d CSR unit checks failed", errors);
        $fatal(1, "CSR unit self-check failed");
    end
end

//---------------------------------------------------------------
// 超时退出，防止遗漏等待事件导致仿真无结束
//---------------------------------------------------------------
initial begin
    #10000;
    $fatal(1, "FAIL: CSR unit test timeout");
end

//---------------------------------------------------------------
// DUT
//---------------------------------------------------------------
csr_unit u_csr_unit(
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
    .mtvec_o(mtvec_o),
    .mepc_o(mepc_o),
    .csr_rd_addr_i(csr_rd_addr_i),
    .csr_rdata_o(csr_rdata_o)
);

endmodule

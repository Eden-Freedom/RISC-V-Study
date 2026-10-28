`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/19 16:19:56
// Design Name: 
// Module Name: tb_addi_core
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


module tb_addi_core();
reg clk;
reg rst_n;
wire [31:0] pc_o;
wire [31:0] instr_o;
wire wr_en;
wire [4:0] wr_addr;
wire [31:0] wr_data;

integer errors;


initial begin
    clk = 0;
    rst_n = 0;
    #25
    rst_n = 1;
end

always #10 clk = ~clk;

addi_core u_addi_core(
    .clk(clk),
    .rst_n(rst_n),
    .pc_o(pc_o),
    .instr_o(instr_o),
    .wr_en(wr_en),
    .wr_addr(wr_addr),
    .wr_data(wr_data)
);

initial begin
    $monitor("time =%dns,pc_o = %h,instr_o = %h,x3 = %h,x4 = %h,x5 = %h, x6 = %h memory16 = %h ram_wr_sel_o = %b,ram_wr_addr_o = %h,ram_wr_data_o = %h",
    $time,
    pc_o,
    instr_o,
    u_addi_core.regfile_inst.reg_file[3],
    u_addi_core.regfile_inst.reg_file[4],
    u_addi_core.regfile_inst.reg_file[5],
    u_addi_core.regfile_inst.reg_file[6],
    u_addi_core.ram_inst.memory[16],
    u_addi_core.ram_wr_sel_o,
    u_addi_core.ram_wr_addr_o,
    u_addi_core.ram_wr_data_o
    );
end


initial begin
    errors = 0;

    // 等待复位结束，再给短程序留出执行时间
    wait (rst_n === 1'b1);
    repeat (20) @(negedge clk);

    // 第1项检查：这里的预期值按你的测试程序填写
    if (u_addi_core.regfile_inst.reg_file[4] !== 32'h00000080) begin
        $display("FAIL x4: actual=%h expected=%h",
                 u_addi_core.regfile_inst.reg_file[4],
                 32'h00000080);
        errors = errors + 1;
    end

    // 在这里继续写第2～6项检查
    if (u_addi_core.regfile_inst.reg_file[5] !== 32'hFFFFFF80) begin
        $display("FAIL x5: actual=%h expected=%h",
                 u_addi_core.regfile_inst.reg_file[5],
                 32'hFFFFFF80);
        errors = errors + 1;
    end
    
    if (u_addi_core.regfile_inst.reg_file[6] !== 32'h00001280) begin
        $display("FAIL x6: actual=%h expected=%h",
                 u_addi_core.regfile_inst.reg_file[6],
                 32'h00001280);
        errors = errors + 1;
    end

    if (u_addi_core.regfile_inst.reg_file[7] !== 32'hFFFFFF80) begin
        $display("FAIL x7: actual=%h expected=%h",
                 u_addi_core.regfile_inst.reg_file[7],
                 32'hFFFFFF80);
        errors = errors + 1;
    end

    if (u_addi_core.regfile_inst.reg_file[8] !== 32'hFF805678) begin
        $display("FAIL x8: actual=%h expected=%h",
                 u_addi_core.regfile_inst.reg_file[8],
                 32'hFF805678);
        errors = errors + 1;
    end

    if (u_addi_core.ram_inst.memory[16] !== 32'hFF805678) begin
        $display("FAIL memory16: actual=%h expected=%h",
                 u_addi_core.ram_inst.memory[16],
                 32'hFF805678);
        errors = errors + 1;
    end
    // 各项用独立的if，不要写成else if

    // 所有检查完成后，统一汇总
    if (errors == 0) begin
        $display("PASS: all checks passed");
    end else begin
        $display("FAIL: %0d checks failed", errors);
    end

    $finish;
end


endmodule

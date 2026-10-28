`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/23 10:00:00
// Design Name: 
// Module Name: tb_pipeline_core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for pipeline_core (top)
//              - verify fetch / if_id / decode / id_ex / ex / regfile
//              - check if_id and id_ex bundles advance per cycle, no field crossing
//              - check nop creates bubble (valid_idex_o=0)
//              - check regfile writeback values (x1..x31)
//              - check x0 correctness via READ PORT, not via reg_file[0]
//              - check wr_en/addr/data at EVERY posedge BEFORE NBA update
// 
// Dependencies: pipeline_core.v (and its sub-modules)
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_pipeline_core();

    reg clk;
    reg rst_n;

    integer errors;

    //---------------------------------------------------------------
    // 时钟：上升沿在 10/30/50/...，下降沿在 20/40/60/...
    //---------------------------------------------------------------
    initial clk = 1'b0;
    always #10 clk = ~clk;

    //---------------------------------------------------------------
    // 检查：if_id 流水寄存器
    //---------------------------------------------------------------
    task check_if_id;
        input        exp_valid;
        input [31:0] exp_pc;
        input [31:0] exp_instr;
        begin
            if (u_pipeline_core.valid_ifid_o !== exp_valid) begin
                $display("FAIL [%0t] valid_ifid_o: actual=%b expected=%b",
                         $time, u_pipeline_core.valid_ifid_o, exp_valid);
                errors = errors + 1;
            end
            if (u_pipeline_core.pc_ifid_o !== exp_pc) begin
                $display("FAIL [%0t] pc_ifid_o: actual=%h expected=%h",
                         $time, u_pipeline_core.pc_ifid_o, exp_pc);
                errors = errors + 1;
            end
            if (u_pipeline_core.instr_ifid_o !== exp_instr) begin
                $display("FAIL [%0t] instr_ifid_o: actual=%h expected=%h",
                         $time, u_pipeline_core.instr_ifid_o, exp_instr);
                errors = errors + 1;
            end
        end
    endtask

    //---------------------------------------------------------------
    // 检查：id_ex 流水寄存器
    //---------------------------------------------------------------
    task check_id_ex;
        input        exp_valid;
        input [31:0] exp_pc;
        input [4:0]  exp_rd;
        input        exp_addi;
        input        exp_add;
        input        exp_sub;
        begin
            if (u_pipeline_core.valid_idex_o !== exp_valid) begin
                $display("FAIL [%0t] valid_idex_o: actual=%b expected=%b",
                         $time, u_pipeline_core.valid_idex_o, exp_valid);
                errors = errors + 1;
            end
            if (u_pipeline_core.pc_idex_o !== exp_pc) begin
                $display("FAIL [%0t] pc_idex_o: actual=%h expected=%h",
                         $time, u_pipeline_core.pc_idex_o, exp_pc);
                errors = errors + 1;
            end
            if (u_pipeline_core.rd_addr_idex_o !== exp_rd) begin
                $display("FAIL [%0t] rd_addr_idex_o: actual=%h expected=%h",
                         $time, u_pipeline_core.rd_addr_idex_o, exp_rd);
                errors = errors + 1;
            end
            if (u_pipeline_core.is_addi_idex_o !== exp_addi) begin
                $display("FAIL [%0t] is_addi_idex_o: actual=%b expected=%b",
                         $time, u_pipeline_core.is_addi_idex_o, exp_addi);
                errors = errors + 1;
            end
            if (u_pipeline_core.is_add_idex_o !== exp_add) begin
                $display("FAIL [%0t] is_add_idex_o: actual=%b expected=%b",
                         $time, u_pipeline_core.is_add_idex_o, exp_add);
                errors = errors + 1;
            end
            if (u_pipeline_core.is_sub_idex_o !== exp_sub) begin
                $display("FAIL [%0t] is_sub_idex_o: actual=%b expected=%b",
                         $time, u_pipeline_core.is_sub_idex_o, exp_sub);
                errors = errors + 1;
            end
        end
    endtask

    //---------------------------------------------------------------
    // 检查：reg_file 数组（仅用于 x1..x31；不能用于 x0）
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
    // 检查：x0 —— 通过实际读口验证，而不是 reg_file[0]
    //---------------------------------------------------------------
    task check_x0_read_ports;
        begin
            if (u_pipeline_core.regfile_inst.rs1_addr_i !== 5'd0) begin
                $display("FAIL [%0t] rs1_addr_i: actual=%h expected=%h (must be 0 to verify x0 read)",
                         $time, u_pipeline_core.regfile_inst.rs1_addr_i, 5'd0);
                errors = errors + 1;
            end
            if (u_pipeline_core.regfile_inst.rs1_data_o !== 32'h0) begin
                $display("FAIL [%0t] rs1_data_o: actual=%h expected=%h (x0 read port)",
                         $time, u_pipeline_core.regfile_inst.rs1_data_o, 32'h0);
                errors = errors + 1;
            end
            if (u_pipeline_core.regfile_inst.rs2_addr_i !== 5'd0) begin
                $display("FAIL [%0t] rs2_addr_i: actual=%h expected=%h (must be 0 to verify x0 read)",
                         $time, u_pipeline_core.regfile_inst.rs2_addr_i, 5'd0);
                errors = errors + 1;
            end
            if (u_pipeline_core.regfile_inst.rs2_data_o !== 32'h0) begin
                $display("FAIL [%0t] rs2_data_o: actual=%h expected=%h (x0 read port)",
                         $time, u_pipeline_core.regfile_inst.rs2_data_o, 32'h0);
                errors = errors + 1;
            end
        end
    endtask

    //---------------------------------------------------------------
    // 检查：pc_o
    //---------------------------------------------------------------
    task check_pc;
        input [31:0] exp_pc;
        begin
            if (u_pipeline_core.pc_o !== exp_pc) begin
                $display("FAIL [%0t] pc_o: actual=%h expected=%h",
                         $time, u_pipeline_core.pc_o, exp_pc);
                errors = errors + 1;
            end
        end
    endtask

    //---------------------------------------------------------------
    // 检查：本沿将要写入的值 (在 posedge, NBL 更新前采样)
    //---------------------------------------------------------------
    task check_wr;
        input        exp_en;
        input [4:0]  exp_addr;
        input [31:0] exp_data;
        begin
            if (u_pipeline_core.wr_en_ex_o !== exp_en) begin
                $display("FAIL [%0t] wr_en_ex_o: actual=%b expected=%b",
                         $time, u_pipeline_core.wr_en_ex_o, exp_en);
                errors = errors + 1;
            end
            if (u_pipeline_core.wr_addr_ex_o !== exp_addr) begin
                $display("FAIL [%0t] wr_addr_ex_o: actual=%h expected=%h",
                         $time, u_pipeline_core.wr_addr_ex_o, exp_addr);
                errors = errors + 1;
            end
            if (u_pipeline_core.wr_data_ex_o !== exp_data) begin
                $display("FAIL [%0t] wr_data_ex_o: actual=%h expected=%h",
                         $time, u_pipeline_core.wr_data_ex_o, exp_data);
                errors = errors + 1;
            end
        end
    endtask

    //---------------------------------------------------------------
    // 每个上升沿、NBL 更新前，检查本沿 wr_*
    //
    // 该 always 块在 active region 执行，而所有 <= 写入在 NBA region
    // 执行；所以此处读到的 wr_* 是 id_ex 上拍内容驱动的 ex 组合输出，
    // 也就是本沿真正要写入 regfile 的值。
    //
    // 期望值（按 imem 内短程序与 id_ex 每拍延迟 1 拍推导）：
    //   t=10 : rst=0                              — 不检查
    //   t=30 : id_ex 旧值 = 复位值                → (0,0,0)
    //   t=50 : id_ex 旧值 = t=30 采的 (全 0)      → (0,0,0)
    //   t=70 : id_ex 旧值 = t=50 采的 addi x1     → (1, 1, 5)
    //   t=90 : id_ex 旧值 = t=70 采的 addi x2     → (1, 2, 7)
    //   t=110: id_ex 旧值 = t=90 采的 addi x3     → (1, 3, 0xFFFFFFFF)
    //   t=130: id_ex 旧值 = t=110 采的 add x4     → (1, 4, 0)
    //   t=150: id_ex 旧值 = t=130 采的 sub x5     → (1, 5, 0)
    //   t=170: id_ex 旧值 = t=150 采的 nop(bubble)→ (0,0,0)
    //   t=190: id_ex 旧值 = t=170 采的 nop(bubble)→ (0,0,0)
    //---------------------------------------------------------------
    integer posedge_cnt;
    initial posedge_cnt = 0;

    always @(posedge clk) begin
        if (rst_n) begin
            case (posedge_cnt)
                1: check_wr(1'b0, 5'd0, 32'h0000_0000);
                2: check_wr(1'b0, 5'd0, 32'h0000_0000);
                3: check_wr(1'b1, 5'd1, 32'd5);
                4: check_wr(1'b1, 5'd2, 32'd7);
                5: check_wr(1'b1, 5'd3, 32'hFFFF_FFFF);
                6: check_wr(1'b1, 5'd4, 32'h0000_0000);
                7: check_wr(1'b1, 5'd5, 32'h0000_0000);
                8: check_wr(1'b0, 5'd0, 32'h0000_0000);
                9: check_wr(1'b0, 5'd0, 32'h0000_0000);
                default: ;
            endcase
        end
        posedge_cnt = posedge_cnt + 1;
    end

    //---------------------------------------------------------------
    // 激励与沿后检查
    //---------------------------------------------------------------
    initial begin
        rst_n  = 1'b0;
        errors = 0;

        // t=15ns：复位期间
        #15;
        check_pc   (32'h0000_0000);
        check_if_id(1'b0, 32'h0000_0000, 32'h0000_0000);
        check_id_ex(1'b0, 32'h0000_0000, 5'h00, 1'b0, 1'b0, 1'b0);
        check_regfile(5'd1, 32'h0000_0000);
        check_regfile(5'd2, 32'h0000_0000);
        check_regfile(5'd3, 32'h0000_0000);
        check_regfile(5'd4, 32'h0000_0000);
        check_regfile(5'd5, 32'h0000_0000);

        // t=25ns：释放复位
        #10;
        rst_n = 1'b1;

        // t=31ns
        @(posedge clk); #1;
        check_pc   (32'h0000_0004);
        check_if_id(1'b1, 32'h0000_0000, 32'h00500093);
        check_id_ex(1'b0, 32'h0000_0000, 5'h00, 1'b0, 1'b0, 1'b0);

        // t=51ns
        @(posedge clk); #1;
        check_pc   (32'h0000_0008);
        check_if_id(1'b1, 32'h0000_0004, 32'h00700113);
        check_id_ex(1'b1, 32'h0000_0000, 5'd1 , 1'b1, 1'b0, 1'b0);

        // t=71ns
        @(posedge clk); #1;
        check_pc   (32'h0000_000C);
        check_if_id(1'b1, 32'h0000_0008, 32'hFFF00193);
        check_id_ex(1'b1, 32'h0000_0004, 5'd2 , 1'b1, 1'b0, 1'b0);
        check_regfile(5'd1, 32'd5);
        check_regfile(5'd2, 32'h0000_0000);

        // t=91ns
        @(posedge clk); #1;
        check_pc   (32'h0000_0010);
        check_if_id(1'b1, 32'h0000_000C, 32'h00000233);
        check_id_ex(1'b1, 32'h0000_0008, 5'd3 , 1'b1, 1'b0, 1'b0);
        check_regfile(5'd1, 32'd5);
        check_regfile(5'd2, 32'd7);

        // t=111ns
        @(posedge clk); #1;
        check_pc   (32'h0000_0014);
        check_if_id(1'b1, 32'h0000_0010, 32'h400002B3);
        check_id_ex(1'b1, 32'h0000_000C, 5'd4 , 1'b0, 1'b1, 1'b0);
        check_regfile(5'd2, 32'd7);
        check_regfile(5'd3, 32'hFFFF_FFFF);

        // t=131ns
        @(posedge clk); #1;
        check_pc   (32'h0000_0018);
        check_if_id(1'b1, 32'h0000_0014, 32'h0000_0000);
        check_id_ex(1'b1, 32'h0000_0010, 5'd5 , 1'b0, 1'b0, 1'b1);
        check_regfile(5'd3, 32'hFFFF_FFFF);
        check_regfile(5'd4, 32'h0000_0000);

        // t=151ns
        @(posedge clk); #1;
        check_pc   (32'h0000_001C);
        check_if_id(1'b1, 32'h0000_0018, 32'h0000_0000);
        check_id_ex(1'b0, 32'h0000_0014, 5'd0 , 1'b0, 1'b0, 1'b0);
        check_regfile(5'd4, 32'h0000_0000);
        check_regfile(5'd5, 32'h0000_0000);

        // t=171ns：id_ex 继续 bubble；x0 用读口验证
        @(posedge clk); #1;
        check_pc   (32'h0000_0020);
        check_id_ex(1'b0, 32'h0000_0018, 5'd0 , 1'b0, 1'b0, 1'b0);
        check_x0_read_ports;

        // t=176ns：最终检查
        #5;
        check_regfile(5'd1, 32'd5);
        check_regfile(5'd2, 32'd7);
        check_regfile(5'd3, 32'hFFFF_FFFF);
        check_regfile(5'd4, 32'h0000_0000);
        check_regfile(5'd5, 32'h0000_0000);
        check_regfile(5'd6, 32'h0000_0000);
        check_regfile(5'd31, 32'h0000_0000);
        check_x0_read_ports;

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
    pipeline_core u_pipeline_core(
        .clk  (clk),
        .rst_n(rst_n)
    );

endmodule
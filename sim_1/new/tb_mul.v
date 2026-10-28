`timescale 1ns / 1ps

// Assistant-authored testbench, requested by the learner.
// Style follows the current Vivado tb_check.v: tasks, errors, !== and #1.
// Install the matching mul_imem_case.txt entries in imem before simulation.
// Checks include both JALs and their commits. No Python or run-time reference
// multiplication is used by this testbench.
module tb_mul();

reg clk;
reg rst_n;
integer errors;
integer checked;
integer mul_checked;

localparam [31:0] DONE_PC = 32'h000000E8;
localparam integer EXPECTED_CHECKS = 57;
localparam integer EXPECTED_MUL_CHECKS = 35;

//---------------------------------------------------------------
// DUT and clock: posedge at 10/30/50/... ns
//---------------------------------------------------------------
pipeline_core u_pipeline_core (
    .clk  (clk),
    .rst_n(rst_n)
);

initial clk = 1'b0;
always #10 clk = ~clk;

//---------------------------------------------------------------
// Shared comparison: !== detects X/Z as well as wrong values.
//---------------------------------------------------------------
task check_value;
    input [383:0] label;
    input [31:0] actual;
    input [31:0] expected;
    begin
        if (actual !== expected) begin
            $display("FAIL [%0t] EX pc=%h %0s: actual=%h expected=%h",
                     $time, u_pipeline_core.pc_idex_o,
                     label, actual, expected);
            errors = errors + 1;
        end
    end
endtask

//---------------------------------------------------------------
// Architectural storage: x1..x31 only. Never inspect reg_file[0].
//---------------------------------------------------------------
task check_regfile;
    input [4:0] idx;
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

task check_ex;
    input exp_en;
    input [4:0] exp_addr;
    input [31:0] exp_data;
    begin
        check_value("wr_en_ex_o", u_pipeline_core.wr_en_ex_o, exp_en);
        check_value("wr_addr_ex_o", u_pipeline_core.wr_addr_ex_o, exp_addr);
        check_value("wr_data_ex_o", u_pipeline_core.wr_data_ex_o, exp_data);
    end
endtask

task check_idex;
    input [31:0] exp_rs1;
    input [31:0] exp_rs2;
    begin
        check_value("rs1_data_idex_o",
                    u_pipeline_core.rs1_data_idex_o, exp_rs1);
        check_value("rs2_data_idex_o",
                    u_pipeline_core.rs2_data_idex_o, exp_rs2);
    end
endtask

task check_valid;
    input exp_ifid;
    input exp_idex;
    begin
        check_value("valid_ifid_o", u_pipeline_core.valid_ifid_o, exp_ifid);
        check_value("valid_idex_o", u_pipeline_core.valid_idex_o, exp_idex);
    end
endtask

// Flag order is {MULHU, MULHSU, MULH, MUL}.
task check_mul_flags;
    input [3:0] exp_flags;
    begin
        check_value("MULHU/MULHSU/MULH/MUL flags",
                    {u_pipeline_core.is_mulhu_idex_o,
                     u_pipeline_core.is_mulhsu_idex_o,
                     u_pipeline_core.is_mulh_idex_o,
                     u_pipeline_core.is_mul_idex_o},
                    exp_flags);
    end
endtask

// Each MUL* writing x0 is immediately followed by ADD rd,x0,x0.
// Inspect real read ports AND forwarding while that ADD is in ID.
task check_x0_read_ports;
    begin
        check_value("x0 rs1 address",
                    u_pipeline_core.regfile_inst.rs1_addr_i, 32'd0);
        check_value("x0 rs2 address",
                    u_pipeline_core.regfile_inst.rs2_addr_i, 32'd0);
        check_value("x0 rs1 read",
                    u_pipeline_core.regfile_inst.rs1_data_o, 32'd0);
        check_value("x0 rs2 read",
                    u_pipeline_core.regfile_inst.rs2_data_o, 32'd0);
        check_value("x0 rs1 forwarding",
                    u_pipeline_core.rs1_data_forward_o, 32'd0);
        check_value("x0 rs2 forwarding",
                    u_pipeline_core.rs2_data_forward_o, 32'd0);
    end
endtask

task check_no_memory;
    begin
        check_value("ram_wr_en_ex_o", u_pipeline_core.ram_wr_en_ex_o, 32'd0);
        check_value("ram_rd_en_ex_o", u_pipeline_core.ram_rd_en_ex_o, 32'd0);
        check_value("ram_wr_sel_ex_o", u_pipeline_core.ram_wr_sel_ex_o, 32'd0);
    end
endtask

task check_idle;
    begin
        check_ex(1'b0, 5'd0, 32'h00000000);
        check_no_memory;
        check_value("idle redirect", u_pipeline_core.pc_brench_flag_ex_o, 32'd0);
        check_value("idle flush", u_pipeline_core.clear_valid_ex_o, 32'd0);
        check_mul_flags(4'b0000);
    end
endtask

//---------------------------------------------------------------
// EX checks occur at negedge; commit checks at the next posedge+#1.
// Waiting for valid allows the existing flush bubbles.
// A dropped instruction will fail the PC sequence or global timeout.
//---------------------------------------------------------------
task check_step;
    input [31:0] exp_pc;
    input [4:0] exp_rd;
    input [31:0] exp_data;
    input [31:0] exp_rs1;
    input [31:0] exp_rs2;
    input [3:0] exp_flags;
    input exp_jump;
    input [31:0] exp_target;
    begin
        @(negedge clk);
        while (u_pipeline_core.valid_idex_o !== 1'b1)
            @(negedge clk);

        check_value("instruction PC", u_pipeline_core.pc_idex_o, exp_pc);
        check_idex(exp_rs1, exp_rs2);
        check_mul_flags(exp_flags);
        check_value("is_jal_idex_o", u_pipeline_core.is_jal_idex_o, exp_jump);
        check_no_memory;

        // Either regfile or EX may suppress writes to x0.
        if (exp_rd != 5'd0)
            check_ex(1'b1, exp_rd, exp_data);
        else if (u_pipeline_core.wr_en_ex_o === 1'b1)
            check_ex(1'b1, 5'd0, exp_data);
        else if (u_pipeline_core.wr_en_ex_o !== 1'b0) begin
            $display("FAIL [%0t] x0 write enable contains X/Z", $time);
            errors = errors + 1;
        end

        check_value("redirect", u_pipeline_core.pc_brench_flag_ex_o, exp_jump);
        check_value("flush", u_pipeline_core.clear_valid_ex_o, exp_jump);
        if (exp_jump)
            check_value("jump target",
                        u_pipeline_core.pc_brench_addr_ex_o, exp_target);

        if (exp_rd == 5'd0)
            check_x0_read_ports;

        @(posedge clk);
        #1;
        if (exp_rd != 5'd0)
            check_regfile(exp_rd, exp_data);

        checked = checked + 1;
        if (exp_flags != 4'b0000)
            mul_checked = mul_checked + 1;
    end
endtask

//---------------------------------------------------------------
// Wrong-path MUL instructions must never enter valid EX.
// Also check all observed bubbles, not only the reset bubble.
//---------------------------------------------------------------
always @(negedge clk) begin
    if (rst_n === 1'b1) begin
        if (u_pipeline_core.valid_idex_o === 1'b1) begin
            if (u_pipeline_core.pc_idex_o === 32'h000000D4 ||
                u_pipeline_core.pc_idex_o === 32'h000000D8) begin
                $display("FAIL [%0t] wrong-path MUL reached EX: pc=%h",
                         $time, u_pipeline_core.pc_idex_o);
                errors = errors + 1;
            end
        end
        else if (u_pipeline_core.valid_idex_o === 1'b0)
            check_idle;
        else begin
            $display("FAIL [%0t] valid_idex_o contains X/Z", $time);
            errors = errors + 1;
        end
    end
end

//---------------------------------------------------------------
// Fixed expected results, independent of the DUT multiplier.
//---------------------------------------------------------------
initial begin
    rst_n = 1'b0;
    errors = 0;
    checked = 0;
    mul_checked = 0;

    #15;
    check_valid(1'b0, 1'b0);
    check_idle;

    #10;                         // t=25ns: away from any posedge
    rst_n = 1'b1;

    // 00000000: ADDI x1,x0,-1
    check_step(32'h00000000, 5'd1, 32'hFFFFFFFF,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 00000004: LUI x2,0x80000
    check_step(32'h00000004, 5'd2, 32'h80000000,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 00000008: ADDI x3,x2,-1
    check_step(32'h00000008, 5'd3, 32'h7FFFFFFF,
               32'h80000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 0000000C: ADDI x4,x0,2
    check_step(32'h0000000C, 5'd4, 32'h00000002,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 00000010: ADDI x5,x0,3
    check_step(32'h00000010, 5'd5, 32'h00000003,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 00000014: ADDI x6,x0,7
    check_step(32'h00000014, 5'd6, 32'h00000007,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 00000018: MUL x7,x5,x6
    check_step(32'h00000018, 5'd7, 32'h00000015,
               32'h00000003, 32'h00000007, 4'b0001,
               1'b0, 32'h00000000);
    // 0000001C: ADDI x8,x7,1; MUL -> ADDI rs1
    check_step(32'h0000001C, 5'd8, 32'h00000016,
               32'h00000015, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 00000020: MULH x9,x5,x6
    check_step(32'h00000020, 5'd9, 32'h00000000,
               32'h00000003, 32'h00000007, 4'b0010,
               1'b0, 32'h00000000);
    // 00000024: MULHSU x10,x5,x6
    check_step(32'h00000024, 5'd10, 32'h00000000,
               32'h00000003, 32'h00000007, 4'b0100,
               1'b0, 32'h00000000);
    // 00000028: MULHU x11,x5,x6
    check_step(32'h00000028, 5'd11, 32'h00000000,
               32'h00000003, 32'h00000007, 4'b1000,
               1'b0, 32'h00000000);
    // 0000002C: MUL x7,x1,x1
    check_step(32'h0000002C, 5'd7, 32'h00000001,
               32'hFFFFFFFF, 32'hFFFFFFFF, 4'b0001,
               1'b0, 32'h00000000);
    // 00000030: MULH x8,x1,x1
    check_step(32'h00000030, 5'd8, 32'h00000000,
               32'hFFFFFFFF, 32'hFFFFFFFF, 4'b0010,
               1'b0, 32'h00000000);
    // 00000034: MULHSU x9,x1,x1
    check_step(32'h00000034, 5'd9, 32'hFFFFFFFF,
               32'hFFFFFFFF, 32'hFFFFFFFF, 4'b0100,
               1'b0, 32'h00000000);
    // 00000038: ADD x10,x0,x9; MULHSU -> ADD rs2
    check_step(32'h00000038, 5'd10, 32'hFFFFFFFF,
               32'h00000000, 32'hFFFFFFFF, 4'b0000,
               1'b0, 32'h00000000);
    // 0000003C: MULHU x11,x1,x1
    check_step(32'h0000003C, 5'd11, 32'hFFFFFFFE,
               32'hFFFFFFFF, 32'hFFFFFFFF, 4'b1000,
               1'b0, 32'h00000000);
    // 00000040: ADDI x12,x11,1; MULHU -> ADDI
    check_step(32'h00000040, 5'd12, 32'hFFFFFFFF,
               32'hFFFFFFFE, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 00000044: MUL x7,x2,x1
    check_step(32'h00000044, 5'd7, 32'h80000000,
               32'h80000000, 32'hFFFFFFFF, 4'b0001,
               1'b0, 32'h00000000);
    // 00000048: MULH x8,x2,x1
    check_step(32'h00000048, 5'd8, 32'h00000000,
               32'h80000000, 32'hFFFFFFFF, 4'b0010,
               1'b0, 32'h00000000);
    // 0000004C: MULHSU x9,x2,x1
    check_step(32'h0000004C, 5'd9, 32'h80000000,
               32'h80000000, 32'hFFFFFFFF, 4'b0100,
               1'b0, 32'h00000000);
    // 00000050: MULHU x10,x2,x1
    check_step(32'h00000050, 5'd10, 32'h7FFFFFFF,
               32'h80000000, 32'hFFFFFFFF, 4'b1000,
               1'b0, 32'h00000000);
    // 00000054: MULHSU x11,x1,x2; swap SU sources
    check_step(32'h00000054, 5'd11, 32'hFFFFFFFF,
               32'hFFFFFFFF, 32'h80000000, 4'b0100,
               1'b0, 32'h00000000);
    // 00000058: MUL x7,x2,x2
    check_step(32'h00000058, 5'd7, 32'h00000000,
               32'h80000000, 32'h80000000, 4'b0001,
               1'b0, 32'h00000000);
    // 0000005C: MULH x8,x2,x2
    check_step(32'h0000005C, 5'd8, 32'h40000000,
               32'h80000000, 32'h80000000, 4'b0010,
               1'b0, 32'h00000000);
    // 00000060: MULHSU x9,x2,x2
    check_step(32'h00000060, 5'd9, 32'hC0000000,
               32'h80000000, 32'h80000000, 4'b0100,
               1'b0, 32'h00000000);
    // 00000064: MULHU x10,x2,x2
    check_step(32'h00000064, 5'd10, 32'h40000000,
               32'h80000000, 32'h80000000, 4'b1000,
               1'b0, 32'h00000000);
    // 00000068: MUL x7,x3,x3
    check_step(32'h00000068, 5'd7, 32'h00000001,
               32'h7FFFFFFF, 32'h7FFFFFFF, 4'b0001,
               1'b0, 32'h00000000);
    // 0000006C: MULH x8,x3,x3
    check_step(32'h0000006C, 5'd8, 32'h3FFFFFFF,
               32'h7FFFFFFF, 32'h7FFFFFFF, 4'b0010,
               1'b0, 32'h00000000);
    // 00000070: MULHSU x9,x3,x3
    check_step(32'h00000070, 5'd9, 32'h3FFFFFFF,
               32'h7FFFFFFF, 32'h7FFFFFFF, 4'b0100,
               1'b0, 32'h00000000);
    // 00000074: MULHU x10,x3,x3
    check_step(32'h00000074, 5'd10, 32'h3FFFFFFF,
               32'h7FFFFFFF, 32'h7FFFFFFF, 4'b1000,
               1'b0, 32'h00000000);
    // 00000078: MUL x7,x0,x1
    check_step(32'h00000078, 5'd7, 32'h00000000,
               32'h00000000, 32'hFFFFFFFF, 4'b0001,
               1'b0, 32'h00000000);
    // 0000007C: MULH x8,x1,x0
    check_step(32'h0000007C, 5'd8, 32'h00000000,
               32'hFFFFFFFF, 32'h00000000, 4'b0010,
               1'b0, 32'h00000000);
    // 00000080: MULHSU x9,x0,x2
    check_step(32'h00000080, 5'd9, 32'h00000000,
               32'h00000000, 32'h80000000, 4'b0100,
               1'b0, 32'h00000000);
    // 00000084: MULHU x10,x2,x0
    check_step(32'h00000084, 5'd10, 32'h00000000,
               32'h80000000, 32'h00000000, 4'b1000,
               1'b0, 32'h00000000);
    // 00000088: ADDI x13,x0,1
    check_step(32'h00000088, 5'd13, 32'h00000001,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 0000008C: MUL x7,x1,x13; ADDI -> MUL rs2
    check_step(32'h0000008C, 5'd7, 32'hFFFFFFFF,
               32'hFFFFFFFF, 32'h00000001, 4'b0001,
               1'b0, 32'h00000000);
    // 00000090: MULH x8,x7,x4; MUL -> MULH rs1
    check_step(32'h00000090, 5'd8, 32'hFFFFFFFF,
               32'hFFFFFFFF, 32'h00000002, 4'b0010,
               1'b0, 32'h00000000);
    // 00000094: ADDI x14,x8,2; MULH -> ADDI
    check_step(32'h00000094, 5'd14, 32'h00000001,
               32'hFFFFFFFF, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 00000098: ADDI x13,x0,-2
    check_step(32'h00000098, 5'd13, 32'hFFFFFFFE,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 0000009C: MULHSU x9,x13,x4; ADDI -> MULHSU rs1
    check_step(32'h0000009C, 5'd9, 32'hFFFFFFFF,
               32'hFFFFFFFE, 32'h00000002, 4'b0100,
               1'b0, 32'h00000000);
    // 000000A0: MULHU x10,x4,x9; MULHSU -> MULHU rs2
    check_step(32'h000000A0, 5'd10, 32'h00000001,
               32'h00000002, 32'hFFFFFFFF, 4'b1000,
               1'b0, 32'h00000000);
    // 000000A4: MUL x11,x10,x6; MULHU -> MUL rs1
    check_step(32'h000000A4, 5'd11, 32'h00000007,
               32'h00000001, 32'h00000007, 4'b0001,
               1'b0, 32'h00000000);
    // 000000A8: ADD x12,x0,x11; MUL -> ADD rs2
    check_step(32'h000000A8, 5'd12, 32'h00000007,
               32'h00000000, 32'h00000007, 4'b0000,
               1'b0, 32'h00000000);
    // 000000AC: MUL x0,x5,x6
    check_step(32'h000000AC, 5'd0, 32'h00000015,
               32'h00000003, 32'h00000007, 4'b0001,
               1'b0, 32'h00000000);
    // 000000B0: ADD x15,x0,x0; x0 probe
    check_step(32'h000000B0, 5'd15, 32'h00000000,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 000000B4: MULH x0,x1,x4
    check_step(32'h000000B4, 5'd0, 32'hFFFFFFFF,
               32'hFFFFFFFF, 32'h00000002, 4'b0010,
               1'b0, 32'h00000000);
    // 000000B8: ADD x16,x0,x0; x0 probe
    check_step(32'h000000B8, 5'd16, 32'h00000000,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 000000BC: MULHSU x0,x2,x1
    check_step(32'h000000BC, 5'd0, 32'h80000000,
               32'h80000000, 32'hFFFFFFFF, 4'b0100,
               1'b0, 32'h00000000);
    // 000000C0: ADD x17,x0,x0; x0 probe
    check_step(32'h000000C0, 5'd17, 32'h00000000,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 000000C4: MULHU x0,x1,x1
    check_step(32'h000000C4, 5'd0, 32'hFFFFFFFE,
               32'hFFFFFFFF, 32'hFFFFFFFF, 4'b1000,
               1'b0, 32'h00000000);
    // 000000C8: ADD x18,x0,x0; x0 probe
    check_step(32'h000000C8, 5'd18, 32'h00000000,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 000000CC: ADDI x19,x0,85
    check_step(32'h000000CC, 5'd19, 32'h00000055,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 000000D0: JAL x20,12
    check_step(32'h000000D0, 5'd20, 32'h000000D4,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b1, 32'h000000DC);
    // 000000DC: ADDI x21,x19,1
    check_step(32'h000000DC, 5'd21, 32'h00000056,
               32'h00000055, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 000000E0: MULHSU x22,x1,x4
    check_step(32'h000000E0, 5'd22, 32'hFFFFFFFF,
               32'hFFFFFFFF, 32'h00000002, 4'b0100,
               1'b0, 32'h00000000);
    // 000000E4: ADDI x23,x22,1; MULHSU -> ADDI
    check_step(32'h000000E4, 5'd23, 32'h00000000,
               32'hFFFFFFFF, 32'h00000000, 4'b0000,
               1'b0, 32'h00000000);
    // 000000E8: JAL x0,0; DONE
    check_step(32'h000000E8, 5'd0, 32'h000000EC,
               32'h00000000, 32'h00000000, 4'b0000,
               1'b1, 32'h000000E8);

    // The final JAL at DONE_PC has committed and flushed both stages.
    check_valid(1'b0, 1'b0);
    check_idle;

    if (checked != EXPECTED_CHECKS) begin
        $display("FAIL: checked=%0d expected=%0d", checked, EXPECTED_CHECKS);
        errors = errors + 1;
    end
    if (mul_checked != EXPECTED_MUL_CHECKS) begin
        $display("FAIL: mul_checked=%0d expected=%0d",
                 mul_checked, EXPECTED_MUL_CHECKS);
        errors = errors + 1;
    end

    // Check the complete writable architectural register set.
    check_regfile(5'd1, 32'hFFFFFFFF);
    check_regfile(5'd2, 32'h80000000);
    check_regfile(5'd3, 32'h7FFFFFFF);
    check_regfile(5'd4, 32'h00000002);
    check_regfile(5'd5, 32'h00000003);
    check_regfile(5'd6, 32'h00000007);
    check_regfile(5'd7, 32'hFFFFFFFF);
    check_regfile(5'd8, 32'hFFFFFFFF);
    check_regfile(5'd9, 32'hFFFFFFFF);
    check_regfile(5'd10, 32'h00000001);
    check_regfile(5'd11, 32'h00000007);
    check_regfile(5'd12, 32'h00000007);
    check_regfile(5'd13, 32'hFFFFFFFE);
    check_regfile(5'd14, 32'h00000001);
    check_regfile(5'd15, 32'h00000000);
    check_regfile(5'd16, 32'h00000000);
    check_regfile(5'd17, 32'h00000000);
    check_regfile(5'd18, 32'h00000000);
    check_regfile(5'd19, 32'h00000055);
    check_regfile(5'd20, 32'h000000D4);
    check_regfile(5'd21, 32'h00000056);
    check_regfile(5'd22, 32'hFFFFFFFF);
    check_regfile(5'd23, 32'h00000000);
    check_regfile(5'd24, 32'h00000000);
    check_regfile(5'd25, 32'h00000000);
    check_regfile(5'd26, 32'h00000000);
    check_regfile(5'd27, 32'h00000000);
    check_regfile(5'd28, 32'h00000000);
    check_regfile(5'd29, 32'h00000000);
    check_regfile(5'd30, 32'h00000000);
    check_regfile(5'd31, 32'h00000000);

    if (errors == 0)
        $display("PASS: all MUL/MULH/MULHSU/MULHU checks passed, instructions=%0d, multiplies=%0d",
                 checked, mul_checked);
    else begin
        $display("FAIL: %0d checks failed", errors);
        $fatal(1, "MUL group test failed");
    end
    $finish;
end

initial begin
    #10000;
    $fatal(1, "MUL group timeout: checked=%0d/%0d, EX pc=%h, done=%h",
           checked, EXPECTED_CHECKS,
           u_pipeline_core.pc_idex_o, DONE_PC);
end

endmodule


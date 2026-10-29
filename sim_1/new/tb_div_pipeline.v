`timescale 1ns / 1ps

module tb_div_pipeline;

    reg clk;
    reg rst_n;

    pipeline_core dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Test program and independent expected results
    // ------------------------------------------------------------

    reg [31:0] rom          [0:255];
    reg [31:0] expected_data[0:255];
    reg [31:0] expected_next[0:255];
    reg        reachable   [0:255];

    integer starts_at [0:255];
    integer commits_at[0:255];

    reg [31:0] model_regs[0:31];

    integer words;
    integer jump_index;
    integer phase;              // 0: cancel, 1: quiet, 2: normal
    integer cycle;
    integer total_starts;
    integer div_commits;
    integer cancelled;
    integer instructions;
    integer i;
    integer m;
    integer index;

    reg finished;
    reg pending;
    reg [31:0] pending_pc;
    integer start_cycle;

    reg [31:0] expected_pc;
    reg [31:0] done_pc;
    reg [31:0] injected_instr;

    // Replace the instruction stream only during this simulation.
    always @(*) begin
        injected_instr = 32'd0;
        if ((dut.pc_o[31:10] == 22'd0) &&
            (dut.pc_o[1:0] == 2'b00))
            injected_instr = rom[dut.pc_o[9:2]];
    end

    initial begin
        force dut.instr_o = injected_instr;
    end

    // ------------------------------------------------------------
    // Encoding and reference functions
    // ------------------------------------------------------------

    function [31:0] enc_addi;
        input [4:0] rd;
        input [4:0] rs1;
        input [31:0] imm;
        begin
            enc_addi = {
                imm[11:0], rs1, 3'b000, rd, 7'b0010011
            };
        end
    endfunction

    function [31:0] enc_div;
        input [2:0] funct3;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        begin
            enc_div = {
                7'b0000001, rs2, rs1, funct3, rd, 7'b0110011
            };
        end
    endfunction

    // {REMU, REM, DIVU, DIV}
    function [3:0] div_kind;
        input [31:0] instr;
        begin
            div_kind = 4'b0000;
            if ((instr[6:0] == 7'b0110011) &&
                (instr[31:25] == 7'b0000001)) begin
                case (instr[14:12])
                    3'b100: div_kind = 4'b0001;
                    3'b101: div_kind = 4'b0010;
                    3'b110: div_kind = 4'b0100;
                    3'b111: div_kind = 4'b1000;
                    default: div_kind = 4'b0000;
                endcase
            end
        end
    endfunction

    function [31:0] ref_div;
        input [2:0] op;
        input [31:0] a;
        input [31:0] b;

        reg signed [31:0] sa;
        reg signed [31:0] sb;
        reg signed [31:0] sq;
        reg signed [31:0] sr;
        reg [31:0] q;
        reg [31:0] r;
        begin
            sa = a;
            sb = b;

            if (b == 32'd0) begin
                q = 32'hFFFFFFFF;
                r = a;
            end
            else if (((op == 3'b100) || (op == 3'b110)) &&
                     (a == 32'h80000000) &&
                     (b == 32'hFFFFFFFF)) begin
                q = 32'h80000000;
                r = 32'd0;
            end
            else if ((op == 3'b100) || (op == 3'b110)) begin
                sq = sa / sb;
                sr = sa % sb;
                q = sq;
                r = sr;
            end
            else begin
                q = a / b;
                r = a % b;
            end

            if ((op == 3'b110) || (op == 3'b111))
                ref_div = r;
            else
                ref_div = q;
        end
    endfunction

    task clear_program;
        integer k;
        begin
            words = 0;
            for (k = 0; k < 256; k = k + 1) begin
                rom[k]           = 32'd0;
                expected_data[k] = 32'd0;
                expected_next[k] = 32'd0;
                reachable[k]     = 1'b0;
                starts_at[k]     = 0;
                commits_at[k]    = 0;
            end
        end
    endtask

    task emit;
        input [31:0] instr;
        input [31:0] result;
        begin
            rom[words]           = instr;
            expected_data[words] = result;
            expected_next[words] = (words + 1) * 4;
            reachable[words]     = 1'b1;
            words = words + 1;
        end
    endtask

    // a/b are explicit expected source values, not DUT outputs.
    task emit_div;
        input [2:0] op;
        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;
        input [31:0] a;
        input [31:0] b;
        begin
            emit(enc_div(op, rd, rs1, rs2), ref_div(op, a, b));
        end
    endtask

    task build_program;
        integer k;
        begin
            clear_program;

            // Positive operands; adjacent producer and consumer
            emit(enc_addi(1, 0, 13), 32'd13);
            emit(enc_addi(2, 0, 3),  32'd3);
            emit_div(3'b100, 3, 1, 2, 13, 3);
            emit(enc_addi(4, 3, 1), 32'd5);

            // -13 / +3
            emit(enc_addi(1, 0, -13), 32'hFFFFFFF3);
            emit_div(3'b100, 5, 1, 2, 32'hFFFFFFF3, 3);
            emit_div(3'b110, 6, 1, 2, 32'hFFFFFFF3, 3);

            // -13 / -3; divisor produced immediately before DIV
            emit(enc_addi(2, 0, -3), 32'hFFFFFFFD);
            emit_div(3'b100, 7, 1, 2,
                     32'hFFFFFFF3, 32'hFFFFFFFD);
            emit_div(3'b110, 8, 1, 2,
                     32'hFFFFFFF3, 32'hFFFFFFFD);

            // +13 / -3
            emit(enc_addi(1, 0, 13), 32'd13);
            emit_div(3'b100, 9, 1, 2, 13, 32'hFFFFFFFD);
            emit_div(3'b110, 10, 1, 2, 13, 32'hFFFFFFFD);

            // +13 / +3 remainder
            emit(enc_addi(2, 0, 3), 32'd3);
            emit_div(3'b110, 10, 1, 2, 13, 3);

            // Consecutive DIV/DIVU/REM/REMU with same bit patterns
            emit(enc_addi(1, 0, -1), 32'hFFFFFFFF);
            emit(enc_addi(2, 0, 2), 32'd2);
            emit_div(3'b100, 11, 1, 2, 32'hFFFFFFFF, 2);
            emit_div(3'b101, 12, 1, 2, 32'hFFFFFFFF, 2);
            emit_div(3'b110, 13, 1, 2, 32'hFFFFFFFF, 2);
            emit_div(3'b111, 14, 1, 2, 32'hFFFFFFFF, 2);

            // INT_MIN / -1, signed and unsigned
            emit(32'h800000B7, 32'h80000000); // LUI x1,0x80000
            emit(enc_addi(2, 0, -1), 32'hFFFFFFFF);
            emit_div(3'b100, 15, 1, 2,
                     32'h80000000, 32'hFFFFFFFF);
            emit_div(3'b110, 16, 1, 2,
                     32'h80000000, 32'hFFFFFFFF);
            emit_div(3'b101, 17, 1, 2,
                     32'h80000000, 32'hFFFFFFFF);
            emit_div(3'b111, 18, 1, 2,
                     32'h80000000, 32'hFFFFFFFF);

            // INT_MIN / +1
            emit(enc_addi(2, 0, 1), 32'd1);
            emit_div(3'b100, 19, 1, 2, 32'h80000000, 1);
            emit_div(3'b110, 20, 1, 2, 32'h80000000, 1);

            // INT_MIN / 0, all four instructions
            emit_div(3'b100, 21, 1, 0, 32'h80000000, 0);
            emit_div(3'b110, 22, 1, 0, 32'h80000000, 0);
            emit_div(3'b101, 23, 1, 0, 32'h80000000, 0);
            emit_div(3'b111, 24, 1, 0, 32'h80000000, 0);

            // 0 / 0
            emit_div(3'b100, 25, 0, 0, 0, 0);
            emit_div(3'b110, 26, 0, 0, 0, 0);
            emit_div(3'b101, 27, 0, 0, 0, 0);
            emit_div(3'b111, 28, 0, 0, 0, 0);

            // Negative dividend / 0
            emit(enc_addi(1, 0, -13), 32'hFFFFFFF3);
            emit_div(3'b100, 29, 1, 0, 32'hFFFFFFF3, 0);
            emit_div(3'b110, 30, 1, 0, 32'hFFFFFFF3, 0);

            // Each instruction writes x0, followed by a real x0 probe
            emit(enc_addi(2, 0, 3), 32'd3);
            for (k = 0; k < 4; k = k + 1) begin
                emit_div(3'b100 + k, 0, 1, 2, 32'hFFFFFFF3, 3);
                emit(32'h00000FB3, 32'd0); // ADD x31,x0,x0
            end

            // DIV result -> next DIV rs1 -> next REM rs2
            emit_div(3'b100, 3, 1, 2, 32'hFFFFFFF3, 3);
            emit_div(3'b100, 4, 3, 2, 32'hFFFFFFFC, 3);
            emit_div(3'b110, 5, 1, 4,
                     32'hFFFFFFF3, 32'hFFFFFFFF);
            emit(enc_addi(6, 5, 7), 32'd7);

            // JAL must cancel two wrong-path division instructions
            emit(enc_addi(21, 0, 85), 32'd85);

            jump_index = words;
            emit(32'h00C00A6F, (words * 4) + 4); // JAL x20,+12
            expected_next[jump_index] = (jump_index + 3) * 4;

            emit_div(3'b100, 21, 1, 2, 32'hFFFFFFF3, 3);
            reachable[words - 1] = 1'b0;

            emit_div(3'b111, 21, 1, 2, 32'hFFFFFFF3, 3);
            reachable[words - 1] = 1'b0;

            emit(enc_addi(22, 21, 1), 32'd86);
            emit_div(3'b101, 23, 2, 2, 3, 3);
            emit(enc_addi(24, 23, 1), 32'd2);

            // Stop after this JAL has actually committed and flushed
            done_pc = words * 4;
            emit(32'h0000006F, done_pc + 4); // JAL x0,0
            expected_next[words - 1] = done_pc;
        end
    endtask

    // ------------------------------------------------------------
    // Pipeline state bundles: compare all saved fields during stall
    // ------------------------------------------------------------

    wire [3:0] div_flags;
    assign div_flags = {
        dut.is_remu_idex_o, dut.is_rem_idex_o,
        dut.is_divu_idex_o, dut.is_div_idex_o
    };

    wire [63:0] control_state;
    assign control_state = {
        dut.is_addi_idex_o, dut.is_xori_idex_o,
        dut.is_ori_idex_o,  dut.is_andi_idex_o,
        dut.is_slli_idex_o, dut.is_srli_idex_o,
        dut.is_srai_idex_o, dut.is_slti_idex_o,
        dut.is_sltiu_idex_o,
        dut.is_add_idex_o, dut.is_sub_idex_o,
        dut.is_xor_idex_o, dut.is_or_idex_o,
        dut.is_and_idex_o, dut.is_sll_idex_o,
        dut.is_srl_idex_o, dut.is_sra_idex_o,
        dut.is_slt_idex_o, dut.is_sltu_idex_o,
        dut.is_beq_idex_o, dut.is_bne_idex_o,
        dut.is_blt_idex_o, dut.is_bge_idex_o,
        dut.is_bltu_idex_o, dut.is_bgeu_idex_o,
        dut.is_jal_idex_o, dut.is_jalr_idex_o,
        dut.is_lui_idex_o, dut.is_auipc_idex_o,
        dut.is_sw_idex_o, dut.is_sb_idex_o, dut.is_sh_idex_o,
        dut.is_lw_idex_o, dut.is_lb_idex_o, dut.is_lbu_idex_o,
        dut.is_lh_idex_o, dut.is_lhu_idex_o,
        dut.is_mul_idex_o, dut.is_mulh_idex_o,
        dut.is_mulhsu_idex_o, dut.is_mulhu_idex_o,
        div_flags
    };

    wire [64:0] ifid_state;
    assign ifid_state = {
        dut.valid_ifid_o, dut.pc_ifid_o, dut.instr_ifid_o
    };

    wire [511:0] idex_state;
    assign idex_state = {
        dut.valid_idex_o, dut.pc_idex_o,
        dut.rs1_data_idex_o, dut.rs2_data_idex_o,
        dut.immi_data_idex_o, dut.immb_data_idex_o,
        dut.immj_data_idex_o, dut.immu_data_idex_o,
        dut.imms_data_idex_o, dut.rd_addr_idex_o,
        control_state
    };

    // ------------------------------------------------------------
    // Rising-edge snapshots
    // ------------------------------------------------------------

    reg s_valid;
    reg s_stall;
    reg s_flush;
    reg s_jump;
    reg s_wr;
    reg s_start;
    reg s_done;
    reg s_busy;
    reg s_id_valid_input;
    reg s_terminal;

    reg [4:0]  s_rd;
    reg [31:0] s_data;
    reg [31:0] s_pc;
    reg [31:0] s_fetch_pc;
    reg [31:0] s_fetch_instr;
    reg [31:0] s_jump_addr;
    reg [31:0] s_instr;
    reg [3:0]  s_kind;
    reg [64:0] s_ifid;
    reg [511:0] s_idex;

    task fail;
        input [8*96-1:0] message;
        begin
            $display(
                "FAIL [%0t] cycle=%0d phase=%0d EX_PC=%h: %0s",
                $time, cycle, phase, s_pc, message
            );
            $display(
                "  instr=%h rd=%0d data=%h stall=%b start=%b done=%b",
                s_instr, s_rd, s_data, s_stall, s_start, s_done
            );
            $fatal(1, "Division pipeline test failed");
        end
    endtask

    always @(posedge clk) begin
        cycle = cycle + 1;

        // Save values used by the DUT at THIS edge.
        s_valid          = dut.valid_idex_o;
        s_stall          = dut.stall_ex_o;
        s_flush          = dut.clear_valid_ex_o;
        s_jump           = dut.pc_brench_flag_ex_o;
        s_jump_addr      = dut.pc_brench_addr_ex_o;
        s_wr             = dut.wr_en_ex_o;
        s_rd             = dut.wr_addr_ex_o;
        s_data           = dut.wr_data_ex_o;
        s_pc             = dut.pc_idex_o;
        s_fetch_pc       = dut.pc_o;
        s_fetch_instr    = dut.instr_o;
        s_ifid           = ifid_state;
        s_idex           = idex_state;
        s_id_valid_input = dut.valid_idex_i;
        s_start          = dut.ex_inst.start_ex_o;
        s_done           = dut.ex_inst.done_div_o;
        s_busy           = dut.ex_inst.busy_div_o;
        s_terminal       = 1'b0;

        s_instr = 32'd0;
        s_kind  = 4'd0;

        if (!rst_n) begin
            if (pending) begin
                cancelled = cancelled + 1;
                pending = 1'b0;
            end

            expected_pc = 32'd0;
            for (m = 0; m < 32; m = m + 1)
                model_regs[m] = 32'd0;
        end
        else begin
            // This test program contains no legitimate memory accesses.
            if ((dut.ram_wr_en_ex_o !== 1'b0) ||
                (dut.ram_rd_en_ex_o !== 1'b0) ||
                (dut.ram_wr_sel_ex_o !== 4'b0000))
                fail("unexpected memory side effect");

            // x0 storage is intentionally NOT inspected.
            // Check actual read ports and forwarding instead.
            if (dut.rs1_addr_o == 5'd0) begin
                if ((dut.rs1_data_o !== 32'd0) ||
                    (dut.rs1_data_forward_o !== 32'd0))
                    fail("x0 rs1 read/forwarding corrupted");
            end
            if (dut.rs2_addr_o == 5'd0) begin
                if ((dut.rs2_data_o !== 32'd0) ||
                    (dut.rs2_data_forward_o !== 32'd0))
                    fail("x0 rs2 read/forwarding corrupted");
            end

            if (!pending && s_done)
                fail("completion without an outstanding request");

            if (s_valid === 1'b1) begin
                if ((s_pc[31:10] !== 22'd0) ||
                    (s_pc[1:0] !== 2'b00))
                    fail("EX PC outside test ROM");

                index   = s_pc[9:2];
                s_instr = rom[index];
                s_kind  = div_kind(s_instr);

                if (reachable[index] !== 1'b1)
                    fail("wrong-path or unexpected instruction reached EX");

                if (s_pc !== expected_pc)
                    fail("instruction skipped, duplicated, or executed out of order");

                if (div_flags !== s_kind)
                    fail("DIV/DIVU/REM/REMU decode flags incorrect");

                // Compare saved operands against architectural state.
                if ((s_instr[6:0] == 7'h33) ||
                    (s_instr[6:0] == 7'h13)) begin
                    if (dut.rs1_data_idex_o !==
                        model_regs[s_instr[19:15]])
                        fail("rs1 dependency/forwarding failure");
                end

                if (s_instr[6:0] == 7'h33) begin
                    if (dut.rs2_data_idex_o !==
                        model_regs[s_instr[24:20]])
                        fail("rs2 dependency/forwarding failure");
                end

                if (s_kind != 4'd0) begin
                    if ((s_jump !== 1'b0) || (s_flush !== 1'b0))
                        fail("division caused redirect/flush");

                    // Count the request sampled at this edge.
                    if (s_start === 1'b1) begin
                        if (pending || (s_busy !== 1'b0) ||
                            (s_done !== 1'b0))
                            fail("repeated or invalid division start");

                        if (starts_at[index] != 0)
                            fail("same instruction started more than once");

                        pending = 1'b1;
                        pending_pc = s_pc;
                        start_cycle = cycle;
                        total_starts = total_starts + 1;
                        starts_at[index] = starts_at[index] + 1;

                        if (dut.ex_inst.signed_ex_o !==
                            ((s_kind == 4'b0001) ||
                             (s_kind == 4'b0100)))
                            fail("signed mode incorrect at start");

                        if ((dut.ex_inst.dividend_ex_o !==
                             model_regs[s_instr[19:15]]) ||
                            (dut.ex_inst.divisor_ex_o !==
                             model_regs[s_instr[24:20]]))
                            fail("division start operands incorrect");
                    end
                    else if (s_start !== 1'b0)
                        fail("division start is X/Z");

                    if (!pending || (pending_pc !== s_pc))
                        fail("division missing its matching start");

                    if (s_stall === 1'b1) begin
                        if ((s_wr !== 1'b0) || (s_done !== 1'b0))
                            fail("division wrote back while waiting");

                        if ((cycle - start_cycle) >= 34)
                            fail("division did not commit at expected latency");
                    end
                    else if (s_stall === 1'b0) begin
                        if ((s_done !== 1'b1) ||
                            (s_busy !== 1'b0) ||
                            (s_start !== 1'b0))
                            fail("invalid division completion handshake");

                        // Wrapper done rises after E33.
                        // Regfile samples the completed result at E34.
                        if ((cycle - start_cycle) != 34)
                            fail("division commit latency is not 34 cycles");

                        div_commits = div_commits + 1;
                        pending = 1'b0;
                    end
                    else
                        fail("stall is X/Z");
                end
                else begin
                    if ((s_start !== 1'b0) || (s_stall !== 1'b0))
                        fail("non-division started divider or stalled");
                    if (pending)
                        fail("pipeline left division before completion");
                end

                // All reachable instructions in this ROM write a result,
                // including writes to x0, as in the current EX interface.
                if (s_stall === 1'b0) begin
                    if ((s_wr !== 1'b1) ||
                        (s_rd !== s_instr[11:7]) ||
                        (s_data !== expected_data[index]))
                        fail("writeback enable/rd/data incorrect");

                    if (commits_at[index] != 0)
                        fail("same instruction committed more than once");

                    commits_at[index] = commits_at[index] + 1;
                    instructions = instructions + 1;

                    if (s_rd != 5'd0)
                        model_regs[s_rd] = s_data;

                    if (s_instr[6:0] == 7'h6F) begin
                        if ((s_jump !== 1'b1) ||
                            (s_flush !== 1'b1) ||
                            (s_jump_addr !== expected_next[index]))
                            fail("JAL redirect/flush incorrect");
                    end
                    else if ((s_jump !== 1'b0) || (s_flush !== 1'b0))
                        fail("unexpected redirect/flush");

                    expected_pc = expected_next[index];

                    if ((phase == 2) && (s_pc == done_pc))
                        s_terminal = 1'b1;
                end
            end
            else if (s_valid === 1'b0) begin
                if ((s_wr !== 1'b0) || (s_start !== 1'b0) ||
                    (s_stall !== 1'b0) || (s_jump !== 1'b0) ||
                    (s_flush !== 1'b0))
                    fail("invalid EX instruction caused a side effect");
            end
            else
                fail("EX valid is X/Z");
        end

        // --------------------------------------------------------
        // AFTER NBA updates: verify the write sampled above.
        // Never use the new EX rd/data as the previous writeback.
        // --------------------------------------------------------
        #1;

        for (m = 1; m < 32; m = m + 1) begin
            if (dut.regfile_inst.reg_file[m] !== model_regs[m])
                fail("architectural register mismatch after rising edge");
        end

        for (m = 0; m < 32; m = m + 1) begin
            if (dut.ram_inst.memory[m] !== 32'd0)
                fail("RAM changed unexpectedly");
        end

        if (!rst_n) begin
            if ((dut.pc_o !== 32'd0) ||
                (dut.valid_ifid_o !== 1'b0) ||
                (dut.valid_idex_o !== 1'b0) ||
                (dut.ex_inst.busy_div_o !== 1'b0) ||
                (dut.ex_inst.done_div_o !== 1'b0) ||
                (dut.ex_inst.quotient_div_o !== 32'd0) ||
                (dut.ex_inst.remainder_div_o !== 32'd0))
                fail("reset failed to cancel/clear pipeline and divider");
        end
        else if (s_flush) begin
            if ((dut.pc_o !== s_jump_addr) ||
                (dut.valid_ifid_o !== 1'b0) ||
                (dut.valid_idex_o !== 1'b0) ||
                (dut.ex_inst.start_ex_o !== 1'b0))
                fail("flush failed to cancel younger instructions");
        end
        else if (s_stall) begin
            if ((dut.pc_o !== s_fetch_pc) ||
                (ifid_state !== s_ifid) ||
                (idex_state !== s_idex))
                fail("PC/IF_ID/ID_EX changed during stall");
        end
        else begin
            if (dut.pc_o !== (s_fetch_pc + 32'd4))
                fail("PC did not advance normally");

            if (ifid_state !== {1'b1, s_fetch_pc, s_fetch_instr})
                fail("IF_ID did not capture the pre-edge fetch instruction");

            if ((dut.valid_idex_o !== s_id_valid_input) ||
                (dut.pc_idex_o !== s_ifid[63:32]))
                fail("ID_EX update incorrect");
        end

        // Signal completion only after checking the final JAL commit.
        if (s_terminal)
            finished = 1'b1;
    end

    // ------------------------------------------------------------
    // Reset-cancellation phase, then normal program
    // ------------------------------------------------------------

    initial begin
        rst_n        = 1'b0;
        phase        = 0;
        cycle        = 0;
        total_starts = 0;
        div_commits  = 0;
        cancelled    = 0;
        instructions = 0;
        pending      = 1'b0;
        finished     = 1'b0;
        expected_pc  = 32'd0;
        done_pc      = 32'hFFFFFFFF;

        clear_program;

        // A request that must be cancelled before it commits.
        emit(enc_addi(1, 0, -13), 32'hFFFFFFF3);
        emit(enc_addi(2, 0, 3), 32'd3);
        emit_div(3'b100, 3, 1, 2, 32'hFFFFFFF3, 3);

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        wait (pending === 1'b1);
        repeat (5) @(negedge clk);

        // Reset while division is still in progress.
        rst_n = 1'b0;
        clear_program;

        repeat (2) @(negedge clk);
        if (cancelled != 1)
            $fatal(1, "Expected exactly one reset-cancelled request");

        // Empty ROM: observe long enough to catch a late completion.
        phase = 1;
        rst_n = 1'b1;
        repeat (35) @(negedge clk);

        if (pending || (div_commits != 0))
            $fatal(1, "Cancelled division produced a late commit");

        // Restart from reset with the complete test program.
        rst_n = 1'b0;
        phase = 2;
        build_program;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        wait (finished === 1'b1);
        @(negedge clk);

        // Per-PC coverage prevents missing/duplicated instructions
        // from cancelling each other out in the global totals.
        for (i = 0; i < words; i = i + 1) begin
            if (reachable[i]) begin
                if (commits_at[i] != 1)
                    $fatal(1, "PC=%h commits=%0d, expected 1",
                           i * 4, commits_at[i]);

                if (div_kind(rom[i]) != 4'd0) begin
                    if (starts_at[i] != 1)
                        $fatal(1, "PC=%h starts=%0d, expected 1",
                               i * 4, starts_at[i]);
                end
                else if (starts_at[i] != 0)
                    $fatal(1, "Non-division PC=%h started divider", i * 4);
            end
            else begin
                if ((starts_at[i] != 0) || (commits_at[i] != 0))
                    $fatal(1, "Wrong-path PC=%h started or committed", i * 4);
            end
        end

        if (pending || (cancelled != 1) ||
            (total_starts != div_commits + cancelled))
            $fatal(1,
                "Count mismatch: starts=%0d commits=%0d cancelled=%0d",
                total_starts, div_commits, cancelled);

        $display(
            "PASS: division pipeline checks passed, instructions=%0d",
            instructions
        );
        $display(
            "      division_starts=%0d commits=%0d reset_cancelled=%0d",
            total_starts, div_commits, cancelled
        );
        $finish;
    end

    initial begin
        #200000;
        $fatal(1,
            "Timeout: EX_PC=%h starts=%0d commits=%0d cancelled=%0d",
            dut.pc_idex_o, total_starts, div_commits, cancelled);
    end

endmodule

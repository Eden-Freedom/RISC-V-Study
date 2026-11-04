`timescale 1ns / 1ps
// System test: CPU-generated requests pass through data_bus to RAM or a mock DEV.
module tb_data_bus_system;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #10 clk = ~clk;

    wire dev2bus_ready_i;
    wire [31:0] dev2bus_rdata_i;
    wire bus2dev_req_o, bus2dev_we_o;
    wire [31:0] bus2dev_addr_o, bus2dev_wdata_o;
    wire [3:0] bus2dev_wstrb_o;

    pipeline_core dut (
        .clk(clk), .rst_n(rst_n), .irq_external_i(1'b0),
        .dev2bus_ready_i(dev2bus_ready_i),
        .dev2bus_rdata_i(dev2bus_rdata_i),
        .bus2dev_req_o(bus2dev_req_o), .bus2dev_we_o(bus2dev_we_o),
        .bus2dev_addr_o(bus2dev_addr_o),
        .bus2dev_wdata_o(bus2dev_wdata_o),
        .bus2dev_wstrb_o(bus2dev_wstrb_o)
    );

    // Mock DEV: two preparation edges, then completion at the third edge.
    // Idle ready=1 intentionally challenges RAM response selection.
    reg [1:0] dev_wait;
    assign dev2bus_ready_i = !bus2dev_req_o || (dev_wait == 2'd2);
    assign dev2bus_rdata_i = 32'h12345678;
    always @(posedge clk) begin
        if (!rst_n)
            dev_wait <= 2'd0;
        else if (!bus2dev_req_o || dev2bus_ready_i)
            dev_wait <= 2'd0;
        else
            dev_wait <= dev_wait + 1'b1;
    end

    integer errors = 0;
    integer retired = 0;
    integer transfers = 0;
    integer wait_edges = 0;
    integer dev_reads = 0, dev_writes = 0;
    integer ram_reads = 0, ram_writes = 0;
    integer unmapped_reads = 0, unmapped_writes = 0;
    integer i;
    reg finished = 1'b0;
    reg was_waiting = 1'b0;
    reg [69:0] saved_payload;
    wire [69:0] payload;
    assign payload = {dut.data_req, dut.data_we, dut.data_addr,
                      dut.ram_wr_data_ex_o, dut.ram_wr_sel_ex_o};
    reg [31:0] saved_pc, saved_ex_pc;
    reg [64:0] saved_ifid;
    reg [31:0] saved_regs [1:31];
    reg stall_before, finish_before;
    reg [31:0] expected_addr, expected_data, expected_rdata;
    reg expected_we;
    integer expected_wait;
    integer expected_target; // 0: RAM; 1: DEV; 2: unmapped
    reg [31:0] transfer_pc [0:7];

    task check;
        input condition;
        input [8*110-1:0] label;
        begin
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s time=%0t EX_PC=%08h", label, $time, dut.pc_idex_o);
            end
        end
    endtask

    task check_final;
        begin
            check(retired == 12, "all program instructions retired once");
            check(transfers == 8, "all expected data accesses completed");
            check(dev_reads == 1 && dev_writes == 1, "DEV read/write completed exactly once");
            check(ram_reads == 2 && ram_writes == 2, "RAM read/write completion counts");
            check(unmapped_reads == 1 && unmapped_writes == 1, "unmapped read/write completed");
            check(dut.regfile_inst.reg_file[1] === 32'h35, "x1 = 35");
            check(dut.regfile_inst.reg_file[2] === 32'h35, "x2 = RAM readback");
            check(dut.regfile_inst.reg_file[3] === 32'h10000000, "x3 = DEV base address");
            check(dut.regfile_inst.reg_file[4] === 32'h12345678, "x4 = DEV read response");
            check(dut.regfile_inst.reg_file[5] === 32'h12345679, "x5 consumes DEV load");
            check(dut.regfile_inst.reg_file[6] === 32'd0, "x6 = unmapped read zero");
            check(dut.regfile_inst.reg_file[7] === 32'h12345679, "x7 = final RAM readback");
            check(dut.data_ram_target_inst.ram_inst.memory[0] === 32'h35, "RAM address 0 unchanged");
            check(dut.data_ram_target_inst.ram_inst.memory[1] === 32'h12345679, "RAM address 4 result");
            for (i = 2; i < 32; i = i + 1)
                check(dut.data_ram_target_inst.ram_inst.memory[i] === 32'd0,
                      "other RAM words unchanged");
            if (errors == 0) begin
                $display("PASS: data bus system checks passed");
                $finish;
            end else
                $fatal(1, "FAIL: data bus system checks failed (%0d errors)", errors);
        end
    endtask

    initial begin
        transfer_pc[0] = 32'h04; transfer_pc[1] = 32'h08;
        transfer_pc[2] = 32'h10; transfer_pc[3] = 32'h14;
        transfer_pc[4] = 32'h1C; transfer_pc[5] = 32'h20;
        transfer_pc[6] = 32'h24; transfer_pc[7] = 32'h28;
        repeat (3) @(negedge clk);
        rst_n = 1'b1; // Change reset away from the sampling edge.
    end

    initial begin
        #20000;
        $fatal(1, "FAIL: timeout EX_PC=%08h retired=%0d transfers=%0d",
               dut.pc_idex_o, retired, transfers);
    end

    // Sample handshake and enables BEFORE nonblocking clock updates.
    // Inspect architectural state AFTER #1, when those updates have settled.
    always @(posedge clk) begin
        if (rst_n && !finished) begin
            check((dut.data_req === 1'b0) || (dut.data_req === 1'b1), "CPU request is known");
            check((dut.bus2cpu_ready_o === 1'b0) || (dut.bus2cpu_ready_o === 1'b1),
                  "CPU ready is known");
            check((dut.stall_ex_o === 1'b0) || (dut.stall_ex_o === 1'b1), "CPU stall is known");
            check((dut.valid_idex_o === 1'b0) || (dut.valid_idex_o === 1'b1), "EX valid is known");
            if (was_waiting)
                check(payload === saved_payload, "request and payload held until completion");

            if (dut.data_req) begin
                expected_addr = 32'd0;
                expected_data = 32'd0;
                expected_rdata = 32'd0;
                expected_we = 1'b0;
                expected_target = 0;
                expected_wait = 1;
                case (dut.pc_idex_o)
                    32'h04: begin expected_we = 1'b1; expected_data = 32'h35; end
                    32'h08: expected_rdata = 32'h35;
                    32'h10: begin
                        expected_target = 1; expected_wait = 2;
                        expected_addr = 32'h10000004;
                        expected_we = 1'b1; expected_data = 32'h35;
                    end
                    32'h14: begin
                        expected_target = 1; expected_wait = 2;
                        expected_addr = 32'h10000004; expected_rdata = 32'h12345678;
                    end
                    32'h1C: begin
                        expected_addr = 32'd4;
                        expected_we = 1'b1; expected_data = 32'h12345679;
                    end
                    32'h20: begin expected_target = 2; expected_wait = 0; expected_addr = 32'h80; end
                    32'h24: begin
                        expected_target = 2; expected_wait = 0; expected_addr = 32'h80;
                        expected_we = 1'b1; expected_data = 32'h35;
                    end
                    32'h28: begin expected_addr = 32'd4; expected_rdata = 32'h12345679; end
                    default: check(1'b0, "unexpected instruction issued data request");
                endcase
                check(dut.valid_idex_o === 1'b1, "data request belongs to a valid instruction");
                check(dut.data_addr === expected_addr, "CPU effective address");
                check(dut.data_we === expected_we, "CPU read/write direction");
                if (expected_we) begin
                    check(dut.ram_wr_data_ex_o === expected_data, "CPU store data");
                    check(dut.ram_wr_sel_ex_o === 4'b1111, "word store byte mask");
                end
                check({dut.bus2ram_we_o, dut.bus2ram_addr_o, dut.bus2ram_wdata_o, dut.bus2ram_wstrb_o}
                      === {dut.data_we, dut.data_addr, dut.ram_wr_data_ex_o, dut.ram_wr_sel_ex_o},
                      "RAM payload forwarded without changes");
                check({bus2dev_we_o, bus2dev_addr_o, bus2dev_wdata_o, bus2dev_wstrb_o}
                      === {dut.data_we, dut.data_addr, dut.ram_wr_data_ex_o, dut.ram_wr_sel_ex_o},
                      "DEV payload forwarded through top ports");
                case (expected_target)
                    0: begin
                        check(dut.bus2ram_req_o === 1'b1 && bus2dev_req_o === 1'b0,
                              "RAM selected exclusively");
                        check(dev2bus_ready_i === 1'b1, "unselected DEV deliberately ready");
                        check(dut.bus2cpu_ready_o === dut.ram_ready_o, "CPU ready comes from RAM");
                    end
                    1: begin
                        check(bus2dev_req_o === 1'b1 && dut.bus2ram_req_o === 1'b0,
                              "DEV selected exclusively");
                        check(dut.bus2cpu_ready_o === dev2bus_ready_i, "CPU ready comes from DEV");
                    end
                    2: begin
                        check(bus2dev_req_o === 1'b0 && dut.bus2ram_req_o === 1'b0,
                              "unmapped access requests neither target");
                        check(dut.bus2cpu_ready_o === 1'b1, "unmapped access completes immediately");
                    end
                endcase
                check(dut.bus2cpu_rdata_o ===
                      ((dut.bus2cpu_ready_o && !expected_we) ? expected_rdata : 32'd0),
                      "CPU read response uses selected target; writes/waits return zero");
                if (dut.bus2cpu_ready_o === 1'b1) begin
                    check(wait_edges == expected_wait, "target-specific wait duration");
                    check(dut.stall_ex_o === 1'b0, "completion releases CPU stall");
                    if (transfers < 8)
                        check(dut.pc_idex_o === transfer_pc[transfers], "data access completion order");
                    else
                        check(1'b0, "extra data completion");
                    transfers = transfers + 1;
                    wait_edges = 0;
                    case (expected_target)
                        0: if (expected_we) ram_writes = ram_writes + 1;
                           else ram_reads = ram_reads + 1;
                        1: if (expected_we) dev_writes = dev_writes + 1;
                           else dev_reads = dev_reads + 1;
                        2: if (expected_we) unmapped_writes = unmapped_writes + 1;
                           else unmapped_reads = unmapped_reads + 1;
                    endcase
                end else begin
                    wait_edges = wait_edges + 1;
                    check(dut.stall_ex_o === 1'b1, "waiting stalls CPU");
                    check(dut.wr_en_ex_o === 1'b0, "waiting cannot write back a register");
                end
            end else begin
                check(!was_waiting, "pending request cannot disappear before completion");
                check(dut.bus2ram_req_o === 1'b0 && bus2dev_req_o === 1'b0, "idle target requests");
                check(dut.bus2cpu_ready_o === 1'b0 && dut.bus2cpu_rdata_o === 32'd0,
                      "idle CPU response is zero");
            end

            if (dut.valid_idex_o && !dut.stall_ex_o) begin
                check(dut.pc_idex_o === (retired * 4), "instruction retirement order");
                retired = retired + 1;
            end
            stall_before = dut.stall_ex_o;
            finish_before = dut.valid_idex_o && !dut.stall_ex_o && dut.pc_idex_o == 32'h2C;
            saved_payload = payload;
            saved_pc = dut.pc_o;
            saved_ex_pc = dut.pc_idex_o;
            saved_ifid = {dut.valid_ifid_o, dut.pc_ifid_o, dut.instr_ifid_o};
            for (i = 1; i < 32; i = i + 1)
                saved_regs[i] = dut.regfile_inst.reg_file[i];
            was_waiting = dut.data_req && !dut.bus2cpu_ready_o;

            #1;
            if (stall_before) begin
                check(dut.pc_o === saved_pc, "fetch PC holds across stalled edge");
                check(dut.pc_idex_o === saved_ex_pc, "EX PC holds across stalled edge");
                check({dut.valid_ifid_o, dut.pc_ifid_o, dut.instr_ifid_o} === saved_ifid,
                      "IF/ID holds across stalled edge");
                for (i = 1; i < 32; i = i + 1)
                    check(dut.regfile_inst.reg_file[i] === saved_regs[i], "registers unchanged during wait");
            end
            if (finish_before) begin
                finished = 1'b1;
                check_final;
            end
        end
    end
endmodule
`timescale 1ns / 1ps
// Only soc_top inputs are driven. All internal references below are observations.
module tb_gpio_system;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire [7:0] gpio_out_o;
    always #10 clk = ~clk;

    soc_top dut (
        .clk(clk), .rst_n(rst_n), .irq_external_i(1'b0),
        .gpio_out_o(gpio_out_o)
    );

    wire ex_valid = dut.pipeline_core_inst.valid_idex_o;
    wire [31:0] ex_pc = dut.pipeline_core_inst.pc_idex_o;
    wire cpu_stall = dut.pipeline_core_inst.stall_ex_o;
    wire cpu_req = dut.pipeline_core_inst.data_req;
    wire cpu_we = dut.pipeline_core_inst.data_we;
    wire [31:0] cpu_addr = dut.pipeline_core_inst.data_addr;
    wire [31:0] cpu_wdata = dut.pipeline_core_inst.ram_wr_data_ex_o;
    wire [3:0] cpu_wstrb = dut.pipeline_core_inst.ram_wr_sel_ex_o;
    wire cpu_ready = dut.pipeline_core_inst.bus2cpu_ready_o;
    wire [31:0] cpu_rdata = dut.pipeline_core_inst.bus2cpu_rdata_o;
    wire ram_req = dut.pipeline_core_inst.bus2ram_req_o;
    wire ram_ready = dut.pipeline_core_inst.ram_ready_o;
    wire wb_en = dut.pipeline_core_inst.wr_en_ex_o;
    wire [4:0] wb_rd = dut.pipeline_core_inst.wr_addr_ex_o;
    wire [31:0] wb_data = dut.pipeline_core_inst.wr_data_ex_o;
    wire [69:0] payload = {cpu_req, cpu_we, cpu_addr, cpu_wdata, cpu_wstrb};

    integer errors = 0;
    integer retired = 0;
    integer gpio_reads = 0, gpio_writes = 0;
    integer ram_reads = 0, ram_writes = 0;
    integer wait_edges = 0;
    integer i;
    reg [7:0] expected_gpio = 8'd0;
    reg [31:0] expected_regs [1:9];
    reg expected_mem, expected_dev, expected_we, expected_wb;
    reg [31:0] expected_addr, expected_wdata, expected_rdata, expected_wb_data;
    reg [3:0] expected_mask;
    reg [4:0] expected_rd;
    reg waiting = 1'b0;
    reg [69:0] saved_payload;
    reg [31:0] saved_pc, saved_fetch_pc;
    reg [64:0] saved_ifid;
    reg [31:0] saved_regs [1:31];
    reg stall_before, finish_before, wb_before;
    reg [4:0] rd_before;
    reg [31:0] wb_data_before;

    task check;
        input condition;
        input [8*110-1:0] label;
        begin
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s time=%0t EX_PC=%08h GPIO=%02h",
                         label, $time, ex_pc, gpio_out_o);
            end
        end
    endtask

    task check_final;
        begin
            check(retired == 15, "all instructions retired once in program order");
            check(gpio_reads == 4 && gpio_writes == 4, "GPIO accesses completed exactly once");
            check(ram_reads == 1 && ram_writes == 1, "RAM read and write completed once");
            check(gpio_out_o === 8'h3C, "final external GPIO output is 3C");
            for (i = 1; i <= 9; i = i + 1)
                check(dut.pipeline_core_inst.regfile_inst.reg_file[i] === expected_regs[i],
                      "final program register value");
            check(dut.pipeline_core_inst.data_ram_target_inst.data_ram_inst.memory[0] === 32'hA6,
                  "RAM address 0 holds A6");
            for (i = 1; i < 32; i = i + 1)
                check(dut.pipeline_core_inst.data_ram_target_inst.data_ram_inst.memory[i] === 32'd0,
                      "other RAM words remain zero");
            if (errors == 0) begin
                $display("PASS: GPIO system checks passed");
                $finish;
            end else
                $fatal(1, "FAIL: GPIO system checks failed (%0d errors)", errors);
        end
    endtask

    initial begin
        expected_regs[1] = 32'h10000000;
        expected_regs[2] = 32'hA5; expected_regs[3] = 32'hA5;
        expected_regs[4] = 32'hA6; expected_regs[5] = 32'h3C;
        expected_regs[6] = 32'hA5; expected_regs[7] = 32'h3C;
        expected_regs[8] = 32'd0; expected_regs[9] = 32'hA6;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
    end

    initial begin
        #10000;
        $fatal(1, "FAIL: GPIO system timeout EX_PC=%08h retired=%0d", ex_pc, retired);
    end

    // All completion/retirement decisions use signals BEFORE the rising-edge
    // nonblocking updates. External output and register storage are checked #1 later.
    always @(posedge clk) begin
        if (!rst_n) begin
            expected_gpio = 8'd0;
            #1;
            check(gpio_out_o === 8'd0, "synchronous reset clears GPIO");
        end else begin
            check((^{ex_valid, cpu_stall, cpu_req, cpu_ready, ram_req,
                      dut.bus2dev_req_o, dut.gpio_ready_o, wb_en}) !== 1'bx,
                  "control signals contain no X/Z");
            check((^{gpio_out_o, cpu_rdata, dut.gpio_rdata_o}) !== 1'bx,
                  "output and read data contain no X/Z");
            check(gpio_out_o === expected_gpio, "GPIO holds expected value before edge");
            if (waiting)
                check(payload === saved_payload, "waiting request payload held through completion");

            // Independent program expectations: a missing request is detected
            // even when the implementation never asserts cpu_req.
            expected_mem = 1'b0; expected_dev = 1'b0; expected_we = 1'b0;
            expected_wb = 1'b0; expected_rd = 5'd0;
            expected_addr = 32'd0; expected_wdata = 32'd0;
            expected_rdata = 32'd0; expected_mask = 4'b1111;
            expected_wb_data = 32'd0;
            if (ex_valid) begin
                case (ex_pc)
                    32'h00: begin expected_wb = 1; expected_rd = 1; expected_wb_data = 32'h10000000; end
                    32'h04: begin expected_wb = 1; expected_rd = 2; expected_wb_data = 32'hA5; end
                    32'h08: begin
                        expected_mem = 1; expected_dev = 1; expected_we = 1;
                        expected_addr = 32'h10000000; expected_wdata = 32'hA5;
                    end
                    32'h0C: begin
                        expected_mem = 1; expected_dev = 1; expected_addr = 32'h10000000;
                        expected_rdata = 32'hA5;
                        expected_wb = 1; expected_rd = 3; expected_wb_data = 32'hA5;
                    end
                    32'h10: begin expected_wb = 1; expected_rd = 4; expected_wb_data = 32'hA6; end
                    32'h14: begin expected_mem = 1; expected_we = 1; expected_wdata = 32'hA6; end
                    32'h18: begin expected_wb = 1; expected_rd = 5; expected_wb_data = 32'h3C; end
                    32'h1C: begin
                        expected_mem = 1; expected_dev = 1; expected_we = 1;
                        expected_addr = 32'h10000001; expected_wdata = 32'h00003C00;
                        expected_mask = 4'b0010;
                    end
                    32'h20: begin
                        expected_mem = 1; expected_dev = 1; expected_addr = 32'h10000000;
                        expected_rdata = 32'hA5;
                        expected_wb = 1; expected_rd = 6; expected_wb_data = 32'hA5;
                    end
                    32'h24: begin
                        expected_mem = 1; expected_dev = 1; expected_we = 1;
                        expected_addr = 32'h10000000; expected_wdata = 32'h3C;
                        expected_mask = 4'b0001;
                    end
                    32'h28: begin
                        expected_mem = 1; expected_dev = 1; expected_addr = 32'h10000000;
                        expected_rdata = 32'h3C;
                        expected_wb = 1; expected_rd = 7; expected_wb_data = 32'h3C;
                    end
                    32'h2C: begin
                        expected_mem = 1; expected_dev = 1; expected_we = 1;
                        expected_addr = 32'h10000004; expected_wdata = 32'hA5;
                    end
                    32'h30: begin
                        expected_mem = 1; expected_dev = 1; expected_addr = 32'h10000004;
                        expected_wb = 1; expected_rd = 8; expected_wb_data = 32'd0;
                    end
                    32'h34: begin
                        expected_mem = 1; expected_rdata = 32'hA6;
                        expected_wb = 1; expected_rd = 9; expected_wb_data = 32'hA6;
                    end
                    32'h38: begin expected_wb = 1; expected_rd = 0; expected_wb_data = 32'h3C; end
                    default: check(1'b0, "unexpected valid EX program address");
                endcase
            end

            check(cpu_req === expected_mem, "program instruction produces expected request");
            if (expected_mem) begin
                check(cpu_addr === expected_addr && cpu_we === expected_we, "CPU address and direction");
                if (expected_we)
                    check(cpu_wdata === expected_wdata && cpu_wstrb === expected_mask,
                          "CPU store data placement and byte mask");
                check({dut.bus2dev_we_o, dut.bus2dev_addr_o, dut.bus2dev_wdata_o, dut.bus2dev_wstrb_o}
                      === {cpu_we, cpu_addr, cpu_wdata, cpu_wstrb}, "DEV payload forwarded without changes");
                check({dut.pipeline_core_inst.bus2ram_we_o, dut.pipeline_core_inst.bus2ram_addr_o,
                       dut.pipeline_core_inst.bus2ram_wdata_o, dut.pipeline_core_inst.bus2ram_wstrb_o}
                      === {cpu_we, cpu_addr, cpu_wdata, cpu_wstrb}, "RAM payload forwarded without changes");
                if (expected_dev) begin
                    check(dut.bus2dev_req_o === 1'b1 && ram_req === 1'b0, "GPIO selected; RAM isolated");
                    check(dut.gpio_ready_o === 1'b1 && cpu_ready === 1'b1 && cpu_stall === 1'b0,
                          "GPIO access completes without a wait cycle");
                    check(dut.gpio_rdata_o === expected_rdata, "GPIO target response");
                end else begin
                    check(ram_req === 1'b1 && dut.bus2dev_req_o === 1'b0, "RAM selected; GPIO isolated");
                    check(cpu_ready === ram_ready, "RAM supplies completion signal");
                    check(cpu_stall === !ram_ready, "RAM wait controls CPU stall");
                end
                check(cpu_rdata === (cpu_ready ? expected_rdata : 32'd0), "selected CPU read response");
                if (cpu_req && cpu_ready) begin
                    if (expected_dev)
                        check(wait_edges == 0, "GPIO adds no wait edges");
                    else
                        check(wait_edges == 1, "RAM has one preparation edge");
                    wait_edges = 0;
                end else
                    wait_edges = wait_edges + 1;
            end else begin
                check(dut.bus2dev_req_o === 1'b0 && ram_req === 1'b0, "idle target requests");
                check(cpu_ready === 1'b0 && cpu_rdata === 32'd0, "idle CPU response");
                check(cpu_stall === 1'b0, "non-memory instructions do not stall");
            end

            // Count actual target handshakes, independently of instruction retirement.
            if (dut.bus2dev_req_o && dut.gpio_ready_o) begin
                if (dut.bus2dev_we_o) gpio_writes = gpio_writes + 1;
                else gpio_reads = gpio_reads + 1;
            end
            if (ram_req && ram_ready) begin
                if (cpu_we) ram_writes = ram_writes + 1;
                else ram_reads = ram_reads + 1;
            end
            if (ex_valid && !cpu_stall) begin
                check(ex_pc === (retired * 4), "instruction retirement order");
                retired = retired + 1;
                check(wb_en === expected_wb, "register writeback enable");
                if (expected_wb)
                    check(wb_rd === expected_rd && wb_data === expected_wb_data,
                          "register writeback destination and value");
                // Expected output comes from program intent, not the DUT's GPIO state.
                if (ex_pc == 32'h08) expected_gpio = 8'hA5;
                if (ex_pc == 32'h24) expected_gpio = 8'h3C;
            end else
                check(wb_en === 1'b0, "invalid/waiting instruction cannot write a register");

            stall_before = cpu_stall;
            finish_before = ex_valid && !cpu_stall && ex_pc == 32'h38;
            wb_before = ex_valid && !cpu_stall && expected_wb && expected_rd != 0;
            rd_before = expected_rd;
            wb_data_before = expected_wb_data;
            waiting = cpu_req && !cpu_ready;
            saved_payload = payload;
            saved_pc = ex_pc;
            saved_fetch_pc = dut.pipeline_core_inst.pc_o;
            saved_ifid = {dut.pipeline_core_inst.valid_ifid_o,
                          dut.pipeline_core_inst.pc_ifid_o, dut.pipeline_core_inst.instr_ifid_o};
            for (i = 1; i < 32; i = i + 1)
                saved_regs[i] = dut.pipeline_core_inst.regfile_inst.reg_file[i];

            #1;
            check(gpio_out_o === expected_gpio, "GPIO output after every clock edge");
            if (wb_before)
                check(dut.pipeline_core_inst.regfile_inst.reg_file[rd_before] === wb_data_before,
                      "register storage after writeback edge");
            if (stall_before) begin
                check(ex_pc === saved_pc && dut.pipeline_core_inst.pc_o === saved_fetch_pc,
                      "EX and fetch PC held during RAM wait");
                check({dut.pipeline_core_inst.valid_ifid_o, dut.pipeline_core_inst.pc_ifid_o,
                       dut.pipeline_core_inst.instr_ifid_o} === saved_ifid, "IF/ID held during RAM wait");
                for (i = 1; i < 32; i = i + 1)
                    check(dut.pipeline_core_inst.regfile_inst.reg_file[i] === saved_regs[i],
                          "register storage unchanged during RAM wait");
            end
            if (finish_before)
                check_final;
        end
    end
endmodule
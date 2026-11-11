`timescale 1ns / 1ps

// CPU instructions produce all bus traffic. The TB observes internal signals.
module tb_uart_tx_system;
    localparam T_NONE=0, T_RAM=1, T_GPIO=2, T_TIMER=3, T_UART=4, T_UNMAPPED=5;
    localparam integer CLKS_PER_BIT = 4;
    localparam integer FRAME_CYCLES = 10 * CLKS_PER_BIT;
    localparam [9:0] FIRST_FRAME = {1'b1, 8'h55, 1'b0};
    localparam [9:0] SECOND_FRAME = {1'b1, 8'hA6, 1'b0};

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire [7:0] gpio_out_o;
    wire uart_tx_o;
    always #10 clk = ~clk;

    soc_top dut (
        .clk(clk), .rst_n(rst_n), .irq_external_i(1'b0),
        .gpio_out_o(gpio_out_o), .uart_tx_o(uart_tx_o)
    );

    wire ex_valid = dut.pipeline_core_inst.valid_idex_o;
    wire [31:0] ex_pc = dut.pipeline_core_inst.pc_idex_o;
    wire cpu_stall = dut.pipeline_core_inst.stall_ex_o;
    wire cpu_req = dut.pipeline_core_inst.data_req;
    wire cpu_we = dut.pipeline_core_inst.data_we;
    wire [31:0] cpu_addr = dut.pipeline_core_inst.data_addr;
    wire [31:0] cpu_wdata = dut.pipeline_core_inst.ram_wr_data_ex_o;
    wire [3:0] cpu_mask = dut.pipeline_core_inst.ram_wr_sel_ex_o;
    wire cpu_ready = dut.pipeline_core_inst.bus2cpu_ready_o;
    wire [31:0] cpu_rdata = dut.pipeline_core_inst.bus2cpu_rdata_o;
    wire ram_req = dut.pipeline_core_inst.bus2ram_req_o;
    wire wb_en = dut.pipeline_core_inst.wr_en_ex_o;
    wire [4:0] wb_rd = dut.pipeline_core_inst.wr_addr_ex_o;
    wire [31:0] wb_data = dut.pipeline_core_inst.wr_data_ex_o;
    wire uart_busy = dut.uart_tx_target_inst.tx_busy;
    wire uart_start = dut.uart_tx_target_inst.tx_start;
    wire [7:0] uart_saved_byte = dut.uart_tx_target_inst.uart_tx_inst.data_reg;
    wire [69:0] cpu_payload = {cpu_req, cpu_we, cpu_addr, cpu_wdata, cpu_mask};

    integer errors = 0;
    integer step = 0;
    integer edge_number = 0;
    integer wait_edges = 0;
    integer uart_wait_edges = 0;
    integer uart_writes_completed = 0;
    integer frame_accepts = 0;
    integer first_accept_edge = -1;
    integer frame_accept_edge = -1;
    integer frame_age;
    integer i;
    reg program_done = 1'b0;
    reg second_frame_done = 1'b0;
    reg waiting = 1'b0;
    reg [69:0] saved_payload;
    reg [31:0] saved_ex_pc, saved_fetch_pc;
    reg [64:0] saved_ifid;
    reg [31:0] expected_regs [1:31];
    reg [7:0] expected_gpio = 8'd0;
    reg [31:0] expected_limit = 32'd1;
    reg [31:0] expected_ram_word = 32'd0;

    integer target;
    reg expected_mem, expected_write, expected_ready, expected_stall;
    reg expected_start, expected_wb;
    reg [31:0] expected_addr, expected_store, expected_read, expected_result;
    reg [3:0] expected_mask;
    reg [4:0] expected_rd;

    task check;
        input condition;
        input [8*110-1:0] label;
        begin
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s t=%0t edge=%0d EX_PC=%08h", label, $time, edge_number, ex_pc);
                $display("  req/we/ready/stall=%b/%b/%b/%b addr=%08h data=%08h mask=%b",
                         cpu_req, cpu_we, cpu_ready, cpu_stall, cpu_addr, cpu_wdata, cpu_mask);
                $display("  RAM/GPIO/Timer/UART req=%b/%b/%b/%b UART busy/start/line=%b/%b/%b",
                         ram_req, dut.gpio_req, dut.timer_req, dut.uart_tx_req,
                         uart_busy, uart_start, uart_tx_o);
            end
        end
    endtask

    task plan_register_write;
        input [4:0] rd;
        input [31:0] value;
        begin
            expected_wb = 1'b1;
            expected_rd = rd;
            expected_result = value;
        end
    endtask

    task plan_store;
        input integer destination;
        input [31:0] address;
        input [31:0] value;
        input [3:0] mask;
        begin
            target = destination;
            expected_addr = address;
            expected_write = 1'b1;
            expected_store = value;
            expected_mask = mask;
        end
    endtask

    task plan_load;
        input integer source;
        input [31:0] address;
        input [4:0] rd;
        input [31:0] value;
        begin
            target = source;
            expected_addr = address;
            expected_read = value;
            plan_register_write(rd, value);
        end
    endtask

    task prepare_expectations;
        begin
            target = T_NONE;
            expected_write = 1'b0;
            expected_addr = 32'd0;
            expected_store = 32'd0;
            expected_mask = 4'd0;
            expected_read = 32'd0;
            expected_wb = 1'b0;
            expected_rd = 5'd0;
            expected_result = 32'd0;

            if (ex_valid === 1'b1) begin
                case (ex_pc)
                    32'h00: plan_register_write(5'd1, 32'h10000000);
                    32'h04: plan_register_write(5'd2, 32'h3C);
                    32'h08: plan_store(T_GPIO, 32'h10000000, 32'h3C, 4'b0001);
                    32'h0C: plan_register_write(5'd3, 32'd3);
                    32'h10: plan_store(T_TIMER, 32'h10000014, 32'd3, 4'b1111);
                    32'h14: plan_register_write(5'd4, 32'h55);
                    32'h18: plan_register_write(5'd5, 32'hA6);
                    32'h1C: plan_store(T_UART, 32'h10000020, 32'h55, 4'b0001);
                    32'h20: plan_load(T_UART, 32'h10000024, 5'd6, 32'd1);
                    32'h24: plan_store(T_UART, 32'h10000020, 32'hA6, 4'b0001);
                    32'h28: plan_load(T_UART, 32'h10000024, 5'd7, 32'd1);
                    32'h2C: plan_load(T_GPIO, 32'h10000000, 5'd8, 32'h3C);
                    32'h30: plan_load(T_TIMER, 32'h10000014, 5'd9, 32'd3);
                    32'h34: plan_store(T_RAM, 32'd0, 32'h3C, 4'b1111);
                    32'h38: plan_load(T_RAM, 32'd0, 5'd10, 32'h3C);
                    32'h3C: plan_load(T_UART, 32'h1000002F, 5'd11, 32'd0);
                    32'h40: plan_load(T_UNMAPPED, 32'h10000030, 5'd12, 32'd0);
                    32'h44: plan_register_write(5'd0, 32'h48);
                    default: check(1'b0, "unexpected instruction PC");
                endcase
            end

            expected_mem = (target != T_NONE);
            if (target == T_NONE) begin
                expected_ready = 1'b0; // Idle bus convention.
            end else if (target == T_RAM) begin
                expected_ready = (wait_edges == 1); // RAM completes after its preparation edge.
            end else if (target == T_UART && ex_pc == 32'h24) begin
                // The held second byte may be sampled one edge after frame 1 ends.
                expected_ready = first_accept_edge >= 0 &&
                                 edge_number >= first_accept_edge + FRAME_CYCLES + 1;
            end else begin
                expected_ready = 1'b1; // GPIO/Timer, UART reads and the default route.
            end
            expected_stall = expected_mem && !expected_ready;
            expected_start = (target == T_UART) && expected_write && expected_ready;
        end
    endtask

    task check_state;
        integer reg_index;
        begin
            check(gpio_out_o === expected_gpio, "GPIO saved output");
            check(dut.timer_target_inst.limit_reg === expected_limit, "Timer saved limit");
            check(dut.timer_target_inst.en_reg === 1'b0 &&
                  dut.timer_target_inst.irq_en_reg === 1'b0 &&
                  dut.timer_target_inst.cnt_value_o === 32'd0, "Timer stays disabled");
            check(dut.timer_irq_o === 1'b0 && dut.irq2cpu === 1'b0, "no interrupt source");
            check(dut.pipeline_core_inst.data_ram_target_inst.data_ram_inst.memory[0] === expected_ram_word,
                  "RAM word zero follows the program store");
            for (reg_index=1; reg_index<32; reg_index=reg_index+1) begin
                if (dut.pipeline_core_inst.regfile_inst.reg_file[reg_index] !== expected_regs[reg_index]) begin
                    errors = errors + 1;
                    $display("FAIL: x%0d=%08h expected=%08h t=%0t", reg_index,
                             dut.pipeline_core_inst.regfile_inst.reg_file[reg_index],
                             expected_regs[reg_index], $time);
                end
            end
        end
    endtask

    task check_serial_sample;
        begin
            if (frame_accepts == 0) begin
                check(uart_busy === 1'b0 && uart_tx_o === 1'b1, "idle before first frame");
                check(uart_saved_byte === 8'd0, "no UART byte captured before first completion");
            end else begin
                frame_age = edge_number - frame_accept_edge;
                if (frame_accepts == 1)
                    check(uart_saved_byte === 8'h55, "first byte remains saved during second-write wait");
                else
                    check(uart_saved_byte === 8'hA6, "second accepted byte remains saved");

                if (frame_age < FRAME_CYCLES) begin
                    check(uart_busy === 1'b1, "busy during every frame cycle");
                    if (frame_accepts == 1)
                        check(uart_tx_o === FIRST_FRAME[frame_age / CLKS_PER_BIT], "first frame serial bit");
                    else
                        check(uart_tx_o === SECOND_FRAME[frame_age / CLKS_PER_BIT], "second frame serial bit");
                end else begin
                    check(uart_busy === 1'b0 && uart_tx_o === 1'b1, "line idle at frame end");
                    if (frame_accepts == 2 && frame_age == FRAME_CYCLES)
                        second_frame_done = 1'b1;
                end
            end
        end
    endtask

    task check_final;
        integer word_index;
        begin
            check(step == 18 && program_done && second_frame_done, "program and both serial frames completed");
            check(frame_accepts == 2 && uart_writes_completed == 2, "exactly two UART write completions and starts");
            check(uart_wait_edges == 39, "second UART write waited A+2 through A+40");
            check(expected_gpio == 8'h3C && expected_limit == 32'd3 && expected_ram_word == 32'h3C,
                  "program reached GPIO/Timer/RAM writes");
            for (word_index=1; word_index<32; word_index=word_index+1)
                check(dut.pipeline_core_inst.data_ram_target_inst.data_ram_inst.memory[word_index] === 32'd0,
                      "other RAM words unchanged");
            if (errors == 0) begin
                $display("PASS: UART TX system checks passed");
                $finish;
            end else begin
                $fatal(1, "FAIL: UART TX system checks failed (%0d errors)", errors);
            end
        end
    endtask

    initial begin
        for (i=1; i<32; i=i+1)
            expected_regs[i] = 32'd0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
    end

    initial begin
        #20000;
        $fatal(1, "FAIL: UART TX system timeout step=%0d program_done=%b frames_done=%b",
               step, program_done, second_frame_done);
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            #1;
            check(uart_busy === 1'b0 && uart_tx_o === 1'b1, "UART reset idle");
            check_state;
        end else begin
            edge_number = edge_number + 1;
            check((^{ex_valid, cpu_req, cpu_ready, cpu_stall, wb_en, uart_start}) !== 1'bx,
                  "control signals contain no X/Z");
            check(dut.pipeline_core_inst.ex_inst.irq_take === 1'b0 &&
                  dut.pipeline_core_inst.ex_inst.trap_enter_ex_o === 1'b0,
                  "program runs without a trap");
            prepare_expectations;
            if (ex_valid === 1'b1) begin
                if (program_done)
                    check(ex_pc === 32'h44, "only final JAL loop after program completion");
                else
                    check(ex_pc === (step * 4), "main program instruction order");
            end
            if (waiting)
                check(cpu_payload === saved_payload, "held request/address/data/mask through completion edge");

            // Check routing from the expected instruction, even if DUT misses the request.
            check(cpu_req === expected_mem, "CPU memory request");
            check(ram_req === (target == T_RAM), "RAM exclusive route");
            check(dut.gpio_req === (target == T_GPIO), "GPIO exclusive route");
            check(dut.timer_req === (target == T_TIMER), "Timer exclusive route");
            check(dut.uart_tx_req === (target == T_UART), "UART exclusive route including byte 2F");
            check(dut.bus2dev_req_o === ((target == T_GPIO) || (target == T_TIMER) || (target == T_UART)),
                  "DEV request, including unmapped address 30");
            check(cpu_ready === expected_ready && cpu_stall === expected_stall, "CPU ready/stall before edge");
            check(cpu_rdata === (expected_ready ? expected_read : 32'd0), "CPU read response before edge");
            check(uart_start === expected_start, "actual UART start at sampling edge");

            if (expected_mem) begin
                check(cpu_addr === expected_addr && cpu_we === expected_write, "memory address/direction");
                if (expected_write)
                    check(cpu_wdata === expected_store && cpu_mask === expected_mask, "store data/mask");
            end
            if (target == T_UART) begin
                check(dut.uart_tx_ready_o === expected_ready && dut.uart_tx_rdata_o === expected_read,
                      "UART selected bus response");
                check({dut.bus2dev_addr_o, dut.bus2dev_we_o, dut.bus2dev_wdata_o, dut.bus2dev_wstrb_o}
                      === {cpu_addr, cpu_we, cpu_wdata, cpu_mask}, "CPU payload forwarded to UART");
            end

            if (ex_valid === 1'b1 && ex_pc == 32'h24 && expected_stall) begin
                uart_wait_edges = uart_wait_edges + 1;
                if (uart_wait_edges == 1)
                    check(edge_number == first_accept_edge + 2, "second UART write first waits at A+2");
                if (edge_number == first_accept_edge + FRAME_CYCLES)
                    check(uart_busy === 1'b1 && uart_tx_o === 1'b1 &&
                          uart_start === 1'b0 && cpu_ready === 1'b0,
                          "A+40 before edge: first STOP and second byte pending");
            end

            // Sample the real handshake before nonblocking DUT updates.
            if (dut.uart_tx_req === 1'b1 && dut.uart_tx_ready_o === 1'b1 && cpu_we === 1'b1)
                uart_writes_completed = uart_writes_completed + 1;
            if (uart_start === 1'b1) begin
                check(cpu_req === 1'b1 && cpu_ready === 1'b1 && dut.uart_tx_req === 1'b1,
                      "each UART start accompanies an actual bus completion");
                frame_accepts = frame_accepts + 1;
                frame_accept_edge = edge_number;
                if (frame_accepts == 1) begin
                    check(ex_pc === 32'h1C && cpu_wdata === 32'h55, "first write hands over byte 55");
                    first_accept_edge = edge_number;
                end else if (frame_accepts == 2) begin
                    check(ex_pc === 32'h24 && cpu_wdata === 32'hA6, "second write hands over byte A6");
                    check(edge_number == first_accept_edge + FRAME_CYCLES + 1 &&
                          uart_busy === 1'b0 && uart_tx_o === 1'b1 && uart_saved_byte === 8'h55,
                          "A+41 before edge: accept second byte only now");
                end else begin
                    $fatal(1, "FAIL: unexpected additional UART start");
                end
            end

            if (ex_valid === 1'b1 && cpu_stall === 1'b0) begin
                check(wb_en === expected_wb, "writeback enable");
                if (expected_wb) begin
                    check(wb_rd === expected_rd && wb_data === expected_result, "writeback destination/value");
                    if (expected_rd != 0)
                        expected_regs[expected_rd] = expected_result;
                end
                case (ex_pc)
                    32'h08: expected_gpio = 8'h3C;
                    32'h10: expected_limit = 32'd3;
                    32'h34: expected_ram_word = 32'h3C;
                    32'h44: program_done = 1'b1;
                endcase
                if (step < 18)
                    step = step + 1;
                if (expected_mem)
                    wait_edges = 0;
            end else begin
                check(wb_en === 1'b0, "stalled instruction or bubble cannot write back");
                if (ex_valid === 1'b1 && cpu_stall === 1'b1)
                    wait_edges = wait_edges + 1;
            end

            waiting = (cpu_req === 1'b1 && cpu_ready === 1'b0);
            saved_payload = cpu_payload;
            saved_ex_pc = ex_pc;
            saved_fetch_pc = dut.pipeline_core_inst.pc_o;
            saved_ifid = {dut.pipeline_core_inst.valid_ifid_o,
                          dut.pipeline_core_inst.pc_ifid_o, dut.pipeline_core_inst.instr_ifid_o};
            #1;
            check_state;
            check_serial_sample;
            if (waiting) begin
                check(ex_pc === saved_ex_pc && dut.pipeline_core_inst.pc_o === saved_fetch_pc,
                      "CPU PCs held at the wait edge");
                check({dut.pipeline_core_inst.valid_ifid_o, dut.pipeline_core_inst.pc_ifid_o,
                       dut.pipeline_core_inst.instr_ifid_o} === saved_ifid, "IF/ID held at the wait edge");
            end
            if (first_accept_edge >= 0 && edge_number == first_accept_edge + FRAME_CYCLES)
                check(cpu_req === 1'b1 && cpu_addr === 32'h10000020 &&
                      cpu_wdata === 32'hA6 && cpu_mask === 4'b0001 &&
                      cpu_ready === 1'b1 && uart_start === 1'b1 &&
                      uart_busy === 1'b0 && uart_tx_o === 1'b1 && uart_saved_byte === 8'h55,
                      "A+40 after edge: line idle and second byte offered for next edge");

            // The CPU can enter its final loop while the second frame is still shifting.
            if (program_done && second_frame_done)
                check_final;
        end
    end
endmodule

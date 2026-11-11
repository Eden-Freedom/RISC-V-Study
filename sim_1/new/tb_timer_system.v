`timescale 1ns / 1ps
// TB drives only soc_top clock/reset/IRQ=0. Internal references observe the DUT.
// CPU requests are generated exclusively by the instr_rom program.
module tb_timer_system;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire [7:0] gpio_out_o;
    always #10 clk = ~clk;

    soc_top dut (
        .clk(clk), .rst_n(rst_n), .irq_external_i(1'b0), .gpio_out_o(gpio_out_o)
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
    wire [31:0] timer_count = dut.timer_target_inst.cnt_value_o;
    wire timer_done = dut.timer_target_inst.cnt_done_o;
    wire [69:0] payload = {cpu_req,cpu_we,cpu_addr,cpu_wdata,cpu_wstrb};

    localparam T_NONE=0, T_RAM=1, T_GPIO=2, T_TIMER=3, T_UNMAPPED=4;
    integer errors = 0;
    integer retired = 0;
    integer wait_edges = 0;
    integer timer_reads = 0, timer_writes = 0;
    integer gpio_reads = 0, gpio_writes = 0;
    integer ram_reads = 0, ram_writes = 0, unmapped_reads = 0;
    integer i;
    integer expected_target;
    reg expected_mem, expected_we, expected_wb;
    reg [31:0] expected_addr, expected_wdata, expected_rdata, expected_wb_data;
    reg [3:0] expected_mask;
    reg [4:0] expected_rd;
    reg [31:0] expected_regs [1:13];

    // Program checkpoints, deliberately not a copy of Timer counter/update RTL.
    reg expected_timer_en = 1'b0;
    reg [31:0] expected_limit = 32'd1;
    reg [31:0] expected_count = 32'd0;
    reg expected_done = 1'b0;
    reg [7:0] expected_gpio = 8'd0;
    reg waiting = 1'b0;
    reg [69:0] saved_payload;
    reg [31:0] saved_ex_pc, saved_fetch_pc;
    reg [64:0] saved_ifid;
    reg [31:0] saved_regs [1:31];
    reg stall_before, finish_before, wb_before;
    reg [4:0] rd_before;
    reg [31:0] wb_data_before;
    reg checked_last_byte = 1'b0;
    reg checked_unmapped = 1'b0;
    reg checked_count_sample = 1'b0;
    reg checked_timer_during_stall = 1'b0;

    task check;
        input condition;
        input [8*110-1:0] label;
        begin
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s time=%0t EX_PC=%08h", label, $time, ex_pc);
                $display("  req=%b we=%b addr=%08h ready=%b stall=%b rdata=%08h",
                         cpu_req,cpu_we,cpu_addr,cpu_ready,cpu_stall,cpu_rdata);
                $display("  RAM/GPIO/Timer req=%b/%b/%b count=%0d done=%b gpio=%02h",
                         ram_req,dut.gpio_req,dut.timer_req,timer_count,timer_done,gpio_out_o);
            end
        end
    endtask

    task check_timer_state;
        begin
            check(dut.timer_target_inst.en_reg === expected_timer_en, "Timer saved enable");
            check(dut.timer_target_inst.limit_reg === expected_limit, "Timer saved limit");
            check(timer_count === expected_count, "Timer count at program checkpoint");
            check(timer_done === expected_done, "Timer expiry at program checkpoint");
            check(gpio_out_o === expected_gpio, "GPIO only changes at its intended write");
        end
    endtask

    task check_final;
        begin
            check(retired == 19, "all instructions completed once in order");
            check(timer_reads == 6 && timer_writes == 3, "Timer read/write completions");
            check(gpio_reads == 1 && gpio_writes == 1, "GPIO read/write completions");
            check(ram_reads == 1 && ram_writes == 1, "RAM read/write completions");
            check(unmapped_reads == 1, "unmapped read completes once");
            check(checked_count_sample && checked_timer_during_stall,
                  "COUNT sample and Timer progress during RAM wait observed");
            check(checked_last_byte && checked_unmapped, "both window-boundary routes observed");
            for (i=1; i<=13; i=i+1)
                check(dut.pipeline_core_inst.regfile_inst.reg_file[i] === expected_regs[i],
                      "final program register value");
            for (i=14; i<32; i=i+1)
                check(dut.pipeline_core_inst.regfile_inst.reg_file[i] === 32'd0,
                      "unused registers remain zero");
            check(dut.pipeline_core_inst.data_ram_target_inst.data_ram_inst.memory[0] === 32'd3,
                  "RAM address zero stores three");
            for (i=1; i<32; i=i+1)
                check(dut.pipeline_core_inst.data_ram_target_inst.data_ram_inst.memory[i] === 32'd0,
                      "other RAM words unchanged");
            check_timer_state;
            if (errors == 0) begin
                $display("PASS: timer system checks passed");
                $finish;
            end else
                $fatal(1,"FAIL: timer system checks failed (%0d errors)",errors);
        end
    endtask

    initial begin
        expected_regs[1]=32'h10000000; expected_regs[2]=3; expected_regs[3]=0;
        expected_regs[4]=1; expected_regs[5]=3; expected_regs[6]=32'h3C;
        expected_regs[7]=32'h3C; expected_regs[8]=2; expected_regs[9]=0;
        expected_regs[10]=0; expected_regs[11]=0; expected_regs[12]=0; expected_regs[13]=3;
        repeat (3) @(negedge clk);
        rst_n=1'b1;
    end

    initial begin
        #20000;
        $fatal(1,"FAIL: timer system timeout EX_PC=%08h retired=%0d",ex_pc,retired);
    end

    // Read/completion/writeback sampling happens BEFORE the nonblocking updates.
    // State/storage checks happen AFTER #1; a CPU load does not sample that later value.
    always @(posedge clk) begin
        if (!rst_n) begin
            expected_timer_en=0; expected_limit=1; expected_count=0;
            expected_done=0; expected_gpio=0;
            #1;
            check_timer_state;
        end else begin
            check((^{ex_valid,cpu_stall,cpu_req,cpu_we,cpu_ready,ram_req,
                      dut.bus2dev_req_o,dut.gpio_req,dut.timer_req,
                      dut.gpio_ready_o,dut.timer_ready_o,wb_en}) !== 1'bx,
                  "control signals contain no X/Z");
            check((^{cpu_rdata,gpio_out_o,timer_count,timer_done}) !== 1'bx,
                  "response and state contain no X/Z");
            check_timer_state;
            if (waiting)
                check(payload === saved_payload,"RAM request held until completion");

            expected_mem=0; expected_target=T_NONE; expected_we=0; expected_wb=0;
            expected_addr=0; expected_wdata=0; expected_mask=4'b1111;
            expected_rdata=0; expected_rd=0; expected_wb_data=0;
            if (ex_valid) begin
                case (ex_pc)
                    32'h00: begin expected_wb=1; expected_rd=1; expected_wb_data=32'h10000000; end
                    32'h04: begin expected_wb=1; expected_rd=2; expected_wb_data=3; end
                    32'h08: begin
                        expected_mem=1; expected_target=T_TIMER; expected_we=1;
                        expected_addr=32'h10000014; expected_wdata=3;
                    end
                    32'h0C: begin
                        expected_mem=1; expected_target=T_TIMER; expected_we=1;
                        expected_addr=32'h10000010; expected_wdata=3;
                    end
                    32'h10: begin
                        expected_mem=1; expected_target=T_TIMER; expected_addr=32'h10000018;
                        expected_wb=1; expected_rd=3; expected_wb_data=0;
                    end
                    32'h14: begin
                        expected_mem=1; expected_target=T_RAM; expected_we=1; expected_wdata=3;
                    end
                    32'h18: begin
                        expected_mem=1; expected_target=T_TIMER; expected_addr=32'h1000001C;
                        expected_rdata=1; expected_wb=1; expected_rd=4; expected_wb_data=1;
                    end
                    32'h1C: begin
                        expected_mem=1; expected_target=T_TIMER; expected_addr=32'h10000018;
                        expected_rdata=3; expected_wb=1; expected_rd=5; expected_wb_data=3;
                    end
                    32'h20: begin expected_wb=1; expected_rd=6; expected_wb_data=32'h3C; end
                    32'h24: begin
                        expected_mem=1; expected_target=T_GPIO; expected_we=1;
                        expected_addr=32'h10000000; expected_wdata=32'h3C; expected_mask=4'b0001;
                    end
                    32'h28: begin
                        expected_mem=1; expected_target=T_GPIO; expected_addr=32'h10000000;
                        expected_rdata=32'h3C; expected_wb=1; expected_rd=7; expected_wb_data=32'h3C;
                    end
                    32'h2C: begin expected_wb=1; expected_rd=8; expected_wb_data=2; end
                    32'h30: begin
                        expected_mem=1; expected_target=T_TIMER; expected_we=1;
                        expected_addr=32'h10000010; expected_wdata=2;
                    end
                    32'h34: begin
                        expected_mem=1; expected_target=T_TIMER; expected_addr=32'h10000010;
                        expected_wb=1; expected_rd=9;
                    end
                    32'h38: begin
                        expected_mem=1; expected_target=T_TIMER; expected_addr=32'h10000018;
                        expected_wb=1; expected_rd=10;
                    end
                    32'h3C: begin
                        expected_mem=1; expected_target=T_TIMER; expected_addr=32'h1000001F;
                        expected_wb=1; expected_rd=11;
                    end
                    32'h40: begin
                        expected_mem=1; expected_target=T_UNMAPPED; expected_addr=32'h10000020;
                        expected_wb=1; expected_rd=12;
                    end
                    32'h44: begin
                        expected_mem=1; expected_target=T_RAM; expected_rdata=3;
                        expected_wb=1; expected_rd=13; expected_wb_data=3;
                    end
                    32'h48: begin expected_wb=1; expected_rd=0; expected_wb_data=32'h4C; end
                    default: check(1'b0,"unexpected valid EX instruction address");
                endcase
            end

            // Independent expectations catch missing requests, not just wrong requests.
            check(cpu_req === expected_mem,"program issues expected memory request");
            check(ram_req === (expected_target==T_RAM),"RAM request route");
            check(dut.gpio_req === (expected_target==T_GPIO),"GPIO request route");
            check(dut.timer_req === (expected_target==T_TIMER),"Timer request route");
            check(dut.bus2dev_req_o === ((expected_target==T_GPIO)||(expected_target==T_TIMER)),
                  "data_bus DEV route");
            check(dut.gpio_target_inst.req_i === dut.gpio_req &&
                  dut.timer_target_inst.req_i === dut.timer_req,"target request pin connections");

            if (expected_mem) begin
                check(cpu_addr === expected_addr && cpu_we === expected_we,"effective address/direction");
                if (expected_we)
                    check(cpu_wdata === expected_wdata && cpu_wstrb === expected_mask,"store data/mask");
                check({dut.bus2dev_we_o,dut.bus2dev_addr_o,dut.bus2dev_wdata_o,dut.bus2dev_wstrb_o}
                      === {cpu_we,cpu_addr,cpu_wdata,cpu_wstrb},"DEV payload forwarded unchanged");
                if (expected_target==T_RAM) begin
                    check(cpu_ready === ram_ready && cpu_stall === !ram_ready,"RAM wait/completion path");
                    check(dut.gpio_ready_o === 1'b0 && dut.timer_ready_o === 1'b0,
                          "unselected peripherals return idle ready");
                end else begin
                    check(cpu_ready === 1'b1 && cpu_stall === 1'b0,"peripheral/default immediate completion");
                    if (expected_target==T_TIMER)
                        check(dut.timer_ready_o === 1'b1 && dut.timer_rdata_o === expected_rdata,
                              "Timer response selected");
                    if (expected_target==T_GPIO)
                        check(dut.gpio_ready_o === 1'b1 && dut.gpio_rdata_o === expected_rdata,
                              "GPIO response selected");
                    if (expected_target==T_UNMAPPED)
                        check(dut.gpio_ready_o === 1'b0 && dut.timer_ready_o === 1'b0,
                              "unmapped read completes without a real target");
                end
                check(cpu_rdata === (cpu_ready ? expected_rdata : 32'd0),"CPU completion-edge read data");
                if (cpu_req && cpu_ready) begin
                    if (expected_target==T_RAM)
                        check(wait_edges==1,"RAM has exactly one preparation edge");
                    else
                        check(wait_edges==0,"peripheral/default adds no wait edges");
                    wait_edges=0;
                end else
                    wait_edges=wait_edges+1;
            end else begin
                check(cpu_ready === 1'b0 && cpu_rdata === 32'd0,"idle CPU response");
                check(cpu_stall === 1'b0,"non-memory instruction does not stall");
            end

            // Actual completions counted independently of instruction retirement.
            if (dut.timer_req && dut.timer_ready_o) begin
                if (cpu_we) timer_writes=timer_writes+1;
                else timer_reads=timer_reads+1;
            end
            if (dut.gpio_req && dut.gpio_ready_o) begin
                if (cpu_we) gpio_writes=gpio_writes+1;
                else gpio_reads=gpio_reads+1;
            end
            if (ram_req && ram_ready) begin
                if (cpu_we) ram_writes=ram_writes+1;
                else ram_reads=ram_reads+1;
            end
            if (expected_target==T_UNMAPPED && cpu_req && cpu_ready)
                unmapped_reads=unmapped_reads+1;

            // Capture writeback BEFORE Timer changes at this same edge.
            if (ex_valid && !cpu_stall) begin
                check(ex_pc === (retired*4),"instruction completion order");
                retired=retired+1;
                check(wb_en === expected_wb,"writeback enable");
                if (expected_wb)
                    check(wb_rd === expected_rd && wb_data === expected_wb_data,
                          "writeback destination/value at sampling edge");
            end else
                check(wb_en === 1'b0,"invalid/waiting instruction cannot write back");

            // Fixed program checkpoints describe intended Timer behavior.
            if (ex_valid) begin
                case (ex_pc)
                    32'h08: expected_limit=3;
                    32'h0C: begin expected_timer_en=1; expected_count=0; expected_done=0; end
                    32'h10: begin
                        check(timer_count === 32'd0 && wb_data === 32'd0,"COUNT load samples old zero");
                        checked_count_sample=1;
                        expected_count=1;
                    end
                    32'h14: begin
                        if (cpu_stall) begin
                            check(timer_count === 32'd1,"Timer is one before RAM preparation edge");
                            expected_count=2;
                            checked_timer_during_stall=1;
                        end else begin
                            check(timer_count === 32'd2,"Timer is two before RAM completion edge");
                            expected_count=3; expected_done=1;
                        end
                    end
                    32'h24: expected_gpio=8'h3C;
                    32'h30: begin expected_timer_en=0; expected_count=0; expected_done=0; end
                    32'h3C: checked_last_byte=1;
                    32'h40: checked_unmapped=1;
                endcase
            end

            stall_before=cpu_stall;
            finish_before=ex_valid && !cpu_stall && ex_pc==32'h48;
            wb_before=ex_valid && !cpu_stall && expected_wb && expected_rd!=0;
            rd_before=expected_rd;
            wb_data_before=expected_wb_data;
            waiting=cpu_req && !cpu_ready;
            saved_payload=payload;
            saved_ex_pc=ex_pc;
            saved_fetch_pc=dut.pipeline_core_inst.pc_o;
            saved_ifid={dut.pipeline_core_inst.valid_ifid_o,
                         dut.pipeline_core_inst.pc_ifid_o,dut.pipeline_core_inst.instr_ifid_o};
            for (i=1;i<32;i=i+1)
                saved_regs[i]=dut.pipeline_core_inst.regfile_inst.reg_file[i];

            #1;
            check_timer_state;
            if (wb_before)
                check(dut.pipeline_core_inst.regfile_inst.reg_file[rd_before] === wb_data_before,
                      "register storage after completion edge");
            if (stall_before) begin
                check(ex_pc === saved_ex_pc && dut.pipeline_core_inst.pc_o === saved_fetch_pc,
                      "CPU PCs held while Timer keeps counting");
                check({dut.pipeline_core_inst.valid_ifid_o,dut.pipeline_core_inst.pc_ifid_o,
                       dut.pipeline_core_inst.instr_ifid_o} === saved_ifid,"IF/ID held during RAM wait");
                for (i=1;i<32;i=i+1)
                    check(dut.pipeline_core_inst.regfile_inst.reg_file[i] === saved_regs[i],
                          "register file held during RAM wait");
            end
            if (finish_before)
                check_final;
        end
    end
endmodule

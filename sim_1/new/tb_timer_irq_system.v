`timescale 1ns / 1ps
// Only clock/reset are driven; the external request pin is tied low.
// The program configures the real Timer, and its real bus write removes the IRQ.
module tb_timer_irq_system;
    reg clk=1'b0;
    reg rst_n=1'b0;
    wire [7:0] gpio_out_o;
    always #10 clk=~clk;
    soc_top dut(.clk(clk),.rst_n(rst_n),.irq_external_i(1'b0),.gpio_out_o(gpio_out_o));

    wire ex_valid=dut.pipeline_core_inst.valid_idex_o;
    wire [31:0] ex_pc=dut.pipeline_core_inst.pc_idex_o;
    wire stall=dut.pipeline_core_inst.stall_ex_o;
    wire irq_take=dut.pipeline_core_inst.execute_unit_inst.irq_take;
    wire trap_enter=dut.pipeline_core_inst.execute_unit_inst.trap_enter_ex_o;
    wire trap_return=dut.pipeline_core_inst.execute_unit_inst.trap_return_ex_o;
    wire csr_wr=dut.pipeline_core_inst.execute_unit_inst.csr_wr_en_ex_o;
    wire csr_rd=dut.pipeline_core_inst.execute_unit_inst.csr_rd_en_ex_o;
    wire cpu_req=dut.pipeline_core_inst.data_req;
    wire cpu_we=dut.pipeline_core_inst.data_we;
    wire [31:0] cpu_addr=dut.pipeline_core_inst.data_addr;
    wire [31:0] cpu_wdata=dut.pipeline_core_inst.ram_wr_data_ex_o;
    wire [3:0] cpu_mask=dut.pipeline_core_inst.ram_wr_sel_ex_o;
    wire cpu_ready=dut.pipeline_core_inst.bus2cpu_ready_o;
    wire [31:0] cpu_rdata=dut.pipeline_core_inst.bus2cpu_rdata_o;
    wire ram_req=dut.pipeline_core_inst.bus2ram_req_o;
    wire ram_ready=dut.pipeline_core_inst.ram_ready_o;
    wire wb_en=dut.pipeline_core_inst.wr_en_ex_o;
    wire [4:0] wb_rd=dut.pipeline_core_inst.wr_addr_ex_o;
    wire [31:0] wb_data=dut.pipeline_core_inst.wr_data_ex_o;
    wire redirect=dut.pipeline_core_inst.pc_brench_flag_ex_o;
    wire flush=dut.pipeline_core_inst.clear_valid_ex_o;
    wire [31:0] redirect_pc=dut.pipeline_core_inst.pc_brench_addr_ex_o;
    wire [69:0] payload={cpu_req,cpu_we,cpu_addr,cpu_wdata,cpu_mask};

    localparam T_NONE=0,T_RAM=1,T_TIMER=2,T_GPIO=3;
    integer errors=0,step=0,enter_count=0,return_count=0,wait_edges=0;
    integer timer_reads=0,timer_writes=0,gpio_reads=0,gpio_writes=0,ram_reads=0,ram_writes=0;
    integer i,target;
    reg [31:0] expected_pc[0:28];
    reg [31:0] regs_expected[1:31];
    reg [31:0] final_regs[1:31];
    reg [31:0] expected_mstatus=32'h1800,expected_mtvec=0,expected_mie=0;
    reg [31:0] expected_mepc=0,expected_mcause=0;
    reg timer_en_expected=0,timer_irq_en_expected=0,timer_done_expected=0,timer_irq_expected=0;
    reg [31:0] timer_limit_expected=1,timer_count_expected=0,ram_zero_expected=0;
    reg [7:0] gpio_expected=0;
    reg exp_mem,exp_we,exp_wb,exp_cwr,exp_crd,exp_return,exp_redirect;
    reg [31:0] exp_addr,exp_store,exp_read,exp_result,exp_csource,exp_target;
    reg [3:0] exp_mask;
    reg [4:0] exp_rd;
    reg [11:0] exp_caddr;
    reg global_enable_committed=0,source_cleared=0;
    reg masked_status_seen=0,masked_addi_seen=0,ram_wait_seen=0,handler_seen=0;
    reg waiting=0,entry_before,return_before,finish_before,stall_before;
    reg [31:0] saved_target,saved_fetch_pc,saved_ex_pc;
    reg [64:0] saved_ifid;
    reg [69:0] saved_payload;

    task check;
        input condition;
        input [8*110-1:0] label;
        begin
            if(condition !== 1'b1) begin
                errors=errors+1;
                $display("FAIL: %0s time=%0t step=%0d EX_PC=%08h entries=%0d returns=%0d",
                         label,$time,step,ex_pc,enter_count,return_count);
                $display("  irq=%b take=%b req=%b addr=%08h ready=%b stall=%b count=%0d gpio=%02h",
                         dut.timer_irq_o,irq_take,cpu_req,cpu_addr,cpu_ready,stall,
                         dut.timer_target_inst.cnt_value_o,gpio_out_o);
            end
        end
    endtask

    task check_state;
        integer r;
        begin
            check(dut.pipeline_core_inst.execute_unit_inst.csr_unit_inst.mstatus_reg === expected_mstatus,"mstatus storage");
            check(dut.pipeline_core_inst.execute_unit_inst.csr_unit_inst.mtvec_reg === expected_mtvec,"mtvec storage");
            check(dut.pipeline_core_inst.execute_unit_inst.csr_unit_inst.mie_reg === expected_mie,"mie storage");
            check(dut.pipeline_core_inst.execute_unit_inst.csr_unit_inst.mepc_reg === expected_mepc,"mepc storage");
            check(dut.pipeline_core_inst.execute_unit_inst.csr_unit_inst.mcause_reg === expected_mcause,"mcause storage");
            check(dut.pipeline_core_inst.execute_unit_inst.csr_unit_inst.mscratch_reg === 32'd0,"mscratch unchanged");
            for(r=1;r<32;r=r+1)
                if(dut.pipeline_core_inst.register_file_inst.reg_file[r] !== regs_expected[r]) begin
                    errors=errors+1;
                    $display("FAIL: x%0d actual=%08h expected=%08h time=%0t step=%0d",r,
                             dut.pipeline_core_inst.register_file_inst.reg_file[r],regs_expected[r],$time,step);
                end
            check(dut.timer_target_inst.en_reg === timer_en_expected,"Timer count enable");
            check(dut.timer_target_inst.irq_en_reg === timer_irq_en_expected,"Timer device IRQ enable");
            check(dut.timer_target_inst.limit_reg === timer_limit_expected,"Timer limit");
            check(dut.timer_target_inst.cnt_value_o === timer_count_expected,"Timer count");
            check(dut.timer_target_inst.cnt_done_o === timer_done_expected,"Timer expiry");
            check(dut.timer_target_inst.irq_o === timer_irq_expected,"Timer actual IRQ output");
            check(dut.timer_irq_o === timer_irq_expected && dut.irq2cpu === timer_irq_expected,
                  "device request through soc_top merge with external input zero");
            check(dut.pipeline_core_inst.irq_external_i === timer_irq_expected &&
                  dut.pipeline_core_inst.execute_unit_inst.irq_external_ex_i === timer_irq_expected,
                  "request reaches CPU and EX");
            check(dut.irq_external_i === 1'b0,"TB never injects an external request");
            check(gpio_out_o === gpio_expected,"GPIO changes only at handler marker store");
            check(dut.pipeline_core_inst.data_ram_target_inst.data_ram_inst.memory[0] === ram_zero_expected,
                  "RAM word zero follows program store");
        end
    endtask

    task no_instruction_effect;
        begin
            check(wb_en === 1'b0,"no ordinary GPR write");
            check(csr_wr === 1'b0 && csr_rd === 1'b0,"no instruction CSR access");
            check(cpu_req === 1'b0 && dut.pipeline_core_inst.ram_wr_en_ex_o === 1'b0 &&
                  dut.pipeline_core_inst.ram_rd_en_ex_o === 1'b0,"no ordinary memory access");
            check(ram_req === 1'b0 && dut.gpio_req === 1'b0 && dut.timer_req === 1'b0,"all target requests idle");
            check(cpu_ready === 1'b0 && cpu_rdata === 32'd0,"idle memory response");
            check(dut.pipeline_core_inst.execute_unit_inst.start_ex_o === 1'b0,"no divider start");
        end
    endtask

    task prepare_instruction;
        begin
            exp_mem=0; target=T_NONE; exp_we=0; exp_wb=0; exp_rd=0; exp_result=0;
            exp_addr=0; exp_store=0; exp_mask=4'b1111; exp_read=0;
            exp_cwr=0; exp_crd=0; exp_caddr=0; exp_csource=0;
            exp_return=0; exp_redirect=0; exp_target=0;
            case(ex_pc)
                32'h00: begin exp_wb=1;exp_rd=1;exp_result=32'h10000000;end
                32'h04: begin exp_wb=1;exp_rd=2;exp_result=32'h100;end
                32'h08: begin exp_cwr=1;exp_caddr=12'h305;exp_csource=32'h100;end
                32'h0C: begin exp_wb=1;exp_rd=3;exp_result=1;end
                32'h10: begin exp_wb=1;exp_rd=3;exp_result=32'h800;end
                32'h14: begin exp_cwr=1;exp_caddr=12'h304;exp_csource=32'h800;end
                32'h18: begin exp_wb=1;exp_rd=4;exp_result=3;end
                32'h1C: begin exp_mem=1;target=T_TIMER;exp_we=1;exp_addr=32'h10000014;exp_store=3;end
                32'h20: begin exp_wb=1;exp_rd=5;exp_result=7;end
                32'h24: begin exp_mem=1;target=T_TIMER;exp_we=1;exp_addr=32'h10000010;exp_store=7;end
                32'h28: begin exp_mem=1;target=T_RAM;exp_we=1;exp_store=3;end
                32'h2C: begin exp_wb=1;exp_rd=6;exp_result=9;end
                32'h30: begin
                    exp_mem=1;target=T_TIMER;exp_addr=32'h1000001C;exp_read=1;
                    exp_wb=1;exp_rd=7;exp_result=1;
                end
                32'h34: begin exp_wb=1;exp_rd=8;exp_result=8;end
                32'h38: begin exp_cwr=1;exp_caddr=12'h300;exp_csource=8;end
                32'h3C: begin exp_wb=1;exp_rd=9;exp_result=32'h55;end
                32'h40: begin exp_mem=1;target=T_TIMER;exp_addr=32'h10000010;exp_wb=1;exp_rd=10;end
                32'h44: begin exp_mem=1;target=T_TIMER;exp_addr=32'h10000018;exp_wb=1;exp_rd=11;end
                32'h48: begin
                    exp_mem=1;target=T_GPIO;exp_addr=32'h10000000;exp_read=32'h3C;
                    exp_wb=1;exp_rd=12;exp_result=32'h3C;
                end
                32'h4C: begin exp_mem=1;target=T_RAM;exp_read=3;exp_wb=1;exp_rd=13;exp_result=3;end
                32'h50: begin exp_wb=1;exp_rd=0;exp_result=32'h54;exp_redirect=1;exp_target=32'h50;end
                32'h100: begin exp_wb=1;exp_rd=20;exp_result=1;end
                32'h104: begin exp_wb=1;exp_rd=21;exp_result=32'h3C;exp_crd=1;exp_caddr=12'h341;end
                32'h108: begin exp_wb=1;exp_rd=22;exp_result=32'h8000000B;exp_crd=1;exp_caddr=12'h342;end
                32'h10C: begin exp_wb=1;exp_rd=23;exp_result=2;end
                32'h110: begin exp_mem=1;target=T_TIMER;exp_we=1;exp_addr=32'h10000010;exp_store=2;end
                32'h114: begin exp_wb=1;exp_rd=24;exp_result=32'h3C;end
                32'h118: begin
                    exp_mem=1;target=T_GPIO;exp_we=1;exp_addr=32'h10000000;
                    exp_store=32'h3C;exp_mask=4'b0001;
                end
                32'h11C: begin exp_return=1;exp_redirect=1;exp_target=32'h3C;end
                default: check(1'b0,"unexpected normal instruction, including wrong path 54/120");
            endcase
        end
    endtask

    task check_memory;
        begin
            check(cpu_req === exp_mem,"instruction issues expected request, including missing-request detection");
            check(ram_req === (target==T_RAM),"RAM exclusive selection");
            check(dut.timer_req === (target==T_TIMER),"Timer exclusive selection");
            check(dut.gpio_req === (target==T_GPIO),"GPIO exclusive selection");
            check(dut.bus2dev_req_o === ((target==T_TIMER)||(target==T_GPIO)),"DEV route");
            if(exp_mem) begin
                check(cpu_addr === exp_addr && cpu_we === exp_we,"memory address/direction");
                if(exp_we) check(cpu_wdata === exp_store && cpu_mask === exp_mask,"store data/byte mask");
                check({dut.bus2dev_we_o,dut.bus2dev_addr_o,dut.bus2dev_wdata_o,dut.bus2dev_wstrb_o}
                      === {cpu_we,cpu_addr,cpu_wdata,cpu_mask},"DEV payload forwarded unchanged");
                if(target==T_RAM)
                    check(cpu_ready === ram_ready && stall === !ram_ready,"RAM waiting/completion");
                else begin
                    check(cpu_ready === 1'b1 && stall === 1'b0,"peripheral completes without waiting");
                    if(target==T_TIMER)
                        check(dut.timer_ready_o === 1'b1 && dut.timer_rdata_o === exp_read,"Timer response");
                    else
                        check(dut.gpio_ready_o === 1'b1 && dut.gpio_rdata_o === exp_read,"GPIO response");
                end
                check(cpu_rdata === (cpu_ready ? exp_read : 32'd0),"read data sampled at completion edge");
                if(cpu_req && cpu_ready) begin
                    if(target==T_RAM) check(wait_edges==1,"one RAM preparation edge");
                    else check(wait_edges==0,"no peripheral wait edges");
                    wait_edges=0;
                end else wait_edges=wait_edges+1;
            end else
                check(cpu_ready === 1'b0 && cpu_rdata === 32'd0 && stall === 1'b0,"non-memory idle response");
        end
    endtask

    task check_final;
        integer r;
        begin
            check(step==29 && enter_count==1 && return_count==1,"complete stream with exactly one IRQ and MRET");
            check(masked_status_seen && masked_addi_seen && ram_wait_seen && handler_seen,
                  "masked progress, RAM wait and handler execution observed");
            check(global_enable_committed && source_cleared,"CPU enabled by program and source cleared by handler");
            check(timer_reads==3 && timer_writes==3,"Timer actual read/write completions");
            check(gpio_reads==1 && gpio_writes==1 && ram_reads==1 && ram_writes==1,"GPIO/RAM completions");
            check(expected_mstatus==32'h1888 && expected_mtvec==32'h100 && expected_mie==32'h800 &&
                  expected_mepc==32'h3C && expected_mcause==32'h8000000B,"final architectural CSR expectations");
            for(r=1;r<32;r=r+1)
                check(dut.pipeline_core_inst.register_file_inst.reg_file[r] === final_regs[r],"final register result");
            for(r=1;r<32;r=r+1)
                check(dut.pipeline_core_inst.data_ram_target_inst.data_ram_inst.memory[r] === 32'd0,
                      "other RAM words remain zero");
            check_state;
            if(errors==0) begin
                $display("PASS: timer IRQ system checks passed");
                $finish;
            end else $fatal(1,"FAIL: timer IRQ system checks failed (%0d errors)",errors);
        end
    endtask

    initial begin
        for(i=0;i<15;i=i+1) expected_pc[i]=i*4;
        for(i=0;i<8;i=i+1) expected_pc[15+i]=32'h100+i*4;
        for(i=0;i<6;i=i+1) expected_pc[23+i]=32'h3C+i*4;
        for(i=1;i<32;i=i+1) begin regs_expected[i]=0;final_regs[i]=0;end
        final_regs[1]=32'h10000000;final_regs[2]=32'h100;final_regs[3]=32'h800;
        final_regs[4]=3;final_regs[5]=7;final_regs[6]=9;final_regs[7]=1;final_regs[8]=8;
        final_regs[9]=32'h55;final_regs[12]=32'h3C;final_regs[13]=3;
        final_regs[20]=1;final_regs[21]=32'h3C;final_regs[22]=32'h8000000B;
        final_regs[23]=2;final_regs[24]=32'h3C;
        repeat(3) @(negedge clk);
        rst_n=1'b1;
    end

    initial begin
        #20000;
        $fatal(1,"FAIL: Timer IRQ system timeout step=%0d entries=%0d returns=%0d",step,enter_count,return_count);
    end

    always @(posedge clk) begin
        if(!rst_n) begin
            // Shadow expectations only: DUT storage must reset itself at this edge.
            for(i=1;i<32;i=i+1) regs_expected[i]=0;
            expected_mstatus=32'h1800;expected_mtvec=0;expected_mie=0;expected_mepc=0;expected_mcause=0;
            timer_en_expected=0;timer_irq_en_expected=0;timer_limit_expected=1;
            timer_count_expected=0;timer_done_expected=0;timer_irq_expected=0;
            gpio_expected=0;ram_zero_expected=0;
            #1;check_state;
        end else begin
            check((^{irq_take,ex_valid,stall,wb_en,csr_wr,csr_rd,trap_enter,trap_return,cpu_req,cpu_ready,
                      dut.timer_irq_o,dut.irq2cpu,dut.timer_req,dut.gpio_req,ram_req}) !== 1'bx,
                  "control signals contain no X/Z");
            check(dut.pipeline_core_inst.execute_unit_inst.start_ex_o === 1'b0,"program never starts divider");
            check_state;
            if(waiting) check(payload === saved_payload,"RAM request payload held through completion");
            if(timer_irq_expected && !expected_mstatus[3])
                check(irq_take === 1'b0,"CPU global mask blocks entry without clearing device request");
            if(return_count==0)
                check(dut.pipeline_core_inst.register_file_inst.reg_file[9] === 32'd0,"x9 must wait until return");

            // Observe actual handshakes, independently of stream progress.
            if(dut.timer_req && dut.timer_ready_o) begin
                if(cpu_we) timer_writes=timer_writes+1;else timer_reads=timer_reads+1;
            end
            if(dut.gpio_req && dut.gpio_ready_o) begin
                if(cpu_we) gpio_writes=gpio_writes+1;else gpio_reads=gpio_reads+1;
            end
            if(ram_req && ram_ready) begin
                if(cpu_we) ram_writes=ram_writes+1;else ram_reads=ram_reads+1;
            end
            entry_before=0;return_before=0;finish_before=0;stall_before=0;saved_target=0;

            // PRIORITY: IRQ entry is an event even when EX valid=0. It is not retirement.
            if(irq_take === 1'b1) begin
                check(step==15 && enter_count==0 && return_count==0 && global_enable_committed,
                      "IRQ is accepted only after PC38 CSR completion");
                check(dut.timer_irq_o === 1'b1 && expected_mstatus==32'h1808 && expected_mie==32'h800,
                      "real Timer request and both CPU permissions at entry");
                no_instruction_effect;
                check(trap_enter === 1'b1 && trap_return === 1'b0,"IRQ entry control");
                check(dut.pipeline_core_inst.execute_unit_inst.trap_pc_ex_o === 32'h3C &&
                      dut.pipeline_core_inst.execute_unit_inst.trap_cause_ex_o === 32'h8000000B,"entry resume PC/cause");
                check(redirect === 1'b1 && flush === 1'b1 && redirect_pc === 32'h100,"IRQ redirect and flush");
                check(dut.pipeline_core_inst.execute_unit_inst.resume_pc_reg === 32'h3C,"boundary records next main PC");
                expected_mepc=32'h3C;expected_mcause=32'h8000000B;expected_mstatus=32'h1880;
                enter_count=enter_count+1;entry_before=1;saved_target=32'h100;
            end else if(irq_take === 1'b0) begin
                check(trap_enter === 1'b0,"no synchronous trap or unexpected entry");
                if(ex_valid === 1'b1) begin
                    if(step>=29) $fatal(1,"FAIL: extra normal instruction");
                    check(ex_pc === expected_pc[step],"main/handler/return instruction order");
                    if(step>=15 && step<23)
                        check(enter_count==1 && return_count==0,"handler requires accepted IRQ");
                    if(step>=23) check(return_count==1,"main return segment requires completed MRET");
                    prepare_instruction;
                    check_memory;
                    if(stall === 1'b1) begin
                        check(ex_pc==32'h28 || ex_pc==32'h4C,"only specified RAM instructions may stall");
                        check(wb_en === 1'b0 && csr_wr === 1'b0 && csr_rd === 1'b0,"no writes during RAM wait");
                        check(redirect === 1'b0 && flush === 1'b0 && trap_return === 1'b0,"no control event during wait");
                        stall_before=1;
                    end else if(stall === 1'b0) begin
                        check(wb_en === exp_wb,"GPR write enable");
                        if(exp_wb) begin
                            check(wb_rd === exp_rd && wb_data === exp_result,"GPR destination/value before edge");
                            if(exp_rd!=0) regs_expected[exp_rd]=exp_result;
                        end
                        check(csr_wr === exp_cwr && csr_rd === exp_crd,"instruction CSR enables");
                        if(exp_cwr)
                            check(dut.pipeline_core_inst.execute_unit_inst.csr_wr_addr_ex_o === exp_caddr &&
                                  dut.pipeline_core_inst.execute_unit_inst.csr_wr_data_ex_o === exp_csource,"CSR write address/source");
                        if(exp_crd)
                            check(dut.pipeline_core_inst.execute_unit_inst.csr_rd_addr_ex_o === exp_caddr,"CSR read address");
                        check(trap_return === exp_return && redirect === exp_redirect && flush === exp_redirect,
                              "normal instruction return/redirect/flush controls");
                        if(exp_redirect) begin
                            check(redirect_pc === exp_target,"normal redirect target");saved_target=exp_target;
                        end
                        case(ex_pc)
                            32'h08: expected_mtvec=32'h100;
                            32'h14: expected_mie=32'h800;
                            32'h1C: timer_limit_expected=3;
                            32'h24: begin timer_en_expected=1;timer_irq_en_expected=1;timer_count_expected=0;end
                            32'h28: ram_zero_expected=3;
                            32'h2C: begin timer_count_expected=3;timer_done_expected=1;timer_irq_expected=1;end
                            32'h30: begin
                                check(dut.timer_irq_o === 1'b1 && expected_mstatus[3]===1'b0,
                                      "STATUS read completes while CPU globally masks real request");masked_status_seen=1;
                            end
                            32'h34: begin
                                check(dut.timer_irq_o === 1'b1 && expected_mstatus[3]===1'b0,
                                      "ADDI completes while request is held behind global mask");masked_addi_seen=1;
                            end
                            32'h38: begin
                                check(enter_count==0 && step==14,"enable CSR completes before any IRQ");
                                expected_mstatus=32'h1808;global_enable_committed=1;
                            end
                            32'h100: handler_seen=1;
                            32'h110: begin
                                check(dut.timer_irq_o === 1'b1 && dut.timer_req === 1'b1 && cpu_ready === 1'b1 &&
                                      dut.timer_target_inst.clear_pulse === 1'b1,"handler store removes still-active source");
                                timer_en_expected=0;timer_irq_en_expected=0;timer_count_expected=0;
                                timer_done_expected=0;timer_irq_expected=0;source_cleared=1;
                            end
                            32'h118: begin check(gpio_out_o === 8'd0,"GPIO marker not written early");gpio_expected=8'h3C;end
                            32'h11C: begin
                                check(source_cleared && dut.timer_irq_o === 1'b0 && dut.irq2cpu === 1'b0,
                                      "source withdrawn before MRET restores CPU permission");
                                check(return_count==0 && expected_mstatus==32'h1880,"one return from masked handler");
                                expected_mstatus=32'h1888;return_count=return_count+1;return_before=1;
                            end
                            32'h50: finish_before=1;
                        endcase
                        step=step+1;
                    end else $fatal(1,"FAIL: unknown CPU stall");

                    // Two edges for the first RAM write: Timer advances despite stall.
                    if(ex_pc==32'h28) begin
                        if(stall) begin
                            check(dut.timer_target_inst.cnt_value_o === 32'd0,"counter zero before RAM preparation");
                            timer_count_expected=1;ram_wait_seen=1;
                        end else begin
                            check(dut.timer_target_inst.cnt_value_o === 32'd1,"counter one before RAM completion");
                            timer_count_expected=2;
                        end
                    end
                end else if(ex_valid === 1'b0) begin
                    no_instruction_effect;
                    check(redirect === 1'b0 && flush === 1'b0 && trap_return === 1'b0 && stall === 1'b0,
                          "ordinary bubble has no entry or return event");
                end else $fatal(1,"FAIL: unknown EX valid");
            end else $fatal(1,"FAIL: unknown IRQ take");

            waiting=cpu_req && !cpu_ready;
            saved_payload=payload;saved_fetch_pc=dut.pipeline_core_inst.pc_o;saved_ex_pc=ex_pc;
            saved_ifid={dut.pipeline_core_inst.valid_ifid_o,dut.pipeline_core_inst.pc_ifid_o,
                         dut.pipeline_core_inst.instr_ifid_o};
            // Always check updated storage after the event sampled above, never the new EX packet.
            #1;
            check_state;
            if(entry_before || return_before || finish_before) begin
                check(dut.pipeline_core_inst.pc_o === saved_target,"PC storage after redirect");
                check(dut.pipeline_core_inst.valid_ifid_o === 1'b0 &&
                      dut.pipeline_core_inst.valid_idex_o === 1'b0,"both pipeline packets flushed");
            end
            if(entry_before)
                check(dut.pipeline_core_inst.execute_unit_inst.boundary_valid_reg === 1'b0,"entry consumes old boundary");
            if(stall_before) begin
                check(ex_pc === saved_ex_pc && dut.pipeline_core_inst.pc_o === saved_fetch_pc,"CPU PCs hold during RAM wait");
                check({dut.pipeline_core_inst.valid_ifid_o,dut.pipeline_core_inst.pc_ifid_o,
                       dut.pipeline_core_inst.instr_ifid_o} === saved_ifid,"IF/ID holds during RAM wait");
            end
            if(finish_before) check_final;
        end
    end
endmodule

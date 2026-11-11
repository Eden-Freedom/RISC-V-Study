`timescale 1ns / 1ps

// Complete CPU test. Only clk/rst_n/irq_external_i are driven.
// Expected PCs/results come from the program specification, never DUT results.
module tb_irq_pipeline();
reg clk = 1'b0;
always #10 clk = ~clk;
reg rst_n;
reg irq_external_i;
integer errors, step, enter_count, return_count, div_start_count, div_write_count;
integer i;
reg finished;
reg mie_closed_seen, jal40_seen, jal0_seen, div_started_seen;
reg [31:0] expected_pc [0:31];
reg [31:0] irq_pc [0:4];
reg [31:0] expected_regs [0:31];
reg [31:0] mstatus, mtvec, mie, mscratch, mepc, mcause;
reg exp_wen, exp_cwr, exp_crd, exp_redirect, exp_return;
reg [4:0] exp_rd;
reg [11:0] exp_caddr;
reg [31:0] exp_data, exp_source, exp_target;
integer expected_entries;

pipeline_core u_pipeline_core(
    .clk(clk), .rst_n(rst_n), .irq_external_i(irq_external_i)
);

task check;
input [8*80-1:0] item;
input [31:0] actual, wanted;
begin
    if (actual !== wanted) begin
        $display("FAIL t=%0t step=%0d irq=%0d %0s actual=%h expected=%h",
                 $time, step, enter_count, item, actual, wanted);
        errors = errors + 1;
    end
end
endtask

task check_state;
integer r;
begin
    check("mstatus", u_pipeline_core.execute_unit_inst.csr_unit_inst.mstatus_reg, mstatus);
    check("mtvec", u_pipeline_core.execute_unit_inst.csr_unit_inst.mtvec_reg, mtvec);
    check("mie", u_pipeline_core.execute_unit_inst.csr_unit_inst.mie_reg, mie);
    check("mscratch", u_pipeline_core.execute_unit_inst.csr_unit_inst.mscratch_reg, mscratch);
    check("mepc", u_pipeline_core.execute_unit_inst.csr_unit_inst.mepc_reg, mepc);
    check("mcause", u_pipeline_core.execute_unit_inst.csr_unit_inst.mcause_reg, mcause);
    // Storage for architectural x0 is intentionally not reset in this register_file.
    for (r=1; r<32; r=r+1)
        if (u_pipeline_core.register_file_inst.reg_file[r] !== expected_regs[r]) begin
            $display("FAIL t=%0t step=%0d x%0d actual=%h expected=%h", $time,
                     step, r, u_pipeline_core.register_file_inst.reg_file[r], expected_regs[r]);
            errors = errors + 1;
        end
    if (u_pipeline_core.register_file_inst.rs1_addr_i === 5'd0)
        check("architectural x0 read",u_pipeline_core.register_file_inst.rs1_data_o,32'd0);
end
endtask

// Normal bubble and IRQ entry both forbid ordinary instruction side effects.
// Entry/redirect signals are checked separately, since an IRQ may enter in a bubble.
task check_no_instruction_effect;
begin
    check("GPR write", {31'b0,u_pipeline_core.wr_en_ex_o},32'd0);
    check("CSR write", {31'b0,u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o},32'd0);
    check("CSR read", {31'b0,u_pipeline_core.execute_unit_inst.csr_rd_en_ex_o},32'd0);
    check("RAM write", {31'b0,u_pipeline_core.ram_wr_en_ex_o},32'd0);
    check("RAM read", {31'b0,u_pipeline_core.ram_rd_en_ex_o},32'd0);
    check("DIV start", {31'b0,u_pipeline_core.execute_unit_inst.start_ex_o},32'd0);
    check("stall", {31'b0,u_pipeline_core.stall_ex_o},32'd0);
    check("trap return", {31'b0,u_pipeline_core.execute_unit_inst.trap_return_ex_o},32'd0);
end
endtask

task check_flush;
input [31:0] target;
begin
    check("PC after redirect",u_pipeline_core.pc_o,target);
    check("IFID flushed",{31'b0,u_pipeline_core.valid_ifid_o},32'd0);
    check("IDEX flushed",{31'b0,u_pipeline_core.valid_idex_o},32'd0);
end
endtask

// The expected instruction stream excludes IRQ entries and stalled DIV cycles.
task prepare_expected;
begin
    exp_wen=0; exp_rd=0; exp_data=0;
    exp_cwr=0; exp_crd=0; exp_caddr=0; exp_source=0;
    exp_redirect=0; exp_target=0; exp_return=0;
    if (step<10) expected_entries=0;
    else if (step<13) expected_entries=1;
    else if (step<18) expected_entries=2;
    else if (step<24) expected_entries=3;
    else if (step<29) expected_entries=4;
    else expected_entries=5;
    check("entry count before instruction",enter_count,expected_entries);
    case (expected_pc[step])
        32'h00: begin exp_wen=1; exp_rd=1; exp_data=32'h100; end
        32'h04: begin exp_cwr=1; exp_caddr=12'h305; exp_source=32'h100; mtvec=32'h100; end
        32'h08: begin exp_wen=1; exp_rd=2; exp_data=1; end
        32'h0C: begin exp_wen=1; exp_rd=2; exp_data=32'h800; end
        32'h10: begin exp_cwr=1; exp_caddr=12'h304; exp_source=32'h800; mie=32'h800; end
        32'h14: begin exp_wen=1; exp_rd=3; exp_data=8; end
        32'h18: begin exp_cwr=1; exp_caddr=12'h300; exp_source=8; mstatus=32'h1808; end
        32'h1C: begin exp_wen=1; exp_rd=0; exp_data=32'h1808; exp_cwr=1; exp_crd=1; exp_caddr=12'h300; exp_source=8; mstatus=32'h1800; end
        32'h20: begin exp_cwr=1; exp_caddr=12'h340; exp_source=21; mscratch=21;
            check("request waiting during mscratch write",{31'b0,irq_external_i},32'd1); end
        32'h24: begin exp_wen=1; exp_rd=0; exp_data=32'h1800; exp_cwr=1; exp_crd=1; exp_caddr=12'h300; exp_source=8; mstatus=32'h1808;
            check("request waiting during MIE enable",{31'b0,irq_external_i},32'd1); end
        32'h28: begin exp_wen=1; exp_rd=5; exp_data=7; end
        32'h2C: begin exp_wen=1; exp_rd=0; exp_data=32'h30; exp_redirect=1; exp_target=32'h40; end
        32'h40: begin exp_wen=1; exp_rd=6; exp_data=100; end
        32'h44: begin exp_wen=1; exp_rd=7; exp_data=3; end
        32'h48: begin exp_wen=1; exp_rd=8; exp_data=33; end
        32'h4C: begin exp_wen=1; exp_rd=9; exp_data=34; end
        32'h50: begin exp_wen=1; exp_rd=0; exp_data=32'h54; exp_redirect=1; exp_target=0; end
        32'h100: begin exp_wen=1; exp_rd=20; exp_data=expected_entries; end
        32'h104: begin exp_wen=1; exp_rd=21; exp_data=irq_pc[expected_entries-1];
            exp_crd=1; exp_caddr=12'h341; end
        32'h108: begin exp_return=1; exp_redirect=1; exp_target=irq_pc[expected_entries-1]; mstatus=32'h1888; end
        default: $fatal(1,"Bad expected PC at step=%0d",step);
    endcase
end
endtask

// Actual fetched instruction words, including wrong-path fetches.
function [31:0] rom_word;
input [31:0] pc;
begin
    case (pc)
        32'h00: rom_word=32'h10000093;
        32'h04: rom_word=32'h30509073;
        32'h08: rom_word=32'h00100113;
        32'h0C: rom_word=32'h00B11113;
        32'h10: rom_word=32'h30411073;
        32'h14: rom_word=32'h00800193;
        32'h18: rom_word=32'h30019073;
        32'h1C: rom_word=32'h30047073;
        32'h20: rom_word=32'h340AD073;
        32'h24: rom_word=32'h30046073;
        32'h28: rom_word=32'h00700293;
        32'h2C: rom_word=32'h0140006F;
        32'h30: rom_word=32'h00000000;
        32'h34: rom_word=32'h340FD073;
        32'h40: rom_word=32'h06400313;
        32'h44: rom_word=32'h00300393;
        32'h48: rom_word=32'h02734433;
        32'h4C: rom_word=32'h00140493;
        32'h50: rom_word=32'hFB1FF06F;
        32'h100: rom_word=32'h001A0A13;
        32'h104: rom_word=32'h34102AF3;
        32'h108: rom_word=32'h30200073;
        32'h10C: rom_word=32'h00000000;
        32'h110: rom_word=32'h340FD073;
        default: rom_word=32'h00000000;
    endcase
end
endfunction

initial begin
    rst_n=0; irq_external_i=0;
    errors=0; step=0; enter_count=0; return_count=0;
    div_start_count=0; div_write_count=0; finished=0;
    mie_closed_seen=0; jal40_seen=0; jal0_seen=0; div_started_seen=0;
    mstatus=32'h1800; mtvec=0; mie=0; mscratch=0; mepc=0; mcause=0;
    for (i=0;i<32;i=i+1) expected_regs[i]=0;
    irq_pc[0]=32'h28; irq_pc[1]=32'h28; irq_pc[2]=32'h40;
    irq_pc[3]=32'h4C; irq_pc[4]=0;
    expected_pc[0]=32'h0;
    expected_pc[1]=32'h4;
    expected_pc[2]=32'h8;
    expected_pc[3]=32'hC;
    expected_pc[4]=32'h10;
    expected_pc[5]=32'h14;
    expected_pc[6]=32'h18;
    expected_pc[7]=32'h1C;
    expected_pc[8]=32'h20;
    expected_pc[9]=32'h24;
    expected_pc[10]=32'h100;
    expected_pc[11]=32'h104;
    expected_pc[12]=32'h108;
    expected_pc[13]=32'h100;
    expected_pc[14]=32'h104;
    expected_pc[15]=32'h108;
    expected_pc[16]=32'h28;
    expected_pc[17]=32'h2C;
    expected_pc[18]=32'h100;
    expected_pc[19]=32'h104;
    expected_pc[20]=32'h108;
    expected_pc[21]=32'h40;
    expected_pc[22]=32'h44;
    expected_pc[23]=32'h48;
    expected_pc[24]=32'h100;
    expected_pc[25]=32'h104;
    expected_pc[26]=32'h108;
    expected_pc[27]=32'h4C;
    expected_pc[28]=32'h50;
    expected_pc[29]=32'h100;
    expected_pc[30]=32'h104;
    expected_pc[31]=32'h108;
    #15;
    check_state;
    check_no_instruction_effect;
    check("boundary reset",{31'b0,u_pipeline_core.execute_unit_inst.boundary_valid_reg},32'd0);
    #10; rst_n=1;
    while (!finished) begin
        @(posedge clk);
        check_state; // Active region: old CSR and register state before NBA.
        check("ROM word",u_pipeline_core.instr_o,rom_word(u_pipeline_core.pc_o));
        check("RAM read forbidden",{31'b0,u_pipeline_core.ram_rd_en_ex_o},32'd0);
        check("RAM write forbidden",{31'b0,u_pipeline_core.ram_wr_en_ex_o},32'd0);
        if (u_pipeline_core.execute_unit_inst.start_ex_o === 1'b1)
            div_start_count=div_start_count+1;
        else if (u_pipeline_core.execute_unit_inst.start_ex_o !== 1'b0)
            $fatal(1,"Unknown DIV start");

        // An entry can occur with either a valid younger packet or a bubble.
        if (u_pipeline_core.execute_unit_inst.irq_take === 1'b1) begin
            if (enter_count>=5) $fatal(1,"Unexpected extra IRQ");
            case (enter_count)
                0: check("IRQ at stream boundary",step,10);
                1: begin check("IRQ after first MRET",step,13); check("first return accepted",return_count,1); end
                2: check("IRQ after JAL 40",step,18);
                3: begin check("IRQ after DIV commit",step,24); check("DIV committed once",div_write_count,1); end
                4: check("IRQ after JAL zero",step,29);
            endcase
            if (enter_count==1 || enter_count==2 || enter_count==4)
                check("IRQ received in bubble",{31'b0,u_pipeline_core.valid_idex_o},32'd0);
            check("request at entry",{31'b0,irq_external_i},32'd1);
            check_no_instruction_effect;
            check("entry",{31'b0,u_pipeline_core.execute_unit_inst.trap_enter_ex_o},32'd1);
            check("cause source",u_pipeline_core.execute_unit_inst.trap_cause_ex_o,32'h8000000B);
            check("resume source",u_pipeline_core.execute_unit_inst.trap_pc_ex_o,irq_pc[enter_count]);
            check("redirect",{31'b0,u_pipeline_core.pc_brench_flag_ex_o},32'd1);
            check("flush",{31'b0,u_pipeline_core.clear_valid_ex_o},32'd1);
            check("entry target",u_pipeline_core.pc_brench_addr_ex_o,32'h100);
            mepc=irq_pc[enter_count]; mcause=32'h8000000B; mstatus=32'h1880;
            #1;
            check_flush(32'h100);
            check_state;
            check("boundary consumed",{31'b0,u_pipeline_core.execute_unit_inst.boundary_valid_reg},32'd0);
            $display("IRQ accepted: index=%0d mepc=%h",enter_count,mepc);
            enter_count=enter_count+1;
        end else if (u_pipeline_core.execute_unit_inst.irq_take === 1'b0) begin
            check("no synchronous exception",{31'b0,u_pipeline_core.execute_unit_inst.trap_enter_ex_o},32'd0);
            if (u_pipeline_core.valid_idex_o === 1'b1) begin
                if (step>=32) $fatal(1,"Extra instruction");
                check("EX instruction PC",u_pipeline_core.pc_idex_o,expected_pc[step]);
                if (u_pipeline_core.stall_ex_o === 1'b1) begin
                    check("only DIV may stall",expected_pc[step],32'h48);
                    check("no DIV write while stalled",{31'b0,u_pipeline_core.wr_en_ex_o},32'd0);
                    check("no CSR write while stalled",{31'b0,u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o},32'd0);
                    check("no CSR read while stalled",{31'b0,u_pipeline_core.execute_unit_inst.csr_rd_en_ex_o},32'd0);
                    check("no redirect while stalled",{31'b0,u_pipeline_core.pc_brench_flag_ex_o},32'd0);
                    check("no flush while stalled",{31'b0,u_pipeline_core.clear_valid_ex_o},32'd0);
                    check("no return while stalled",{31'b0,u_pipeline_core.execute_unit_inst.trap_return_ex_o},32'd0);
                    #1;
                    check_state;
                    check("DIV closes boundary",{31'b0,u_pipeline_core.execute_unit_inst.boundary_valid_reg},32'd0);
                    if (div_start_count==1 && u_pipeline_core.execute_unit_inst.busy_div_o===1'b1
                        && u_pipeline_core.execute_unit_inst.done_div_o===1'b0) div_started_seen=1;
                end else if (u_pipeline_core.stall_ex_o === 1'b0) begin
                    prepare_expected;
                    check("GPR enable",{31'b0,u_pipeline_core.wr_en_ex_o},{31'b0,exp_wen});
                    if (exp_wen) begin
                        check("GPR destination",{27'b0,u_pipeline_core.wr_addr_ex_o},{27'b0,exp_rd});
                        check("GPR result",u_pipeline_core.wr_data_ex_o,exp_data);
                        if (exp_rd!=0) expected_regs[exp_rd]=exp_data;
                    end
                    check("CSR write enable",{31'b0,u_pipeline_core.execute_unit_inst.csr_wr_en_ex_o},{31'b0,exp_cwr});
                    check("CSR read enable",{31'b0,u_pipeline_core.execute_unit_inst.csr_rd_en_ex_o},{31'b0,exp_crd});
                    if (exp_cwr) begin
                        check("CSR write address",{20'b0,u_pipeline_core.execute_unit_inst.csr_wr_addr_ex_o},{20'b0,exp_caddr});
                        check("CSR source",u_pipeline_core.execute_unit_inst.csr_wr_data_ex_o,exp_source);
                    end
                    if (exp_crd) check("CSR read address",{20'b0,u_pipeline_core.execute_unit_inst.csr_rd_addr_ex_o},{20'b0,exp_caddr});
                    check("redirect flag",{31'b0,u_pipeline_core.pc_brench_flag_ex_o},{31'b0,exp_redirect});
                    check("flush flag",{31'b0,u_pipeline_core.clear_valid_ex_o},{31'b0,exp_redirect});
                    check("return event",{31'b0,u_pipeline_core.execute_unit_inst.trap_return_ex_o},{31'b0,exp_return});
                    check("no DIV start on commit",{31'b0,u_pipeline_core.execute_unit_inst.start_ex_o},32'd0);
                    if (exp_redirect) check("redirect target",u_pipeline_core.pc_brench_addr_ex_o,exp_target);
                    if (expected_pc[step]==32'h48) begin
                        check("DIV done before commit",{31'b0,u_pipeline_core.execute_unit_inst.done_div_o},32'd1);
                        check("DIV request arrived while busy",{31'b0,irq_external_i},32'd1);
                        div_write_count=div_write_count+1;
                    end
                    #1;
                    check_state;
                    check("completion boundary",{31'b0,u_pipeline_core.execute_unit_inst.boundary_valid_reg},32'd1);
                    check("recorded resume PC",u_pipeline_core.execute_unit_inst.resume_pc_reg,
                          exp_redirect ? exp_target : expected_pc[step]+32'd4);
                    if (exp_redirect) check_flush(exp_target);
                    // No post-MRET 'bubble must have no event' assertion:
                    // restoring MIE may immediately assert the next irq_take.
                    if (expected_pc[step]==32'h1C) mie_closed_seen=1;
                    if (expected_pc[step]==32'h2C) jal40_seen=1;
                    if (expected_pc[step]==32'h50) jal0_seen=1;
                    if (exp_return) begin
                        return_count=return_count+1;
                        if (return_count==5) finished=1;
                    end
                    step=step+1;
                end else $fatal(1,"Unknown stall");
            end else if (u_pipeline_core.valid_idex_o === 1'b0) begin
                check_no_instruction_effect;
                check("no redirect in ordinary bubble",{31'b0,u_pipeline_core.pc_brench_flag_ex_o},32'd0);
                check("no flush in ordinary bubble",{31'b0,u_pipeline_core.clear_valid_ex_o},32'd0);
                #1; check_state;
            end else $fatal(1,"Unknown EX valid");
        end else $fatal(1,"Unknown irq_take");
    end
    check("all expected instructions committed",step,32);
    check("IRQ count",enter_count,5); check("MRET count",return_count,5);
    check("DIV start count",div_start_count,1); check("DIV write count",div_write_count,1);
    check("final PC",u_pipeline_core.pc_o,32'h0);
    check("final x5",u_pipeline_core.register_file_inst.reg_file[5],7);
    check("final x8",u_pipeline_core.register_file_inst.reg_file[8],33);
    check("final x9",u_pipeline_core.register_file_inst.reg_file[9],34);
    check("final x20",u_pipeline_core.register_file_inst.reg_file[20],5);
    check("final x21",u_pipeline_core.register_file_inst.reg_file[21],0);
    check("final mscratch",u_pipeline_core.execute_unit_inst.csr_unit_inst.mscratch_reg,21);
    check("final mepc",u_pipeline_core.execute_unit_inst.csr_unit_inst.mepc_reg,0);
    check("final mcause",u_pipeline_core.execute_unit_inst.csr_unit_inst.mcause_reg,32'h8000000B);
    check("final mstatus",u_pipeline_core.execute_unit_inst.csr_unit_inst.mstatus_reg,32'h1888);
    if (errors==0) begin
        $display("PASS: external IRQ pipeline checks passed"); $finish;
    end else $fatal(1,"FAIL: %0d external IRQ pipeline checks failed",errors);
end

// Handshake with the checker: each flag/count is published only after its
// actual submission edge. External request changes only on subsequent negedges.
initial begin
    wait (mie_closed_seen===1'b1);
    @(negedge clk); irq_external_i=1;
    wait (enter_count==2);
    @(negedge clk); irq_external_i=0;
    wait (jal40_seen===1'b1);
    @(negedge clk); irq_external_i=1;
    wait (enter_count==3);
    @(negedge clk); irq_external_i=0;
    wait (div_started_seen===1'b1);
    wait (u_pipeline_core.execute_unit_inst.busy_div_o===1'b1 && u_pipeline_core.execute_unit_inst.done_div_o===1'b0);
    @(negedge clk); irq_external_i=1;
    wait (enter_count==4);
    @(negedge clk); irq_external_i=0;
    wait (jal0_seen===1'b1);
    @(negedge clk); irq_external_i=1;
    wait (enter_count==5);
    @(negedge clk); irq_external_i=0;
end

initial begin
    #20000;
    $fatal(1,"FAIL: IRQ pipeline timeout step=%0d entries=%0d returns=%0d DIVstarts=%0d",
           step,enter_count,return_count,div_start_count);
end
endmodule


`timescale 1ns / 1ps
// CPU握手集成自检：唯一驱动为clk/rst_n/irq_external_i。
module tb_data_handshake();
reg clk=0;
always #10 clk=~clk;
reg rst_n, irq_external_i;
integer errors, step, i, irq_count, return_count, actual_fires;
integer prepares [0:31];
integer commits [0:31];
reg finished, lw_prepared, memory_waiting;
reg [31:0] expected_pc [0:31];
reg [31:0] expected_regs [0:31];
reg [31:0] expected_ram [0:31];
reg [31:0] mstatus, mtvec, mie, mepc, mcause;
reg exp_req, exp_we, exp_mapped, exp_gwr, exp_cwr, exp_crd, exp_return, exp_jump;
reg [31:0] exp_addr, exp_wdata, exp_word, exp_result, exp_target, exp_csource;
reg [3:0] exp_mask;
reg [4:0] exp_rd;
reg [11:0] exp_caddr;
reg [31:0] saved_pc;
reg [64:0] saved_ifid;
reg [69:0] saved_payload;
integer saved_step;
wire [69:0] payload;
assign payload={u_pipeline_core.data_req,u_pipeline_core.data_we,
                u_pipeline_core.data_addr,u_pipeline_core.ram_wr_data_ex_o,
                u_pipeline_core.ram_wr_sel_ex_o};
wire [359:0] ex_packet;
reg [359:0] saved_ex_packet;
assign ex_packet={
    u_pipeline_core.id_ex_inst.valid_idex_o,
    u_pipeline_core.id_ex_inst.pc_idex_o,
    u_pipeline_core.id_ex_inst.rs1_data_idex_o,
    u_pipeline_core.id_ex_inst.rs2_data_idex_o,
    u_pipeline_core.id_ex_inst.immi_data_idex_o,
    u_pipeline_core.id_ex_inst.immb_data_idex_o,
    u_pipeline_core.id_ex_inst.immj_data_idex_o,
    u_pipeline_core.id_ex_inst.immu_data_idex_o,
    u_pipeline_core.id_ex_inst.imms_data_idex_o,
    u_pipeline_core.id_ex_inst.imm_csr_idex_o,
    u_pipeline_core.id_ex_inst.csr_addr_idex_o,
    u_pipeline_core.id_ex_inst.rd_addr_idex_o,
    u_pipeline_core.id_ex_inst.is_addi_idex_o,
    u_pipeline_core.id_ex_inst.is_xori_idex_o,
    u_pipeline_core.id_ex_inst.is_ori_idex_o,
    u_pipeline_core.id_ex_inst.is_andi_idex_o,
    u_pipeline_core.id_ex_inst.is_slli_idex_o,
    u_pipeline_core.id_ex_inst.is_srli_idex_o,
    u_pipeline_core.id_ex_inst.is_srai_idex_o,
    u_pipeline_core.id_ex_inst.is_slti_idex_o,
    u_pipeline_core.id_ex_inst.is_sltiu_idex_o,
    u_pipeline_core.id_ex_inst.is_sub_idex_o,
    u_pipeline_core.id_ex_inst.is_add_idex_o,
    u_pipeline_core.id_ex_inst.is_xor_idex_o,
    u_pipeline_core.id_ex_inst.is_or_idex_o,
    u_pipeline_core.id_ex_inst.is_and_idex_o,
    u_pipeline_core.id_ex_inst.is_sll_idex_o,
    u_pipeline_core.id_ex_inst.is_srl_idex_o,
    u_pipeline_core.id_ex_inst.is_sra_idex_o,
    u_pipeline_core.id_ex_inst.is_slt_idex_o,
    u_pipeline_core.id_ex_inst.is_sltu_idex_o,
    u_pipeline_core.id_ex_inst.is_beq_idex_o,
    u_pipeline_core.id_ex_inst.is_bne_idex_o,
    u_pipeline_core.id_ex_inst.is_blt_idex_o,
    u_pipeline_core.id_ex_inst.is_bge_idex_o,
    u_pipeline_core.id_ex_inst.is_bltu_idex_o,
    u_pipeline_core.id_ex_inst.is_bgeu_idex_o,
    u_pipeline_core.id_ex_inst.is_jal_idex_o,
    u_pipeline_core.id_ex_inst.is_jalr_idex_o,
    u_pipeline_core.id_ex_inst.is_lui_idex_o,
    u_pipeline_core.id_ex_inst.is_auipc_idex_o,
    u_pipeline_core.id_ex_inst.is_sw_idex_o,
    u_pipeline_core.id_ex_inst.is_sb_idex_o,
    u_pipeline_core.id_ex_inst.is_sh_idex_o,
    u_pipeline_core.id_ex_inst.is_lw_idex_o,
    u_pipeline_core.id_ex_inst.is_lb_idex_o,
    u_pipeline_core.id_ex_inst.is_lbu_idex_o,
    u_pipeline_core.id_ex_inst.is_lh_idex_o,
    u_pipeline_core.id_ex_inst.is_lhu_idex_o,
    u_pipeline_core.id_ex_inst.is_mul_idex_o,
    u_pipeline_core.id_ex_inst.is_mulh_idex_o,
    u_pipeline_core.id_ex_inst.is_mulhsu_idex_o,
    u_pipeline_core.id_ex_inst.is_mulhu_idex_o,
    u_pipeline_core.id_ex_inst.is_div_idex_o,
    u_pipeline_core.id_ex_inst.is_divu_idex_o,
    u_pipeline_core.id_ex_inst.is_rem_idex_o,
    u_pipeline_core.id_ex_inst.is_remu_idex_o,
    u_pipeline_core.id_ex_inst.is_csrrw_idex_o,
    u_pipeline_core.id_ex_inst.is_csrrs_idex_o,
    u_pipeline_core.id_ex_inst.is_csrrc_idex_o,
    u_pipeline_core.id_ex_inst.is_csrrwi_idex_o,
    u_pipeline_core.id_ex_inst.is_csrrsi_idex_o,
    u_pipeline_core.id_ex_inst.is_csrrci_idex_o,
    u_pipeline_core.id_ex_inst.is_ecall_idex_o,
    u_pipeline_core.id_ex_inst.is_mret_idex_o,
    u_pipeline_core.id_ex_inst.is_illegal_idex_o};
pipeline_core u_pipeline_core(.clk(clk),.rst_n(rst_n),.irq_external_i(irq_external_i));

// 独立观察目标实际完成次数，复位期间不计数。
always @(posedge clk)
    if(rst_n===1'b1 && u_pipeline_core.data_req===1'b1 && u_pipeline_core.ram_ready_o===1'b1)
        actual_fires <= actual_fires+1;

task check;
input [8*80-1:0] item;
input [31:0] actual, wanted;
begin
    if(actual !== wanted) begin
        $display("FAIL t=%0t step=%0d %0s actual=%h expected=%h",$time,step,item,actual,wanted);
        errors=errors+1;
    end
end
endtask

task check_state;
integer n;
begin
    for(n=0;n<32;n=n+1) begin
        if(u_pipeline_core.data_ram_target_inst.data_ram_inst.memory[n] !== expected_ram[n]) begin
            $display("FAIL t=%0t step=%0d RAM[%0d]=%h expected=%h",$time,step,n,
                u_pipeline_core.data_ram_target_inst.data_ram_inst.memory[n],expected_ram[n]);
            errors=errors+1;
        end
        if(n!=0 && u_pipeline_core.regfile_inst.reg_file[n] !== expected_regs[n]) begin
            $display("FAIL t=%0t step=%0d x%0d=%h expected=%h",$time,step,n,
                u_pipeline_core.regfile_inst.reg_file[n],expected_regs[n]);
            errors=errors+1;
        end
    end
    check("mstatus",u_pipeline_core.ex_inst.csr_unit_inst.mstatus_reg,mstatus);
    check("mtvec",u_pipeline_core.ex_inst.csr_unit_inst.mtvec_reg,mtvec);
    check("mie",u_pipeline_core.ex_inst.csr_unit_inst.mie_reg,mie);
    check("mepc",u_pipeline_core.ex_inst.csr_unit_inst.mepc_reg,mepc);
    check("mcause",u_pipeline_core.ex_inst.csr_unit_inst.mcause_reg,mcause);
    check("mscratch unchanged",u_pipeline_core.ex_inst.csr_unit_inst.mscratch_reg,0);
    if(u_pipeline_core.regfile_inst.rs1_addr_i===5'd0)
        check("architectural x0",u_pipeline_core.regfile_inst.rs1_data_o,0);
end
endtask

task prepare_expected;
begin
    exp_req=0; exp_we=0; exp_mapped=1; exp_addr=0; exp_wdata=0; exp_mask=0; exp_word=0;
    exp_gwr=0; exp_rd=0; exp_result=0;
    exp_cwr=0; exp_crd=0; exp_caddr=0; exp_csource=0;
    exp_return=0; exp_jump=0; exp_target=0;
    case(expected_pc[step])
        32'h00: begin exp_gwr=1; exp_rd=28; exp_result=32'h100; end
        32'h04: begin exp_cwr=1; exp_caddr=12'h305; exp_csource=32'h100; end
        32'h08: begin exp_gwr=1; exp_rd=29; exp_result=1; end
        32'h0C: begin exp_gwr=1; exp_rd=29; exp_result=32'h800; end
        32'h10: begin exp_cwr=1; exp_caddr=12'h304; exp_csource=32'h800; end
        32'h14: begin exp_gwr=1; exp_rd=30; exp_result=8; end
        32'h18: begin exp_cwr=1; exp_caddr=12'h300; exp_csource=8; end
        32'h1C: begin exp_gwr=1; exp_rd=1; exp_result=32'h55; end
        32'h20: begin exp_req=1; exp_we=1; exp_wdata=32'h55; exp_mask=4'b1111; end
        32'h24: begin exp_req=1; exp_gwr=1; exp_rd=2; exp_result=32'h55; exp_word=32'h55; end
        32'h28: begin exp_gwr=1; exp_rd=3; exp_result=32'h56; end
        32'h2C: begin exp_req=1; exp_we=1; exp_addr=4; exp_wdata=32'h56; exp_mask=4'b1111; end
        32'h30: begin exp_gwr=1; exp_rd=4; exp_result=32'h80; end
        32'h34: begin exp_req=1; exp_we=1; exp_addr=1; exp_wdata=32'h8000; exp_mask=4'b0010; end
        32'h38: begin exp_req=1; exp_addr=1; exp_gwr=1; exp_rd=5; exp_result=32'hFFFFFF80; exp_word=32'h8055; end
        32'h3C: begin exp_req=1; exp_addr=1; exp_gwr=1; exp_rd=6; exp_result=32'h80; exp_word=32'h8055; end
        32'h40: begin exp_gwr=1; exp_rd=7; exp_result=32'h8000; end
        32'h44: begin exp_gwr=1; exp_rd=7; exp_result=32'h8123; end
        32'h48: begin exp_req=1; exp_we=1; exp_addr=2; exp_wdata=32'h81230000; exp_mask=4'b1100; end
        32'h4C: begin exp_req=1; exp_addr=2; exp_gwr=1; exp_rd=8; exp_result=32'hFFFF8123; exp_word=32'h81238055; end
        32'h50: begin exp_req=1; exp_addr=2; exp_gwr=1; exp_rd=9; exp_result=32'h8123; exp_word=32'h81238055; end
        32'h54: begin exp_req=1; exp_gwr=1; exp_rd=10; exp_result=32'h81238055; exp_word=32'h81238055; end
        32'h58: begin exp_req=1; exp_we=1; exp_addr=8; exp_wdata=32'h81238055; exp_mask=4'b1111; end
        32'h5C: begin exp_gwr=1; exp_rd=11; exp_result=32'h80; end
        32'h60: begin exp_req=1; exp_we=1; exp_mapped=0; exp_addr=32'h80; exp_wdata=32'h56; exp_mask=4'b1111; end
        32'h64: begin exp_req=1; exp_mapped=0; exp_addr=32'h80; exp_gwr=1; exp_rd=12; exp_result=0; end
        32'h68: begin exp_gwr=1; exp_rd=13; exp_result=1; end
        32'h6C: begin exp_req=1; exp_addr=4; exp_gwr=1; exp_rd=14; exp_result=32'h56; exp_word=32'h56; end
        32'h70: begin exp_gwr=1; exp_rd=0; exp_result=32'h74; exp_jump=1; exp_target=32'h70; end
        32'h100: begin exp_gwr=1; exp_rd=20; exp_result=1; end
        32'h104: begin exp_gwr=1; exp_rd=21; exp_result=32'h28; exp_crd=1; exp_caddr=12'h341; end
        32'h108: begin exp_return=1; exp_jump=1; exp_target=32'h28; end
        default: $fatal(1,"Invalid expected PC");
    endcase
end
endtask

// 检查接口负载而非用ready去门控请求。
task check_payload;
begin
    check("data req",{31'b0,u_pipeline_core.data_req},{31'b0,exp_req});
    check("data write type",{31'b0,u_pipeline_core.data_we},{31'b0,exp_we});
    check("data address",u_pipeline_core.data_addr,exp_addr);
    check("data write payload",u_pipeline_core.ram_wr_data_ex_o,exp_wdata);
    check("data byte mask",{28'b0,u_pipeline_core.ram_wr_sel_ex_o},{28'b0,exp_mask});
    check("EX store request",{31'b0,u_pipeline_core.ram_wr_en_ex_o},{31'b0,(exp_req && exp_we)});
    check("EX load request",{31'b0,u_pipeline_core.ram_rd_en_ex_o},{31'b0,(exp_req && !exp_we)});
    check("target req pin",{31'b0,u_pipeline_core.data_ram_target_inst.req_i},{31'b0,exp_req});
    check("target we pin",{31'b0,u_pipeline_core.data_ram_target_inst.we_i},{31'b0,exp_we});
    check("target address pin",u_pipeline_core.data_ram_target_inst.addr_i,exp_addr);
    check("target data pin",u_pipeline_core.data_ram_target_inst.wdata_i,exp_wdata);
    check("target mask pin",{28'b0,u_pipeline_core.data_ram_target_inst.wstrb_i},{28'b0,exp_mask});
end
endtask

task check_target;
input complete_phase;
begin
    check("ready",{31'b0,u_pipeline_core.ram_ready_o},{31'b0,complete_phase});
    check("target pending",{31'b0,u_pipeline_core.data_ram_target_inst.pending_reg},{31'b0,complete_phase});
    check("RAM write pin",{31'b0,u_pipeline_core.data_ram_target_inst.data_ram_inst.ram_wr_en_i},
          {31'b0,(complete_phase && exp_req && exp_we && exp_mapped)});
    check("RAM read pin",{31'b0,u_pipeline_core.data_ram_target_inst.data_ram_inst.ram_rd_en_i},
          {31'b0,(complete_phase && exp_req && !exp_we && exp_mapped)});
    check("target read word",u_pipeline_core.ram_rd_data_o,complete_phase ? exp_word : 32'd0);
end
endtask

task check_controls;
input commit_phase;
begin
    check("GPR write",{31'b0,u_pipeline_core.wr_en_ex_o},{31'b0,(exp_gwr && commit_phase)});
    if(exp_gwr && commit_phase) begin
        check("GPR destination",{27'b0,u_pipeline_core.wr_addr_ex_o},{27'b0,exp_rd});
        check("GPR result",u_pipeline_core.wr_data_ex_o,exp_result);
    end
    check("CSR write",{31'b0,u_pipeline_core.ex_inst.csr_wr_en_ex_o},{31'b0,exp_cwr});
    check("CSR read",{31'b0,u_pipeline_core.ex_inst.csr_rd_en_ex_o},{31'b0,exp_crd});
    if(exp_cwr) begin
        check("CSR write address",{20'b0,u_pipeline_core.ex_inst.csr_wr_addr_ex_o},{20'b0,exp_caddr});
        check("CSR source",u_pipeline_core.ex_inst.csr_wr_data_ex_o,exp_csource);
    end
    if(exp_crd) check("CSR read address",{20'b0,u_pipeline_core.ex_inst.csr_rd_addr_ex_o},{20'b0,exp_caddr});
    check("return event",{31'b0,u_pipeline_core.ex_inst.trap_return_ex_o},{31'b0,exp_return});
    check("redirect",{31'b0,u_pipeline_core.pc_brench_flag_ex_o},{31'b0,exp_jump});
    check("flush",{31'b0,u_pipeline_core.clear_valid_ex_o},{31'b0,exp_jump});
    if(exp_jump) check("redirect target",u_pipeline_core.pc_brench_addr_ex_o,exp_target);
end
endtask

task check_empty;
begin
    check("no data request",{31'b0,u_pipeline_core.data_req},0);
    check("no GPR write",{31'b0,u_pipeline_core.wr_en_ex_o},0);
    check("no CSR write",{31'b0,u_pipeline_core.ex_inst.csr_wr_en_ex_o},0);
    check("no CSR read",{31'b0,u_pipeline_core.ex_inst.csr_rd_en_ex_o},0);
    check("no return",{31'b0,u_pipeline_core.ex_inst.trap_return_ex_o},0);
    check("no stall",{31'b0,u_pipeline_core.stall_ex_o},0);
    check("no pending access",{31'b0,u_pipeline_core.ram_ready_o},0);
    check("no target write",{31'b0,u_pipeline_core.data_ram_target_inst.data_ram_inst.ram_wr_en_i},0);
    check("no target read",{31'b0,u_pipeline_core.data_ram_target_inst.data_ram_inst.ram_rd_en_i},0);
    check("idle target read data",u_pipeline_core.ram_rd_data_o,0);
end
endtask

task check_flush;
input [31:0] target;
begin
    check("PC redirect update",u_pipeline_core.pc_o,target);
    check("IFID flushed",{31'b0,u_pipeline_core.valid_ifid_o},0);
    check("IDEX flushed",{31'b0,u_pipeline_core.valid_idex_o},0);
end
endtask

task check_hold;
begin
    check("PC held",u_pipeline_core.pc_o,saved_pc);
    if({u_pipeline_core.valid_ifid_o,u_pipeline_core.pc_ifid_o,u_pipeline_core.instr_ifid_o} !== saved_ifid) begin
        $display("FAIL t=%0t step=%0d IFID packet changed while waiting",$time,step); errors=errors+1;
    end
    if(ex_packet !== saved_ex_packet) begin
        $display("FAIL t=%0t step=%0d IDEX packet changed while waiting",$time,step); errors=errors+1;
    end
    if(payload !== saved_payload) begin
        $display("FAIL t=%0t step=%0d request payload changed while waiting",$time,step); errors=errors+1;
    end
    check("same waiting instruction",step,saved_step);
end
endtask

// 仅在提交沿调用；等待沿不改变任何预期架构状态。
task update_expected;
begin
    if(exp_gwr && exp_rd!=0) expected_regs[exp_rd]=exp_result;
    case(expected_pc[step])
        32'h04: mtvec=32'h100;
        32'h10: mie=32'h800;
        32'h18: mstatus=32'h1808;
        32'h20: expected_ram[0]=32'h55;
        32'h2C: expected_ram[1]=32'h56;
        32'h34: expected_ram[0]=32'h8055;
        32'h48: expected_ram[0]=32'h81238055;
        32'h58: expected_ram[2]=32'h81238055;
        32'h108: mstatus=32'h1888;
    endcase
end
endtask

initial begin
    errors=0; step=0; irq_count=0; return_count=0; actual_fires=0;
    rst_n=0; irq_external_i=0; finished=0; lw_prepared=0; memory_waiting=0;
    mstatus=32'h1800; mtvec=0; mie=0; mepc=0; mcause=0;
    for(i=0;i<32;i=i+1) begin
        expected_regs[i]=0; expected_ram[i]=0; prepares[i]=0; commits[i]=0;
    end
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
    expected_pc[13]=32'h28;
    expected_pc[14]=32'h2C;
    expected_pc[15]=32'h30;
    expected_pc[16]=32'h34;
    expected_pc[17]=32'h38;
    expected_pc[18]=32'h3C;
    expected_pc[19]=32'h40;
    expected_pc[20]=32'h44;
    expected_pc[21]=32'h48;
    expected_pc[22]=32'h4C;
    expected_pc[23]=32'h50;
    expected_pc[24]=32'h54;
    expected_pc[25]=32'h58;
    expected_pc[26]=32'h5C;
    expected_pc[27]=32'h60;
    expected_pc[28]=32'h64;
    expected_pc[29]=32'h68;
    expected_pc[30]=32'h6C;
    expected_pc[31]=32'h70;
    #15; check_state; check_empty;
    check("reset entry",{31'b0,u_pipeline_core.ex_inst.trap_enter_ex_o},0);
    #10; rst_n=1;
    while(!finished) begin
        @(posedge clk);
        check_state;
        check("no DIV start",{31'b0,u_pipeline_core.ex_inst.start_ex_o},0);
        if(u_pipeline_core.ex_inst.irq_take===1'b1) begin
            check("one IRQ only",irq_count,0);
            check("IRQ after LW completion",step,10);
            check("no in-flight memory at IRQ",{31'b0,memory_waiting},0);
            check("LW already wrote x2",u_pipeline_core.regfile_inst.reg_file[2],32'h55);
            check("consumer not executed",u_pipeline_core.regfile_inst.reg_file[3],0);
            check_empty;
            check("IRQ request asserted",{31'b0,irq_external_i},1);
            check("entry",{31'b0,u_pipeline_core.ex_inst.trap_enter_ex_o},1);
            check("saved address source",u_pipeline_core.ex_inst.trap_pc_ex_o,32'h28);
            check("interrupt cause",u_pipeline_core.ex_inst.trap_cause_ex_o,32'h8000000B);
            check("IRQ redirect",{31'b0,u_pipeline_core.pc_brench_flag_ex_o},1);
            check("IRQ flush",{31'b0,u_pipeline_core.clear_valid_ex_o},1);
            check("IRQ target",u_pipeline_core.pc_brench_addr_ex_o,32'h100);
            mepc=32'h28; mcause=32'h8000000B; mstatus=32'h1880;
            #1; check_state; check_flush(32'h100); check_empty;
            irq_count=irq_count+1;
        end else if(u_pipeline_core.ex_inst.irq_take===1'b0) begin
            check("no synchronous exception",{31'b0,u_pipeline_core.ex_inst.trap_enter_ex_o},0);
            if(u_pipeline_core.valid_idex_o===1'b1) begin
                if(step>=32) $fatal(1,"Extra instruction");
                check("instruction order",u_pipeline_core.pc_idex_o,expected_pc[step]);
                check("IRQ ordering",irq_count,(step<10) ? 0 : 1);
                prepare_expected;
                check_payload;
                if(exp_req) begin
                    if(u_pipeline_core.ram_ready_o===1'b0) begin
                        if(memory_waiting) $fatal(1,"Extra wait cycle step=%0d",step);
                        check("one prepare per access",prepares[step],0);
                        check("wait stall",{31'b0,u_pipeline_core.stall_ex_o},1);
                        check_target(0); check_controls(0);
                        saved_pc=u_pipeline_core.pc_o;
                        saved_ifid={u_pipeline_core.valid_ifid_o,u_pipeline_core.pc_ifid_o,u_pipeline_core.instr_ifid_o};
                        saved_ex_packet=ex_packet; saved_payload=payload; saved_step=step;
                        prepares[step]=prepares[step]+1; memory_waiting=1;
                        #1;
                        check_hold; check_state; check_payload;
                        check_target(1); check_controls(1);
                        check("stall clears after A",{31'b0,u_pipeline_core.stall_ex_o},0);
                        check("old boundary closed",{31'b0,u_pipeline_core.ex_inst.boundary_valid_reg},0);
                        if(expected_pc[step]==32'h24) lw_prepared=1;
                        // No step advance: ready=1 after A is not a submission.
                    end else if(u_pipeline_core.ram_ready_o===1'b1) begin
                        check("prepared before completion",{31'b0,memory_waiting},1);
                        check("exactly one prepare",prepares[step],1);
                        check_hold; check_target(1); check_controls(1);
                        check("completion not stalled",{31'b0,u_pipeline_core.stall_ex_o},0);
                        if(expected_pc[step]==32'h24) check("IRQ arrived during LW",{31'b0,irq_external_i},1);
                        update_expected;
                        commits[step]=commits[step]+1; memory_waiting=0;
                        #1; check_state;
                        check("target ready resets after B",{31'b0,u_pipeline_core.ram_ready_o},0);
                        check("target write inactive after B",{31'b0,u_pipeline_core.data_ram_target_inst.data_ram_inst.ram_wr_en_i},0);
                        check("target read inactive after B",{31'b0,u_pipeline_core.data_ram_target_inst.data_ram_inst.ram_rd_en_i},0);
                        check("boundary established",{31'b0,u_pipeline_core.ex_inst.boundary_valid_reg},1);
                        check("resume after memory",u_pipeline_core.ex_inst.resume_pc_reg,expected_pc[step]+4);
                        if(expected_pc[step]==32'h24)
                            check("IRQ becomes eligible after LW submission",{31'b0,u_pipeline_core.ex_inst.irq_take},1);
                        // A following memory instruction may already assert a NEW req.
                        step=step+1;
                    end else $fatal(1,"Unknown memory ready");
                end else begin
                    check("no unfinished access",{31'b0,memory_waiting},0);
                    check("ordinary instruction not stalled",{31'b0,u_pipeline_core.stall_ex_o},0);
                    check_target(0); check_controls(1);
                    update_expected; commits[step]=commits[step]+1;
                    #1; check_state;
                    if(exp_jump) check_flush(exp_target);
                    if(exp_return) return_count=return_count+1;
                    if(expected_pc[step]==32'h70) begin
                        check_empty;
                        check("no event in final bubble",{31'b0,u_pipeline_core.ex_inst.trap_enter_ex_o},0);
                        finished=1;
                    end
                    step=step+1;
                end
            end else if(u_pipeline_core.valid_idex_o===1'b0) begin
                check_empty;
                check("bubble redirect",{31'b0,u_pipeline_core.pc_brench_flag_ex_o},0);
                check("bubble flush",{31'b0,u_pipeline_core.clear_valid_ex_o},0);
                #1; check_state;
            end else $fatal(1,"Unknown EX valid");
        end else $fatal(1,"Unknown irq_take");
    end
    check("all program instructions committed",step,32);
    check("one IRQ",irq_count,1); check("one MRET",return_count,1);
    check("actual target completions",actual_fires,14);
    for(i=0;i<32;i=i+1) begin
        check("instruction committed once",commits[i],1);
        case(expected_pc[i])
            32'h20,32'h24,32'h2C,32'h34,32'h38,32'h3C,32'h48,
            32'h4C,32'h50,32'h54,32'h58,32'h60,32'h64,32'h6C:
                check("memory instruction waited once",prepares[i],1);
            default: check("ordinary instruction never waits",prepares[i],0);
        endcase
    end
    check_state;
    check("final RAM[0]",u_pipeline_core.data_ram_target_inst.data_ram_inst.memory[0],32'h81238055);
    check("final RAM[1]",u_pipeline_core.data_ram_target_inst.data_ram_inst.memory[1],32'h56);
    check("final RAM[2]",u_pipeline_core.data_ram_target_inst.data_ram_inst.memory[2],32'h81238055);
    if(errors==0) begin
        $display("PASS: CPU data handshake checks passed"); $finish;
    end else $fatal(1,"FAIL: %0d CPU data handshake checks failed",errors);
end

// 只在检查器确认准备沿A完成之后，才在负沿拉高请求。
initial begin
    wait(lw_prepared===1'b1);
    @(negedge clk); irq_external_i=1;
    wait(irq_count==1);
    @(negedge clk); irq_external_i=0;
end
initial begin
    #20000;
    $fatal(1,"FAIL: CPU data handshake timeout step=%0d IRQ=%0d waiting=%b",
           step,irq_count,memory_waiting);
end
endmodule

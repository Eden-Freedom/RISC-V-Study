`timescale 1ns / 1ps
// CPU 数据地址译码自检：只驱动时钟/复位，不强制任何内部信号。
module tb_data_decode();
reg clk = 1'b0;
always #10 clk = ~clk;
reg rst_n;
integer errors, step, r;
reg finished;
reg [31:0] expected_regs [0:31];
reg [31:0] expected_ram [0:31];
reg [31:0] program_word [0:23];
reg exp_gwr, exp_wr, exp_rd, exp_wr_selected, exp_rd_selected;
reg [4:0] exp_dest;
reg [31:0] exp_result, exp_wr_addr, exp_rd_addr, exp_wr_data, exp_read_word;
reg [3:0] exp_sel;
reg exp_jump;

pipeline_core u_pipeline_core(
    .clk(clk), .rst_n(rst_n), .irq_external_i(1'b0)
);

task check;
input [8*80-1:0] item;
input [31:0] actual, expected;
begin
    if (actual !== expected) begin
        $display("FAIL t=%0t step=%0d %0s actual=%h expected=%h",
                 $time,step,item,actual,expected);
        errors=errors+1;
    end
end
endtask

// 独立预期状态：仅按程序表更新，不从DUT计算或复制。
task check_state;
integer n;
begin
    for (n=0;n<32;n=n+1) begin
        if (u_pipeline_core.data_ram_inst.memory[n] !== expected_ram[n]) begin
            $display("FAIL t=%0t step=%0d RAM[%0d]=%h expected=%h",$time,step,n,
                     u_pipeline_core.data_ram_inst.memory[n],expected_ram[n]);
            errors=errors+1;
        end
        // x0内部存储未复位，架构读口的零值另行检查。
        if (n!=0 && u_pipeline_core.regfile_inst.reg_file[n] !== expected_regs[n]) begin
            $display("FAIL t=%0t step=%0d x%0d=%h expected=%h",$time,step,n,
                     u_pipeline_core.regfile_inst.reg_file[n],expected_regs[n]);
            errors=errors+1;
        end
    end
    if (u_pipeline_core.regfile_inst.rs1_addr_i === 5'd0)
        check("x0 read",u_pipeline_core.regfile_inst.rs1_data_o,32'd0);
end
endtask

task check_no_control_events;
begin
    check("no stall",{31'b0,u_pipeline_core.stall_ex_o},32'd0);
    check("no IRQ",{31'b0,u_pipeline_core.ex_inst.irq_take},32'd0);
    check("no trap entry",{31'b0,u_pipeline_core.ex_inst.trap_enter_ex_o},32'd0);
    check("no trap return",{31'b0,u_pipeline_core.ex_inst.trap_return_ex_o},32'd0);
    check("no DIV start",{31'b0,u_pipeline_core.ex_inst.start_ex_o},32'd0);
    check("no CSR write",{31'b0,u_pipeline_core.ex_inst.csr_wr_en_ex_o},32'd0);
    check("no CSR read",{31'b0,u_pipeline_core.ex_inst.csr_rd_en_ex_o},32'd0);
end
endtask

// 请求、命中、选中使能和RAM实例端口分别检查，防止只看最终结果。
task check_memory_path;
begin
    check("EX write request",{31'b0,u_pipeline_core.ram_wr_en_ex_o},{31'b0,exp_wr});
    check("EX read request",{31'b0,u_pipeline_core.ram_rd_en_ex_o},{31'b0,exp_rd});
    check("EX write address",u_pipeline_core.ram_wr_addr_ex_o,exp_wr_addr);
    check("EX read address",u_pipeline_core.ram_rd_addr_ex_o,exp_rd_addr);
    check("write hit",{31'b0,u_pipeline_core.ram_wr_hit},
          (exp_wr_addr==32'h80 || exp_wr_addr==32'h10000000 || exp_wr_addr==32'hFC) ? 32'd0 : 32'd1);
    check("read hit",{31'b0,u_pipeline_core.ram_rd_hit},
          (exp_rd_addr==32'h80 || exp_rd_addr==32'h10000000 || exp_rd_addr==32'hFC) ? 32'd0 : 32'd1);
    check("selected RAM write",{31'b0,u_pipeline_core.ram_wr_en_selected},{31'b0,exp_wr_selected});
    check("selected RAM read",{31'b0,u_pipeline_core.ram_rd_en_selected},{31'b0,exp_rd_selected});
    check("RAM write pin",{31'b0,u_pipeline_core.data_ram_inst.ram_wr_en_i},{31'b0,exp_wr_selected});
    check("RAM read pin",{31'b0,u_pipeline_core.data_ram_inst.ram_rd_en_i},{31'b0,exp_rd_selected});
    check("RAM read word",u_pipeline_core.ram_rd_data_o,exp_read_word);
    check("EX read data input",u_pipeline_core.ex_inst.ram_rd_data_ex_i,exp_read_word);
    check("EX store byte mask",{28'b0,u_pipeline_core.ram_wr_sel_ex_o},{28'b0,exp_sel});
    check("EX store data",u_pipeline_core.ram_wr_data_ex_o,exp_wr_data);
    if (exp_wr) begin
        check("RAM store word index",{27'b0,u_pipeline_core.data_ram_inst.ram_wr_addr_i},
              (step==4 || step==16 || step==20) ? 32'd31 : 32'd0);
        check("RAM store data pin",u_pipeline_core.data_ram_inst.ram_wr_data_i,exp_wr_data);
        check("RAM byte mask pin",{28'b0,u_pipeline_core.data_ram_inst.ram_wr_sel_i},{28'b0,exp_sel});
    end
    if (exp_rd)
        check("RAM load word index",{27'b0,u_pipeline_core.data_ram_inst.ram_rd_addr_i},
              (step==13 || step==17 || step==18 || step==21 || step==22) ? 32'd31 : 32'd0);
end
endtask

task clear_expected;
begin
    exp_gwr=0; exp_dest=0; exp_result=0; exp_jump=0;
    exp_wr=0; exp_rd=0; exp_wr_selected=0; exp_rd_selected=0;
    exp_wr_addr=0; exp_rd_addr=0; exp_wr_data=0; exp_read_word=0; exp_sel=0;
end
endtask

task prepare_expected;
begin
    clear_expected;
    case (step)
        0: begin exp_gwr=1; exp_dest=1; exp_result=32'h55; end
        1: begin exp_wr=1; exp_wr_selected=1; exp_wr_data=32'h55; exp_sel=4'b1111; end
        2: begin exp_gwr=1; exp_dest=2; exp_result=32'h7C; end
        3: begin exp_gwr=1; exp_dest=3; exp_result=32'h66; end
        4: begin exp_wr=1; exp_wr_selected=1; exp_wr_addr=32'h7C; exp_wr_data=32'h66; exp_sel=4'b1111; end
        5: begin exp_gwr=1; exp_dest=4; exp_result=32'h80; end
        6: begin exp_gwr=1; exp_dest=5; exp_result=32'h33; end
        7: begin exp_wr=1; exp_wr_addr=32'h80; exp_wr_data=32'h33; exp_sel=4'b1111; end
        8: begin exp_rd=1; exp_rd_addr=32'h80; exp_gwr=1; exp_dest=6; exp_result=0; end
        9: begin exp_gwr=1; exp_dest=7; exp_result=32'h10000000; end
        10: begin exp_wr=1; exp_wr_addr=32'h10000000; exp_wr_data=32'h33; exp_sel=4'b1111; end
        11: begin exp_rd=1; exp_rd_addr=32'h10000000; exp_gwr=1; exp_dest=8; exp_result=0; end
        12: begin exp_rd=1; exp_rd_selected=1; exp_gwr=1; exp_dest=9; exp_result=32'h55; exp_read_word=32'h55; end
        13: begin exp_rd=1; exp_rd_selected=1; exp_rd_addr=32'h7C; exp_gwr=1; exp_dest=10; exp_result=32'h66; exp_read_word=32'h66; end
        14: begin exp_gwr=1; exp_dest=11; exp_result=32'h7F; end
        15: begin exp_gwr=1; exp_dest=12; exp_result=32'h7A; end
        16: begin exp_wr=1; exp_wr_selected=1; exp_wr_addr=32'h7F; exp_wr_data=32'h7A000000; exp_sel=4'b1000; end
        17: begin exp_rd=1; exp_rd_selected=1; exp_rd_addr=32'h7F; exp_gwr=1; exp_dest=13; exp_result=32'h7A; exp_read_word=32'h7A000066; end
        18: begin exp_rd=1; exp_rd_selected=1; exp_rd_addr=32'h7C; exp_gwr=1; exp_dest=14; exp_result=32'h7A000066; exp_read_word=32'h7A000066; end
        19: begin exp_gwr=1; exp_dest=15; exp_result=32'hFC; end
        20: begin exp_wr=1; exp_wr_addr=32'hFC; exp_wr_data=32'h33; exp_sel=4'b1111; end
        21: begin exp_rd=1; exp_rd_addr=32'hFC; exp_gwr=1; exp_dest=16; exp_result=0; end
        22: begin exp_rd=1; exp_rd_selected=1; exp_rd_addr=32'h7C; exp_gwr=1; exp_dest=17; exp_result=32'h7A000066; exp_read_word=32'h7A000066; end
        23: begin exp_jump=1; exp_gwr=1; exp_dest=0; exp_result=32'h60; end
        default: $fatal(1,"Unexpected instruction step=%0d",step);
    endcase
end
endtask

task check_bubble;
begin
    clear_expected;
    check_no_control_events;
    check_memory_path;
    check("bubble GPR write",{31'b0,u_pipeline_core.wr_en_ex_o},32'd0);
    check("bubble redirect",{31'b0,u_pipeline_core.pc_brench_flag_ex_o},32'd0);
    check("bubble flush",{31'b0,u_pipeline_core.clear_valid_ex_o},32'd0);
end
endtask

initial begin
    rst_n=0; errors=0; step=0; finished=0;
    for (r=0;r<32;r=r+1) begin expected_ram[r]=0; expected_regs[r]=0; end
    program_word[0]=32'h05500093; // ADDI x1,x0,0x55
    program_word[1]=32'h00102023; // SW x1,0(x0)
    program_word[2]=32'h07C00113; // ADDI x2,x0,0x7C
    program_word[3]=32'h06600193; // ADDI x3,x0,0x66
    program_word[4]=32'h00312023; // SW x3,0(x2)
    program_word[5]=32'h08000213; // ADDI x4,x0,0x80
    program_word[6]=32'h03300293; // ADDI x5,x0,0x33
    program_word[7]=32'h00522023; // SW x5,0(x4): unmapped
    program_word[8]=32'h00022303; // LW x6,0(x4): zero
    program_word[9]=32'h100003B7; // LUI x7,0x10000
    program_word[10]=32'h0053A023; // SW x5,0(x7): unmapped
    program_word[11]=32'h0003A403; // LW x8,0(x7): zero
    program_word[12]=32'h00002483; // LW x9,0(x0)
    program_word[13]=32'h00012503; // LW x10,0(x2)
    program_word[14]=32'h07F00593; // ADDI x11,x0,0x7F
    program_word[15]=32'h07A00613; // ADDI x12,x0,0x7A
    program_word[16]=32'h00C58023; // SB x12,0(x11): last byte
    program_word[17]=32'h0005C683; // LBU x13,0(x11)
    program_word[18]=32'h00012703; // LW x14,0(x2)
    program_word[19]=32'h0FC00793; // ADDI x15,x0,0xFC
    program_word[20]=32'h0057A023; // SW x5,0(x15): unmapped
    program_word[21]=32'h0007A803; // LW x16,0(x15): zero
    program_word[22]=32'h00012883; // LW x17,0(x2)
    program_word[23]=32'h0000006F; // JAL x0,0: done
    #15; // 同步复位已在t=10的上升沿生效。
    check_state;
    check_bubble;
    check("reset IFID",{31'b0,u_pipeline_core.valid_ifid_o},32'd0);
    check("reset IDEX",{31'b0,u_pipeline_core.valid_idex_o},32'd0);
    #10; rst_n=1;
    while (!finished) begin
        @(posedge clk);
        check_state; // 更新沿之前仍应保持上一条提交后的状态。
        check_no_control_events;
        if (u_pipeline_core.pc_o<=32'h5C && u_pipeline_core.pc_o[1:0]==2'b00)
            check("fetched program word",u_pipeline_core.instr_o,program_word[u_pipeline_core.pc_o>>2]);
        else check("unmapped instruction word",u_pipeline_core.instr_o,32'd0);
        if (u_pipeline_core.valid_idex_o === 1'b1) begin
            if (step>=24) $fatal(1,"Too many submitted instructions");
            check("EX PC in order",u_pipeline_core.pc_idex_o,step*4);
            prepare_expected;
            check_memory_path;
            check("GPR write enable",{31'b0,u_pipeline_core.wr_en_ex_o},{31'b0,exp_gwr});
            if (exp_gwr) begin
                check("GPR destination",{27'b0,u_pipeline_core.wr_addr_ex_o},{27'b0,exp_dest});
                check("GPR write result",u_pipeline_core.wr_data_ex_o,exp_result);
                if (exp_dest!=0) expected_regs[exp_dest]=exp_result;
            end
            check("redirect flag",{31'b0,u_pipeline_core.pc_brench_flag_ex_o},{31'b0,exp_jump});
            check("flush flag",{31'b0,u_pipeline_core.clear_valid_ex_o},{31'b0,exp_jump});
            if (exp_jump) check("JAL target",u_pipeline_core.pc_brench_addr_ex_o,32'h5C);
            // 只有这三次映射内写能够改变预期RAM，范围外写不更新模型。
            case (step)
                1: expected_ram[0]=32'h55;
                4: expected_ram[31]=32'h66;
                16: expected_ram[31]=32'h7A000066;
            endcase
            #1;
            check_state;
            if (step==23) begin
                check("PC after JAL",u_pipeline_core.pc_o,32'h5C);
                check("IFID flushed",{31'b0,u_pipeline_core.valid_ifid_o},32'd0);
                check("IDEX flushed",{31'b0,u_pipeline_core.valid_idex_o},32'd0);
                check_bubble; // 冲刷气泡默认地址命中，但RAM使能必须关闭。
                finished=1;
            end
            step=step+1;
        end else if (u_pipeline_core.valid_idex_o === 1'b0) begin
            check_bubble;
            #1;
            check_state;
        end else $fatal(1,"Unknown EX valid");
    end
    check("all instructions submitted",step,24);
    check("final RAM[0]",u_pipeline_core.data_ram_inst.memory[0],32'h55);
    check("final RAM[31]",u_pipeline_core.data_ram_inst.memory[31],32'h7A000066);
    if (errors==0) begin
        $display("PASS: data address decode pipeline checks passed");
        $finish;
    end else $fatal(1,"FAIL: %0d data address decode checks failed",errors);
end

initial begin
    #10000;
    $fatal(1,"FAIL: data address decode timeout at step=%0d",step);
end
endmodule

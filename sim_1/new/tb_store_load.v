`timescale 1ns / 1ps

module tb_store_load;

reg clk;
reg rst_n;

integer errors;
reg bad_path_seen;

initial clk = 1'b0;
always #10 clk = ~clk;

task fail;
input [255:0] msg;
begin
    $display("FAIL [%0t] %s", $time, msg);
    errors = errors + 1;
end
endtask

task check_regfile;
input [4:0] idx;
input [31:0] exp_val;
begin
    if (u_pipeline_core.regfile_inst.reg_file[idx] !== exp_val) begin
        $display("FAIL [%0t] x%0d actual=%h expected=%h",
                 $time, idx,
                 u_pipeline_core.regfile_inst.reg_file[idx],
                 exp_val);
        errors = errors + 1;
    end
end
endtask

task wait_for_pc;
input [31:0] pc_exp;
integer cycles;
reg found;
begin
    found = 1'b0;
    cycles = 0;

    while (!found && cycles < 100) begin
        @(negedge clk);

        if (u_pipeline_core.valid_idex_o &&
            u_pipeline_core.pc_idex_o == pc_exp) begin
            found = 1'b1;
        end

        cycles = cycles + 1;
    end

    if (!found) begin
        $display("FAIL [%0t] timeout waiting PC=%h",
                 $time, pc_exp);
        errors = errors + 1;
    end
end
endtask

task check_store_at_pc;
input [31:0] pc_exp;
input [31:0] addr_exp;
input [31:0] data_exp;
input [3:0]  sel_exp;
input [31:0] mem_exp;
begin
    wait_for_pc(pc_exp);

    if (u_pipeline_core.ram_wr_en_ex_o !== 1'b1) begin
        fail("store ram_wr_en_ex_o is not asserted");
    end

    if (u_pipeline_core.ram_wr_addr_ex_o !== addr_exp) begin
        $display("FAIL [%0t] store address actual=%h expected=%h",
                 $time,
                 u_pipeline_core.ram_wr_addr_ex_o,
                 addr_exp);
        errors = errors + 1;
    end

    if (u_pipeline_core.ram_wr_data_ex_o !== data_exp) begin
        $display("FAIL [%0t] store data actual=%h expected=%h",
                 $time,
                 u_pipeline_core.ram_wr_data_ex_o,
                 data_exp);
        errors = errors + 1;
    end

    if (u_pipeline_core.ram_wr_sel_ex_o !== sel_exp) begin
        $display("FAIL [%0t] store select actual=%b expected=%b",
                 $time,
                 u_pipeline_core.ram_wr_sel_ex_o,
                 sel_exp);
        errors = errors + 1;
    end

    @(posedge clk);
    #1;

    if (u_pipeline_core.ram_inst.memory[16] !== mem_exp) begin
        $display("FAIL [%0t] memory[16] actual=%h expected=%h",
                 $time,
                 u_pipeline_core.ram_inst.memory[16],
                 mem_exp);
        errors = errors + 1;
    end
end
endtask

task check_load_at_pc;
input [31:0] pc_exp;
input [31:0] addr_exp;
input [4:0]  rd_exp;
input [31:0] raw_mem_exp;
input [31:0] result_exp;
begin
    wait_for_pc(pc_exp);

    if (u_pipeline_core.ram_rd_en_ex_o !== 1'b1) begin
        fail("load ram_rd_en_ex_o is not asserted");
    end

    if (u_pipeline_core.ram_rd_addr_ex_o !== addr_exp) begin
        $display("FAIL [%0t] load address actual=%h expected=%h",
                 $time,
                 u_pipeline_core.ram_rd_addr_ex_o,
                 addr_exp);
        errors = errors + 1;
    end

    if (u_pipeline_core.ram_rd_data_o !== raw_mem_exp) begin
        $display("FAIL [%0t] raw load data actual=%h expected=%h",
                 $time,
                 u_pipeline_core.ram_rd_data_o,
                 raw_mem_exp);
        errors = errors + 1;
    end

    if (u_pipeline_core.wr_addr_ex_o !== rd_exp) begin
        $display("FAIL [%0t] load rd actual=%0d expected=%0d",
                 $time,
                 u_pipeline_core.wr_addr_ex_o,
                 rd_exp);
        errors = errors + 1;
    end

    if (u_pipeline_core.wr_data_ex_o !== result_exp) begin
        $display("FAIL [%0t] load result actual=%h expected=%h",
                 $time,
                 u_pipeline_core.wr_data_ex_o,
                 result_exp);
        errors = errors + 1;
    end

    @(posedge clk);
    #1;
    check_regfile(rd_exp, result_exp);
end
endtask

task check_addi_at_pc;
input [31:0] pc_exp;
input [31:0] rs1_exp;
input [4:0]  rd_exp;
input [31:0] result_exp;
begin
    wait_for_pc(pc_exp);

    if (u_pipeline_core.rs1_data_idex_o !== rs1_exp) begin
        $display("FAIL [%0t] ADDI rs1 actual=%h expected=%h",
                 $time,
                 u_pipeline_core.rs1_data_idex_o,
                 rs1_exp);
        errors = errors + 1;
    end

    if (u_pipeline_core.wr_en_ex_o !== 1'b1 ||
        u_pipeline_core.wr_addr_ex_o !== rd_exp ||
        u_pipeline_core.wr_data_ex_o !== result_exp) begin
        $display("FAIL [%0t] ADDI writeback actual: en=%b rd=%0d data=%h",
                 $time,
                 u_pipeline_core.wr_en_ex_o,
                 u_pipeline_core.wr_addr_ex_o,
                 u_pipeline_core.wr_data_ex_o);
        errors = errors + 1;
    end

    @(posedge clk);
    #1;
    check_regfile(rd_exp, result_exp);
end
endtask

task check_jal_at_pc;
input [31:0] pc_exp;
input [31:0] target_exp;
begin
    wait_for_pc(pc_exp);

    if (u_pipeline_core.pc_brench_flag_ex_o !== 1'b1) begin
        fail("JAL branch flag is not asserted");
    end

    if (u_pipeline_core.pc_brench_addr_ex_o !== target_exp) begin
        $display("FAIL [%0t] JAL target actual=%h expected=%h",
                 $time,
                 u_pipeline_core.pc_brench_addr_ex_o,
                 target_exp);
        errors = errors + 1;
    end

    if (u_pipeline_core.clear_valid_ex_o !== 1'b1) begin
        fail("JAL clear_valid_ex_o is not asserted");
    end

    @(posedge clk);
    #1;
end
endtask

always @(negedge clk) begin
    if (u_pipeline_core.valid_idex_o &&
        ((u_pipeline_core.pc_idex_o == 32'h00000070) ||
         (u_pipeline_core.pc_idex_o == 32'h00000074))) begin

        bad_path_seen = 1'b1;

        $display("FAIL [%0t] wrong-path store reached EX, PC=%h",
                 $time,
                 u_pipeline_core.pc_idex_o);

        errors = errors + 1;
    end
end

initial begin
    rst_n = 1'b0;
    errors = 0;
    bad_path_seen = 1'b0;

    #15;
    rst_n = 1'b1;

    // 初始化存储器
    check_store_at_pc(
        32'h0000000C,
        32'h00000040,
        32'h80FF7F01,
        4'b1111,
        32'h80FF7F01
    );

    // LB/LBU
    check_load_at_pc(
        32'h00000010,
        32'h00000040,
        5'd3,
        32'h80FF7F01,
        32'h00000001
    );

    check_addi_at_pc(
        32'h00000014,
        32'h00000001,
        5'd4,
        32'h00000002
    );

    check_load_at_pc(
        32'h00000018,
        32'h00000041,
        5'd5,
        32'h80FF7F01,
        32'h0000007F
    );

    check_load_at_pc(
        32'h0000001C,
        32'h00000042,
        5'd6,
        32'h80FF7F01,
        32'hFFFFFFFF
    );

    check_load_at_pc(
        32'h00000020,
        32'h00000043,
        5'd7,
        32'h80FF7F01,
        32'h00000080
    );

    // LH/LHU
    check_load_at_pc(
        32'h00000024,
        32'h00000040,
        5'd8,
        32'h80FF7F01,
        32'h00007F01
    );

    check_load_at_pc(
        32'h00000028,
        32'h00000040,
        5'd9,
        32'h80FF7F01,
        32'h00007F01
    );

    check_load_at_pc(
        32'h0000002C,
        32'h00000042,
        5'd10,
        32'h80FF7F01,
        32'hFFFF80FF
    );

    check_load_at_pc(
        32'h00000030,
        32'h00000042,
        5'd11,
        32'h80FF7F01,
        32'h000080FF
    );

    // SB lane 00/01/02/03
    check_store_at_pc(
        32'h00000054,
        32'h00000040,
        32'h000000AA,
        4'b0001,
        32'h80FF7FAA
    );

    check_store_at_pc(
        32'h00000058,
        32'h00000041,
        32'h0000BB00,
        4'b0010,
        32'h80FFBBAA
    );

    check_store_at_pc(
        32'h0000005C,
        32'h00000042,
        32'h00CC0000,
        4'b0100,
        32'h80CCBBAA
    );

    check_store_at_pc(
        32'h00000060,
        32'h00000043,
        32'hDD000000,
        4'b1000,
        32'hDDCCBBAA
    );

    // SH halfword address 00/02
    check_store_at_pc(
        32'h00000064,
        32'h00000040,
        32'h00001122,
        4'b0011,
        32'hDDCC1122
    );

    check_store_at_pc(
        32'h00000068,
        32'h00000042,
        32'h33440000,
        4'b1100,
        32'h33441122
    );

    // JAL 应跳过 0x70 和 0x74
    check_jal_at_pc(
        32'h0000006C,
        32'h00000078
    );

    if (bad_path_seen) begin
        fail("wrong-path SB/SH was executed");
    end

    // 跳转目标的 LW，以及紧邻消费
    check_load_at_pc(
        32'h00000078,
        32'h00000040,
        5'd18,
        32'h33441122,
        32'h33441122
    );

    check_addi_at_pc(
        32'h0000007C,
        32'h33441122,
        5'd19,
        32'h33441123
    );

    check_jal_at_pc(
        32'h00000080,
        32'h00000080
    );

    check_regfile(5'd2,  32'h80FF7F01);
    check_regfile(5'd3,  32'h00000001);
    check_regfile(5'd4,  32'h00000002);
    check_regfile(5'd5,  32'h0000007F);
    check_regfile(5'd6,  32'hFFFFFFFF);
    check_regfile(5'd7,  32'h00000080);
    check_regfile(5'd8,  32'h00007F01);
    check_regfile(5'd9,  32'h00007F01);
    check_regfile(5'd10, 32'hFFFF80FF);
    check_regfile(5'd11, 32'h000080FF);
    check_regfile(5'd18, 32'h33441122);
    check_regfile(5'd19, 32'h33441123);

    if (u_pipeline_core.ram_inst.memory[16] !== 32'h33441122) begin
        $display("FAIL [%0t] final memory[16] actual=%h expected=33441122",
                 $time,
                 u_pipeline_core.ram_inst.memory[16]);
        errors = errors + 1;
    end

    if (errors == 0) begin
        $display("PASS: LB/LBU/LH/LHU/SB/SH checks passed");
    end
    else begin
        $display("FAIL: %0d checks failed", errors);
    end

    $finish;
end

pipeline_core u_pipeline_core (
    .clk  (clk),
    .rst_n(rst_n)
);

endmodule
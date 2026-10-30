`timescale 1ns / 1ps

// Unified CSR test: actual decode -> EX -> csr_unit.
// Does not test IF, ID/EX, forwarding or the complete pipeline.
// Internal probes intentionally check enables as well as stored values.
module tb_csr;
  reg clk = 1'b0;
  always #5 clk = ~clk;
  reg rst_n = 1'b0;
  reg valid = 1'b0;
  reg [31:0] instr = 32'b0;
  reg [31:0] rs1_data = 32'b0;

  wire is_csrrw, is_csrrs, is_csrrc;
  wire is_csrrwi, is_csrrsi, is_csrrci;
  wire [31:0] csr_field;
  wire [11:0] csr_addr;
  wire [4:0] rd;
  wire gpr_we, stall;
  wire [4:0] gpr_addr;
  wire [31:0] gpr_data;
  integer errors = 0;
  integer cases_run = 0;

  addi_decode decoder (
      .instr_i(instr),
      .imm_csr_o(csr_field),
      .csr_addr_o(csr_addr),
      .rd_addr_o(rd),
      .is_csrrw_o(is_csrrw), .is_csrrs_o(is_csrrs),
      .is_csrrc_o(is_csrrc), .is_csrrwi_o(is_csrrwi),
      .is_csrrsi_o(is_csrrsi), .is_csrrci_o(is_csrrci)
  );

  ex dut (
      .clk(clk),
      .rst_n(rst_n),
      .valid_ex_i(valid),
      .is_addi_ex_i(1'b0),
      .is_xori_ex_i(1'b0),
      .is_ori_ex_i(1'b0),
      .is_andi_ex_i(1'b0),
      .is_slli_ex_i(1'b0),
      .is_srli_ex_i(1'b0),
      .is_srai_ex_i(1'b0),
      .is_slti_ex_i(1'b0),
      .is_sltiu_ex_i(1'b0),
      .is_add_ex_i(1'b0),
      .is_sub_ex_i(1'b0),
      .is_xor_ex_i(1'b0),
      .is_or_ex_i(1'b0),
      .is_and_ex_i(1'b0),
      .is_sll_ex_i(1'b0),
      .is_srl_ex_i(1'b0),
      .is_sra_ex_i(1'b0),
      .is_slt_ex_i(1'b0),
      .is_sltu_ex_i(1'b0),
      .is_beq_ex_i(1'b0),
      .is_bne_ex_i(1'b0),
      .is_blt_ex_i(1'b0),
      .is_bge_ex_i(1'b0),
      .is_bltu_ex_i(1'b0),
      .is_bgeu_ex_i(1'b0),
      .is_jal_ex_i(1'b0),
      .is_jalr_ex_i(1'b0),
      .is_lui_ex_i(1'b0),
      .is_auipc_ex_i(1'b0),
      .is_sw_ex_i(1'b0),
      .is_sb_ex_i(1'b0),
      .is_sh_ex_i(1'b0),
      .is_lw_ex_i(1'b0),
      .is_lb_ex_i(1'b0),
      .is_lbu_ex_i(1'b0),
      .is_lh_ex_i(1'b0),
      .is_lhu_ex_i(1'b0),
      .is_mul_ex_i(1'b0),
      .is_mulh_ex_i(1'b0),
      .is_mulhsu_ex_i(1'b0),
      .is_mulhu_ex_i(1'b0),
      .is_div_ex_i(1'b0),
      .is_divu_ex_i(1'b0),
      .is_rem_ex_i(1'b0),
      .is_remu_ex_i(1'b0),
      .is_csrrw_ex_i(is_csrrw),
      .is_csrrs_ex_i(is_csrrs),
      .is_csrrc_ex_i(is_csrrc),
      .is_csrrwi_ex_i(is_csrrwi),
      .is_csrrsi_ex_i(is_csrrsi),
      .is_csrrci_ex_i(is_csrrci),
      .pc_ex_i(32'b0),
      .rs1_data_ex_i(rs1_data),
      .rs2_data_ex_i(32'b0),
      .immi_data_ex_i(32'b0),
      .immb_data_ex_i(32'b0),
      .immj_data_ex_i(32'b0),
      .immu_data_ex_i(32'b0),
      .imms_data_ex_i(32'b0),
      .imm_csr_ex_i(csr_field),
      .csr_addr_ex_i(csr_addr),
      .rd_addr_ex_i(rd),
      .wr_en_ex_o(gpr_we),
      .wr_addr_ex_o(gpr_addr),
      .wr_data_ex_o(gpr_data),
      .pc_brench_flag_ex_o(),
      .pc_brench_addr_ex_o(),
      .clear_valid_ex_o(),
      .ram_wr_en_ex_o(),
      .ram_wr_addr_ex_o(),
      .ram_wr_data_ex_o(),
      .ram_wr_sel_ex_o(),
      .ram_rd_en_ex_o(),
      .ram_rd_addr_ex_o(),
      .ram_rd_data_ex_i(32'b0),
      .stall_ex_o(stall)
  );

  task check;
    input [8*64-1:0] test_name;
    input [8*48-1:0] item;
    input [31:0] actual;
    input [31:0] expected;
    begin
      if (actual !== expected) begin
        errors = errors + 1;
        $display("FAIL %0s: %0s got=%08h expected=%08h time=%0t",
                 test_name, item, actual, expected, $time);
      end
    end
  endtask

  // field = instr[19:15]: rs1 index for register forms, uimm for I forms.
  // exp_old/exp_new are explicit expectations, independent of DUT formulas.
  task access_csr;
    input [8*64-1:0] name;
    input [2:0] op;
    input [4:0] field;
    input [31:0] reg_data;
    input [4:0] dest;
    input access_valid;
    input [31:0] exp_old;
    input [31:0] exp_new;
    input exp_read;
    input exp_write;
    integer errors_before;
    reg [31:0] exp_src;
    begin
      errors_before = errors;
      cases_run = cases_run + 1;
      // Drive halfway between commit edges; no race with state updates.
      @(negedge clk);
      instr = {12'h340, field, op, dest, 7'b1110011};
      rs1_data = reg_data;
      valid = access_valid;
      exp_src = op[2] ? {27'b0, field} : reg_data;
      #1;
      check(name, "decoded source field", csr_field, {27'b0, field});
      check(name, "CSR before commit", dut.csr_unit_inst.mscratch_reg, exp_old);
      check(name, "CSR read enable", {31'b0, dut.csr_rd_en_ex_o}, {31'b0, exp_read});
      check(name, "CSR write enable", {31'b0, dut.csr_wr_en_ex_o}, {31'b0, exp_write});
      check(name, "CSR read data", dut.csr_rdata_csr_o, exp_read ? exp_old : 32'b0);
      check(name, "stall", {31'b0, stall}, 32'b0);
      if (exp_read)
        check(name, "CSR read address", {20'b0, dut.csr_rd_addr_ex_o}, 32'h340);
      if (exp_write) begin
        check(name, "CSR write address", {20'b0, dut.csr_wr_addr_ex_o}, 32'h340);
        check(name, "CSR source data", dut.csr_wr_data_ex_o, exp_src);
      end

      // Active region: NBA writes have not occurred yet. The GPR write
      // port must carry the OLD CSR value at this commit edge.
      @(posedge clk);
      check(name, "old CSR at commit", dut.csr_unit_inst.mscratch_reg, exp_old);
      if (exp_read && dest != 0) begin
        check(name, "GPR write enable", {31'b0, gpr_we}, 32'd1);
        check(name, "GPR destination", {27'b0, gpr_addr}, {27'b0, dest});
        check(name, "GPR old value at commit", gpr_data, exp_old);
      end
      else if (!exp_read) begin
        check(name, "GPR write suppressed", {31'b0, gpr_we}, 32'b0);
      end
      // SET/CLEAR rd=x0 must still read CSR. GPR write-enable may be
      // asserted with address zero (regfile discards it), or suppressed.
      if (dest == 0 && gpr_we === 1'b1)
        check(name, "GPR x0 destination", {27'b0, gpr_addr}, 32'b0);

      // After NBA: check the actual stored state, even if read is disabled.
      #1;
      check(name, "CSR after commit", dut.csr_unit_inst.mscratch_reg, exp_new);
      check(name, "CSR read after commit", dut.csr_rdata_csr_o,
            exp_read ? exp_new : 32'b0);
      if (errors == errors_before)
        $display("PASS %0s: old=%08h new=%08h rd_en=%b wr_en=%b",
                 name, exp_old, exp_new, exp_read, exp_write);
    end
  endtask

  initial begin
    // Synchronous reset is checked only after a clock edge.
    repeat (2) @(posedge clk);
    #1;
    check("reset", "mscratch", dut.csr_unit_inst.mscratch_reg, 32'b0);
    @(negedge clk);
    rst_n = 1'b1;

    // Six forms back-to-back; no reset or idle commit between accesses.
    access_csr("CSRRW",  3'b001, 5'd2, 32'h35, 5'd5, 1, 32'h00, 32'h35, 1, 1);
    access_csr("CSRRS",  3'b010, 5'd2, 32'h0A, 5'd5, 1, 32'h35, 32'h3F, 1, 1);
    access_csr("CSRRC",  3'b011, 5'd2, 32'h05, 5'd5, 1, 32'h3F, 32'h3A, 1, 1);
    // Deliberately unrelated rs1 data: I forms must use the encoded uimm.
    access_csr("CSRRWI", 3'b101, 5'd3, 32'hDEADBEEF, 5'd5, 1, 32'h3A, 32'h03, 1, 1);
    access_csr("CSRRSI", 3'b110, 5'd12,32'hDEADBEEF, 5'd5, 1, 32'h03, 32'h0F, 1, 1);
    access_csr("CSRRCI", 3'b111, 5'd5, 32'hDEADBEEF, 5'd5, 1, 32'h0F, 32'h0A, 1, 1);

    // WRITE rd=x0: CSR read OFF, CSR write ON (both forms).
    access_csr("CSRRW rd=x0",  3'b001, 5'd2, 32'hA5, 5'd0, 1, 32'h0A, 32'hA5, 0, 1);
    access_csr("CSRRWI rd=x0", 3'b101, 5'd9, 32'hFFFFFFFF, 5'd0, 1, 32'hA5, 32'h09, 0, 1);

    // SET/CLEAR field zero: read ON, write OFF (all four forms).
    access_csr("CSRRS rs1=x0", 3'b010, 5'd0, 32'b0, 5'd5, 1, 32'h09, 32'h09, 1, 0);
    access_csr("CSRRC rs1=x0", 3'b011, 5'd0, 32'b0, 5'd5, 1, 32'h09, 32'h09, 1, 0);
    access_csr("CSRRSI uimm=0",3'b110, 5'd0, 32'hFFFFFFFF, 5'd5, 1, 32'h09, 32'h09, 1, 0);
    access_csr("CSRRCI uimm=0",3'b111, 5'd0, 32'hFFFFFFFF, 5'd5, 1, 32'h09, 32'h09, 1, 0);

    // Nonzero register INDEX, zero CONTENT: write must remain ON.
    access_csr("CSRRS x7 contains zero",3'b010,5'd7,32'b0,5'd5,1,32'h09,32'h09,1,1);
    access_csr("CSRRC x7 contains zero",3'b011,5'd7,32'b0,5'd5,1,32'h09,32'h09,1,1);

    // SET/CLEAR rd=x0 must NOT suppress CSR reading.
    access_csr("CSRRS rd=x0", 3'b010, 5'd2, 32'h06, 5'd0, 1, 32'h09, 32'h0F, 1, 1);
    access_csr("CSRRC rd=x0", 3'b011, 5'd2, 32'h03, 5'd0, 1, 32'h0F, 32'h0C, 1, 1);
    access_csr("CSRRSI rd=x0",3'b110, 5'd3, 32'hDEADBEEF, 5'd0, 1, 32'h0C, 32'h0F, 1, 1);
    access_csr("CSRRCI rd=x0",3'b111, 5'd5, 32'hDEADBEEF, 5'd0, 1, 32'h0F, 32'h0A, 1, 1);

    // uimm bit4 is a value bit, not a sign bit; WRITE zero still writes.
    access_csr("CSRRWI uimm=31",3'b101,5'd31,32'hDEADBEEF,5'd5,1,32'h0A,32'h1F,1,1);
    access_csr("CSRRWI uimm=0", 3'b101,5'd0,32'hDEADBEEF,5'd5,1,32'h1F,32'h00,1,1);
    access_csr("CSRRW rs1=x0", 3'b001,5'd0,32'b0,5'd5,1,32'h00,32'h00,1,1);
    access_csr("invalid valid bit",3'b001,5'd2,32'hFFFFFFFF,5'd5,0,32'h00,32'h00,0,0);
    access_csr("non-CSR SYSTEM",3'b000,5'd0,32'b0,5'd0,1,32'h00,32'h00,0,0);

    @(negedge clk);
    valid = 1'b0;
    instr = 32'b0;
    if (errors == 0) begin
      $display("CSR SELF-CHECK PASS (%0d accesses)", cases_run);
      $finish;
    end
    else begin
      $fatal(1, "CSR SELF-CHECK FAIL: %0d errors", errors);
    end
  end

  initial begin
    #10000;
    $fatal(1, "CSR SELF-CHECK TIMEOUT");
  end
endmodule


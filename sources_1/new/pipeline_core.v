`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 20:29:44
// Design Name: 
// Module Name: pipeline_core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pipeline_core#(
  parameter USE_EXTERNAL_PROGRAM = 0
)(
    input wire clk,
    input wire rst_n,

    input wire irq_external_i,
    input wire dev2bus_ready_i,
    input wire[31:0] dev2bus_rdata_i,

    input wire[31:0] external_instr_i,

    output wire bus2dev_req_o,
    output wire bus2dev_we_o,
    output wire[31:0] bus2dev_addr_o,
    output wire[31:0] bus2dev_wdata_o,
    output wire[3:0] bus2dev_wstrb_o,

    output wire [31:0] fetch_addr_o

);

  //fetch_unit

  wire [31:0] pc_o;  //fetch_unit 输出，if_id 输入
  wire [31:0] instr_o;  //fetch_unit 输出，if_id 输入

  //if_id
  wire        valid_ifid_o;  //if_id输出，id_ex输入
  wire [31:0] pc_ifid_o;  //if_id输出，id_ex输入   
  wire [31:0] instr_ifid_o;  //if_id输出，decode输入

  //decode
  wire [31:0] imm_typei_o;  //decode输出，id_ex输入
  wire [31:0] imm_typeb_o;  //decode输出，id_ex输入
  wire [31:0] imm_typej_o;  //decode输出，id_ex输入
  wire [31:0] imm_typeu_o;  //decode输出，id_ex输入
  wire [31:0] imm_types_o;  //decode输出，id_ex输入
  wire [31:0] imm_csr_o;  //decode输出，id_ex输入

  wire [ 4:0] rs1_addr_o;  //decode输出，id_ex，regfile输入
  wire [ 4:0] rs2_addr_o;  //decode输出，id_ex，regfile输入
  wire [11:0] csr_addr_o;  //decode输出，id_ex输入
  wire [ 4:0] rd_addr_o;  //decode输出，id_ex输入

  wire [ 5:0] op_dc_o;  //decode输出，id_ex输入

  wire        is_illegal_o;  //decode输出，id_ex输入


  //id_ex
  wire        valid_idex_i;  //id_ex输入，if_id，decode组合逻辑输出
  wire        valid_idex_o;  //id_ex输出，ex输入
  wire [31:0] pc_idex_o;  //id_ex输出
  wire [31:0] rs1_data_idex_o;  //id_ex输出，ex输入
  wire [31:0] rs2_data_idex_o;  //id_ex输出，ex输入
  wire [31:0] immi_data_idex_o;  //id_ex输出，ex输入
  wire [31:0] immb_data_idex_o;  //id_ex输出，ex输入
  wire [31:0] immj_data_idex_o;  //id_ex输出，ex输入
  wire [31:0] immu_data_idex_o;  //id_ex输出，ex输入
  wire [31:0] imms_data_idex_o;  //id_ex输出，ex输入
  wire [31:0] imm_csr_idex_o;  //id_ex输出，ex输入
  wire [11:0] csr_addr_idex_o;  //id_ex输出，ex输入
  wire [ 4:0] rd_addr_idex_o;  //id_ex输出，ex输入


  wire [ 5:0] op_idex_o;  //id_ex输出，ex输入

  wire        is_illegal_idex_o;  //id_ex输出 ex输入

  //ex
  wire        wr_en_ex_o;  //ex输出，regfile输入
  wire [ 4:0] wr_addr_ex_o;  //ex输出，regfile输入
  wire [31:0] wr_data_ex_o;  //ex输出，regfile输入
  wire        pc_brench_flag_ex_o;  //ex输出，fetch_unit输入
  wire [31:0] pc_brench_addr_ex_o;  //ex输出，fetch_unit输入
  wire        clear_valid_ex_o;  //ex输出，if_id输入,id_ex输入
  wire        stall_ex_o;  //ex输出，fetch_unit输入，if_id输入,id_ex输入


  wire        ram_wr_en_ex_o;  //ex输出，data_ram输入
  wire [31:0] ram_wr_addr_ex_o;  //ex输出，data_ram输入
  wire [31:0] ram_wr_data_ex_o;  //ex输出，data_ram输入
  wire [ 3:0] ram_wr_sel_ex_o;  //ex输出，data_ram输入
  wire        ram_rd_en_ex_o;  //ex输出，data_ram输入
  wire [31:0] ram_rd_addr_ex_o;  //ex输出，data_ram输入

  wire        data_req;  //外部数据请求读写信号
  wire        data_we;  //外部数据读写使能信号
  wire [31:0] data_addr;  //外部数据地址信号


  //regfile
  wire [31:0] rs1_data_o;  //regfile输出，id_ex输入
  wire [31:0] rs2_data_o;  //regfile输出，id_ex输入

  //data_bus
  wire        bus2ram_req_o;//data_bus输出，data_ram输入
  wire        bus2ram_we_o;//data_bus输出，data_ram输入
  wire [31:0] bus2ram_addr_o;//data_bus输出，data_ram输入
  wire [31:0] bus2ram_wdata_o;//data_bus输出，data_ram输入
  wire [ 3:0] bus2ram_wstrb_o;//data_bus输出，data_ram输入
//   wire        bus2dev_req_o;//data_bus输出，dev输入
//   wire        bus2dev_we_o;//data_bus输出，dev输入
//   wire [31:0] bus2dev_addr_o;//data_bus输出，dev输入
//   wire [31:0] bus2dev_wdata_o;//data_bus输出，dev输入
//   wire [ 3:0] bus2dev_wstrb_o;//data_bus输出，dev输入
  wire        bus2cpu_ready_o;//data_bus输出，ex输入
  wire [31:0] bus2cpu_rdata_o;//data_bus输出，ex输入

  //data_ram
  wire [31:0] ram_rd_data_o;  //data_ram输出，data_bus输入
  wire        ram_ready_o;  //data_ram输出，data_bus输入

  //dev
//   wire [31:0] dev_rd_data_o;  //dev输出，data_bus输入
//   wire        dev_ready_o;  //dev输出，data_bus输入



  //旁路，解决数据冒险
  wire [31:0] rs1_data_forward_o;  //id_ex输入
  wire [31:0] rs2_data_forward_o;  //id_ex输入




assign fetch_addr_o = pc_o;

  fetch_unit #(
    .USE_EXTERNAL_INSTR(USE_EXTERNAL_PROGRAM)
  ) fetch_unit_inst
  (
      .clk(clk),
      .rst_n(rst_n),
      .external_instr_i(external_instr_i),
      .pc_brench_flag_i(pc_brench_flag_ex_o),
      .pc_brench_addr_i(pc_brench_addr_ex_o),
      .pc_stall_i(stall_ex_o),
      .pc_o(pc_o),
      .instr_o(instr_o)
  );




  if_id if_id_inst (
      .clk(clk),
      .rst_n(rst_n),
      .valid_i(1'b1),
      .flush_ifid_i(clear_valid_ex_o),
      .stall_ifid_i(stall_ex_o),
      .pc_ifid_i(pc_o),
      .instr_ifid_i(instr_o),
      .valid_o(valid_ifid_o),
      .pc_ifid_o(pc_ifid_o),
      .instr_ifid_o(instr_ifid_o)
  );

  decode decode_inst (
      .instr_i(instr_ifid_o),
      .imm_typei_o(imm_typei_o),
      .imm_typeu_o(imm_typeu_o),
      .imm_typeb_o(imm_typeb_o),
      .imm_typej_o(imm_typej_o),
      .imm_types_o(imm_types_o),
      .imm_csr_o(imm_csr_o),

      .rs1_addr_o(rs1_addr_o),
      .rs2_addr_o(rs2_addr_o),
      .csr_addr_o(csr_addr_o),
      .rd_addr_o (rd_addr_o),

      .op_dc_o(op_dc_o),

      .is_illegal_o(is_illegal_o)
  );

  assign rs1_data_forward_o = (rs1_addr_o == wr_addr_ex_o && wr_en_ex_o && wr_addr_ex_o != 5'h0) ? wr_data_ex_o : rs1_data_o;
  assign rs2_data_forward_o = (rs2_addr_o == wr_addr_ex_o && wr_en_ex_o && wr_addr_ex_o != 5'h0) ? wr_data_ex_o : rs2_data_o;
  assign valid_idex_i = valid_ifid_o;
  id_ex id_ex_inst (
      .clk(clk),
      .rst_n(rst_n),
      .valid_idex_i(valid_idex_i),
      .flush_idex_i(clear_valid_ex_o),
      .stall_idex_i(stall_ex_o),
      .pc_idex_i(pc_ifid_o),
      .rs1_data_idex_i(rs1_data_forward_o),
      .rs2_data_idex_i(rs2_data_forward_o),
      .immi_data_idex_i(imm_typei_o),//先用I立即数进行组合逻辑运算，后面再根据类型选择不同的立即数
      .immb_data_idex_i(imm_typeb_o),
      .immj_data_idex_i(imm_typej_o),
      .immu_data_idex_i(imm_typeu_o),
      .imms_data_idex_i(imm_types_o),
      .imm_csr_idex_i(imm_csr_o),
      .csr_addr_idex_i(csr_addr_o),
      .rd_addr_idex_i(rd_addr_o),

      .op_idex_i(op_dc_o),

      .is_illegal_idex_i(is_illegal_o),

      .valid_idex_o(valid_idex_o),
      .pc_idex_o(pc_idex_o),
      .rs1_data_idex_o(rs1_data_idex_o),
      .rs2_data_idex_o(rs2_data_idex_o),
      .immi_data_idex_o(immi_data_idex_o),
      .immb_data_idex_o(immb_data_idex_o),
      .immj_data_idex_o(immj_data_idex_o),
      .immu_data_idex_o(immu_data_idex_o),
      .imms_data_idex_o(imms_data_idex_o),
      .imm_csr_idex_o(imm_csr_idex_o),
      .csr_addr_idex_o(csr_addr_idex_o),
      .rd_addr_idex_o(rd_addr_idex_o),

      .op_idex_o(op_idex_o),

      .is_illegal_idex_o(is_illegal_idex_o)
  );

  ex ex_inst (
      .clk(clk),
      .rst_n(rst_n),
      .valid_ex_i(valid_idex_o),
      .pc_ex_i(pc_idex_o),

      .op_ex_i(op_idex_o),

      .is_illegal_ex_i(is_illegal_idex_o),

      .irq_external_ex_i(irq_external_i),  //CPU外部输入的中断

      .rs1_data_ex_i(rs1_data_idex_o),
      .rs2_data_ex_i(rs2_data_idex_o),
      .immi_data_ex_i(immi_data_idex_o),
      .immb_data_ex_i(immb_data_idex_o),
      .immj_data_ex_i(immj_data_idex_o),
      .immu_data_ex_i(immu_data_idex_o),
      .imms_data_ex_i(imms_data_idex_o),
      .imm_csr_ex_i(imm_csr_idex_o),
      .csr_addr_ex_i(csr_addr_idex_o),
      .rd_addr_ex_i(rd_addr_idex_o),
      .wr_en_ex_o(wr_en_ex_o),
      .wr_addr_ex_o(wr_addr_ex_o),
      .wr_data_ex_o(wr_data_ex_o),

      .pc_brench_flag_ex_o(pc_brench_flag_ex_o),
      .pc_brench_addr_ex_o(pc_brench_addr_ex_o),

      .clear_valid_ex_o(clear_valid_ex_o),

      .ram_wr_en_ex_o  (ram_wr_en_ex_o),
      .ram_wr_addr_ex_o(ram_wr_addr_ex_o),
      .ram_wr_data_ex_o(ram_wr_data_ex_o),
      .ram_wr_sel_ex_o (ram_wr_sel_ex_o),
      .ram_rd_en_ex_o  (ram_rd_en_ex_o),
      .ram_rd_addr_ex_o(ram_rd_addr_ex_o),
      .ram_rd_data_ex_i(bus2cpu_rdata_o),
      .ram_ready_ex_i  (bus2cpu_ready_o),

      .stall_ex_o(stall_ex_o)
  );

  regfile regfile_inst (
      .clk(clk),
      .rst_n(rst_n),
      .wr_en_i(wr_en_ex_o),
      .wr_addr_i(wr_addr_ex_o),
      .wr_data_i(wr_data_ex_o),
      .rs1_addr_i(rs1_addr_o),
      .rs2_addr_i(rs2_addr_o),
      .rs1_data_o(rs1_data_o),
      .rs2_data_o(rs2_data_o)
  );
  assign data_req  = ram_wr_en_ex_o || ram_rd_en_ex_o;
  assign data_we   = ram_wr_en_ex_o;
  assign data_addr = ram_wr_en_ex_o ? ram_wr_addr_ex_o : ram_rd_addr_ex_o;

  data_bus  data_bus_inst (
    .cpu2bus_req_i(data_req),
    .cpu2bus_we_i(data_we),
    .cpu2bus_addr_i(data_addr),
    .cpu2bus_wdata_i(ram_wr_data_ex_o),
    .cpu2bus_wstrb_i(ram_wr_sel_ex_o),
    .ram2bus_ready_i(ram_ready_o),
    .ram2bus_rdata_i(ram_rd_data_o),
    .dev2bus_ready_i(dev2bus_ready_i),
    .dev2bus_rdata_i(dev2bus_rdata_i),
    .bus2ram_req_o(bus2ram_req_o),
    .bus2ram_we_o(bus2ram_we_o),
    .bus2ram_addr_o(bus2ram_addr_o),
    .bus2ram_wdata_o(bus2ram_wdata_o),
    .bus2ram_wstrb_o(bus2ram_wstrb_o),
    .bus2dev_req_o(bus2dev_req_o),
    .bus2dev_we_o(bus2dev_we_o),
    .bus2dev_addr_o(bus2dev_addr_o),
    .bus2dev_wdata_o(bus2dev_wdata_o),
    .bus2dev_wstrb_o(bus2dev_wstrb_o),
    .bus2cpu_ready_o(bus2cpu_ready_o),
    .bus2cpu_rdata_o(bus2cpu_rdata_o)
  );




  data_ram_target data_ram_target_inst (
      .clk(clk),
      .rst_n(rst_n),
      .req_i(bus2ram_req_o),
      .we_i(bus2ram_we_o),
      .addr_i(bus2ram_addr_o),
      .wdata_i(bus2ram_wdata_o),
      .wstrb_i(bus2ram_wstrb_o),
      .ready_o(ram_ready_o),
      .rdata_o(ram_rd_data_o)
  );



endmodule

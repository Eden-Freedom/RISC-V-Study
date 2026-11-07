`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/30 10:22:43
// Design Name: 
// Module Name: csr_unit
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


module csr_unit (
    input wire        clk,
    input wire        rst_n,
    input wire        csr_wr_en_i,
    input wire        csr_rd_en_i,
    input wire [ 2:0] csr_type_i, //csr_指令类型
    input wire [11:0] csr_wr_addr_i,
    input wire [31:0] csr_src_data_i, //输入的源数据

    input wire trap_enter_i, //进入异常处理
    input wire [31:0]trap_pc_i, //异常指令的地址
    input wire [31:0]trap_cause_i, //异常或中断原因
    input wire trap_return_i, //返回异常处理

    input wire irq_external_i, //外部中断请求
    output wire irq_eligible_o,//表明可以接受外部中断请求

    output wire [31:0] mtvec_o, //处理异常情况程序的入口地址
    output wire [31:0] mepc_o, //异常指令的地址，可由软件调整为返回地址


    input  wire [11:0] csr_rd_addr_i,
    output reg  [31:0] csr_rdata_o
);

  reg     [31:0] mscratch_reg;//保存临时数据
  reg     [31:0] mstatus_reg;//保存状态寄存器
  reg     [31:0] mtvec_reg;//保存处理异常情况程序的地址
  reg     [31:0] mepc_reg;//保存异常指令的地址，可由软件调整为返回地址
  reg     [31:0] mcause_reg;//保存异常或中断原因
  reg     [31:0] mie_reg;//保存中断使能寄存器
  reg [63:0] cycle_count;

  always @(posedge clk) begin
    if (!rst_n) begin
      cycle_count <= 64'd0;
    end
    else begin
      cycle_count <= cycle_count + 64'd1;
    end
  end
  reg [31:0] csr_sw_old;
  reg [31:0] csr_sw_new;
 reg csr_sw_op_valid;

//由于中断请求不一定会立马执行，但是中断请求一直在，
 //一直接受外部的中断请求，所以需要一个寄存器来保存中断请求，当有中断请求时，将中断请求寄存器中的值设置为1
 wire [31:0] mip_value; 
 
 assign mip_value = {20'b0, irq_external_i, 11'b0};


//按写地址选取旧值
 always@(*)begin
  csr_sw_old = 32'b0;

  case(csr_wr_addr_i)
    12'h300: csr_sw_old = mstatus_reg;
    12'h304: csr_sw_old = mie_reg;
    12'h340: csr_sw_old = mscratch_reg;
    12'h305: csr_sw_old = mtvec_reg;
    12'h341: csr_sw_old = mepc_reg;
    12'h342: csr_sw_old = mcause_reg;
    default: csr_sw_old = 32'b0;
  endcase
 
 end

 //根据操作计算新值
 always@(*)begin
  csr_sw_new =  csr_sw_old;
  csr_sw_op_valid = 1'b1;

  case(csr_type_i)
    3'b001, 3'b101: begin
      csr_sw_new = csr_src_data_i;
    end
    3'b010, 3'b110: begin
      csr_sw_new = csr_sw_old | csr_src_data_i;
    end
    3'b011, 3'b111: begin
      csr_sw_new = csr_sw_old & ~csr_src_data_i;
    end
    default: begin
      csr_sw_op_valid = 1'b0;
    end
  endcase
 end


 //写入路径

  always @(posedge clk) begin
    if (!rst_n) begin
        mscratch_reg <= 32'h00000000;
        mie_reg <= 32'h00000000;
        mstatus_reg  <= 32'h00001800;
        mtvec_reg    <= 32'h00000000;
        mepc_reg     <= 32'h00000000;
        mcause_reg   <= 32'h00000000;
    end
    else if (trap_enter_i) begin
        mepc_reg   <= {trap_pc_i[31:2], 2'b00};
        mcause_reg <= trap_cause_i;

        // MPIE 保存进入前的 MIE
        mstatus_reg[7] <= mstatus_reg[3];

        // 把 MIE，也就是 mstatus_reg[3]，清零
        mstatus_reg[3] <= 1'b0;
    end
    else if (trap_return_i) begin
        // MIE 从 MPIE 恢复
        // 目标是 mstatus_reg[3]，来源是 mstatus_reg[7]
        mstatus_reg[3] <= mstatus_reg[7];

        // MPIE 置为 1
        // 目标是 mstatus_reg[7]，来源是常量 1'b1
        mstatus_reg[7] <= 1'b1;
    end
    else if(csr_wr_en_i && csr_sw_op_valid) begin
      case(csr_wr_addr_i)
        12'h300: mstatus_reg <= (csr_sw_new & 32'h0000_0088) | 32'h0000_1800;
        12'h304: mie_reg <= csr_sw_new & 32'h0000_0800;
        12'h340: mscratch_reg <= csr_sw_new;
        12'h305: mtvec_reg <= {csr_sw_new[31:2], 2'b00};
        12'h341: mepc_reg <= {csr_sw_new[31:2], 2'b00};
        12'h342: mcause_reg <= csr_sw_new;
        default: begin
          mstatus_reg <= mstatus_reg;
          mscratch_reg <= mscratch_reg;
          mtvec_reg <= mtvec_reg;
          mepc_reg <= mepc_reg;
          mcause_reg <= mcause_reg;
        end
      endcase
    end
end


//读出路径

always@(*)begin
  csr_rdata_o = 32'b0;

  if(csr_rd_en_i)begin
    case(csr_rd_addr_i)
      12'h300: csr_rdata_o = mstatus_reg;
      12'h304: csr_rdata_o = mie_reg;
      12'h340: csr_rdata_o = mscratch_reg;
      12'h305: csr_rdata_o = mtvec_reg;
      12'h341: csr_rdata_o = mepc_reg;
      12'h342: csr_rdata_o = mcause_reg;
      12'h344: csr_rdata_o = mip_value;
      12'hC00: csr_rdata_o = cycle_count[31:0];
      12'hC80: csr_rdata_o = cycle_count[63:32];
    endcase
  end
end

assign mtvec_o = mtvec_reg;
assign mepc_o = mepc_reg;
assign irq_eligible_o = irq_external_i & mie_reg[11] & mstatus_reg[3];


endmodule

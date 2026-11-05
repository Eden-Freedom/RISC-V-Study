`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/03 19:14:54
// Design Name: 
// Module Name: data_bus
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


module data_bus (
    //cpu输入
    input wire        cpu2bus_req_i,    //cpu输入请求
    input wire        cpu2bus_we_i,     //cpu输入写使能
    input wire [31:0] cpu2bus_addr_i,   //cpu输入地址
    input wire [31:0] cpu2bus_wdata_i,  //cpu输入写数据
    input wire [ 3:0] cpu2bus_wstrb_i,  //cpu输入写选通
    //ram输入
    input wire        ram2bus_ready_i,  //ram输入ready信号
    input wire [31:0] ram2bus_rdata_i,  //ram输入读数据
    //dev输入
    input wire        dev2bus_ready_i,  //dev输入ready信号
    input wire [31:0] dev2bus_rdata_i,  //dev输入读数据
    //bus2ram输出
    output wire         bus2ram_req_o,    //bus输出的请求（目前是给RAM的请求）
    output wire        bus2ram_we_o,     //bus输出的写使能（目前是给RAM的写使能）
    output wire [31:0] bus2ram_addr_o,   //bus输出的地址（目前是给RAM的地址）
    output wire [31:0] bus2ram_wdata_o,  //bus输出的写数据（目前是给RAM的写数据）
    output wire [ 3:0] bus2ram_wstrb_o,  //bus输出的写选通（目前是给RAM的写选通）
    //bus2dev输出
    output wire         bus2dev_req_o,
    output wire        bus2dev_we_o,
    output wire [31:0] bus2dev_addr_o,
    output wire [31:0] bus2dev_wdata_o,
    output wire [ 3:0] bus2dev_wstrb_o,
    //bus2cpu输出
    output reg        bus2cpu_ready_o,  //bus输出的ready信号（目前是给CPU的ready信号）
    output reg [31:0] bus2cpu_rdata_o   //bus输出的读数据（目前是给CPU的读数据）
);


  wire ram_hit;
  assign ram_hit     = (cpu2bus_addr_i[31:7] == 25'd0);  //先检查是否发生到RAM地址

  wire dev_hit;
  assign dev_hit = (cpu2bus_addr_i >= 32'h1000_0000
                    && cpu2bus_addr_i <= 32'h1000_001F);

  assign bus2ram_req_o   = cpu2bus_req_i && ram_hit;
  assign bus2ram_we_o    = cpu2bus_we_i;
  assign bus2ram_addr_o  = cpu2bus_addr_i;
  assign bus2ram_wdata_o = cpu2bus_wdata_i;
  assign bus2ram_wstrb_o = cpu2bus_wstrb_i;

  assign bus2dev_req_o   = cpu2bus_req_i && dev_hit;
  assign bus2dev_we_o = cpu2bus_we_i;
  assign bus2dev_addr_o = cpu2bus_addr_i;
  assign bus2dev_wdata_o = cpu2bus_wdata_i;
  assign bus2dev_wstrb_o = cpu2bus_wstrb_i;


  always @(*) begin
    bus2cpu_ready_o = 1'b0;
    bus2cpu_rdata_o = 32'd0;
    if (bus2ram_req_o) begin
      bus2cpu_ready_o = ram2bus_ready_i;
      if (!cpu2bus_we_i && ram2bus_ready_i) begin
        bus2cpu_rdata_o = ram2bus_rdata_i;
      end
    end
    else if(bus2dev_req_o)begin
        bus2cpu_ready_o = dev2bus_ready_i;
        if(!cpu2bus_we_i && dev2bus_ready_i)begin
            bus2cpu_rdata_o = dev2bus_rdata_i;
        end
        end
    else if (cpu2bus_req_i && !ram_hit && !dev_hit) begin
      bus2cpu_ready_o = 1'b1;
    end
  end

endmodule

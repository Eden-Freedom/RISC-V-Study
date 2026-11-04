`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/04 15:17:35
// Design Name: 
// Module Name: gpio_target
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


module gpio_target(
    input wire clk,
    input wire rst_n,
    input wire req_i,
    input wire we_i,
    input wire [31:0] addr_i,
    input wire [31:0] wdata_i,
    input wire [3:0] wstrb_i,
    output wire ready_o,
    output wire [31:0] rdata_o,
    output wire [7:0] gpio_out_o

    );

    reg [7:0] gpio_out_reg;
    wire out_hit;
    wire req_done;

    assign ready_o = req_i;
    assign gpio_out_o = gpio_out_reg;
    assign req_done = req_i && ready_o;//请求完成
    //GPIO中也有很多寄存器，通过地址的【3：2】来判断给哪个寄存器赋值
    //地址的低两位【1：0】是用来选择选中的寄存器的高位还是低位赋值，但是在ex模块中就已经解析执行成wstrb了
    assign out_hit = (addr_i[3:2] == 2'b00);


    always@(posedge clk)begin
        if(!rst_n)begin
            gpio_out_reg <= 8'b0;
        end
        else if(req_done && we_i && (wstrb_i[0] == 1'b1) && out_hit)begin
            gpio_out_reg <= wdata_i[7:0];
        end
    end

    assign rdata_o = (req_done && !we_i && out_hit) ? {24'b0, gpio_out_o} : 32'b0;

endmodule

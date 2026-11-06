`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 10:15:17
// Design Name: 
// Module Name: spi_master
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


module spi_master(
    input wire clk,
    input wire rst_n,
    input wire start_i,
    input wire miso_i,
    input wire [7:0] tx_data_i,//cpu发送来的数据

    output reg cs_n_o,//片选信号
    output reg sclk_o,//时钟信号
    output reg mosi_o,//主输出从输入信号
    output wire busy_o,//忙信号
    output reg done_o,//完成信号
    output reg [7:0] rx_data_o//CPU需要接收到的数据
    );

    localparam IDLE = 2'b00;
    localparam HIGH = 2'b01;
    localparam LOW = 2'b10;
    localparam FINISH = 2'b11;

    reg [1:0] state, nstate;
    reg [2:0] bit_index;
    reg half_count; //分频计数器，sclk_o 时钟周期为 clk 的4倍
    reg [7:0] rx_work; //逐位保存从机发来的数据
    reg [7:0] tx_byte; //启动时锁存发送字节，供 MOSI 逐位读取

    wire accept_start; //当前这个系统时钟沿可以接收启动请求
    wire half_tick; //当前这个系统时钟沿到达半周期末尾

    assign accept_start = (state == IDLE) && start_i;
    //只有当前空闲且有启动请求，才接受新的交换。

    assign half_tick = (state != IDLE) && (half_count == 1'b1);
    //活动状态下，沿前计数为 1，表示这个沿正好结束一个半周期。

    always @(posedge clk) begin
        if(!rst_n) begin
            half_count <= 1'b0;
        end
        else if (state == IDLE || half_tick) begin
            half_count <= 1'b0;
            //空闲时保持零，到点时清零以便下一段重新数
        end
            else begin
            half_count <= 1'b1;
        end
    end

    always @(posedge clk ) begin
        if(!rst_n)begin
            bit_index <= 3'd0;
        end
        else if (accept_start) begin
            bit_index <= 3'd7;
        end
        else if (state == HIGH && half_tick && bit_index != 3'd0) begin
            //state == HIGH 只表示当前正处在高电平阶段,如果此时half_tick则说明
            //要由高电平转为低电平了，即下降沿，准备下一位
            bit_index <= bit_index - 3'd1;
        end
        //其他沿保持位编号，最后一位也保持为 0。
    end
    

    always @(posedge clk ) begin
        if(!rst_n)begin
            state <= IDLE;
        end
        else begin
            state <= nstate;
        end
    end


    always @(*) begin
        nstate = state;
        case(state)
        IDLE: begin
            if(accept_start) begin
                nstate = LOW;
            end
            else begin
                nstate = IDLE;
            end
        end
        LOW: begin
            if(half_tick) begin
                nstate = HIGH;
            end
            else
                nstate = LOW;
        end
        HIGH: begin
            if(half_tick) begin
                if(bit_index == 3'd0)begin
                    nstate = FINISH;
                end
                else begin
                    nstate = LOW;
                end
            end
            else
                nstate = HIGH;
        end
        FINISH: begin
            if (half_tick) begin
                nstate = IDLE;
            end
            else
                nstate = FINISH;
        end
        default: begin
            nstate = IDLE;
        end
        endcase
    end

    assign busy_o = (state != IDLE); //LOW、HIGH、FINISH 都属于忙状态

    always @(*) begin
        if (state == IDLE) begin
            mosi_o = 1'b0;
        end
        else begin
            mosi_o = tx_byte[bit_index];
        end
    end

    always @(posedge clk) begin
        if(!rst_n)begin
            cs_n_o <= 1'b1;
            sclk_o <= 1'b0;
            done_o <= 1'b0;
            tx_byte <= 8'd0;
            rx_work <= 8'd0;
            rx_data_o <= 8'd0;
        end
        else begin
            done_o <= 1'b0;
            if (accept_start) begin
                tx_byte <= tx_data_i;
                cs_n_o <= 1'b0;
            end
            else if (state == LOW && half_tick) begin
                sclk_o <= 1'b1;
                //state == LOW 只表示当前正处在低电平阶段,如果此时half_tick则说明
                //要由低电平转为高电平了，即上升沿
                rx_work[bit_index] <= miso_i;
            end
            else if (state == HIGH && half_tick) begin
                sclk_o <= 1'b0;
            end
            else if (state == FINISH && half_tick) begin
                cs_n_o <= 1'b1;
                rx_data_o <= rx_work;
                done_o <= 1'b1;
            end
        end
    end
endmodule

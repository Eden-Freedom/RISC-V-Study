`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 11:12:18
// Design Name: 
// Module Name: tb_spi_master
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


module tb_spi_master;
    localparam [7:0] TX_BYTE = 8'h96;
    localparam [7:0] RX_BYTE = 8'h3C;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg start_i = 1'b0;
    reg miso_i = RX_BYTE[7];
    wire cs_n_o;
    wire sclk_o;
    wire mosi_o;
    wire busy_o;
    wire done_o;
    wire [7:0] rx_data_o;

    integer rise_count = 0;

    spi_master dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_i(start_i),
        .miso_i(miso_i),
        .tx_data_i(TX_BYTE),
        .cs_n_o(cs_n_o),
        .sclk_o(sclk_o),
        .mosi_o(mosi_o),
        .busy_o(busy_o),
        .done_o(done_o),
        .rx_data_o(rx_data_o)
    );

    always #5 clk = ~clk;

    // 从机在 SCLK 上升沿读取 MOSI。rise_count 是此前已采样的位数。
    always @(posedge sclk_o) begin
        if (rst_n) begin
            if (cs_n_o !== 1'b0 || busy_o !== 1'b1) begin
                $fatal(1, "SCLK rose while SPI was inactive at %0t", $time);
            end
            if (rise_count >= 8) begin
                $fatal(1, "Unexpected ninth SCLK rising edge at %0t", $time);
            end
            if (mosi_o !== TX_BYTE[7 - rise_count]) begin
                $fatal(1, "MOSI bit %0d: expected %b, got %b",
                       7 - rise_count, TX_BYTE[7 - rise_count], mosi_o);
            end
            rise_count = rise_count + 1;
        end
    end

    // 第一位在启动前已放到 MISO。之后的下降沿准备下一位。
    always @(negedge sclk_o) begin
        if (rst_n && cs_n_o === 1'b0 && rise_count > 0 && rise_count < 8) begin
            miso_i = RX_BYTE[7 - rise_count];
        end
    end

    initial begin
        repeat (2) @(negedge clk);
        if ({cs_n_o, sclk_o, busy_o, done_o} !== 4'b1000) begin
            $fatal(1, "SPI outputs are not idle after reset");
        end
        rst_n = 1'b1;

        @(negedge clk);
        start_i = 1'b1;
        @(negedge clk);
        start_i = 1'b0;

        wait (done_o === 1'b1);
        #1;
        if (rise_count != 8 || rx_data_o !== RX_BYTE) begin
            $fatal(1, "Expected 8 SCLK rising edges and RX=%h, got %0d and RX=%h",
                   RX_BYTE, rise_count, rx_data_o);
        end
        if ({cs_n_o, sclk_o, busy_o} !== 3'b100) begin
            $fatal(1, "SPI did not return to idle at completion");
        end
        @(negedge clk);
        if (done_o !== 1'b1) begin
            $fatal(1, "done_o deasserted before the end of its clock cycle");
        end
        @(posedge clk);
        #1;
        if (done_o !== 1'b0 || rx_data_o !== RX_BYTE) begin
            $fatal(1, "Expected one-cycle done_o and stable RX data");
        end

        $display("PASS: SPI master byte checks passed");
        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "SPI master test timed out after %0d SCLK rising edges", rise_count);
    end
endmodule

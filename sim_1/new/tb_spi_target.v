`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 11:36:33
// Design Name: 
// Module Name: tb_spi_target
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


module tb_spi_target;
    localparam [31:0] XFER   = 32'h0;
    localparam [31:0] STATUS = 32'h4;
    localparam [31:0] RXDATA = 32'h8;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg req_i = 1'b0;
    reg we_i = 1'b0;
    reg miso_i = 1'b0;
    reg [31:0] addr_i = 32'd0;
    reg [31:0] wdata_i = 32'd0;
    reg [3:0] wstrb_i = 4'd0;
    wire ready_o, cs_n_o, sclk_o, mosi_o;
    wire [31:0] rdata_o;

    integer frame_count = 0;
    integer rise_count = 0;
    integer start_count = 0;
    reg [7:0] expected_tx, reply_byte;

    spi_target dut (
        .clk(clk),
        .rst_n(rst_n),
        .req_i(req_i),
        .we_i(we_i),
        .miso_i(miso_i),
        .addr_i(addr_i),
        .wdata_i(wdata_i),
        .wstrb_i(wstrb_i),
        .ready_o(ready_o),
        .cs_n_o(cs_n_o),
        .sclk_o(sclk_o),
        .mosi_o(mosi_o),
        .rdata_o(rdata_o)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n && dut.spi_start === 1'b1) begin
            start_count = start_count + 1;
        end
    end

    // 片选拉低后，外设先把 bit7 放在 MISO 上。
    always @(negedge cs_n_o) begin
        if (rst_n) begin
            case (frame_count)
                0: begin expected_tx = 8'h96; reply_byte = 8'h3C; end
                1: begin expected_tx = 8'hA6; reply_byte = 8'h5A; end
                2: begin expected_tx = 8'h69; reply_byte = 8'hC3; end
                default: $fatal(1, "Unexpected SPI frame at %0t", $time);
            endcase
            rise_count = 0;
            miso_i = reply_byte[7];
        end
    end

    always @(posedge sclk_o) begin
        if (rst_n) begin
            if (cs_n_o !== 1'b0 || rise_count >= 8) begin
                $fatal(1, "Unexpected SCLK rising edge in frame %0d at %0t",
                       frame_count, $time);
            end
            if (mosi_o !== expected_tx[7 - rise_count]) begin
                $fatal(1, "Frame %0d MOSI bit %0d expected %b, got %b",
                       frame_count, 7 - rise_count, expected_tx[7 - rise_count], mosi_o);
            end
            rise_count = rise_count + 1;
        end
    end

    // 当前位已采样，下降沿换到下一位。
    always @(negedge sclk_o) begin
        if (rst_n && cs_n_o === 1'b0 && rise_count > 0 && rise_count < 8) begin
            miso_i = reply_byte[7 - rise_count];
        end
    end

    always @(posedge cs_n_o) begin
        if (rst_n) begin
            if (rise_count != 8 || sclk_o !== 1'b0) begin
                $fatal(1, "Frame %0d ended with %0d sampled bits and SCLK=%b",
                       frame_count, rise_count, sclk_o);
            end
            frame_count = frame_count + 1;
        end
    end

    task check_read;
        input [31:0] address;
        input [31:0] expected;
        begin
            @(negedge clk);
            req_i = 1'b1;
            we_i = 1'b0;
            addr_i = address;
            @(posedge clk);
            if (ready_o !== 1'b1 || rdata_o !== expected) begin
                $fatal(1, "Read %h expected ready=1 data=%h, got ready=%b data=%h",
                       address, expected, ready_o, rdata_o);
            end
            @(negedge clk);
            req_i = 1'b0;
        end
    endtask

    task drive_xfer;
        input [7:0] value;
        input [3:0] mask;
        begin
            @(negedge clk);
            req_i = 1'b1;
            we_i = 1'b1;
            addr_i = XFER;
            wdata_i = {24'd0, value};
            wstrb_i = mask;
        end
    endtask

    task check_immediate_write;
        input [7:0] value;
        input [3:0] mask;
        begin
            drive_xfer(value, mask);
            @(posedge clk);
            if (ready_o !== 1'b1 || dut.spi_start !== mask[0]) begin
                $fatal(1, "XFER %h mask %b: ready=%b start=%b",
                       value, mask, ready_o, dut.spi_start);
            end
            @(negedge clk);
            req_i = 1'b0;
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        check_read(STATUS, 32'd0);

        check_immediate_write(8'h96, 4'b0001);
        check_read(STATUS, 32'd1);
        check_immediate_write(8'hFF, 4'b0010);
        wait (dut.done_pending === 1'b1);
        check_read(STATUS, 32'd2);
        check_read(RXDATA, 32'h3C);
        check_read(STATUS, 32'd2);

        check_immediate_write(8'hA6, 4'b0001);
        check_read(STATUS, 32'd1);
        drive_xfer(8'h69, 4'b0001);
        if (dut.spi_busy !== 1'b1) begin
            $fatal(1, "A6 must still be busy when the 69 write arrives");
        end

        // 请求及负载保持到握手。包括 A6 完成的 B 沿，沿前都应仍在等待。
        while (dut.spi_busy === 1'b1) begin
            @(posedge clk);
            if ({ready_o, dut.spi_start} !== 2'b00) begin
                $fatal(1, "The 69 write completed while A6 was still busy");
            end
            #1;
        end

        // B 沿后总线已就绪，上一笔的完成脉冲仍有效。
        if ({dut.spi_busy, dut.spi_done, ready_o} !== 3'b011 ||
            dut.spi_rx_data !== 8'h5A) begin
            $fatal(1, "A6 completion did not publish 5A and release the waiting write");
        end

        // B+1 沿前，新启动与上一笔完成同时有效。
        @(posedge clk);
        if ({req_i, ready_o, dut.spi_start, dut.spi_done} !== 4'b1111) begin
            $fatal(1, "Expected the 69 write handshake and A6 done on the same edge");
        end
        #1;
        if ({dut.done_pending, dut.spi_busy, cs_n_o} !== 3'b010) begin
            $fatal(1, "The 69 start must take priority over the old done pulse");
        end
        @(negedge clk);
        req_i = 1'b0;

        wait (dut.done_pending === 1'b1);
        check_read(STATUS, 32'd2);
        check_read(RXDATA, 32'hC3);
        if (start_count != 3 || frame_count != 3) begin
            $fatal(1, "Expected three starts and frames, got %0d starts and %0d frames",
                   start_count, frame_count);
        end

        $display("PASS: SPI target checks passed");
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "SPI target test timed out after %0d frames", frame_count);
    end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 11:46:37
// Design Name: 
// Module Name: tb_spi_system
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


module tb_spi_system;
    localparam [31:0] XFER   = 32'h1000_0030;
    localparam [31:0] STATUS = 32'h1000_0034;
    localparam [31:0] RXDATA = 32'h1000_0038;
    localparam [31:0] GPIO   = 32'h1000_0000;
    localparam [31:0] SECOND_SB_PC = 32'h14;
    localparam [31:0] DONE_PC      = 32'h2C;

    localparam [2:0] FIRST_WRITE = 3'd0, FIRST_STATUS = 3'd1,
                     SECOND_WRITE = 3'd2, POLL_STATUS = 3'd3,
                     READ_REPLY = 3'd4, WRITE_GPIO = 3'd5, PROGRAM_END = 3'd6;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg spi_miso_i = 1'b0;
    wire [7:0] gpio_out_o;
    wire spi_cs_n_o, spi_sclk_o, spi_mosi_o;

    reg [2:0] step = FIRST_WRITE;
    reg waiting_second = 1'b0;
    integer frame_count = 0;
    integer rise_count = 0;
    reg [7:0] expected_tx, reply_byte;

    soc_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .irq_external_i(1'b0),
        .uart_rx_i(1'b1),
        .spi_miso_i(spi_miso_i),
        .gpio_out_o(gpio_out_o),
        .uart_tx_o(),
        .spi_mosi_o(spi_mosi_o),
        .spi_sclk_o(spi_sclk_o),
        .spi_cs_n_o(spi_cs_n_o)
    );

    wire ex_valid = dut.pipeline_core_inst.valid_idex_o;
    wire [31:0] ex_pc = dut.pipeline_core_inst.pc_idex_o;
    wire ex_stall = dut.pipeline_core_inst.stall_ex_o;
    wire spi_start = dut.spi_target_inst.spi_start;
    wire spi_busy = dut.spi_target_inst.spi_busy;
    wire spi_done = dut.spi_target_inst.spi_done;

    always #5 clk = ~clk;

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
    end

    // TB 只驱动顶层 MISO。总线访问全部来自 CPU 执行 instruction_rom 中的程序。
    always @(negedge spi_cs_n_o) begin
        if (rst_n) begin
            case (frame_count)
                0: begin expected_tx = 8'h96; reply_byte = 8'h3C; end
                1: begin expected_tx = 8'hA6; reply_byte = 8'h5A; end
                default: $fatal(1, "Unexpected SPI frame at %0t", $time);
            endcase
            rise_count = 0;
            spi_miso_i = reply_byte[7];
        end
    end

    always @(posedge spi_sclk_o) begin
        if (rst_n) begin
            if (spi_cs_n_o !== 1'b0 || rise_count >= 8) begin
                $fatal(1, "Unexpected SCLK rising edge in frame %0d", frame_count);
            end
            if (spi_mosi_o !== expected_tx[7 - rise_count]) begin
                $fatal(1, "Frame %0d MOSI bit %0d expected %b, got %b",
                       frame_count, 7 - rise_count, expected_tx[7 - rise_count], spi_mosi_o);
            end
            rise_count = rise_count + 1;
        end
    end

    always @(negedge spi_sclk_o) begin
        if (rst_n && spi_cs_n_o === 1'b0 && rise_count > 0 && rise_count < 8) begin
            spi_miso_i = reply_byte[7 - rise_count];
        end
    end

    always @(posedge spi_cs_n_o) begin
        if (rst_n) begin
            if (rise_count != 8 || spi_sclk_o !== 1'b0) begin
                $fatal(1, "Frame %0d ended with %0d sampled bits and SCLK=%b",
                       frame_count, rise_count, spi_sclk_o);
            end
            frame_count = frame_count + 1;
        end
    end

    task expect_spi_access;
        input [31:0] address;
        input is_write;
        begin
            if ({dut.spi_req, dut.gpio_req, dut.timer_req, dut.uart_tx_req,
                 dut.bus2dev_we_o, dut.bus2dev_addr_o} !==
                {4'b1000, is_write, address}) begin
                $fatal(1, "Step %0d expected exclusive SPI access to %h, got %h",
                       step, address, dut.bus2dev_addr_o);
            end
        end
    endtask

    task expect_spi_read;
        input [31:0] address;
        begin
            expect_spi_access(address, 1'b0);
            if ({dut.dev_ready_o, ex_stall, spi_start} !== 3'b100) begin
                $fatal(1, "Step %0d SPI read must complete without starting a transfer", step);
            end
        end
    endtask

    task expect_xfer_payload;
        input [7:0] value;
        begin
            expect_spi_access(XFER, 1'b1);
            if ({dut.bus2dev_wstrb_o, dut.bus2dev_wdata_o} !== {4'b0001, 24'd0, value}) begin
                $fatal(1, "XFER expected byte %h, got data=%h mask=%b",
                       value, dut.bus2dev_wdata_o, dut.bus2dev_wstrb_o);
            end
        end
    endtask

    // 沿前检查实际完成的总线访问，沿后检查寄存器和 GPIO。
    always @(posedge clk) begin
        if (rst_n) begin
            if (waiting_second && dut.bus2dev_req_o !== 1'b1) begin
                $fatal(1, "CPU dropped its waiting A6 request");
            end

            if (dut.bus2dev_req_o === 1'b1) begin
                case (step)
                    FIRST_WRITE: begin
                        expect_xfer_payload(8'h96);
                        if ({dut.dev_ready_o, ex_stall, spi_start} !== 3'b101) begin
                            $fatal(1, "The first XFER write did not start 96");
                        end
                        step = FIRST_STATUS;
                    end
                    FIRST_STATUS: begin
                        expect_spi_read(STATUS);
                        if (dut.dev_rdata_o !== 32'd1) begin
                            $fatal(1, "First STATUS expected 1, got %h", dut.dev_rdata_o);
                        end
                        step = SECOND_WRITE;
                    end
                    SECOND_WRITE: begin
                        expect_xfer_payload(8'hA6);
                        if (ex_valid !== 1'b1 || ex_pc !== SECOND_SB_PC) begin
                            $fatal(1, "CPU did not hold the A6 store in EX");
                        end
                        if (spi_busy === 1'b1) begin
                            if ({dut.dev_ready_o, ex_stall, spi_start} !== 3'b010) begin
                                $fatal(1, "A6 must stall without starting while 96 is busy");
                            end
                            waiting_second = 1'b1;
                        end else begin
                            if (!waiting_second ||
                                {spi_busy, dut.dev_ready_o, ex_stall, spi_start, spi_done} !== 5'b01011 ||
                                dut.spi_target_inst.spi_rx_data !== 8'h3C) begin
                                $fatal(1, "Expected A6 handoff immediately after 96 completed with reply 3C");
                            end
                            waiting_second = 1'b0;
                            step = POLL_STATUS;
                            #1;
                            if ({spi_busy, dut.spi_target_inst.done_pending} !== 2'b10) begin
                                $fatal(1, "A6 start did not clear the first transfer's completion");
                            end
                        end
                    end
                    POLL_STATUS: begin
                        expect_spi_read(STATUS);
                        case (dut.dev_rdata_o)
                            32'd0, 32'd1: begin end
                            32'd2: step = READ_REPLY;
                            default: $fatal(1, "Unexpected polling STATUS %h", dut.dev_rdata_o);
                        endcase
                    end
                    READ_REPLY: begin
                        expect_spi_read(RXDATA);
                        if (dut.dev_rdata_o !== 32'h5A) begin
                            $fatal(1, "RXDATA expected 5A, got %h", dut.dev_rdata_o);
                        end
                        step = WRITE_GPIO;
                    end
                    WRITE_GPIO: begin
                        if ({dut.spi_req, dut.gpio_req, dut.timer_req, dut.uart_tx_req,
                             dut.dev_ready_o, dut.bus2dev_we_o, dut.bus2dev_addr_o,
                             dut.bus2dev_wstrb_o, dut.bus2dev_wdata_o[7:0]} !==
                            {4'b0100, 2'b11, GPIO, 4'b0001, 8'h5A}) begin
                            $fatal(1, "Expected CPU to write reply 5A to GPIO");
                        end
                        step = PROGRAM_END;
                    end
                    default: $fatal(1, "Unexpected peripheral request after the GPIO write");
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n && ex_valid === 1'b1 && ex_pc === DONE_PC && ex_stall === 1'b0) begin
            #1;
            if (step !== PROGRAM_END || frame_count != 2 ||
                {spi_cs_n_o, spi_sclk_o, spi_busy} !== 3'b100 ||
                gpio_out_o !== 8'h5A ||
                dut.pipeline_core_inst.register_file_inst.reg_file[4] !== 32'd1 ||
                dut.pipeline_core_inst.register_file_inst.reg_file[7] !== 32'h5A) begin
                $fatal(1, "Unexpected final state: step=%0d frames=%0d GPIO=%h x4=%h x7=%h",
                       step, frame_count, gpio_out_o,
                       dut.pipeline_core_inst.register_file_inst.reg_file[4],
                       dut.pipeline_core_inst.register_file_inst.reg_file[7]);
            end
            $display("PASS: SPI system checks passed");
            $finish;
        end
    end

    initial begin
        #5000;
        $fatal(1, "SPI system test timed out at step %0d, PC=%h", step, ex_pc);
    end
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 21:12:25
// Design Name: 
// Module Name: tb_uart_rx_system
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


module tb_uart_rx_system;
    localparam integer CLKS_PER_BIT = 4;
    localparam [31:0] GPIO = 32'h1000_0000;
    localparam [31:0] STATUS = 32'h1000_0024;
    localparam [31:0] RXDATA = 32'h1000_0028;
    localparam [7:0] RX_BYTE = 8'h96;
    localparam [31:0] RX_WORD = {24'd0, RX_BYTE};

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg uart_rx_i = 1'b1;
    wire [7:0] gpio_out_o;
    wire uart_tx_o;
    reg saw_empty_poll = 1'b0;
    integer step = 0;
    integer bit_index;

    always #5 clk = ~clk;

    // The CPU drives the bus. soc_top routes UART accesses to uart_tx_target_inst.
    soc_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .irq_external_i(1'b0),
        .uart_rx_i(uart_rx_i),
        .gpio_out_o(gpio_out_o),
        .uart_tx_o(uart_tx_o)
    );

    task drive_bit;
        input value;
        begin
            @(negedge clk);
            uart_rx_i = value;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task expect_uart_read;
        input [31:0] address;
        input [31:0] value;
        input pop;
        begin
            if ({dut.uart_tx_req, dut.gpio_req, dut.timer_req, dut.bus2dev_we_o,
                 dut.bus2dev_addr_o, dut.dev_rdata_o, dut.uart_tx_target_inst.rx_pop} !==
                {1'b1, 1'b0, 1'b0, 1'b0, address, value, pop}) begin
                $fatal(1, "step %0d: expected UART read %h -> %h pop=%b, got addr=%h data=%h pop=%b",
                       step, address, value, pop, dut.bus2dev_addr_o,
                       dut.dev_rdata_o, dut.uart_tx_target_inst.rx_pop);
            end
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        wait (saw_empty_poll);
        drive_bit(1'b0);
        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
            drive_bit(RX_BYTE[bit_index]);
        end
        drive_bit(1'b1);
    end

    always @(posedge clk) begin
        if (rst_n) begin
            if (uart_tx_o !== 1'b1) begin
                $fatal(1, "UART TX must stay idle during the receive program");
            end

            if (dut.bus2dev_req_o) begin
                if (dut.dev_ready_o !== 1'b1) begin
                    $fatal(1, "step %0d: peripheral request did not complete", step);
                end
                case (step)
                    0: begin
                        if (dut.dev_rdata_o === 32'd0) begin
                            expect_uart_read(STATUS, 32'd0, 1'b0);
                            saw_empty_poll = 1'b1;
                        end else begin
                            expect_uart_read(STATUS, 32'd2, 1'b0);
                            if (!saw_empty_poll) $fatal(1, "missing empty STATUS poll");
                            step = 1;
                        end
                    end
                    1: begin
                        expect_uart_read(RXDATA, RX_WORD, 1'b1);
                        step = 2;
                    end
                    2: begin
                        if ({dut.uart_tx_req, dut.gpio_req, dut.timer_req,
                             dut.bus2dev_we_o, dut.bus2dev_addr_o,
                             dut.bus2dev_wstrb_o, dut.bus2dev_wdata_o[7:0]} !==
                            {1'b0, 1'b1, 1'b0, 1'b1, GPIO, 4'b0001, RX_BYTE}) begin
                            $fatal(1, "expected CPU to store byte %h to GPIO", RX_BYTE);
                        end
                        step = 3;
                    end
                    3: begin
                        expect_uart_read(STATUS, 32'd0, 1'b0);
                        step = 4;
                    end
                    4: begin
                        expect_uart_read(RXDATA, 32'd0, 1'b0);
                        step = 5;
                    end
                    default: $fatal(1, "unexpected peripheral request after final RXDATA read");
                endcase
            end

            if (dut.pipeline_core_inst.valid_idex_o === 1'b1 &&
                dut.pipeline_core_inst.pc_idex_o === 32'h20 &&
                dut.pipeline_core_inst.stall_ex_o === 1'b0) begin
                #1;
                if (step != 5 || gpio_out_o !== RX_BYTE ||
                    dut.pipeline_core_inst.regfile_inst.reg_file[4] !== RX_WORD ||
                    dut.pipeline_core_inst.regfile_inst.reg_file[5] !== 32'd0 ||
                    dut.pipeline_core_inst.regfile_inst.reg_file[6] !== 32'd0 ||
                    dut.uart_tx_target_inst.rx_pending !== 1'b0) begin
                    $fatal(1, "unexpected final state: step=%0d GPIO=%h x4=%h x5=%h x6=%h pending=%b",
                           step, gpio_out_o,
                           dut.pipeline_core_inst.regfile_inst.reg_file[4],
                           dut.pipeline_core_inst.regfile_inst.reg_file[5],
                           dut.pipeline_core_inst.regfile_inst.reg_file[6],
                           dut.uart_tx_target_inst.rx_pending);
                end
                $display("PASS: UART RX system checks passed");
                $finish;
            end
        end
    end

    initial begin
        #5000;
        $fatal(1, "UART RX system test timed out at step %0d", step);
    end
endmodule

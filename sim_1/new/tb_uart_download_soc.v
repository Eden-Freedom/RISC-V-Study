`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 17:09:22
// Design Name: 
// Module Name: tb_uart_download_soc
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


module tb_uart_download_soc;
    localparam integer CLKS_PER_BIT = 4;
    localparam [31:0] ADDI_WORD = 32'h0070_0093;
    localparam [31:0] JAL_WORD  = 32'h0000_006F;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg download_en_i = 1'b1;
    reg uart_rx_i = 1'b1;
    reg expect_load = 1'b0;
    integer load_count = 0;

    soc_top #(.USE_UART_DOWNLOAD(1'b1)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .irq_external_i(1'b0),
        .uart_rx_i(uart_rx_i),
        .spi_miso_i(1'b0),
        .download_en_i(download_en_i),
        .gpio_out_o(),
        .uart_tx_o(),
        .spi_mosi_o(),
        .spi_sclk_o(),
        .spi_cs_n_o()
    );

    wire ifid_valid = dut.pipeline_core_inst.valid_ifid_o;
    wire [31:0] ifid_pc = dut.pipeline_core_inst.pc_ifid_o;
    wire [31:0] ifid_instr = dut.pipeline_core_inst.instr_ifid_o;
    wire [31:0] x1_value = dut.pipeline_core_inst.register_file_inst.reg_file[1];

    always #5 clk = ~clk;

    task drive_bit;
        input value;
        begin
            @(negedge clk);
            uart_rx_i = value;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task send_byte;
        input [7:0] data;
        input ends_word;
        integer bit_index;
        begin
            drive_bit(1'b0);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                drive_bit(data[bit_index]);
            end

            @(negedge clk);
            uart_rx_i = 1'b1;
            repeat (CLKS_PER_BIT - 1) @(posedge clk);
            // 每组第四个字节在停止位第 4 个上升沿写入存储器。
            @(negedge clk);
            expect_load = ends_word;
            @(posedge clk);
            #1;
            expect_load = 1'b0;
        end
    endtask

    task expect_ifid;
        input [31:0] address;
        input [31:0] instruction;
        begin
            if (ifid_valid !== 1'b1 || ifid_pc !== address || ifid_instr !== instruction) begin
                $fatal(1, "IF/ID expected valid=1 pc=%h instr=%h, got valid=%b pc=%h instr=%h",
                       address, instruction, ifid_valid, ifid_pc, ifid_instr);
            end
        end
    endtask

    always @(posedge clk) begin
        // 在 DUT 更新寄存器之前，检查这个沿真正送给 program_mem 的写入。
        if (dut.load_we_o !== expect_load) begin
            $fatal(1, "At %0t expected load_we=%b, got %b", $time, expect_load, dut.load_we_o);
        end
        if (expect_load) begin
            case (load_count)
                0: if ({dut.load_addr_o, dut.load_data_o} !== {32'd0, ADDI_WORD}) begin
                    $fatal(1, "First write expected addr=0 data=%h, got addr=%h data=%h",
                           ADDI_WORD, dut.load_addr_o, dut.load_data_o);
                end
                1: if ({dut.load_addr_o, dut.load_data_o} !== {32'd4, JAL_WORD}) begin
                    $fatal(1, "Second write expected addr=4 data=%h, got addr=%h data=%h",
                           JAL_WORD, dut.load_addr_o, dut.load_data_o);
                end
                default: $fatal(1, "Unexpected download write at %0t", $time);
            endcase
            load_count = load_count + 1;
        end

        #1;
        if (download_en_i && (dut.cpu_rst_n !== 1'b0 || dut.fetch_addr_o !== 32'd0)) begin
            $fatal(1, "CPU advanced during download: cpu_rst_n=%b fetch=%h",
                   dut.cpu_rst_n, dut.fetch_addr_o);
        end
    end

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        send_byte(8'h93, 1'b0);
        send_byte(8'h00, 1'b0);
        send_byte(8'h70, 1'b0);
        send_byte(8'h00, 1'b1);

        send_byte(8'h6F, 1'b0);
        send_byte(8'h00, 1'b0);
        send_byte(8'h00, 1'b0);
        send_byte(8'h00, 1'b1);

        if (load_count != 2) begin
            $fatal(1, "Expected two program writes, got %0d", load_count);
        end

        // 先拉低总复位，再在复位期间退出下载模式。
        @(negedge clk);
        rst_n = 1'b0;
        @(negedge clk);
        download_en_i = 1'b0;
        @(posedge clk);
        #1;
        if (dut.cpu_rst_n !== 1'b0 || dut.fetch_addr_o !== 32'd0 || ifid_valid !== 1'b0) begin
            $fatal(1, "CPU left reset before total reset was released");
        end

        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;
        if (dut.cpu_rst_n !== 1'b1) begin
            $fatal(1, "CPU reset did not release in run mode");
        end
        expect_ifid(32'd0, ADDI_WORD);

        @(posedge clk);
        #1;
        expect_ifid(32'd4, JAL_WORD);

        wait (x1_value === 32'd7);
        $display("PASS: UART download SoC checks passed");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "UART download SoC test timed out: writes=%0d fetch=%h x1=%h",
               load_count, dut.fetch_addr_o, x1_value);
    end
endmodule

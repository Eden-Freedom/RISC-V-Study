`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 16:27:28
// Design Name: 
// Module Name: tb_uart_boot_top
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


module tb_uart_boot_top;
    localparam integer CLKS_PER_BIT = 4;
    localparam [31:0] ADDI_WORD = 32'h0070_0093;
    localparam [31:0] JAL_WORD  = 32'h0000_006F;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg uart_rx_i = 1'b1;
    reg start_run_i = 1'b0;
    reg loading = 1'b1;
    wire running_o;
    wire [31:0] fetch_addr_o;

    uart_boot_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_i(uart_rx_i),
        .start_run_i(start_run_i),
        .running_o(running_o),
        .fetch_addr_o(fetch_addr_o)
    );

    wire ifid_valid = dut.pipeline_core_inst.valid_ifid_o;
    wire [31:0] ifid_pc = dut.pipeline_core_inst.pc_ifid_o;
    wire [31:0] ifid_instr = dut.pipeline_core_inst.instr_ifid_o;
    wire [31:0] x1_value = dut.pipeline_core_inst.regfile_inst.reg_file[1];

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
        integer bit_index;
        begin
            drive_bit(1'b0);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                drive_bit(data[bit_index]);
            end
            drive_bit(1'b1);
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

    // 每个装载沿都检查 CPU 仍处于复位状态。
    always @(posedge clk) begin
        #1;
        if (loading && (running_o !== 1'b0 || fetch_addr_o !== 32'd0 || ifid_valid !== 1'b0)) begin
            $fatal(1, "CPU advanced during loading at %0t: running=%b fetch=%h IF/ID valid=%b",
                   $time, running_o, fetch_addr_o, ifid_valid);
        end
    end

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        send_byte(8'h93);
        send_byte(8'h00);
        send_byte(8'h70);
        send_byte(8'h00);

        send_byte(8'h6F);
        send_byte(8'h00);
        send_byte(8'h00);
        send_byte(8'h00);

        // 最后一帧的停止位结束后，再等一沿让 program_mem 写入。
        @(posedge clk);
        #1;
        @(negedge clk);
        loading = 1'b0;
        start_run_i = 1'b1;

        // R 沿接受启动。CPU 仍按该沿之前的复位状态更新 IF/ID。
        @(posedge clk);
        #1;
        if (running_o !== 1'b1 || ifid_valid !== 1'b0) begin
            $fatal(1, "Start edge expected running=1 IF/ID valid=0, got running=%b valid=%b",
                   running_o, ifid_valid);
        end

        @(negedge clk);
        start_run_i = 1'b0;

        // R+1 沿后，IF/ID 保存首条指令，取指地址已指向下一字。
        @(posedge clk);
        #1;
        if (running_o !== 1'b1 || fetch_addr_o !== 32'h0000_0004) begin
            $fatal(1, "First fetch expected running=1 and next fetch=4, got running=%b fetch=%h",
                   running_o, fetch_addr_o);
        end
        expect_ifid(32'h0000_0000, ADDI_WORD);

        @(posedge clk);
        #1;
        expect_ifid(32'h0000_0004, JAL_WORD);

        wait (x1_value === 32'd7);
        $display("PASS: UART boot top checks passed");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "UART boot test timed out: running=%b fetch=%h x1=%h",
               running_o, fetch_addr_o, x1_value);
    end
endmodule

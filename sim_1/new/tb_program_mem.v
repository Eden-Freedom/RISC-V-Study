`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 14:38:15
// Design Name: 
// Module Name: tb_program_mem
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


module tb_program_mem;
    localparam [31:0] TEST_ADDR      = 32'h0000_0004;
    localparam [31:0] LAST_ADDR      = 32'h0000_00FC;
    localparam [31:0] OUT_OF_RANGE   = 32'h0000_0104;
    localparam [31:0] MISALIGNED     = 32'h0000_0005;
    localparam [31:0] OLD_WORD       = 32'h0070_0093;
    localparam [31:0] NEW_WORD       = 32'h0090_0093;
    localparam [31:0] LAST_WORD      = 32'h0000_006F;
    localparam [31:0] REJECTED_WORD  = 32'hFFFF_FFFF;

    reg clk = 1'b0;
    reg [31:0] fetch_addr_i = TEST_ADDR;
    reg load_we_i = 1'b0;
    reg [31:0] load_addr_i = 32'd0;
    reg [31:0] load_data_i = 32'd0;
    wire [31:0] instr_o;

    program_mem dut (
        .fetch_addr_i(fetch_addr_i),
        .instr_o(instr_o),
        .clk(clk),
        .load_we_i(load_we_i),
        .load_addr_i(load_addr_i),
        .load_data_i(load_data_i)
    );

    always #5 clk = ~clk;

    task prepare_write;
        input [31:0] address;
        input [31:0] data;
        input enable;
        begin
            @(negedge clk);
            load_addr_i = address;
            load_data_i = data;
            load_we_i = enable;
        end
    endtask

    task expect_instr;
        input [31:0] expected;
        begin
            if (instr_o !== expected) begin
                $fatal(1, "At %0t fetch %h: expected %h, got %h",
                       $time, fetch_addr_i, expected, instr_o);
            end
        end
    endtask

    initial begin
        // 先装载旧指令，再保持取指地址不变，覆盖同一个字。
        prepare_write(TEST_ADDR, OLD_WORD, 1'b1);
        @(posedge clk);
        #1;
        expect_instr(OLD_WORD);

        prepare_write(TEST_ADDR, NEW_WORD, 1'b1);
        #1;
        expect_instr(OLD_WORD);
        @(posedge clk);
        #1;
        expect_instr(NEW_WORD);

        // 写末尾地址时，当前取指字不受影响。切换地址后在下一上升沿前读出。
        prepare_write(LAST_ADDR, LAST_WORD, 1'b1);
        @(posedge clk);
        #1;
        expect_instr(NEW_WORD);
        fetch_addr_i = LAST_ADDR;
        #1;
        expect_instr(LAST_WORD);

        // 两个非法地址的 [7:2] 都与 TEST_ADDR 相同，逐笔检查写入被拒绝。
        fetch_addr_i = TEST_ADDR;
        prepare_write(OUT_OF_RANGE, REJECTED_WORD, 1'b1);
        @(posedge clk);
        #1;
        expect_instr(NEW_WORD);

        prepare_write(MISALIGNED, REJECTED_WORD, 1'b1);
        @(posedge clk);
        #1;
        expect_instr(NEW_WORD);

        fetch_addr_i = OUT_OF_RANGE;
        #1;
        expect_instr(32'd0);
        fetch_addr_i = MISALIGNED;
        #1;
        expect_instr(32'd0);

        fetch_addr_i = TEST_ADDR;
        prepare_write(TEST_ADDR, REJECTED_WORD, 1'b0);
        @(posedge clk);
        #1;
        expect_instr(NEW_WORD);

        $display("PASS: program memory checks passed");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "Program memory test timed out");
    end
endmodule

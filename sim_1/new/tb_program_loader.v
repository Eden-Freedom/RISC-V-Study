`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 15:26:08
// Design Name: 
// Module Name: tb_program_loader
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


module tb_program_loader;
    localparam [31:0] FULL_ADDR = 32'h0000_0100;
    localparam [31:0] FIRST_WORD = 32'h1000_0000;
    localparam [31:0] LAST_WORD = FIRST_WORD + 32'd63;
    localparam [31:0] REJECTED_WORD = 32'hDEAD_BEEF;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg word_valid_i = 1'b1;
    reg [31:0] word_data_i = REJECTED_WORD;
    reg [31:0] fetch_addr_i = 32'd0;

    wire load_we_o, full_o;
    wire [31:0] load_addr_o, load_data_o, instr_o;

    integer word_index;
    reg [31:0] write_addr, expected_word;

    program_loader loader (
        .clk(clk),
        .rst_n(rst_n),
        .word_valid_i(word_valid_i),
        .word_data_i(word_data_i),
        .load_we_o(load_we_o),
        .load_addr_o(load_addr_o),
        .load_data_o(load_data_o),
        .full_o(full_o)
    );

    program_mem mem (
        .clk(clk),
        .fetch_addr_i(fetch_addr_i),
        .instr_o(instr_o),
        .load_we_i(load_we_o),
        .load_addr_i(load_addr_o),
        .load_data_i(load_data_o)
    );

    always #5 clk = ~clk;

    task expect_loader;
        input [31:0] address;
        input write_enable;
        input full;
        begin
            if (load_addr_o !== address || load_we_o !== write_enable || full_o !== full) begin
                $fatal(1, "At %0t expected addr=%h we=%b full=%b, got addr=%h we=%b full=%b",
                       $time, address, write_enable, full, load_addr_o, load_we_o, full_o);
            end
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
        // 复位时保持 word_valid_i=1，禁止装载写。
        @(posedge clk);
        #1;
        expect_loader(32'd0, 1'b0, 1'b0);

        @(negedge clk);
        word_valid_i = 1'b0;
        rst_n = 1'b1;
        @(posedge clk);
        #1;
        expect_loader(32'd0, 1'b0, 1'b0);

        // 每个沿用当前地址写入。沿后地址前进，取指仍从刚写的地址读回。
        for (word_index = 0; word_index < 64; word_index = word_index + 1) begin
            @(negedge clk);
            write_addr = word_index * 32'd4;
            expected_word = FIRST_WORD + word_index;
            word_valid_i = 1'b1;
            word_data_i = expected_word;
            fetch_addr_i = write_addr;
            #1;
            expect_loader(write_addr, 1'b1, 1'b0);
            if (load_data_o !== expected_word) begin
                $fatal(1, "Load data at %h: expected %h, got %h",
                       write_addr, expected_word, load_data_o);
            end

            @(posedge clk);
            #1;
            expect_instr(expected_word);
            expect_loader(write_addr + 32'd4, word_index != 63, word_index == 63);
        end

        // 最后一字已写进 0xFC。额外一字不能写入，地址保持 0x100。
        @(negedge clk);
        word_data_i = REJECTED_WORD;
        #1;
        expect_loader(FULL_ADDR, 1'b0, 1'b1);
        @(posedge clk);
        #1;
        expect_loader(FULL_ADDR, 1'b0, 1'b1);
        expect_instr(LAST_WORD);

        // 满标志复位清零后仍保持 valid=1，确认复位门控不会误写首字。
        @(negedge clk);
        rst_n = 1'b0;
        fetch_addr_i = 32'd0;
        repeat (2) begin
            @(posedge clk);
            #1;
            expect_loader(32'd0, 1'b0, 1'b0);
            expect_instr(FIRST_WORD);
        end

        $display("PASS: program loader checks passed");
        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "Program loader test timed out at word %0d", word_index);
    end
endmodule

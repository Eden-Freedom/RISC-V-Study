`timescale 1ns / 1ps
// Standalone timer counter checks, using the RTL's actual port names.
module tb_timer_counter;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg en_i = 1'b0;
    reg clear_i = 1'b0;
    reg [31:0] limit_i = 32'd3;
    wire cnt_done_o;
    wire [31:0] cnt_o;
    integer errors = 0;
    reg [31:0] expected_count;

    always #10 clk = ~clk;
    timer_counter dut (
        .clk(clk), .rst_n(rst_n), .en_i(en_i), .clear_i(clear_i),
        .limit_i(limit_i), .cnt_done_o(cnt_done_o), .cnt_value_o(cnt_o)
    );

    task check;
        input condition;
        input [8*90-1:0] label;
        begin
            // X/Z in an equality or predicate is a failure, not a skipped check.
            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s time=%0t rst_n=%b en=%b clear=%b limit=%0d count=%0d done=%b",
                         label, $time, rst_n, en_i, clear_i, limit_i, cnt_o, cnt_done_o);
            end
        end
    endtask

    // Expected values are explicit per stimulus. In particular, done_before
    // checks that changing limit updates the comparison before any rising edge.
    task check_cycle;
        input [8*90-1:0] label;
        input reset_n_value;
        input enable_value;
        input clear_value;
        input [31:0] limit_value;
        input done_before;
        input [31:0] count_after;
        input done_after;
        begin
            @(negedge clk);
            rst_n = reset_n_value;
            en_i = enable_value;
            clear_i = clear_value;
            limit_i = limit_value;
            #1;
            $display("CHECK: %0s", label);
            check(cnt_o === expected_count, "count holds before the rising edge");
            check(cnt_done_o === done_before, "comparison responds combinationally");
            @(posedge clk);
            #1;
            check(cnt_o === count_after, "count after rising-edge update");
            check(cnt_done_o === done_after, "comparison after rising-edge update");
            expected_count = count_after;
        end
    endtask

    initial begin
        // Do not initialize DUT state: a real synchronous reset edge must clear it.
        @(posedge clk);
        #1;
        check(cnt_o === 32'd0, "initial reset clears count");
        check(cnt_done_o === 1'b0, "zero count is below limit three");
        expected_count = 32'd0;

        // Stable limit=3: count 1,2,3,3,3; expiry is a level, not a pulse.
        check_cycle("limit 3: first count",       1, 1, 0, 3, 0, 1, 0);
        check_cycle("limit 3: second count",      1, 1, 0, 3, 0, 2, 0);
        check_cycle("limit 3: reach threshold",   1, 1, 0, 3, 0, 3, 1);
        check_cycle("expired: first hold",        1, 1, 0, 3, 1, 3, 1);
        check_cycle("expired: second hold",       1, 1, 0, 3, 1, 3, 1);
        check_cycle("disable does not hide expiry", 1, 0, 0, 3, 1, 3, 1);

        // Clear works even when disabled; pause/resume preserves partial progress.
        check_cycle("clear while disabled",      1, 0, 1, 3, 1, 0, 0);
        check_cycle("restart and count to one",  1, 1, 0, 3, 0, 1, 0);
        check_cycle("pause first edge",           1, 0, 0, 3, 0, 1, 0);
        check_cycle("pause second edge",          1, 0, 0, 3, 0, 1, 0);
        check_cycle("resume from one to two",     1, 1, 0, 3, 0, 2, 0);
        check_cycle("resume reaches three",       1, 1, 0, 3, 0, 3, 1);
        check_cycle("disable at expiry",          1, 0, 0, 3, 1, 3, 1);

        // Clear overrides enabled counting and stays effective on every held edge.
        check_cycle("clear overrides enable",     1, 1, 1, 3, 1, 0, 0);
        check_cycle("held clear first edge",      1, 1, 1, 3, 0, 0, 0);
        check_cycle("held clear second edge",     1, 1, 1, 3, 0, 0, 0);
        check_cycle("release clear: start at one", 1, 1, 0, 3, 0, 1, 0);
        check_cycle("reset overrides counting",   0, 1, 0, 3, 0, 0, 0);
        check_cycle("hold reset while enabled",   0, 1, 0, 3, 0, 0, 0);

        // Expiry uses the current limit, including zero, even during reset/disable.
        check_cycle("zero limit expires immediately at count zero", 0, 1, 0, 0, 1, 0, 1);
        check_cycle("zero limit enabled: remain at zero",           1, 1, 0, 0, 1, 0, 1);
        check_cycle("zero limit enabled: expiry persists",          1, 1, 0, 0, 1, 0, 1);
        check_cycle("zero limit disabled: still expired",           1, 0, 0, 0, 1, 0, 1);
        check_cycle("zero limit clear: still expired",              1, 1, 1, 0, 1, 0, 1);

        // Obtain count=2, lower limit below it, then raise limit and resume.
        check_cycle("raise limit to three: resume at one", 1, 1, 0, 3, 0, 1, 0);
        check_cycle("prepare count two",                   1, 1, 0, 3, 0, 2, 0);
        check_cycle("lower limit to one while paused",     1, 0, 0, 1, 1, 2, 1);
        check_cycle("count above limit stays stopped",     1, 1, 0, 1, 1, 2, 1);
        check_cycle("raise limit to four while paused",    1, 0, 0, 4, 0, 2, 0);
        check_cycle("resume to three",                     1, 1, 0, 4, 0, 3, 0);
        check_cycle("reach new limit four",                1, 1, 0, 4, 0, 4, 1);
        check_cycle("hold at new threshold",               1, 1, 0, 4, 1, 4, 1);
        check_cycle("disable preserves new expiry",         1, 0, 0, 4, 1, 4, 1);

        if (errors == 0) begin
            $display("PASS: timer counter checks passed");
            $finish;
        end else
            $fatal(1, "FAIL: timer counter checks failed (%0d errors)", errors);
    end

    initial begin
        #5000;
        $fatal(1, "FAIL: timer counter timeout");
    end
endmodule
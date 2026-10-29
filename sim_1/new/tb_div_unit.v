`timescale 1ns / 1ps


module tb_div_unit;

    reg        clk;
    reg        rst_n;
    reg        start_i;
    reg  [31:0] dividend_i;
    reg  [31:0] divisor_i;

    wire [31:0] quotient_o;
    wire [31:0] remainder_o;
    wire       busy_o;
    wire       done_o;

    // 最近一次完成运算的预期结果
    reg [31:0] held_q;
    reg [31:0] held_r;

    integer step;
    integer completed_cases;

    // 助手按学习者请求补充的随机测试变量；数据保持unsigned 32位
    reg [31:0] random_dividend;
    reg [31:0] random_divisor;
    integer random_index;
    integer random_seed;

    div_unit dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start_i     (start_i),
        .dividend_i  (dividend_i),
        .divisor_i   (divisor_i),
        .quotient_o  (quotient_o),
        .remainder_o (remainder_o),
        .busy_o      (busy_o),
        .done_o      (done_o)
    );

    // 时钟周期10ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 全局超时，防止仿真挂起
    initial begin
        #1000000;
        $fatal(1, "FAIL: simulation timeout");
    end

    // 使用 !==，同时检测错误数值及X/Z
    task check_state;
        input       expected_busy;
        input       expected_done;
        input [31:0] expected_q;
        input [31:0] expected_r;
        input [8*80-1:0] tag;
        begin
            if ((busy_o      !== expected_busy) ||
                (done_o      !== expected_done) ||
                (quotient_o  !== expected_q)    ||
                (remainder_o !== expected_r)) begin

                $display("\nFAIL: %0s, time=%0t", tag, $time);

                $display(
                    "  expected: busy=%b done=%b Q=%h R=%h",
                    expected_busy, expected_done,
                    expected_q, expected_r
                );

                $display(
                    "  actual:   busy=%b done=%b Q=%h R=%h",
                    busy_o, done_o, quotient_o, remainder_o
                );

                $display(
                    "  inputs: start=%b dividend=%h divisor=%h",
                    start_i, dividend_i, divisor_i
                );

                $fatal(1, "State check failed");
            end
        end
    endtask

    // 同步复位；也用于运算中取消
    task apply_reset;
        begin
            @(negedge clk);
            rst_n      = 1'b0;
            start_i    = 1'b0;
            dividend_i = 32'h0;
            divisor_i  = 32'h0;

            @(posedge clk);
            #1;
            check_state(
                1'b0, 1'b0, 32'h0, 32'h0,
                "reset clears status and results"
            );

            held_q = 32'h0;
            held_r = 32'h0;

            @(negedge clk);
            rst_n = 1'b1;

            @(posedge clk);
            #1;
            check_state(
                1'b0, 1'b0, held_q, held_r,
                "idle after reset release"
            );
        end
    endtask

    // 在空闲时启动；检查E0只装载、不完成、不改变旧结果
    task launch;
        input [31:0] numerator;
        input [31:0] denominator;
        begin
            @(negedge clk);
            start_i    = 1'b1;
            dividend_i = numerator;
            divisor_i  = denominator;

            @(posedge clk);
            #1;
            check_state(
                1'b1, 1'b0, held_q, held_r,
                "E0: request accepted, old results retained"
            );
        end
    endtask

    // 完整检查一次除法
    // inject_requests=1时：
    //   E1~E32改变外部输入
    //   E2和E32分别注入start请求，均应被忽略
    task run_case;
        input [31:0] numerator;
        input [31:0] denominator;
        input       inject_requests;

        reg [31:0] expected_q;
        reg [31:0] expected_r;
        integer round;
        integer idle_cycle;
        begin
            // TB允许用 / 和 % 计算参考结果
            if (denominator == 32'h0) begin
                expected_q = 32'hFFFFFFFF;
                expected_r = numerator;
            end
            else begin
                expected_q = numerator / denominator;
                expected_r = numerator % denominator;
            end

            launch(numerator, denominator);

            for (round = 1; round <= 32; round = round + 1) begin
                @(negedge clk);

                start_i = 1'b0;

                if (inject_requests) begin
                    // 与启动时的数据不同，验证内部已经锁存输入
                    dividend_i = numerator   ^ 32'hFFFFFFFF;
                    divisor_i  = denominator ^ 32'hFFFFFFFF;

                    // E2忙时请求，E32完成沿请求
                    if ((round == 2) || (round == 32))
                        start_i = 1'b1;
                end
                else begin
                    dividend_i = numerator;
                    divisor_i  = denominator;
                end

                @(posedge clk);
                #1;

                if (round < 32) begin
                    check_state(
                        1'b1, 1'b0, held_q, held_r,
                        "E1-E31: busy, no done, old results retained"
                    );
                end
                else begin
                    // 先显示当前用例，方便失败时定位
                    if ((busy_o      !== 1'b0) ||
                        (done_o      !== 1'b1) ||
                        (quotient_o  !== expected_q) ||
                        (remainder_o !== expected_r)) begin

                        $display(
                            "Case: dividend=%0d divisor=%0d inject=%b",
                            numerator, denominator, inject_requests
                        );
                    end

                    check_state(
                        1'b0, 1'b1, expected_q, expected_r,
                        "E32: operation completes with correct results"
                    );
                end
            end

            // 保存预期结果，用于之后的保持检查
            held_q = expected_q;
            held_r = expected_r;

            // E33清done；继续空闲两拍检查结果保持
            // 同时检查E32的start没有被缓存成后续请求
            for (idle_cycle = 0;
                 idle_cycle < 3;
                 idle_cycle = idle_cycle + 1) begin

                @(negedge clk);
                start_i    = 1'b0;
                dividend_i = 32'h5;
                divisor_i  = 32'hA;

                @(posedge clk);
                #1;
                check_state(
                    1'b0, 1'b0, held_q, held_r,
                    "E33 onward: done cleared, idle, results retained"
                );
            end

            completed_cases = completed_cases + 1;
        end
    endtask

    initial begin
        rst_n          = 1'b1;
        start_i        = 1'b0;
        dividend_i     = 32'h0;
        divisor_i      = 32'h0;
        held_q         = 32'h0;
        held_r         = 32'h0;
        completed_cases = 0;

        apply_reset;

        // 1. 定向覆盖普通值、边界值和除零
        run_case(32'd13, 32'd3, 1'b0);
        run_case(32'd0, 32'd7, 1'b0);
        run_case(32'd7, 32'd1, 1'b0);
        run_case(32'd2, 32'd3, 1'b0);
        run_case(32'hFFFFFFFF, 32'd2, 1'b0);
        run_case(32'h80000000, 32'hFFFFFFFF, 1'b0);
        run_case(32'd0, 32'd0, 1'b0);
        run_case(32'hFFFFFFFF, 32'd0, 1'b0);

        $display("Directed arithmetic and timing checks passed: 8 cases");

        // 2. 普通除法和除零运算中的输入变化、忙时start、
        //    完成沿start，都不得影响本次运算
        run_case(32'd11, 32'd3, 1'b1);
        run_case(32'd15, 32'd0, 1'b1);

        $display("Busy-input isolation and ignored-start checks passed");

        // 3. 启动一次运算，执行两轮后复位取消
        launch(32'd14, 32'd3);

        for (step = 1; step <= 2; step = step + 1) begin
            @(negedge clk);
            start_i = 1'b0;

            @(posedge clk);
            #1;
            check_state(
                1'b1, 1'b0, held_q, held_r,
                "before cancellation: operation is busy"
            );
        end

        apply_reset;

        // 取消后继续观察，旧运算不得产生迟到的done或结果
        repeat (35) begin
            @(negedge clk);
            start_i = 1'b0;

            @(posedge clk);
            #1;
            check_state(
                1'b0, 1'b0, 32'h0, 32'h0,
                "cancelled operation must not complete later"
            );
        end

        // 4. 复位取消后可以正常重新启动
        run_case(32'd13, 32'd3, 1'b0);

        $display("Reset cancellation and restart checks passed");

        // 5. 助手按学习者请求补充：100组全宽32位随机输入
        // 固定种子，便于在相同仿真器中复现失败用例
        random_seed = 32'h13579BDF;
        for (random_index = 0; random_index < 100;
             random_index = random_index + 1) begin
            random_dividend = $random(random_seed);
            random_divisor  = $random(random_seed);
            run_case(random_dividend, random_divisor, 1'b0);
        end

        $display("Full-width random checks passed: 100 cases");

        // 6. 100组全宽被除数和小除数，增加多位商的覆盖
        // 先取低8位，再用32位加法加1，除数范围为1~256
        for (random_index = 0; random_index < 100;
             random_index = random_index + 1) begin
            random_dividend = $random(random_seed);
            random_divisor  = ($random(random_seed) & 32'h000000FF)
                              + 32'd1;
            run_case(random_dividend, random_divisor, 1'b0);
        end

        $display("Small-divisor random checks passed: 100 cases");
        $display(
            "PASS: all div_unit checks passed, completed_cases=%0d",
            completed_cases
        );

        $finish;
    end

endmodule

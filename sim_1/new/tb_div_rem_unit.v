`timescale 1ns / 1ps

module tb_div_rem_unit;

    reg         clk;
    reg         rst_n;
    reg         start_i;
    reg         signed_i;
    reg  [31:0] dividend_i;
    reg  [31:0] divisor_i;

    wire [31:0] quotient_o;
    wire [31:0] remainder_o;
    wire        busy_o;
    wire        done_o;

    // 最近一次完成结果的预期值
    reg [31:0] held_q;
    reg [31:0] held_r;

    // 失败诊断：记录原始请求，避免被干扰输入覆盖
    reg        case_signed;
    reg [31:0] case_dividend;
    reg [31:0] case_divisor;
    integer    active_edge;

    // 随机数据先保存为unsigned 32位
    reg [31:0] random_dividend;
    reg [31:0] random_divisor;
    reg [31:0] small_magnitude;
    integer    random_seed;
    integer    random_index;
    integer    completed_cases;

    div_rem_unit dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start_i     (start_i),
        .signed_i    (signed_i),
        .dividend_i  (dividend_i),
        .divisor_i   (divisor_i),
        .quotient_o  (quotient_o),
        .remainder_o (remainder_o),
        .busy_o      (busy_o),
        .done_o      (done_o)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 所有测试预计远小于此时间
    initial begin
        #1000000;
        $fatal(1, "FAIL: simulation timeout");
    end

    task check_state;
        input        expected_busy;
        input        expected_done;
        input [31:0] expected_q;
        input [31:0] expected_r;
        input [8*96-1:0] tag;
        begin
            if ((busy_o      !== expected_busy) ||
                (done_o      !== expected_done) ||
                (quotient_o  !== expected_q)    ||
                (remainder_o !== expected_r)) begin

                $display("\nFAIL: %0s", tag);
                $display(
                    "  time=%0t edge=E%0d completed_cases=%0d",
                    $time, active_edge, completed_cases
                );
                $display(
                    "  original request: signed=%b A=%h B=%h",
                    case_signed, case_dividend, case_divisor
                );
                $display(
                    "  current inputs: start=%b signed=%b A=%h B=%h",
                    start_i, signed_i, dividend_i, divisor_i
                );
                $display(
                    "  expected: busy=%b done=%b Q=%h R=%h",
                    expected_busy, expected_done,
                    expected_q, expected_r
                );
                $display(
                    "  actual:   busy=%b done=%b Q=%h R=%h",
                    busy_o, done_o, quotient_o, remainder_o
                );

                $fatal(1, "State check failed");
            end
        end
    endtask

    // 复位在下降沿驱动，上升沿之后检查
    task apply_reset;
        begin
            @(negedge clk);
            rst_n      = 1'b0;
            start_i    = 1'b0;
            signed_i   = 1'b0;
            dividend_i = 32'd0;
            divisor_i  = 32'd0;

            @(posedge clk);
            #1;
            check_state(
                1'b0, 1'b0, 32'd0, 32'd0,
                "reset clears status and results"
            );

            held_q = 32'd0;
            held_r = 32'd0;

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

    // 空闲期间结果保持，同时检查done清零和无迟到请求
    task check_idle;
        input integer cycles;
        integer k;
        begin
            for (k = 0; k < cycles; k = k + 1) begin
                @(negedge clk);
                start_i    = 1'b0;
                signed_i   = ~signed_i;
                dividend_i = 32'hA5A55A5A;
                divisor_i  = 32'h5A5AA5A5;

                @(posedge clk);
                #1;
                check_state(
                    1'b0, 1'b0, held_q, held_r,
                    "idle: done cleared and results retained"
                );
            end
        end
    endtask

    task launch;
        input        mode_signed;
        input [31:0] numerator;
        input [31:0] denominator;
        begin
            case_signed   = mode_signed;
            case_dividend = numerator;
            case_divisor  = denominator;
            active_edge   = 0;

            @(negedge clk);
            start_i    = 1'b1;
            signed_i   = mode_signed;
            dividend_i = numerator;
            divisor_i  = denominator;

            @(posedge clk);
            #1;
            check_state(
                1'b1, 1'b0, held_q, held_r,
                "E0: accepted, busy asserted, old results retained"
            );
        end
    endtask

    task run_case;
        input        mode_signed;
        input [31:0] numerator;
        input [31:0] denominator;
        input        inject_requests;

        reg [31:0] expected_q;
        reg [31:0] expected_r;

        // 普通signed运算必须使用signed操作数
        reg signed [31:0] signed_a;
        reg signed [31:0] signed_b;
        reg signed [31:0] signed_q;
        reg signed [31:0] signed_r;

        integer edge_index;
        begin
            signed_a = numerator;
            signed_b = denominator;

            // 参考模型按要求显式区分特殊情况
            if (denominator == 32'd0) begin
                expected_q = 32'hFFFFFFFF;
                expected_r = numerator;
            end
            else if (mode_signed &&
                     (numerator   == 32'h80000000) &&
                     (denominator == 32'hFFFFFFFF)) begin
                expected_q = 32'h80000000;
                expected_r = 32'd0;
            end
            else if (mode_signed) begin
                signed_q = signed_a / signed_b;
                signed_r = signed_a % signed_b;
                expected_q = signed_q;
                expected_r = signed_r;
            end
            else begin
                expected_q = numerator / denominator;
                expected_r = numerator % denominator;
            end

            launch(mode_signed, numerator, denominator);

            for (edge_index = 1;
                 edge_index <= 33;
                 edge_index = edge_index + 1) begin

                @(negedge clk);
                start_i = 1'b0;

                if (inject_requests) begin
                    // 改变模式和两个数据，检查请求信息已锁存
                    signed_i   = ~mode_signed;
                    dividend_i = numerator   ^ 32'hFFFFFFFF;
                    divisor_i  = denominator ^ 32'hFFFFFFFF;

                    // E2忙时、E32核心完成沿、E33包装完成沿
                    // E32和E33连续两拍为高，均不得受理
                    if ((edge_index == 2)  ||
                        (edge_index == 32) ||
                        (edge_index == 33))
                        start_i = 1'b1;
                end
                else begin
                    signed_i   = mode_signed;
                    dividend_i = numerator;
                    divisor_i  = denominator;
                end

                @(posedge clk);
                #1;
                active_edge = edge_index;

                if (edge_index <= 32) begin
                    check_state(
                        1'b1, 1'b0, held_q, held_r,
                        "E1-E32: busy, no done, old results retained"
                    );
                end
                else begin
                    check_state(
                        1'b0, 1'b1, expected_q, expected_r,
                        "E33: correct results and one-cycle completion"
                    );
                end
            end

            held_q = expected_q;
            held_r = expected_r;
            completed_cases = completed_cases + 1;

            // 返回时仍处于E33沿后。
            // 若立即调用下一次run_case，它在E34受理，
            // 并检查旧done已清零、旧结果仍保留。
        end
    endtask

    // cancel_edge=3：执行两轮后复位
    // cancel_edge=33：核心已在E32完成，E33复位取消包装输出
    task cancel_operation;
        input integer cancel_edge;
        integer edge_index;
        begin
            launch(1'b1, 32'hFFFFFFF3, 32'd3);

            for (edge_index = 1;
                 edge_index < cancel_edge;
                 edge_index = edge_index + 1) begin

                @(negedge clk);
                start_i = 1'b0;

                @(posedge clk);
                #1;
                active_edge = edge_index;

                check_state(
                    1'b1, 1'b0, held_q, held_r,
                    "before cancellation: busy and old results retained"
                );
            end

            // 下一个上升沿正好是指定的取消沿
            active_edge = cancel_edge;
            apply_reset;

            // 越过旧运算原本可能完成的时刻
            check_idle(35);
        end
    endtask

    initial begin
        rst_n           = 1'b1;
        start_i         = 1'b0;
        signed_i        = 1'b0;
        dividend_i      = 32'd0;
        divisor_i       = 32'd0;
        held_q          = 32'd0;
        held_r          = 32'd0;
        case_signed     = 1'b0;
        case_dividend   = 32'd0;
        case_divisor    = 32'd0;
        active_edge     = 0;
        completed_cases = 0;
        random_seed     = 32'h13579BDF;

        apply_reset;

        // 1. 四种正负组合：连续调用还覆盖E34立即接收下一笔
        run_case(1'b1, 32'd13,       32'd3,       1'b0);
        run_case(1'b1, 32'hFFFFFFF3, 32'd3,       1'b0);
        run_case(1'b1, 32'd13,       32'hFFFFFFFD, 1'b0);
        run_case(1'b1, 32'hFFFFFFF3, 32'hFFFFFFFD, 1'b0);

        // 2. signed/unsigned解释差异、溢出和除零
        run_case(1'b1, 32'hFFFFFFFF, 32'd2,       1'b0);
        run_case(1'b0, 32'hFFFFFFFF, 32'd2,       1'b0);

        run_case(1'b1, 32'h80000000, 32'hFFFFFFFF, 1'b0);
        run_case(1'b0, 32'h80000000, 32'hFFFFFFFF, 1'b0);
        run_case(1'b1, 32'h80000000, 32'd1,        1'b0);

        run_case(1'b1, 32'hFFFFFFF3, 32'd0, 1'b0);
        run_case(1'b1, 32'h80000000, 32'd0, 1'b0);
        run_case(1'b0, 32'd0,        32'd0, 1'b0);
        run_case(1'b1, 32'd0,        32'd0, 1'b0);

        check_idle(3);
        $display("Directed arithmetic and back-to-back checks passed");

        // 3. 同时改变模式和数据，注入E2/E32/E33请求
        // 每次后面留空闲周期，确保没有缓存的非法请求
        run_case(1'b1, 32'hFFFFFFF3, 32'd3, 1'b1);
        check_idle(3);

        run_case(1'b0, 32'hFFFFFFFF, 32'd2, 1'b1);
        check_idle(3);

        run_case(1'b1, 32'hFFFFFFF3, 32'd0, 1'b1);
        check_idle(3);

        $display("Busy isolation and ignored-start checks passed");

        // 4. 中途复位取消，观察35拍，然后正常重启
        cancel_operation(3);
        run_case(1'b1, 32'd13, 32'hFFFFFFFD, 1'b0);
        check_idle(3);

        // 5. 在E33复位：取消核心已算完但包装尚未交出的结果
        cancel_operation(33);
        run_case(1'b0, 32'h80000000, 32'd3, 1'b0);
        check_idle(3);

        $display("Reset cancellation and restart checks passed");

        // 6. unsigned随机100组
        // 前50组全宽，后50组除数限制为1~256
        for (random_index = 0;
             random_index < 100;
             random_index = random_index + 1) begin

            random_dividend = $random(random_seed);

            if (random_index < 50) begin
                random_divisor = $random(random_seed);
            end
            else begin
                random_divisor =
                    ($random(random_seed) & 32'h000000FF) + 32'd1;
            end

            run_case(
                1'b0, random_dividend, random_divisor, 1'b0
            );
        end

        check_idle(3);
        $display("Unsigned random checks passed: 100 cases");

        // 7. signed随机100组
        // 前50组全宽，后50组除数为±1~±256
        for (random_index = 0;
             random_index < 100;
             random_index = random_index + 1) begin

            random_dividend = $random(random_seed);

            if (random_index < 50) begin
                random_divisor = $random(random_seed);
            end
            else begin
                small_magnitude =
                    ($random(random_seed) & 32'h000000FF) + 32'd1;

                // 正负小除数各25组
                if ((random_index % 2) == 0)
                    random_divisor = small_magnitude;
                else
                    random_divisor = ~small_magnitude + 32'd1;
            end

            run_case(
                1'b1, random_dividend, random_divisor, 1'b0
            );
        end

        check_idle(3);
        $display("Signed random checks passed: 100 cases");

        $display(
            "PASS: all div_rem_unit checks passed, completed_cases=%0d",
            completed_cases
        );
        $finish;
    end

endmodule
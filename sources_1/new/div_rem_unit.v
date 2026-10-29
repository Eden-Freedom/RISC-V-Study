//当前的设计是当包装层和核心层都完成任务之后再接受新的请求
//所以core_start = start_i && !busy_o;
//当start上升沿的时候，核心层取走转换后的被除数和除数保存用于计算，包装层取走商和余数是否需要转换的标签保存
//包装层的busy是指包装层自己和核心层都在忙，或者是包装层自己在忙
//因为包装层结束工作肯定是在核心层计算完成之后，然后当前的设计又是当包装层和核心层都完成任务之后再接受新的请求
//所以当busy为0 的时候说明包装层和核心层都是空闲的
//结果的两种特殊情况只有除数为0的商需要特别的处理，其余的情况按照正常的计算流程即可覆盖


module div_rem_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start_i,
    input  wire        signed_i,
    input  wire [31:0] dividend_i,
    input  wire [31:0] divisor_i,

    output reg  [31:0] quotient_o,
    output reg  [31:0] remainder_o,
    output reg         busy_o,
    output reg         done_o
);

    wire [31:0] core_dividend;
    wire [31:0] core_divisor;
    wire [31:0] core_quotient;
    wire [31:0] core_remainder;
    wire        core_busy;
    wire        core_done;
    wire        core_start;

    // 保存本次运算的信息，忙时不再读取外部符号控制
    reg quotient_neg;
    reg remainder_neg;
    reg divisor_zero;

    // --------------------------------------------------
    // 1. 组合逻辑：计算当前输入的无符号幅值
    // --------------------------------------------------

    assign core_dividend =
        (signed_i && dividend_i[31])
        ? (~dividend_i + 32'd1)
        : dividend_i;

    assign core_divisor =
        (signed_i && divisor_i[31])
        ? (~divisor_i + 32'd1)
        : divisor_i;

    // 只有包装层空闲时，核心才能收到启动请求
    assign core_start = start_i && !busy_o;

    // --------------------------------------------------
    // 2. 时序逻辑：保存标志、管理状态、恢复结果符号
    // --------------------------------------------------

    always @(posedge clk) begin
        if (!rst_n) begin
            quotient_o   <= 32'd0;
            remainder_o  <= 32'd0;
            busy_o       <= 1'b0;
            done_o       <= 1'b0;

            quotient_neg  <= 1'b0;
            remainder_neg <= 1'b0;
            divisor_zero  <= 1'b0;
        end
        else begin
            // 默认清零，只在完成时置1
            done_o <= 1'b0;

            if (busy_o) begin
                // 忙时忽略start和外部输入变化
                if (core_done) begin

                    // 商：先处理除零，再恢复符号
                    if (divisor_zero) begin
                        quotient_o <= 32'hFFFFFFFF;
                    end
                    else if (quotient_neg) begin
                        quotient_o <= ~core_quotient + 32'd1;
                    end
                    else begin
                        quotient_o <= core_quotient;
                    end

                    // 余数：非零余数与原被除数同号
                    // 除零时也能据此恢复原被除数
                    if (remainder_neg) begin
                        remainder_o <= ~core_remainder + 32'd1;
                    end
                    else begin
                        remainder_o <= core_remainder;
                    end

                    busy_o <= 1'b0;
                    done_o <= 1'b1;
                end
            end
            else if (start_i) begin
                // 空闲受理：核心在同一个沿锁存组合幅值
                quotient_neg <=
                    signed_i && (dividend_i[31] ^ divisor_i[31]);

                remainder_neg <=
                    signed_i && dividend_i[31];

                divisor_zero <=
                    (divisor_i == 32'd0);

                busy_o <= 1'b1;

                // 不改结果输出，保留上一次完成的结果
            end
        end
    end

    // --------------------------------------------------
    // 3. 无符号除法核心
    // --------------------------------------------------

    div_unit div_unit_inst (
        .clk         (clk),
        .rst_n       (rst_n),
        .start_i     (core_start),
        .dividend_i  (core_dividend),
        .divisor_i   (core_divisor),
        .quotient_o  (core_quotient),
        .remainder_o (core_remainder),
        .busy_o      (core_busy),
        .done_o      (core_done)
    );

endmodule
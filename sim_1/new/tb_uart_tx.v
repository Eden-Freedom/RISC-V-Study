`timescale 1ns / 1ps

module tb_uart_tx;
    localparam integer CLKS_PER_BIT = 4;
    localparam integer FRAME_CYCLES = 10 * CLKS_PER_BIT;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg start_i = 1'b0;
    reg [7:0] data_i = 8'd0;
    wire busy_o;
    wire tx_o;
    integer errors = 0;

    always #10 clk = ~clk;

    uart_tx dut (
        .clk(clk), .rst_n(rst_n), .start_i(start_i), .data_i(data_i),
        .busy_o(busy_o), .tx_o(tx_o)
    );

    task check_line;
        input [8*64-1:0] label;
        input integer cycle_from_start;
        input expected_busy;
        input expected_tx;
        begin
            if (busy_o !== expected_busy || tx_o !== expected_tx) begin
                errors = errors + 1;
                $display("FAIL: %0s t=%0t cycle=%0d busy=%b expected=%b tx=%b expected=%b",
                         label, $time, cycle_from_start, busy_o, expected_busy, tx_o, expected_tx);
            end
        end
    endtask

    task send_frame;
        input [7:0] frame_byte;
        input inject_busy_start;
        integer cycle;
        reg [9:0] expected_frame;
        begin
            // Index zero is the start bit; data follows least significant bit first.
            expected_frame = {1'b1, frame_byte, 1'b0};
            @(negedge clk);
            data_i = frame_byte;
            start_i = 1'b1;
            #1;
            check_line("before start acceptance", -1, 1'b0, 1'b1);
            $display("CHECK: send %02h", frame_byte);

            // Cycle 0 is the rising edge A that accepts the start request.
            for (cycle = 0; cycle < FRAME_CYCLES; cycle = cycle + 1) begin
                @(posedge clk);
                #1;
                check_line("frame output", cycle, 1'b1,
                           expected_frame[cycle / CLKS_PER_BIT]);

                @(negedge clk);
                // Assert for exactly one busy sampling edge (A+11).
                start_i = inject_busy_start && (cycle == 10);
                if (start_i)
                    data_i = 8'h00;
            end

            @(posedge clk);
            #1;
            check_line("frame ends at A+40", FRAME_CYCLES, 1'b0, 1'b1);

            // Leave the sender idle for one bit time to detect a queued start.
            repeat (CLKS_PER_BIT) begin
                @(posedge clk);
                #1;
                check_line("idle after frame", -1, 1'b0, 1'b1);
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #1;
        check_line("synchronous reset", -1, 1'b0, 1'b1);
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;
        check_line("idle after reset release", -1, 1'b0, 1'b1);

        send_frame(8'h83, 1'b1);
        send_frame(8'h06, 1'b0);

        if (errors == 0) begin
            $display("PASS: UART TX checks passed");
            $finish;
        end else
            $fatal(1, "FAIL: UART TX checks failed (%0d errors)", errors);
    end

    initial begin
        #5000;
        $fatal(1, "FAIL: UART TX timeout");
    end
endmodule

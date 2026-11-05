`timescale 1ns / 1ps

// The TB acts as the bus requester. The UART state and saved byte are observations.
module tb_uart_tx_target;
    localparam integer CLKS_PER_BIT = 4;
    localparam integer FRAME_CYCLES = 10 * CLKS_PER_BIT;
    localparam integer FIRST_END = FRAME_CYCLES;
    localparam integer SECOND_ACCEPT = FIRST_END + 1;
    localparam integer SECOND_END = SECOND_ACCEPT + FRAME_CYCLES;
    localparam [31:0] TXDATA = 32'h0;
    localparam [31:0] STATUS = 32'h4;
    localparam [31:0] RESERVED_8 = 32'h8;
    localparam [31:0] RESERVED_C = 32'hC;
    localparam [7:0] FIRST_BYTE = 8'h55;
    localparam [7:0] SECOND_BYTE = 8'hA6;
    // Index zero is START, followed by eight LSB-first data bits, then STOP.
    localparam [9:0] FIRST_FRAME = {1'b1, FIRST_BYTE, 1'b0};
    localparam [9:0] SECOND_FRAME = {1'b1, SECOND_BYTE, 1'b0};

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg req_i = 1'b0;
    reg we_i = 1'b0;
    reg [31:0] addr_i = 32'd0;
    reg [31:0] wdata_i = 32'd0;
    reg [3:0] wstrb_i = 4'd0;
    wire ready_o;
    wire [31:0] rdata_o;
    wire tx_o;

    integer errors = 0;
    integer cycle = -1;
    integer bus_completions = 0;
    integer tx_accepts = 0;

    always #10 clk = ~clk;

    uart_tx_target dut (
        .clk(clk), .rst_n(rst_n), .req_i(req_i), .we_i(we_i),
        .addr_i(addr_i), .wdata_i(wdata_i), .wstrb_i(wstrb_i),
        .ready_o(ready_o), .rdata_o(rdata_o), .tx_o(tx_o)
    );

    task drive_bus;
        input request;
        input write_access;
        input [31:0] address;
        input [31:0] data;
        input [3:0] mask;
        begin
            req_i = request;
            we_i = write_access;
            addr_i = address;
            wdata_i = data;
            wstrb_i = mask;
        end
    endtask

    task expect_bus;
        input [8*64-1:0] phase;
        input expected_ready;
        input expected_start;
        input [31:0] expected_rdata;
        begin
            if ({ready_o, dut.tx_start, rdata_o} !==
                {expected_ready, expected_start, expected_rdata}) begin
                errors = errors + 1;
                $display("FAIL: %0s t=%0t cycle=%0d req=%b we=%b addr=%08h data=%08h mask=%b",
                         phase, $time, cycle, req_i, we_i, addr_i, wdata_i, wstrb_i);
                $display("  ready/start/rdata=%b/%b/%08h expected=%b/%b/%08h",
                         ready_o, dut.tx_start, rdata_o, expected_ready, expected_start, expected_rdata);
            end
        end
    endtask

    task expect_sender;
        input [8*64-1:0] phase;
        input expected_busy;
        input expected_tx;
        input [7:0] expected_byte;
        begin
            if ({dut.tx_busy, tx_o, dut.uart_tx_inst.data_reg} !==
                {expected_busy, expected_tx, expected_byte}) begin
                errors = errors + 1;
                $display("FAIL: %0s t=%0t cycle=%0d busy/tx/saved=%b/%b/%02h expected=%b/%b/%02h",
                         phase, $time, cycle, dut.tx_busy, tx_o, dut.uart_tx_inst.data_reg,
                         expected_busy, expected_tx, expected_byte);
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        #1;
        expect_bus("after synchronous reset", 1'b0, 1'b0, 32'd0);
        expect_sender("after synchronous reset", 1'b0, 1'b1, 8'd0);
        @(negedge clk);
        rst_n = 1'b1;

        // Cycle 0 is A. Drive at negedge and sample acceptance at posedge.
        for (cycle = 0; cycle <= SECOND_END + 6; cycle = cycle + 1) begin
            @(negedge clk);
            case (cycle)
                0: drive_bus(1'b1, 1'b1, TXDATA, {24'd0, FIRST_BYTE}, 4'b0001);
                1: drive_bus(1'b1, 1'b0, STATUS, 32'd0, 4'b0000);
                2: drive_bus(1'b1, 1'b1, TXDATA + 32'd1, 32'h00005A00, 4'b0010);
                3: drive_bus(1'b1, 1'b1, TXDATA, {24'd0, SECOND_BYTE}, 4'b0001);
                SECOND_ACCEPT + 1: req_i = 1'b0; // Keep payload, withdraw completed request.
                SECOND_END + 1: drive_bus(1'b1, 1'b0, STATUS, 32'd0, 4'b0000);
                SECOND_END + 2: drive_bus(1'b1, 1'b0, TXDATA, 32'd0, 4'b0000);
                SECOND_END + 3: drive_bus(1'b1, 1'b0, RESERVED_8, 32'd0, 4'b0000);
                SECOND_END + 4: drive_bus(1'b1, 1'b1, RESERVED_C, 32'hFFFFFFFF, 4'b1111);
                SECOND_END + 5: req_i = 1'b0;
                default: begin
                    // Hold the complete second-write payload from A+3 through A+41.
                end
            endcase

            @(posedge clk);
            case (cycle)
                0, SECOND_ACCEPT:
                    expect_bus("send write sampled", 1'b1, 1'b1, 32'd0);
                1:  expect_bus("busy STATUS read sampled", 1'b1, 1'b0, 32'd1);
                2:  expect_bus("masked TXDATA write sampled", 1'b1, 1'b0, 32'd0);
                SECOND_END + 1, SECOND_END + 2, SECOND_END + 3, SECOND_END + 4:
                    expect_bus("idle read or ignored access sampled", 1'b1, 1'b0, 32'd0);
                default:
                    expect_bus("waiting or no request at sampling edge", 1'b0, 1'b0, 32'd0);
            endcase
            if (cycle == FIRST_END)
                expect_sender("A+40 before edge: first STOP", 1'b1, 1'b1, FIRST_BYTE);
            if (cycle == SECOND_ACCEPT)
                expect_sender("A+41 before edge: byte still pending", 1'b0, 1'b1, FIRST_BYTE);

            // These are sampled before DUT nonblocking state updates.
            if (req_i === 1'b1 && ready_o === 1'b1)
                bus_completions = bus_completions + 1;
            if (dut.tx_start === 1'b1)
                tx_accepts = tx_accepts + 1;

            #1;
            case (cycle)
                FIRST_END:
                    expect_bus("A+40 after edge: second write offered", 1'b1, 1'b1, 32'd0);
                SECOND_ACCEPT:
                    expect_bus("A+41 after edge: transmitter busy again", 1'b0, 1'b0, 32'd0);
                1:  expect_bus("busy STATUS read response", 1'b1, 1'b0, 32'd1);
                2, SECOND_END + 1, SECOND_END + 2, SECOND_END + 3, SECOND_END + 4:
                    expect_bus("immediate access response", 1'b1, 1'b0, 32'd0);
                default:
                    expect_bus("busy send or idle bus response", 1'b0, 1'b0, 32'd0);
            endcase

            if (cycle < FIRST_END) begin
                expect_sender("first frame sample", 1'b1,
                              FIRST_FRAME[cycle / CLKS_PER_BIT], FIRST_BYTE);
            end else if (cycle == FIRST_END) begin
                // Ready/start are high, but the new byte is saved at A+41.
                expect_sender("A+40 after edge: line still high", 1'b0, 1'b1, FIRST_BYTE);
            end else if (cycle < SECOND_END) begin
                expect_sender("second frame sample", 1'b1,
                              SECOND_FRAME[(cycle - SECOND_ACCEPT) / CLKS_PER_BIT], SECOND_BYTE);
            end else begin
                expect_sender("second frame finished; line idle", 1'b0, 1'b1, SECOND_BYTE);
            end
        end

        if (bus_completions != 8 || tx_accepts != 2) begin
            errors = errors + 1;
            $display("FAIL: bus completions=%0d (expected 8), UART accepts=%0d (expected 2)",
                     bus_completions, tx_accepts);
        end
        if (errors == 0) begin
            $display("PASS: UART TX target checks passed");
            $finish;
        end else begin
            $fatal(1, "FAIL: UART TX target checks failed (%0d errors)", errors);
        end
    end

    initial begin
        #5000;
        $fatal(1, "FAIL: UART TX target timeout at cycle=%0d", cycle);
    end
endmodule

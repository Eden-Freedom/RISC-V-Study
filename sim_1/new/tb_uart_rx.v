`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 20:33:45
// Design Name: 
// Module Name: tb_uart_rx
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


module tb_uart_rx;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg rx_i = 1'b1;
  wire valid_o;
  wire [7:0] data_o;

  reg expected_valid = 1'b0;
  reg [7:0] expected_data = 8'h00;

  uart_rx dut (
      .clk(clk),
      .rst_n(rst_n),
      .rx_i(rx_i),
      .valid_o(valid_o),
      .data_o(data_o)
  );

  always #5 clk = ~clk;

  // Wait for the DUT's nonblocking updates before checking every cycle.
  always @(posedge clk) begin
    #1;
    if (valid_o !== expected_valid || data_o !== expected_data) begin
      $fatal(1, "UART RX at %0t: expected valid=%b data=%02h, got valid=%b data=%02h",
             $time, expected_valid, expected_data, valid_o, data_o);
    end
  end

  task drive_bit;
    input value;
    begin
      @(negedge clk);
      rx_i = value;
      repeat (4) @(posedge clk);
    end
  endtask

  task drive_frame;
    input [7:0] byte_to_send;
    input stop_value;
    integer i;
    begin
      drive_bit(1'b0);
      for (i = 0; i < 8; i = i + 1) begin
        drive_bit(byte_to_send[i]);
      end

      @(negedge clk);
      rx_i = stop_value;
      repeat (2) @(posedge clk);

      // Publish on the third rising edge of a valid stop bit.
      @(negedge clk);
      if (stop_value == 1'b1) begin
        expected_valid = 1'b1;
        expected_data = byte_to_send;
      end
      @(posedge clk);
      @(negedge clk);
      expected_valid = 1'b0;
      @(posedge clk);
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1'b1;

    drive_frame(8'h96, 1'b1);

    // One low cycle ends before the start-bit confirmation edge.
    @(negedge clk);
    rx_i = 1'b0;
    @(negedge clk);
    rx_i = 1'b1;
    repeat (4) @(posedge clk);

    drive_frame(8'hA5, 1'b0);
    drive_bit(1'b1);  // Restore idle after the bad stop bit.

    drive_frame(8'h3C, 1'b1);
    drive_bit(1'b1);

    // Finish after the final rising-edge check has run.
    @(negedge clk);
    $display("PASS: UART RX unit checks passed");
    $finish;
  end

  initial begin
    #5000;
    $fatal(1, "UART RX test timed out");
  end
endmodule

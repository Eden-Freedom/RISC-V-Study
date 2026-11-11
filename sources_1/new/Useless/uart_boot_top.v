`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/06 16:20:23
// Design Name: 
// Module Name: uart_boot_top
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


module uart_boot_top(
    input wire clk,
    input wire rst_n,
    input wire uart_rx_i,
    input wire start_run_i,

    output reg running_o,
    output wire [31:0] fetch_addr_o
);

    wire cpu_rst_n;
    wire store_rst_n;
    wire [31:0] fetched_instr;

    always @(posedge clk) begin
        if (!rst_n) begin
            running_o <= 1'b0;
        end
        else if (start_run_i) begin
            running_o <= 1'b1;
        end
    end

    assign cpu_rst_n = rst_n && running_o;
    assign store_rst_n = rst_n && !running_o;

    uart_program_store uart_program_store_inst (
        .clk(clk),
        .rst_n(store_rst_n),
        .uart_rx_i(uart_rx_i),
        .fetch_addr_i(fetch_addr_o),
        .instr_o(fetched_instr),
        .full_o()
    );

    pipeline_core #(
        .USE_EXTERNAL_PROGRAM(1'b1)
    ) pipeline_core_inst (
        .clk               (clk),
        .rst_n             (cpu_rst_n),
        .irq_external_i    (1'b0),
        .dev2bus_ready_i   (1'b1),
        .dev2bus_rdata_i   (32'd0),
        .external_instr_i  (fetched_instr),
        .fetch_addr_o      (fetch_addr_o),
        .bus2dev_req_o     (),
        .bus2dev_we_o      (),
        .bus2dev_addr_o    (),
        .bus2dev_wdata_o   (),
        .bus2dev_wstrb_o   ()
    );
    
endmodule

`timescale 1ns / 1ps
module imem(input wire [31:0] addr_i, output reg [31:0] instr_o);
    // CPU program for tb_uart_rx_system.
    always @(*) begin
        case (addr_i)
            32'h00: instr_o = 32'h100000B7; // LUI  x1,0x10000
            32'h04: instr_o = 32'h0240A103; // LW   x2,36(x1): poll STATUS
            32'h08: instr_o = 32'h00217193; // ANDI x3,x2,2
            32'h0C: instr_o = 32'hFE018CE3; // BEQ  x3,x0,-8: go back to PC 04
            32'h10: instr_o = 32'h0280C203; // LBU  x4,40(x1): consume RXDATA
            32'h14: instr_o = 32'h00408023; // SB   x4,0(x1): update GPIO
            32'h18: instr_o = 32'h0240A283; // LW   x5,36(x1): empty STATUS
            32'h1C: instr_o = 32'h0280A303; // LW   x6,40(x1): empty RXDATA
            32'h20: instr_o = 32'h0000006F; // JAL  x0,0: done
            default: instr_o = 32'h00000000;
        endcase
    end
endmodule

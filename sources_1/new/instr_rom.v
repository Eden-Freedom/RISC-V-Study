`timescale 1ns / 1ps
module instr_rom(input wire [31:0] addr_i, output reg [31:0] instr_o);
    // CPU program for tb_spi_system.
    always @(*) begin
        case (addr_i)
            32'h00: instr_o = 32'h100000B7; // LUI  x1,0x10000
            32'h04: instr_o = 32'h09600113; // ADDI x2,x0,0x96
            32'h08: instr_o = 32'h0A600193; // ADDI x3,x0,0xA6
            32'h0C: instr_o = 32'h02208823; // SB   x2,48(x1): start 96
            32'h10: instr_o = 32'h0340A203; // LW   x4,52(x1): busy STATUS
            32'h14: instr_o = 32'h02308823; // SB   x3,48(x1): wait, then start A6
            32'h18: instr_o = 32'h0340A283; // LW   x5,52(x1): poll STATUS
            32'h1C: instr_o = 32'h0022F313; // ANDI x6,x5,2
            32'h20: instr_o = 32'hFE030CE3; // BEQ  x6,x0,-8: go back to PC 18
            32'h24: instr_o = 32'h0380C383; // LBU  x7,56(x1): read RXDATA
            32'h28: instr_o = 32'h00708023; // SB   x7,0(x1): update GPIO
            32'h2C: instr_o = 32'h0000006F; // JAL  x0,0: done
            default: instr_o = 32'h00000000;
        endcase
    end
endmodule

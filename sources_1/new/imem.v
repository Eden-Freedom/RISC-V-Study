`timescale 1ns / 1ps
module imem(input wire [31:0] addr_i, output reg [31:0] instr_o);
// tb_gpio_system program: CPU -> data_bus -> actual GPIO target.
// The GPIO register layout is a convention of this teaching system.
always @(*) begin
    case (addr_i)
        32'h00: instr_o = 32'h100000B7; // LUI x1,0x10000: GPIO base
        32'h04: instr_o = 32'h0A500113; // ADDI x2,x0,0xA5
        32'h08: instr_o = 32'h0020A023; // SW x2,0(x1): GPIO becomes A5
        32'h0C: instr_o = 32'h0000A183; // LW x3,0(x1): read A5
        32'h10: instr_o = 32'h00118213; // ADDI x4,x3,1: adjacent load consumer
        32'h14: instr_o = 32'h00402023; // SW x4,0(x0): RAM[0] becomes A6
        32'h18: instr_o = 32'h03C00293; // ADDI x5,x0,0x3C
        32'h1C: instr_o = 32'h005080A3; // SB x5,1(x1): second byte, GPIO unchanged
        32'h20: instr_o = 32'h0000A303; // LW x6,0(x1): still A5
        32'h24: instr_o = 32'h00508023; // SB x5,0(x1): low byte, GPIO becomes 3C
        32'h28: instr_o = 32'h0000C383; // LBU x7,0(x1): read 3C
        32'h2C: instr_o = 32'h0020A223; // SW x2,4(x1): reserved word, ignored
        32'h30: instr_o = 32'h0040A403; // LW x8,4(x1): reserved word returns zero
        32'h34: instr_o = 32'h00002483; // LW x9,0(x0): RAM still A6
        32'h38: instr_o = 32'h0000006F; // JAL x0,0: finish on first retirement
        default: instr_o = 32'h00000000;
    endcase
end
endmodule
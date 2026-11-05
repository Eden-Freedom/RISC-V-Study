`timescale 1ns / 1ps
module imem(input wire [31:0] addr_i, output reg [31:0] instr_o);
// Timer-generated request -> existing machine-external CPU entry (cause 8000000B).
// Device layout and handler GPR choices are conventions of this test program.
always @(*) begin
    case (addr_i)
        32'h000: instr_o=32'h100000B7; // LUI x1,0x10000
        32'h004: instr_o=32'h10000113; // ADDI x2,x0,0x100
        32'h008: instr_o=32'h30511073; // CSRRW x0,mtvec,x2
        32'h00C: instr_o=32'h00100193; // ADDI x3,x0,1
        32'h010: instr_o=32'h00B19193; // SLLI x3,x3,11
        32'h014: instr_o=32'h30419073; // CSRRW x0,mie,x3; global MIE stays closed
        32'h018: instr_o=32'h00300213; // ADDI x4,x0,3
        32'h01C: instr_o=32'h0040AA23; // SW x4,20(x1): Timer LIMIT=3
        32'h020: instr_o=32'h00700293; // ADDI x5,x0,7
        32'h024: instr_o=32'h0050A823; // SW x5,16(x1): Timer clear/start, device IRQ enabled
        32'h028: instr_o=32'h00402023; // SW x4,0(x0): Timer counts during RAM wait
        32'h02C: instr_o=32'h00900313; // ADDI x6,x0,9: Timer expires after this edge
        32'h030: instr_o=32'h01C0A383; // LW x7,28(x1): STATUS=1, not required to generate IRQ
        32'h034: instr_o=32'h00800413; // ADDI x8,x0,8
        32'h038: instr_o=32'h30041073; // CSRRW x0,mstatus,x8: open global MIE
        32'h03C: instr_o=32'h05500493; // ADDI x9,x0,0x55: execute only after MRET
        32'h040: instr_o=32'h0100A503; // LW x10,16(x1): cleared Timer CTRL=0
        32'h044: instr_o=32'h0180A583; // LW x11,24(x1): cleared Timer COUNT=0
        32'h048: instr_o=32'h0000A603; // LW x12,0(x1): GPIO=3C
        32'h04C: instr_o=32'h00002683; // LW x13,0(x0): RAM[0]=3
        32'h050: instr_o=32'h0000006F; // JAL x0,0: finish on first completion
        32'h054: instr_o=32'h00508023; // Wrong path: must not change GPIO to 7
        32'h100: instr_o=32'h001A0A13; // ADDI x20,x20,1: handler entry counter
        32'h104: instr_o=32'h34102AF3; // CSRRS x21,mepc,x0: expected 3C
        32'h108: instr_o=32'h34202B73; // CSRRS x22,mcause,x0: expected 8000000B
        32'h10C: instr_o=32'h00200B93; // ADDI x23,x0,2
        32'h110: instr_o=32'h0170A823; // SW x23,16(x1): clear/disable Timer, withdraw IRQ
        32'h114: instr_o=32'h03C00C13; // ADDI x24,x0,0x3C
        32'h118: instr_o=32'h01808023; // SB x24,0(x1): GPIO marker
        32'h11C: instr_o=32'h30200073; // MRET to 3C
        32'h120: instr_o=32'h00508023; // Wrong path after MRET: must not execute
        default: instr_o=32'h00000000;
    endcase
end
endmodule

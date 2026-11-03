`timescale 1ns / 1ps
module imem(input wire [31:0] addr_i, output reg [31:0] instr_o);
// tb_irq_pipeline program. Handler counts entries and returns without mepc+4.
always @(*) begin
    case (addr_i)
        32'h00: instr_o=32'h10000093; // ADDI x1,x0,0x100
        32'h04: instr_o=32'h30509073; // CSRRW x0,mtvec,x1
        32'h08: instr_o=32'h00100113; // ADDI x2,x0,1
        32'h0C: instr_o=32'h00B11113; // SLLI x2,x2,11
        32'h10: instr_o=32'h30411073; // CSRRW x0,mie,x2
        32'h14: instr_o=32'h00800193; // ADDI x3,x0,8
        32'h18: instr_o=32'h30019073; // CSRRW x0,mstatus,x3
        32'h1C: instr_o=32'h30047073; // CSRRCI x0,mstatus,8
        32'h20: instr_o=32'h340AD073; // CSRRWI x0,mscratch,21
        32'h24: instr_o=32'h30046073; // CSRRSI x0,mstatus,8
        32'h28: instr_o=32'h00700293; // ADDI x5,x0,7
        32'h2C: instr_o=32'h0140006F; // JAL x0,+0x14 -> 0x40
        32'h30: instr_o=32'h00000000; // Wrong path: unrecognized encoding
        32'h34: instr_o=32'h340FD073; // Wrong path: CSRRWI x0,mscratch,31
        32'h40: instr_o=32'h06400313; // ADDI x6,x0,100
        32'h44: instr_o=32'h00300393; // ADDI x7,x0,3
        32'h48: instr_o=32'h02734433; // DIV x8,x6,x7
        32'h4C: instr_o=32'h00140493; // ADDI x9,x8,1
        32'h50: instr_o=32'hFB1FF06F; // JAL x0,-0x50 -> 0
        32'h100: instr_o=32'h001A0A13; // ADDI x20,x20,1
        32'h104: instr_o=32'h34102AF3; // CSRRS x21,mepc,x0
        32'h108: instr_o=32'h30200073; // MRET
        32'h10C: instr_o=32'h00000000; // Wrong return path
        32'h110: instr_o=32'h340FD073; // Wrong path: CSRRWI x0,mscratch,31
        default: instr_o=32'h00000000;
    endcase
end
endmodule

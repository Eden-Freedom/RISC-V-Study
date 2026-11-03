`timescale 1ns / 1ps
module imem(input wire [31:0] addr_i, output reg [31:0] instr_o);
// tb_data_handshake program. Instruction fetch remains independent of data RAM.
always @(*) begin
    case(addr_i)
        32'h0: instr_o=32'h10000E13; // ADDI x28,x0,0x100
        32'h4: instr_o=32'h305E1073; // CSRRW x0,mtvec,x28
        32'h8: instr_o=32'h00100E93; // ADDI x29,x0,1
        32'hC: instr_o=32'h00BE9E93; // SLLI x29,x29,11
        32'h10: instr_o=32'h304E9073; // CSRRW x0,mie,x29
        32'h14: instr_o=32'h00800F13; // ADDI x30,x0,8
        32'h18: instr_o=32'h300F1073; // CSRRW x0,mstatus,x30
        32'h1C: instr_o=32'h05500093; // ADDI x1,x0,0x55
        32'h20: instr_o=32'h00102023; // SW x1,0(x0)
        32'h24: instr_o=32'h00002103; // LW x2,0(x0): IRQ after preparation edge
        32'h28: instr_o=32'h00110193; // ADDI x3,x2,1
        32'h2C: instr_o=32'h00302223; // SW x3,4(x0)
        32'h30: instr_o=32'h08000213; // ADDI x4,x0,0x80
        32'h34: instr_o=32'h004000A3; // SB x4,1(x0)
        32'h38: instr_o=32'h00100283; // LB x5,1(x0)
        32'h3C: instr_o=32'h00104303; // LBU x6,1(x0)
        32'h40: instr_o=32'h000083B7; // LUI x7,0x8
        32'h44: instr_o=32'h12338393; // ADDI x7,x7,0x123
        32'h48: instr_o=32'h00701123; // SH x7,2(x0)
        32'h4C: instr_o=32'h00201403; // LH x8,2(x0)
        32'h50: instr_o=32'h00205483; // LHU x9,2(x0)
        32'h54: instr_o=32'h00002503; // LW x10,0(x0)
        32'h58: instr_o=32'h00A02423; // SW x10,8(x0): adjacent load consumer
        32'h5C: instr_o=32'h08000593; // ADDI x11,x0,0x80
        32'h60: instr_o=32'h0035A023; // SW x3,0(x11): unmapped
        32'h64: instr_o=32'h0005A603; // LW x12,0(x11): unmapped zero
        32'h68: instr_o=32'h00160693; // ADDI x13,x12,1
        32'h6C: instr_o=32'h00402703; // LW x14,4(x0)
        32'h70: instr_o=32'h0000006F; // JAL x0,0: finish at first submission
        32'h74: instr_o=32'h00302023; // WRONG PATH: SW x3,0(x0)
        32'h100: instr_o=32'h001A0A13; // ADDI x20,x20,1
        32'h104: instr_o=32'h34102AF3; // CSRRS x21,mepc,x0
        32'h108: instr_o=32'h30200073; // MRET: no mepc increment
        32'h10C: instr_o=32'h00000000; // WRONG PATH: unrecognized encoding
        32'h110: instr_o=32'h00302023; // WRONG PATH: SW x3,0(x0)
        default: instr_o=32'h00000000;
    endcase
end
endmodule


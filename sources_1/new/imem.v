`timescale 1ns / 1ps
module imem(input wire [31:0] addr_i, output reg [31:0] instr_o);
// CPU program for tb_uart_tx_system. Timer remains disabled.
always @(*) begin
    case (addr_i)
        32'h00: instr_o = 32'h100000B7; // LUI x1,0x10000: device address reference
        32'h04: instr_o = 32'h03C00113; // ADDI x2,x0,0x3C
        32'h08: instr_o = 32'h00208023; // SB x2,0(x1): GPIO output = 3C
        32'h0C: instr_o = 32'h00300193; // ADDI x3,x0,3
        32'h10: instr_o = 32'h0030AA23; // SW x3,20(x1): Timer LIMIT = 3
        32'h14: instr_o = 32'h05500213; // ADDI x4,x0,0x55
        32'h18: instr_o = 32'h0A600293; // ADDI x5,x0,0xA6
        32'h1C: instr_o = 32'h02408023; // SB x4,32(x1): UART accepts 55 at A
        32'h20: instr_o = 32'h0240A303; // LW x6,36(x1): STATUS while frame 1 is busy
        32'h24: instr_o = 32'h02508023; // SB x5,32(x1): UART waits, then accepts A6
        32'h28: instr_o = 32'h0240A383; // LW x7,36(x1): STATUS while frame 2 is busy
        32'h2C: instr_o = 32'h0000A403; // LW x8,0(x1): GPIO reads 3C
        32'h30: instr_o = 32'h0140A483; // LW x9,20(x1): Timer LIMIT reads 3
        32'h34: instr_o = 32'h00202023; // SW x2,0(x0): RAM[0] = 3C
        32'h38: instr_o = 32'h00002503; // LW x10,0(x0): RAM reads 3C
        32'h3C: instr_o = 32'h02F0C583; // LBU x11,47(x1): UART last byte, result zero
        32'h40: instr_o = 32'h0300A603; // LW x12,48(x1): unmapped, result zero
        32'h44: instr_o = 32'h0000006F; // JAL x0,0: program completion marker
        default: instr_o = 32'h00000000;
    endcase
end
endmodule

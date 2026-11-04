`timescale 1ns / 1ps
module imem(input wire [31:0] addr_i, output reg [31:0] instr_o);
// tb_data_bus_system program. DEV addresses are this teaching system's convention.
always @(*) begin
    case (addr_i)
        32'h00: instr_o = 32'h03500093; // ADDI x1,x0,0x35
        32'h04: instr_o = 32'h00102023; // SW x1,0(x0)
        32'h08: instr_o = 32'h00002103; // LW x2,0(x0)
        32'h0C: instr_o = 32'h100001B7; // LUI x3,0x10000 -> 0x10000000
        32'h10: instr_o = 32'h0021A223; // SW x2,4(x3): DEV write
        32'h14: instr_o = 32'h0041A203; // LW x4,4(x3): DEV read
        32'h18: instr_o = 32'h00120293; // ADDI x5,x4,1: adjacent load consumer
        32'h1C: instr_o = 32'h00502223; // SW x5,4(x0)
        32'h20: instr_o = 32'h08002303; // LW x6,128(x0): unmapped zero
        32'h24: instr_o = 32'h08102023; // SW x1,128(x0): unmapped ignored
        32'h28: instr_o = 32'h00402383; // LW x7,4(x0)
        32'h2C: instr_o = 32'h0000006F; // JAL x0,0: finish on first retirement
        default: instr_o = 32'h00000000;
    endcase
end
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 16:04:51
// Design Name: 
// Module Name: tb_if_id
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


module tb_if_id();

    reg clk;
    reg rst_n;
    reg valid_i;
    reg [31:0] pc_ifid_i;
    reg [31:0] instr_ifid_i;
    wire valid_o;
    wire [31:0] pc_ifid_o;
    wire [31:0] instr_ifid_o;

    integer errors;


    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        valid_i = 1'b0;
        pc_ifid_i = 32'h0;
        instr_ifid_i = 32'h0;
        #25
        rst_n = 1'b1;
        #5
        valid_i = 1'b0;
        pc_ifid_i = 32'h0;
        instr_ifid_i = 32'h0;
        #10
        valid_i = 1'b1;
        pc_ifid_i = 32'h00000000;
        instr_ifid_i = 32'h04000093;
        #20
        valid_i = 1'b1;
        pc_ifid_i = 32'h00000004;
        instr_ifid_i = 32'hF8000193;
        #20
        valid_i = 1'b0;
        pc_ifid_i = 32'h00000008;
        instr_ifid_i = 32'h0020A023;
        #20
        valid_i = 1'b1;
        pc_ifid_i = 32'h0000000C;
        instr_ifid_i = 32'h0000A203;
    end

    always #10 clk = ~clk;

    initial begin
        errors = 0;

    // 等待复位结束，再给短程序留出执行时间
    wait (rst_n === 1'b1);
    #26//51ns的时候
    if (valid_o !== 1'b1) begin
        $display("FAIL valid_o: actual=%b expected=%b",
                 valid_o,
                 1'b1);
        errors = errors + 1;
    end
    if (pc_ifid_o !== 32'h00000000) begin
        $display("FAIL pc_ifid_o: actual=%h expected=%h",
                 pc_ifid_o,
                 32'h00000000);
        errors = errors + 1;
    end
    if (instr_ifid_o !== 32'h04000093) begin
        $display("FAIL instr_ifid_o: actual=%h expected=%h",
                 instr_ifid_o,
                 32'h04000093);
        errors = errors + 1;
    end

    #10//61ns的时候
    if (valid_o !== 1'b1) begin
        $display("FAIL valid_o: actual=%b expected=%b",
                 valid_o,
                 1'b1);
        errors = errors + 1;
    end
    if (pc_ifid_o !== 32'h00000000) begin
        $display("FAIL pc_ifid_o: actual=%h expected=%h",
                 pc_ifid_o,
                 32'h00000000);
        errors = errors + 1;
    end
    if (instr_ifid_o !== 32'h04000093) begin
        $display("FAIL instr_ifid_o: actual=%h expected=%h",
                 instr_ifid_o,
                 32'h04000093);
        errors = errors + 1;
    end

    #10//71ns的时候
    if (valid_o !== 1'b1) begin
        $display("FAIL valid_o: actual=%b expected=%b",
                 valid_o,
                 1'b1);
        errors = errors + 1;
    end
    if (pc_ifid_o !== 32'h00000004) begin
        $display("FAIL pc_ifid_o: actual=%h expected=%h",
                 pc_ifid_o,
                 32'h00000004);
        errors = errors + 1;
    end
    if (instr_ifid_o !== 32'hF8000193) begin
        $display("FAIL instr_ifid_o: actual=%h expected=%h",
                 instr_ifid_o,
                 32'hF8000193);
        errors = errors + 1;
    end

    #10//81ns的时候
    if (valid_o !== 1'b1) begin
        $display("FAIL valid_o: actual=%b expected=%b",
                 valid_o,
                 1'b1);
        errors = errors + 1;
    end
    if (pc_ifid_o !== 32'h00000004) begin
        $display("FAIL pc_ifid_o: actual=%h expected=%h",
                 pc_ifid_o,
                 32'h00000004);
        errors = errors + 1;
    end
    if (instr_ifid_o !== 32'hF8000193) begin
        $display("FAIL instr_ifid_o: actual=%h expected=%h",
                 instr_ifid_o,
                 32'hF8000193);
        errors = errors + 1;
    end    

    #10//91ns的时候
    if (valid_o !== 1'b0) begin
        $display("FAIL valid_o: actual=%b expected=%b",
                 valid_o,
                 1'b0);
        errors = errors + 1;
    end
    if (pc_ifid_o !== 32'h00000008) begin
        $display("FAIL pc_ifid_o: actual=%h expected=%h",
                 pc_ifid_o,
                 32'h00000008);
        errors = errors + 1;
    end
    if (instr_ifid_o !== 32'h0020A023) begin
        $display("FAIL instr_ifid_o: actual=%h expected=%h",
                 instr_ifid_o,
                 32'h0020A023);
        errors = errors + 1;
    end

    #10//101ns的时候
    if (valid_o !== 1'b0) begin
        $display("FAIL valid_o: actual=%b expected=%b",
                 valid_o,
                 1'b0);
        errors = errors + 1;
    end
    if (pc_ifid_o !== 32'h00000008) begin
        $display("FAIL pc_ifid_o: actual=%h expected=%h",
                 pc_ifid_o,
                 32'h00000008);
        errors = errors + 1;
    end
    if (instr_ifid_o !== 32'h0020A023) begin
        $display("FAIL instr_ifid_o: actual=%h expected=%h",
                 instr_ifid_o,
                 32'h0020A023);
        errors = errors + 1;
    end

    #10//111ns的时候
    if (valid_o !== 1'b1) begin
        $display("FAIL valid_o: actual=%b expected=%b",
                 valid_o,
                 1'b1);
        errors = errors + 1;
    end
    if (pc_ifid_o !== 32'h0000000C) begin
        $display("FAIL pc_ifid_o: actual=%h expected=%h",
                 pc_ifid_o,
                 32'h0000000C);
        errors = errors + 1;
    end
    if (instr_ifid_o !== 32'h0000A203) begin
        $display("FAIL instr_ifid_o: actual=%h expected=%h",
                 instr_ifid_o,
                 32'h0000A203);
        errors = errors + 1;
    end

    #10//121ns的时候
    if (valid_o !== 1'b1) begin
        $display("FAIL valid_o: actual=%b expected=%b",
                 valid_o,
                 1'b1);
        errors = errors + 1;
    end
    if (pc_ifid_o !== 32'h0000000C) begin
        $display("FAIL pc_ifid_o: actual=%h expected=%h",
                 pc_ifid_o,
                 32'h0000000C);
        errors = errors + 1;
    end
    if (instr_ifid_o !== 32'h0000A203) begin
        $display("FAIL instr_ifid_o: actual=%h expected=%h",
                 instr_ifid_o,
                 32'h0000A203);
        errors = errors + 1;
    end
    
    #10//131ns的时候

    if (errors == 0) begin
        $display("PASS: all checks passed");
    end else begin
        $display("FAIL: %0d checks failed", errors);
    end

    $finish;
end




    if_id u_if_id(
        .clk(clk),
        .rst_n(rst_n),
        .valid_i(valid_i),
        .pc_ifid_i(pc_ifid_i),
        .instr_ifid_i(instr_ifid_i),
        .valid_o(valid_o),
        .pc_ifid_o(pc_ifid_o),
        .instr_ifid_o(instr_ifid_o)
    );
endmodule

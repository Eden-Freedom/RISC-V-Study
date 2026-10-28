`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/23 19:32:44
// Design Name: 
// Module Name: tb_check
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


module tb_check();

reg clk;
reg rst_n;

integer errors;

//---------------------------------------------------------------
// 时钟：上升沿在 10/30/50/...，下降沿在 20/40/60/...
//---------------------------------------------------------------
initial clk = 1'b0;
always #10 clk = ~clk;

    //---------------------------------------------------------------
    // 检查：reg_file 数组（仅用于 x1..x31；不能用于 x0）
    //---------------------------------------------------------------
task check_regfile;
input [4:0]  idx;
input [31:0] exp_val;
begin
    if (u_pipeline_core.regfile_inst.reg_file[idx] !== exp_val) begin
        $display("FAIL [%0t] x%0d: actual=%h expected=%h",
                 $time, idx,
                 u_pipeline_core.regfile_inst.reg_file[idx], exp_val);
        errors = errors + 1;
    end
end
endtask


task check_idex;
input [31:0] rs1_data_idex_o_exp_val;
begin
    if (u_pipeline_core.rs1_data_idex_o !== rs1_data_idex_o_exp_val) begin
        $display("FAIL [%0t] rs1_data_idex_o: actual=%h expected=%h",
                 $time,
                 u_pipeline_core.rs1_data_idex_o, rs1_data_idex_o_exp_val);
        errors = errors + 1;
    end
end
endtask

task check_ex;
input  wr_en_ex_o_exp_val;
    input [4:0] wr_addr_ex_o_exp_val;
    input [31:0] wr_data_ex_o_exp_val;
    begin

        if(u_pipeline_core.wr_en_ex_o !== wr_en_ex_o_exp_val) begin
            $display("FAIL [%0t] wr_en_ex_o: actual=%h expected=%h",
                     $time,
                     u_pipeline_core.wr_en_ex_o, wr_en_ex_o_exp_val);
            errors = errors + 1;
        end
        if (u_pipeline_core.wr_addr_ex_o !== wr_addr_ex_o_exp_val) begin
            $display("FAIL [%0t] wr_addr_ex_o: actual=%h expected=%h",
                     $time,
                     u_pipeline_core.wr_addr_ex_o, wr_addr_ex_o_exp_val);
            errors = errors + 1;
        end
        if (u_pipeline_core.wr_data_ex_o !== wr_data_ex_o_exp_val) begin
            $display("FAIL [%0t] wr_data_ex_o: actual=%h expected=%h",
                     $time,
                     u_pipeline_core.wr_data_ex_o, wr_data_ex_o_exp_val);
            errors = errors + 1;
        end
    end
endtask


task check_x0_read_ports;
begin
    if (u_pipeline_core.regfile_inst.rs1_addr_i !== 5'd0) begin
        $display("FAIL [%0t] rs1_addr_i: actual=%h expected=%h (must be 0 to verify x0 read)",
                 $time, u_pipeline_core.regfile_inst.rs1_addr_i, 5'd0);
        errors = errors + 1;
    end
    if (u_pipeline_core.regfile_inst.rs1_data_o !== 32'h0) begin
        $display("FAIL [%0t] rs1_data_o: actual=%h expected=%h (x0 read port)",
                 $time, u_pipeline_core.regfile_inst.rs1_data_o, 32'h0);
        errors = errors + 1;
    end
    if (u_pipeline_core.regfile_inst.rs2_addr_i !== 5'd0) begin
        $display("FAIL [%0t] rs2_addr_i: actual=%h expected=%h (must be 0 to verify x0 read)",
                 $time, u_pipeline_core.regfile_inst.rs2_addr_i, 5'd0);
        errors = errors + 1;
    end
    if (u_pipeline_core.regfile_inst.rs2_data_o !== 32'h0) begin
        $display("FAIL [%0t] rs2_data_o: actual=%h expected=%h (x0 read port)",
                 $time, u_pipeline_core.regfile_inst.rs2_data_o, 32'h0);
        errors = errors + 1;
    end
end
endtask

task check_valid;
input valid_ifid_exp_val;
input valid_idex_exp_val;
begin
    if (u_pipeline_core.valid_ifid_o !== valid_ifid_exp_val) begin
        $display("FAIL [%0t] valid_ifid_o: actual=%h expected=%h",
                 $time, u_pipeline_core.valid_ifid_o, valid_ifid_exp_val);
        errors = errors + 1;
    end
    if (u_pipeline_core.valid_idex_o !== valid_idex_exp_val) begin
        $display("FAIL [%0t] valid_idex_o: actual=%h expected=%h",
                 $time, u_pipeline_core.valid_idex_o, valid_idex_exp_val);
        errors = errors + 1;
    end
end
endtask

//---------------------------------------------------------------
    // 激励与沿后检查
    //---------------------------------------------------------------
initial begin
    rst_n  = 1'b0;
    errors = 0;

    // t=15ns：复位期间
    #15;

    check_ex(1'b0,5'h0,32'h0000_0000);


    // t=25ns：释放复位
    #10;
    rst_n = 1'b1;

    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    @(posedge clk);#1;
    check_regfile(5'd1,32'd8);
    check_regfile(5'd2,32'd9);
    check_regfile(5'd3,32'd55);
    check_regfile(5'd5,32'd17);
    check_regfile(5'd6,32'd33);

    



    if (errors == 0) begin
        $display("PASS: all checks passed");
    end else begin
        $display("FAIL: %0d checks failed", errors);
    end
    $finish;
end

//---------------------------------------------------------------
// DUT
//---------------------------------------------------------------
pipeline_core u_pipeline_core(
    .clk  (clk),
    .rst_n(rst_n)
);


endmodule

`timescale 1ns / 1ps
// 固定等待RAM目标的独立自检；不驱动或force任何内部状态。
module tb_data_ram_target();
reg clk = 1'b0;
always #10 clk = ~clk;
reg rst_n, req_i, we_i;
reg [31:0] addr_i, wdata_i;
reg [3:0] wstrb_i;
wire ready_o;
wire [31:0] rdata_o;
reg [31:0] expected_ram [0:31];
integer errors, test_id, expected_completions, observed_completions, n;

data_ram_target u_target(
    .clk(clk), .rst_n(rst_n), .req_i(req_i), .we_i(we_i),
    .addr_i(addr_i), .wdata_i(wdata_i), .wstrb_i(wstrb_i),
    .ready_o(ready_o), .rdata_o(rdata_o)
);

// 在接收沿计数。复位取消不算一次完成；计数跨复位保留作为TB统计。
always @(posedge clk) begin
    if (rst_n === 1'b1 && req_i === 1'b1 && ready_o === 1'b1)
        observed_completions <= observed_completions + 1;
end

task check;
input [8*80-1:0] item;
input [31:0] actual, expected;
begin
    if (actual !== expected) begin
        $display("FAIL t=%0t test=%0d %0s actual=%h expected=%h",
                 $time,test_id,item,actual,expected);
        errors=errors+1;
    end
end
endtask

task check_ram;
integer word_index;
begin
    for (word_index=0;word_index<32;word_index=word_index+1)
        if (u_target.data_ram_inst.memory[word_index] !== expected_ram[word_index]) begin
            $display("FAIL t=%0t test=%0d RAM[%0d]=%h expected=%h",$time,test_id,
                     word_index,u_target.data_ram_inst.memory[word_index],expected_ram[word_index]);
            errors=errors+1;
        end
end
endtask

task check_phase;
input exp_ready, exp_done, exp_write, exp_read;
input [31:0] exp_data;
begin
    check("ready",{31'b0,ready_o},{31'b0,exp_ready});
    check("pending",{31'b0,u_target.pending_reg},{31'b0,exp_ready});
    check("completion condition (done)",{31'b0,u_target.done},{31'b0,exp_done});
    check("RAM write enable",{31'b0,u_target.ram_wr_en},{31'b0,exp_write});
    check("RAM read enable",{31'b0,u_target.ram_rd_en},{31'b0,exp_read});
    check("RAM write enable pin",{31'b0,u_target.data_ram_inst.ram_wr_en_i},{31'b0,exp_write});
    check("RAM read enable pin",{31'b0,u_target.data_ram_inst.ram_rd_en_i},{31'b0,exp_read});
    check("rdata",rdata_o,exp_data);
end
endtask

// 无请求时刻意保留命中地址、写类型、全字节掩码和非零写数据。
// 若缺少req门控，会改坏RAM；每个空闲沿都检查内容及完成计数保持。
task idle_cycles;
input integer cycles;
integer c;
begin
    @(negedge clk);
    req_i=0; we_i=1; addr_i=0; wdata_i=32'hFFFFFFFF; wstrb_i=4'b1111;
    #1;
    check_phase(0,0,0,0,0);
    check_ram;
    for (c=0;c<cycles;c=c+1) begin
        @(posedge clk);
        check_phase(0,0,0,0,0);
        #1;
        check_phase(0,0,0,0,0);
        check_ram;
        check("no extra completion while idle",observed_completions,expected_completions);
    end
end
endtask

// 每笔访问固定经历A准备沿、B完成沿。task结束在B之后#1，
// req仍为1；调用者在后续负沿撤销，或由下次task直接切换负载。
// exp_word_after / exp_read_word均由测试流程显式给定，不复制DUT结果。
task access_target;
input write_access;
input [31:0] address, write_data;
input [3:0] byte_mask;
input mapped;
input [31:0] exp_word_after, exp_read_word;
begin
    test_id=test_id+1;
    @(negedge clk);
    req_i=1; we_i=write_access; addr_i=address;
    wdata_i=write_data; wstrb_i=byte_mask;
    #1; // 请求已经给出，但沿A还未发生。
    check_phase(0,0,0,0,0);
    check_ram;
    check("no completion before A",observed_completions,expected_completions);
    check("write address index",{27'b0,u_target.data_ram_inst.ram_wr_addr_i},{27'b0,address[6:2]});
    check("read address index",{27'b0,u_target.data_ram_inst.ram_rd_addr_i},{27'b0,address[6:2]});
    check("write data connection",u_target.data_ram_inst.ram_wr_data_i,write_data);
    check("byte mask connection",{28'b0,u_target.data_ram_inst.ram_wr_sel_i},{28'b0,byte_mask});

    @(posedge clk); // 沿A的Active区：仍未完成。
    check_phase(0,0,0,0,0);
    #1;
    // 沿A之后写使能可能已经为1，但写入尚未发生。
    check_phase(1,1,mapped && write_access,mapped && !write_access,exp_read_word);
    check_ram;
    check("A only prepares",observed_completions,expected_completions);

    @(posedge clk); // 沿B前：读数据要在这里检查，不能等B之后。
    check_phase(1,1,mapped && write_access,mapped && !write_access,exp_read_word);
    check_ram;
    check("request held until B",{31'b0,req_i},32'd1);
    check("write type held until B",{31'b0,we_i},{31'b0,write_access});
    check("address held until B",addr_i,address);
    check("write data held until B",wdata_i,write_data);
    check("byte mask held until B",{28'b0,wstrb_i},{28'b0,byte_mask});
    if (mapped && write_access) expected_ram[address[6:2]]=exp_word_after;
    expected_completions=expected_completions+1;
    #1;
    // 沿B后pending清零，读结果也回零，RAM才呈现新状态。
    check_phase(0,0,0,0,0);
    check_ram;
    check("one completion per access",observed_completions,expected_completions);
end
endtask

initial begin
    errors=0; test_id=0; expected_completions=0; observed_completions=0;
    rst_n=0; req_i=0; we_i=0; addr_i=0; wdata_i=0; wstrb_i=0;
    for (n=0;n<32;n=n+1) expected_ram[n]=0;
    #15; // 已经过第一个同步复位上升沿。
    check_phase(0,0,0,0,0);
    check_ram;
    @(negedge clk); rst_n=1;
    idle_cycles(2);

    // 地址0全字写入、读回。
    access_target(1,32'h0,32'h11223344,4'b1111,1,32'h11223344,0);
    idle_cycles(2);
    access_target(0,32'h0,0,4'b0000,1,0,32'h11223344);
    idle_cycles(1);

    // 地址3只修改最高字节；读取仍返回整个RAM字。
    access_target(1,32'h3,32'hAA000000,4'b1000,1,32'hAA223344,0);
    idle_cycles(1);
    access_target(0,32'h3,0,4'b0000,1,0,32'hAA223344);
    idle_cycles(1);

    // 未映射读写同样完成握手，写不能破坏非零RAM[0]。
    access_target(1,32'h80,32'hFFFFFFFF,4'b1111,0,0,0);
    idle_cycles(2);
    access_target(0,32'h80,0,4'b0000,0,0,0);
    idle_cycles(1);

    // 最后一个字节：目标不再移动写数据，也不截取读取结果。
    access_target(1,32'h7F,32'h55000000,4'b1000,1,32'h55000000,0);
    idle_cycles(1);
    access_target(0,32'h7F,0,4'b0000,1,0,32'h55000000);
    idle_cycles(1);

    // 不拉低req：每次完成后，在负沿直接换下一笔负载。
    // 每个access_target仍核对新的A/B两沿，不能每沿都完成。
    access_target(1,32'h4,32'hDEADBEEF,4'b1111,1,32'hDEADBEEF,0);
    access_target(0,32'h4,0,4'b0000,1,0,32'hDEADBEEF);
    access_target(1,32'h8,32'h01020304,4'b1111,1,32'h01020304,0);
    access_target(0,32'h8,0,4'b0000,1,0,32'h01020304);
    idle_cycles(3);

    // 准备后、完成前复位：保留请求和负载到复位沿，
    // 验证同步复位优先于原本可进行的写入。此笔被取消，不计完成。
    test_id=test_id+1;
    @(negedge clk);
    req_i=1; we_i=1; addr_i=0; wdata_i=32'hFFFFFFFF; wstrb_i=4'b1111;
    #1; check_phase(0,0,0,0,0);
    @(posedge clk);
    #1;
    check_phase(1,1,1,0,0);
    check_ram;
    check("reset case only prepared",observed_completions,expected_completions);
    @(negedge clk);
    rst_n=0;
    #1;
    // 同步复位不能提前改变pending或存储内容。
    check_phase(1,1,1,0,0);
    check_ram;
    @(posedge clk);
    for (n=0;n<32;n=n+1) expected_ram[n]=0;
    #1;
    check_phase(0,0,0,0,0);
    check_ram;
    check("reset abort is not completion",observed_completions,expected_completions);
    @(negedge clk); req_i=0;
    @(posedge clk); #1;
    check_phase(0,0,0,0,0);
    check_ram;
    @(negedge clk); rst_n=1;
    idle_cycles(3); // 不允许出现延后的旧写或旧完成。

    // 复位后的新访问必须重新经历等待，且旧内容已经清零。
    access_target(0,32'h0,0,4'b0000,1,0,0);
    idle_cycles(1);
    access_target(0,32'h4,0,4'b0000,1,0,0);
    idle_cycles(1);
    access_target(0,32'h7F,0,4'b0000,1,0,0);
    idle_cycles(1);
    access_target(1,32'h0,32'hCAFEBABE,4'b1111,1,32'hCAFEBABE,0);
    idle_cycles(1);
    access_target(0,32'h0,0,4'b0000,1,0,32'hCAFEBABE);
    idle_cycles(3);

    check_ram;
    check("final completion count",observed_completions,expected_completions);
    if (errors==0) begin
        $display("PASS: data RAM target checks passed");
        $finish;
    end else $fatal(1,"FAIL: %0d data RAM target checks failed",errors);
end

initial begin
    #20000;
    $fatal(1,"FAIL: data RAM target timeout at test=%0d",test_id);
end
endmodule

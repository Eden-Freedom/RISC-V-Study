`timescale 1ns / 1ps
// 纯组合互连自检：直接模拟CPU请求及两侧目标回应，无时钟/复位。
module tb_data_bus();
reg cpu2bus_req_i, cpu2bus_we_i;
reg [31:0] cpu2bus_addr_i, cpu2bus_wdata_i;
reg [3:0] cpu2bus_wstrb_i;
reg ram2bus_ready_i, dev2bus_ready_i;
reg [31:0] ram2bus_rdata_i, dev2bus_rdata_i;
wire bus2ram_req_o, bus2ram_we_o, bus2dev_req_o, bus2dev_we_o;
wire [31:0] bus2ram_addr_o, bus2ram_wdata_o, bus2dev_addr_o, bus2dev_wdata_o;
wire [3:0] bus2ram_wstrb_o, bus2dev_wstrb_o;
wire bus2cpu_ready_o;
wire [31:0] bus2cpu_rdata_o;
integer errors, test_id, a, request_case, write_case, response_case, mask_case, table_index;
reg [31:0] address_cases [0:12];
// 0=未映射，1=RAM，2=DEV；由规格地址样例直接列出，不复用DUT切片公式。
integer route_cases [0:12];
reg expected_ready_table [0:11];
reg [31:0] expected_read_table [0:11];

data_bus u_data_bus(
    .cpu2bus_req_i(cpu2bus_req_i), .cpu2bus_we_i(cpu2bus_we_i),
    .cpu2bus_addr_i(cpu2bus_addr_i), .cpu2bus_wdata_i(cpu2bus_wdata_i),
    .cpu2bus_wstrb_i(cpu2bus_wstrb_i),
    .ram2bus_ready_i(ram2bus_ready_i), .ram2bus_rdata_i(ram2bus_rdata_i),
    .dev2bus_ready_i(dev2bus_ready_i), .dev2bus_rdata_i(dev2bus_rdata_i),
    .bus2ram_req_o(bus2ram_req_o), .bus2ram_we_o(bus2ram_we_o),
    .bus2ram_addr_o(bus2ram_addr_o), .bus2ram_wdata_o(bus2ram_wdata_o),
    .bus2ram_wstrb_o(bus2ram_wstrb_o),
    .bus2dev_req_o(bus2dev_req_o), .bus2dev_we_o(bus2dev_we_o),
    .bus2dev_addr_o(bus2dev_addr_o), .bus2dev_wdata_o(bus2dev_wdata_o),
    .bus2dev_wstrb_o(bus2dev_wstrb_o),
    .bus2cpu_ready_o(bus2cpu_ready_o), .bus2cpu_rdata_o(bus2cpu_rdata_o)
);

task check;
input [8*80-1:0] item;
input [31:0] actual, expected;
begin
    if(actual !== expected) begin
        $display("FAIL t=%0t test=%0d addr=%h req=%b we=%b %0s actual=%h expected=%h",
                 $time,test_id,cpu2bus_addr_i,cpu2bus_req_i,cpu2bus_we_i,item,actual,expected);
        errors=errors+1;
    end
end
endtask

// 输入改变后#1采样；每次同时检查返回、请求分发和两侧所有负载。
// 无请求或未选中时，负载仍应广播原值，只有req必须关闭。
task sample;
input exp_ram_req, exp_dev_req, exp_ready;
input [31:0] exp_data;
begin
    test_id=test_id+1;
    #1;
    check("RAM request",{31'b0,bus2ram_req_o},{31'b0,exp_ram_req});
    check("DEV request",{31'b0,bus2dev_req_o},{31'b0,exp_dev_req});
    check("CPU ready",{31'b0,bus2cpu_ready_o},{31'b0,exp_ready});
    check("CPU read data",bus2cpu_rdata_o,exp_data);
    check("RAM direction",{31'b0,bus2ram_we_o},{31'b0,cpu2bus_we_i});
    check("DEV direction",{31'b0,bus2dev_we_o},{31'b0,cpu2bus_we_i});
    check("RAM full address",bus2ram_addr_o,cpu2bus_addr_i);
    check("DEV full address",bus2dev_addr_o,cpu2bus_addr_i);
    check("RAM write payload",bus2ram_wdata_o,cpu2bus_wdata_i);
    check("DEV write payload",bus2dev_wdata_o,cpu2bus_wdata_i);
    check("RAM byte mask",{28'b0,bus2ram_wstrb_o},{28'b0,cpu2bus_wstrb_i});
    check("DEV byte mask",{28'b0,bus2dev_wstrb_o},{28'b0,cpu2bus_wstrb_i});
    check("mutually exclusive requests",{31'b0,(bus2ram_req_o & bus2dev_req_o)},0);
end
endtask

initial begin
    errors=0; test_id=0;
    cpu2bus_req_i=0; cpu2bus_we_i=0; cpu2bus_addr_i=0;
    cpu2bus_wdata_i=32'h5AC3E17B; cpu2bus_wstrb_i=4'b1010;
    ram2bus_ready_i=1; dev2bus_ready_i=1;
    ram2bus_rdata_i=32'h11223344; dev2bus_rdata_i=32'hAABBCCDD;
    sample(0,0,0,0);

    // RAM等待时，未选中的DEV即使就绪也不能结束请求。
    cpu2bus_req_i=1; cpu2bus_addr_i=32'h4; ram2bus_ready_i=0;
    sample(1,0,0,0);
    dev2bus_ready_i=0; dev2bus_rdata_i=32'hDEADBEEF;
    sample(1,0,0,0);
    dev2bus_ready_i=1;
    sample(1,0,0,0);
    ram2bus_ready_i=1;
    sample(1,0,1,32'h11223344);

    // 切换到DEV后不能残留RAM的ready或读数据。
    cpu2bus_addr_i=32'h10000004; dev2bus_ready_i=0;
    sample(0,1,0,0);
    ram2bus_ready_i=0; ram2bus_rdata_i=32'h76543210;
    sample(0,1,0,0);
    ram2bus_ready_i=1; dev2bus_ready_i=1; dev2bus_rdata_i=32'hAABBCCDD;
    sample(0,1,1,32'hAABBCCDD);
    cpu2bus_we_i=1; // 写访问只返回选中目标ready，读数据必须为0。
    sample(0,1,1,0);
    cpu2bus_req_i=0; // 完成后撤销请求，不能锁存上一次返回。
    sample(0,0,0,0);

    // 未选中回应即使未知也不应传播到CPU；关闭请求同样屏蔽回应。
    ram2bus_ready_i=1'bx; dev2bus_ready_i=1'bx;
    ram2bus_rdata_i=32'hXXXXXXXX; dev2bus_rdata_i=32'hXXXXXXXX;
    sample(0,0,0,0);
    cpu2bus_req_i=1; cpu2bus_we_i=0; cpu2bus_addr_i=4;
    ram2bus_ready_i=1; ram2bus_rdata_i=32'h11223344;
    sample(1,0,1,32'h11223344);
    cpu2bus_addr_i=32'h10000004; dev2bus_ready_i=1; dev2bus_rdata_i=32'hAABBCCDD;
    ram2bus_ready_i=1'bx; ram2bus_rdata_i=32'hXXXXXXXX;
    sample(0,1,1,32'hAABBCCDD);

    // 独立地址预期：覆盖两端、相邻边界、高地址别名及少一位零的旧错误。
    address_cases[0]=32'h00000000; route_cases[0]=1;
    address_cases[1]=32'h00000004; route_cases[1]=1;
    address_cases[2]=32'h0000007C; route_cases[2]=1;
    address_cases[3]=32'h0000007F; route_cases[3]=1;
    address_cases[4]=32'h00000080; route_cases[4]=0;
    address_cases[5]=32'h000000FC; route_cases[5]=0;
    address_cases[6]=32'h10000000; route_cases[6]=2;
    address_cases[7]=32'h10000004; route_cases[7]=2;
    address_cases[8]=32'h1000000F; route_cases[8]=2;
    address_cases[9]=32'h10000010; route_cases[9]=0;
    address_cases[10]=32'h01000000; route_cases[10]=0;
    address_cases[11]=32'h0FFFFFFF; route_cases[11]=0;
    address_cases[12]=32'hFFFFFFFF; route_cases[12]=0;

    // ready组合按{DEV ready,RAM ready}=00/01/10/11排列。
    // 未映射请求不依赖任何目标回应，总是立即完成、读零。
    expected_ready_table[0]=1; expected_read_table[0]=0;
    expected_ready_table[1]=1; expected_read_table[1]=0;
    expected_ready_table[2]=1; expected_read_table[2]=0;
    expected_ready_table[3]=1; expected_read_table[3]=0;
    // RAM选择行：只有RAM ready有效时可返回RAM数据。
    expected_ready_table[4]=0; expected_read_table[4]=0;
    expected_ready_table[5]=1; expected_read_table[5]=32'h11223344;
    expected_ready_table[6]=0; expected_read_table[6]=0;
    expected_ready_table[7]=1; expected_read_table[7]=32'h11223344;
    // DEV选择行：只有DEV ready有效时可返回DEV数据。
    expected_ready_table[8]=0; expected_read_table[8]=0;
    expected_ready_table[9]=0; expected_read_table[9]=0;
    expected_ready_table[10]=1; expected_read_table[10]=32'hAABBCCDD;
    expected_ready_table[11]=1; expected_read_table[11]=32'hAABBCCDD;

    ram2bus_rdata_i=32'h11223344; dev2bus_rdata_i=32'hAABBCCDD;
    for(a=0;a<13;a=a+1) begin
        cpu2bus_addr_i=address_cases[a];
        cpu2bus_wdata_i=32'h89ABCDEF ^ a;
        cpu2bus_wstrb_i=a;
        for(request_case=0;request_case<2;request_case=request_case+1) begin
            cpu2bus_req_i=request_case[0];
            for(write_case=0;write_case<2;write_case=write_case+1) begin
                cpu2bus_we_i=write_case[0];
                for(response_case=0;response_case<4;response_case=response_case+1) begin
                    ram2bus_ready_i=response_case[0]; dev2bus_ready_i=response_case[1];
                    table_index=route_cases[a]*4+response_case;
                    if(request_case==0) sample(0,0,0,0);
                    else sample(route_cases[a]==1,route_cases[a]==2,
                                expected_ready_table[table_index],
                                write_case==1 ? 32'd0 : expected_read_table[table_index]);
                end
            end
        end
    end

    // 写掩码四位原值转发，包含0000和1111，不要求互连解释字节含义。
    cpu2bus_req_i=1; cpu2bus_we_i=1;
    ram2bus_ready_i=1; dev2bus_ready_i=1;
    for(mask_case=0;mask_case<16;mask_case=mask_case+1) begin
        cpu2bus_wstrb_i=mask_case;
        cpu2bus_wdata_i=32'h01234567 ^ (mask_case << 24);
        cpu2bus_addr_i=32'h7F; sample(1,0,1,0);
        cpu2bus_addr_i=32'h1000000F; sample(0,1,1,0);
        cpu2bus_req_i=0; sample(0,0,0,0);
        cpu2bus_req_i=1;
    end

    // 两侧ready都为0，未映射读写仍正常完成。
    ram2bus_ready_i=0; dev2bus_ready_i=0; cpu2bus_addr_i=32'h80;
    cpu2bus_we_i=0; sample(0,0,1,0);
    cpu2bus_we_i=1; sample(0,0,1,0);
    cpu2bus_req_i=0; sample(0,0,0,0);

    if(errors==0) begin
        $display("PASS: data bus checks passed");
        $finish;
    end else $fatal(1,"FAIL: %0d data bus checks failed",errors);
end

initial begin
    #10000;
    $fatal(1,"FAIL: data bus timeout at test=%0d",test_id);
end
endmodule

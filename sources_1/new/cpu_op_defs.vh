`ifndef CPU_OP_DEFS_VH
`define CPU_OP_DEFS_VH

//R型操作指令
`define CPU_OP_NONE 6'd0
`define CPU_OP_ADD  6'd1
`define CPU_OP_SUB  6'd2
`define CPU_OP_XOR  6'd3
`define CPU_OP_OR   6'd4
`define CPU_OP_AND  6'd5
`define CPU_OP_SLL  6'd6
`define CPU_OP_SRL  6'd7
`define CPU_OP_SRA  6'd8
`define CPU_OP_SLT  6'd9
`define CPU_OP_SLTU 6'd10


//I型操作指令
`define CPU_OP_ADDI 6'd11
`define CPU_OP_XORI 6'd12
`define CPU_OP_ORI  6'd13
`define CPU_OP_ANDI 6'd14
`define CPU_OP_SLLI 6'd15
`define CPU_OP_SRLI 6'd16
`define CPU_OP_SRAI 6'd17
`define CPU_OP_SLTI 6'd18
`define CPU_OP_SLTIU 6'd19


//加载数据操作指令
`define CPU_OP_LB 6'd20
`define CPU_OP_LH 6'd21
`define CPU_OP_LW 6'd22
`define CPU_OP_LBU 6'd23
`define CPU_OP_LHU 6'd24

//存储数据操作指令
`define CPU_OP_SB 6'd25
`define CPU_OP_SH 6'd26
`define CPU_OP_SW 6'd27

//B型条件跳转操作指令
`define CPU_OP_BEQ 6'd28
`define CPU_OP_BNE 6'd29
`define CPU_OP_BLT 6'd30
`define CPU_OP_BGE 6'd31
`define CPU_OP_BLTU 6'd32
`define CPU_OP_BGEU 6'd33


//无条件跳转指令
`define CPU_OP_JAL 6'd34
`define CPU_OP_JALR 6'd35

//U型指令
`define CPU_OP_LUI 6'd36
`define CPU_OP_AUIPC 6'd37

//CSR操作指令
`define CPU_OP_CSRRW 6'd38
`define CPU_OP_CSRRS 6'd39
`define CPU_OP_CSRRC 6'd40
`define CPU_OP_CSRRWI 6'd41
`define CPU_OP_CSRRSI 6'd42
`define CPU_OP_CSRRCI 6'd43

//乘法指令
`define CPU_OP_MUL 6'd44
`define CPU_OP_MULH 6'd45
`define CPU_OP_MULHU 6'd46
`define CPU_OP_MULHSU 6'd47

//除法指令
`define CPU_OP_DIV 6'd48
`define CPU_OP_DIVU 6'd49
`define CPU_OP_REM 6'd50
`define CPU_OP_REMU 6'd51


//系统指令
`define CPU_OP_ECALL 6'd52
`define CPU_OP_EBREAK 6'd53
`define CPU_OP_MRET 6'd54


`endif
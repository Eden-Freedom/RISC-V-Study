`ifndef CPU_DEFS_VH
`define CPU_DEFS_VH


//R型操作指令代码
`define INSTR_R_CODE 7'b0110011
//I型操作指令代码
`define INSTR_I_CODE 7'b0010011
//L型操作指令代码
`define INSTR_L_CODE 7'b0000011
//S型操作指令代码
`define INSTR_S_CODE 7'b0100011
//B型操作指令代码
`define INSTR_B_CODE 7'b1100011
// lui指令代码
`define INSTR_LUI_CODE 7'b0110111
// auipc指令代码
`define INSTR_AUIPC_CODE 7'b0010111
// jal指令代码
`define INSTR_JAL_CODE 7'b1101111
// jalr指令代码
`define INSTR_JALR_CODE 7'b1100111
//数据加载指令代码
`define INSTR_LOAD_CODE 7'b0000011
//CSR寄存器指令代码
`define INSTR_CSR_CODE 7'b1110011


// opcode=INSTR_R_CODE 时使用的 funct7 编码
`define F7_R_BASE    7'b0000000 // 普通寄存器运算
`define F7_R_SUB_SRA 7'b0100000 // SUB、SRA
`define F7_R_M       7'b0000001 // 乘法、除法和余数

// 普通寄存器运算组的 funct3 编码
`define F3_R_ADD_SUB 3'b000
`define F3_R_SLL     3'b001
`define F3_R_SLT     3'b010
`define F3_R_SLTU    3'b011
`define F3_R_XOR     3'b100
`define F3_R_SR      3'b101 // SRL、SRA 共用此 funct3
`define F3_R_OR      3'b110
`define F3_R_AND     3'b111


// 乘除法组的 funct3 编码
`define F3_M_MUL    3'b000
`define F3_M_MULH   3'b001
`define F3_M_MULHSU 3'b010
`define F3_M_MULHU  3'b011
`define F3_M_DIV    3'b100
`define F3_M_DIVU   3'b101
`define F3_M_REM    3'b110
`define F3_M_REMU   3'b111






`endif
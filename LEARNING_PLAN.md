# TinyRISC-V 从零实现学习计划

## 最新收尾（2026-10-29）：除法流水线本人PASS；下次直接接CSR独立单元

本次学习已按用户要求结束。收尾仅维护学习文档，不新增练习、不继续教学、不运行编译/仿真/Python，不修改核心RTL或TB。CSR任务是今天已讲解、已布置但尚未提交的原任务，下次沿用。

### 今日完成与证据

| 阶段 | 用户本人运行证据 | 状态 |
|---|---|---|
| 4位unsigned除法原型 | 全遍历256组及协议测试，completed_cases=259 | 本人PASS |
| 32位unsigned独立除法器 | 定向/协议/复位及全宽、小除数随机各100组，completed_cases=211 | 本人PASS |
| signed/unsigned包装div_rem_unit | 定向/协议/两模式随机/复位取消与重启，completed_cases=218 | 本人PASS |
| 流水线DIV/DIVU/REM/REMU整组 | instructions=62；division_starts=37 commits=36 reset_cancelled=1 | 本人PASS |

- 流水线日志：PASS: division pipeline checks passed, instructions=62；division_starts=37 commits=36 reset_cancelled=1。37=36+1；62包含正式程序60条与取消阶段已提交的2条准备ADDI，正式ROM62项中有2条被JAL跳过。
- 用户已提交并同步逐位除法、符号包装、三级寄存器保持及四条译码/控制传递/EX接入；两处接口问题（EX漏接clk/rst_n、子模块输出接收信号误用reg）已由用户修正并被实际核对，不再作为待修题。
- 关键时序：unsigned内核E0受理、E1～E32迭代；包装E33沿后结果/done有效；CPU在E34沿提交一次并推进，复用EX到ID旁路。TB使用沿前快照、沿后#1核对，检查完整暂停现场、无提前/重复提交、两源依赖、连续除法、x0、JAL错误路径不启动、复位取消后35拍观察及重启、终点JAL提交后flush。
- 用户对包装简化的推导正确：只保存商负、余数负、除零三个标签；除零余数由符号恢复原A，最小负数/-1自然得到规定溢出结果，无需补冗余寄存器。

### 归属与边界

- 用户提交RTL/TB及本人运行日志；助手实际读取约定Vivado目录源码和TB，做静态评审、PowerShell参考/计数核对及学习文档维护。不能把本人日志记为助手运行，也不把通过直接等同全部独立设计能力或完整ISA合规。
- 助手曾运行xvlog成功，xelab静态展开及数据流分析通过，但后端生成C编译失败；没有运行xsim。该历史结果保留，不追溯改成助手仿真成功，也不作为下次学习门槛。本次收尾不补跑检查。
- tb_div_pipeline通过force dut.instr_o注入自身ROM；原imem.v仍是之前乘法程序，不表示除法程序已写入硬件ROM。此TB无合法访存/条件分支消费者，仅检查无意外RAM副作用；不新增宣称DIV→SW/条件分支交互通过或完整ISA/综合时序通过。此前乘法57条/35次、逻辑立即数、访存及更早PASS保持，不重跑。

### 当前暂停点与下次唯一动作

CSR仅为已讲解待用户亲写：独立12位CSR编号、mscratch=12'h340及32位宽；六种CSRRW/CSRRS/CSRRC及立即数型共享WRITE/SET/CLEAR；返回旧值、同沿写新值；立即数零扩展及读写抑制。尚无用户CSR回答/代码/日志，不能记为CSR已实现或掌握。已知代码修复均已处理，没有新的待答除法题。

下次直接接独立csr_unit的用户代码或具体疑问；若未开始，沿用今天的原任务，不重新讲整轮除法、不重做已答手推、不重跑259/211/218例或流水线PASS。不直接催完整CSR流水线/TB。先评审独立单元，再统一验证六种访问，再整组接流水线，随后才异常/中断。

原CSR任务契约：
- 仅保存一个mscratch_reg[31:0]；输入clk/rst_n（低有效同步，复位清零为教学选择）、valid_i、csr_addr_i[11:0]、funct3_i[2:0]、rs1_data_i[31:0]、rs1_uimm_i[4:0]（原instr[19:15]）、rd_i[4:0]。
- 输出csr_hit_o、csr_read_en_o、csr_write_en_o、csr_rdata_o[31:0]。hit仅比较地址340；valid且命中且funct3合法时读写。合法funct3按六条顺序为001/010/011/101/110/111。无效/未命中/非法funct3不读写，read_en=0时rdata为0。
- WRITE新值=src，SET=old|src，CLEAR=old&~src；寄存器型src为rs1数据，立即数型为零扩展rs1_uimm。write_en有效时上升沿保存新值，否则保持；rdata组合输出当前值，沿前供外部采样旧值，沿后随CSR变化。
- CSRRW[I]始终写，rd=x0不读；CSRRS/CSRRC始终读，rs1编号=0才不写（不能以数据为0替代）；CSRRSI/CSRRCI始终读，uimm=0不写。来源与例子保留在后面的本日CSR教学记录。

长期流程保持：一个适量完整主题→必要原理→用户亲写→评审→本人统一验证；同机制整组推进，局部小错顺手修正并继续，默认不代写整模块或整套TB。当前源码仍按vivado_prj/rebulid_riscv.srcs/sources_1/new和sim_1/new评审，不回退旧rebuild，不强制双份同步；聊天与落盘证据区分。文件用PowerShell操作，不用rg；以后若运行Python须先用UV管理工作区虚拟环境。

## 历史教学（2026-10-29）：流水线除法验收与CSR讲解，随后按用户要求收尾

- 用户提交约定目录sim_1/new/tb_div_pipeline.v并报告本人日志：PASS: division pipeline checks passed, instructions=62；division_starts=37 commits=36 reset_cancelled=1。助手实际读取TB并用PowerShell静态计数核对：正式ROM62项，JAL跳过2项，正式执行60条、其中36条除法；复位取消阶段还提交2条准备ADDI，所以全局instructions=62。总37次启动=36次提交+1次取消，计数一致。
- TB静态评审：独立参考按除零/溢出/signed/unsigned计算；逐PC reachable/expected_next和starts_at/commits_at检查指令顺序、无漏/重复；四DIV标志/模式/两源与架构模型一致；E0起暂停，组合现场包比较PC/IFID/IDEX全部字段保持；等待无写回/跳转/访存；E34提交延迟检查，沿前快照/沿后#1比对31个有效寄存器及RAM未变化。连续DIV和REM、ALU生产两源、除法紧邻ADDI及下一条除法的两源旁路均覆盖，四条写x0后实际读口/旁路保护有检查。
- JAL取消两条错误路径DIV/REMU，逐PC不得启动或提交；终点JAL已实际提交及flush后才结束。初始除法启动后复位取消，空ROM观察35拍无迟到提交，重新复位后完整程序通过；有全局超时。未发现本TB功能问题，本组按用户本人运行日志验收，不重跑已通过测试。
- 证据边界：TB通过force dut.instr_o注入自身ROM，不改imem.v；原imem磁盘程序仍是之前乘法程序，不能据此声称除法程序已写进硬件ROM。此TB没有合法访存或条件分支消费者，仅检查无意外RAM副作用，不能新增记为DIV→SW/条件分支交互已验证；既有访存/分支PASS保持。此组是定向流水线M组证据，不是完整ISA合规/综合时序通过。助手本轮仅读取文档/TB与参考资料、执行PowerShell静态计数并维护记录，未改RTL/TB、未运行HDL/Python；此前助手xelab后端C失败保留为历史，用户本次PASS不追溯改成助手仿真成功。
- 新主题：CSR基础及六条CSRRW/CSRRS/CSRRC/CSRRWI/CSRRSI/CSRRCI共用的读改写机制。CSR为独立于x寄存器和内存的12位编号空间；先选mscratch（0x340，RV32下32位普通读写暂存CSR）。操作返回旧值至rd，在同一提交沿将新值写CSR；WRITE取src、SET取old|src、CLEAR取old&~src；寄存器型src=rs1数据，立即数型src=零扩展原指令[19:15]，不是读取对应x寄存器。
- 重点抑制规则：CSRRW[I]始终尝试写，rd=x0时不进行架构CSR读；CSRRS/CSRRC始终读，rs1编号为0才不写，不能用rs1数据值是否为0替代；CSRRSI/CSRRCI始终读，uimm=0不写。例rs1=x5但x5内容为0时SET/CLEAR仍有写使能，即使数值未变。mscratch无特殊读副作用，本轮将read/write使能显式作为输出以便验证语义。
- 当前唯一亲写任务：实现独立csr_unit，仅存一个32位mscratch_reg。接口clk/rst_n（低有效同步，清零为本练习选择）、valid_i、csr_addr_i[11:0]、funct3_i[2:0]、rs1_data_i[31:0]、rs1_uimm_i[4:0]（原instr[19:15]）、rd_i[4:0]；输出csr_hit_o、csr_read_en_o、csr_write_en_o、csr_rdata_o[31:0]。hit仅比较addr=12'h340；六个合法funct3下valid且hit才读/写；无效/未命中或非法funct3不读写，rdata在read_en=0时为0。仅write_en=1时在上升沿保存组合新值，其他时刻保持，复位最高优先。csr_rdata是组合当前旧值，在写入沿前供外部采样，沿后随寄存器变化，不另加done/busy。
- 六条funct3分别001/010/011/101/110/111，opcode1110011；本轮先写独立单元，默认不改流水线，不要求同时写完整TB。评审后统一验证六种访问，再整组接decode/IDEX/EX与写回，之后才异常/中断。CSR仅已讲解待用户实现，尚无CSR用户代码/PASS，不重复M组测试。
- 资料：中文手册10.2节作机器模式背景；访问精确行为采用官方Zicsr5.1.1节 https://docs.riscv.org/reference/isa/v20260120/unpriv/zicsr.html，mscratch见Machine2.1.1.13节及官方riscv-opcodes csrs.csv，指令编码见extensions/rv_zicsr。助手按规范核对，不把中文转换表中的疑似错标题作为实现依据。

## 历史续接（2026-10-29）：接口修正后统一TB，随后流水线DIV/REM本人PASS

- 用户报告修正完成。助手实际读取默认Vivado目录pipeline_core.v第445～447行，确认ex_inst已接.clk(clk)、.rst_n(rst_n)；读取ex.v第122～125行，确认busy_div_o/done_div_o/quotient_div_o/remainder_div_o已为wire。上一轮两项问题已解决，不再要求重复修改或重交这些片段。
- 助手本轮重跑Vivado2024.2 xvlog（当前12个依赖模块）exit=0。xelab输出Completed static elaboration及Completed simulation data flow analysis，原未连接端口/非net错误消失；随后在生成仿真程序的C编译阶段报XSIM43-3409（xsim_1.c）及43-3915，exit=1。改用单线程和短snapshot名重试，仍在同一后端步骤失败，未定位原因；不能将其写为xelab全流程通过、功能PASS或已确认纯环境问题。未运行xsim/行为仿真。
- 检查产物保存在review_artifacts/div_pipeline_20261029/compile_fixed.log、elaborate_fixed.log、elaborate_fixed_serial.log；原检查日志保留。助手仅读取源码、编译/静态展开及维护学习文档，未改用户RTL/TB/xpr，未运行Python。用户独立包装218例/unsigned211例等旧PASS保持，但还没有流水线DIV/REM本人日志。
- 当前唯一任务：用户亲写一个统一流水线DIV/DIVU/REM/REMU自检TB及配套指令程序（可沿用已有流水线TB结构）。覆盖整组译码与商余数/符号选择、除零与signed溢出；前一条ALU生产除法两源及除法结果被下一条ADD/ADDI/分支/store使用；相邻除法（切换signed/unsigned和商余数）；x0读写；JAL取消错误路径DIV/REM且不启动/不暂停；复位取消并从PC=0重启。无需重跑独立218例或抄写完整算术回归。
- 验证新机制重点：第一次请求即stall，E0受理后至包装done前PC/IFID/IDEX完整保持（含valid、pc、源数据、rd和控制），除法器继续跑；等待时无写回/RAM副作用/跳转；一次有效除法只采样到一次启动与一次完成提交，done周期不得重启。包装E33沿后done有效，组合EX写回使能和数据有效且stall释放，E34沿才真正写regfile并装载下一条，既有两源旁路应向紧邻消费者提供结果。
- TB采样教学：真正提交检查应使用上升沿之前已经稳定的valid/指令类别/wr_en/rd/data（可在posedge时先保存、再#1检查寄存器）；不能先#1再用沿后新EX指令判断刚发生的提交。暂停检查则保存沿前现场/暂停条件，沿后#1比较保持；跳转/flush/reset优先级按既有约定排除。正常段启动数=除法提交数=有效除法数；复位取消的请求单独记录，不要求其产生提交。保留!==、全局超时、完成计数和终点已提交后的检查。
- 下一次直接接用户统一流水线TB/本人日志或疑问；当前不进入CSR/异常等新主题，不重复已通过的接口修改。若用户需要协助定位后端工具错误，可基于上述日志继续，但不能把该编译链路问题当成必须让用户重新写RTL的理由。

## 历史评审（2026-10-29）：两处接口问题，随后用户修正并已核对

- 用户明确同步到约定Vivado目录并要求检查。助手实际读取sources_1/new的addi_decode、pipeline_core、id_ex、ex、pc_reg、fetch_unit、if_id、div_unit、div_rem_unit、regfile，并检查新增指令/暂停/旁路链路；不再把本轮代码写为仅聊天片段。
- 发现1（功能阻断）：pipeline_core.v第445行ex ex_inst实例没有连接ex新增的clk/rst_n输入。需用户在该实例补.clk(clk)、.rst_n(rst_n)。否则内置div_rem_unit没有有效时钟/复位，不能正常受理、迭代及完成，可能表现为X或流水线无法继续。xelab报告该实例clk未连接，静态源码同时确认rst_n也缺失。
- 发现2（展开阻断）：ex.v第122～125行将busy_div_o/done_div_o/quotient_div_o/remainder_div_o声明为reg，但它们由子模块div_rem_unit输出驱动（第659～662行），在当前Verilog模式必须使用wire。用户只需将这四个声明改为wire；signed_ex_o/dividend_ex_o/divisor_ex_o/start_ex_o等在always中赋值的量继续保持reg。
- 助手实际执行Vivado2024.2 xvlog编译12个当前流水线依赖文件，exit=0；随后xelab展开div_review.pipeline_core，exit=1，四个VRFC10-3236 concurrent assignment to a non-net错误及未接clk警告。未运行xsim或行为仿真；这不是功能PASS。检查产物位于review_artifacts/div_pipeline_20261029/compile.log与elaborate.log及该目录下的编译库；未覆盖用户Vivado仿真运行目录，未修改核心RTL/TB或xpr。
- 已确认正确部分：decode四条默认清零及opcode/funct7/funct3；valid支持与decode→IDEX→EX四标志连线；IDEX reset/flush/hold/capture四分支均含新标志且优先级正确；PC/IFID/IDEX接统一stall_ex_o并由EX输出驱动，无临时常零多驱动。EX四条均位于valid内部，start=!包装busy&&!包装done，stall=!包装done，写回仅done有效；DIV/REM有符号、DIVU/REMU无符号，商余数选择正确；普通指令路径保留，等待期间RAM/跳转/flush默认无副作用，EX到ID两源旁路保留x0保护。
- 当前待办：用户修上述两处接口问题，不必重写EX四个功能分支或新增状态机；局部修正可与下一步统一流水线TB一起提交，不要求单独回复确认。下一阶段统一TB覆盖四条算术/符号边界/除零/溢出、紧邻依赖及两源旁路、连续除法、等待期间PC/IFID/IDEX保持且无提前或重复写回、x0、跳转错误路径DIV不启动、复位取消并重启。暂不记录流水线DIV/REM PASS，不重跑已通过独立包装218例。
- 用户核心RTL/将来TB由用户亲写，助手本轮只审阅、执行编译/静态展开和维护学习记录；Python未运行。先前独立unsigned211例、包装218例及更早指令组本人PASS保持。下一次接用户修正/统一TB/本人日志或具体疑问，从这两处明确问题续接，不重复已答教学。

## 历史教学（2026-10-29）：暂停评审后整组接入，随后RTL已落盘检查

- 用户聊天提交pc_reg/if_id/id_ex保持片段、fetch_unit透传及pipeline_core三处统一连接。pc_reg优先级reset>redirect>stall>+4正确；if_id为reset>flush>stall>capture正确。IDEX片段保留valid/PC/两源/立即数/rd和现有全部指令控制，保持行为正确，但未给完整上下文，需把该分支放在flush后、原装载前。自赋值合法，无需为省略写法重写。当前按聊天片段静态评审，未核对新版核心文件或运行仿真。
- 小待修：顶层片段只见wire div_stall_o及消费者，未见驱动；若尚未接EX输出则临时assign div_stall_o=1'b0，避免无驱动Z。后续接EX暂停输出时删除临时常零，保持单一驱动。注释来源应为EX除法控制，不是既有div_unit/div_rem_unit输出（其接口没有stall）。不为这个局部问题单独停一轮。
- 当前完整小主题是四条DIV/DIVU/REM/REMU统一接入既有流水线。已查官方riscv-opcodes rv_m：opcode0110011，funct7=0000001；funct3依次100/101/110/111。DIV/REM signed_i=1，DIVU/REMU=0；DIV/DIVU选商，REM/REMU选余数。来源：https://raw.githubusercontent.com/riscv/riscv-opcodes/master/extensions/rv_m。
- 教学控制模型：D表示valid_ex_i且任一DIV/REM控制位为1，B/T为包装div_rem_unit busy/done。请求条件D&&!B&&!T，暂停条件D&&!T；写回仅D&&T。初始B=0/T=0仍需stall保护启动沿，完成时B=0/T=1必须用!T禁止重启。全部基于包装层busy/done而非unsigned内核信号，不必另加发起标志/FSM（前提当前EX保留到done并在提交沿推进）。
- 周期契约：E0受理并冻结PC/IFID/IDEX；E1～E32等待无寄存器写回/访存/跳转副作用；E33沿后包装done=1，EX组合选正确商/余数，wr_en=1、stall=0且start=0；E34沿regfile写一次并推进三级寄存器，IDEX装载下一条。下一条若也是除法，沿后按新指令重新产生下一请求，不与前条重复。完成周期复用现有EX到ID旁路，紧邻消费者在E34采样新结果，无需新旁路路径。
- 当前唯一亲写任务：用户整组扩addi_decode四标志及默认赋值；扩pipeline_core valid支持与连线；IDEX四标志加入复位/flush/hold/capture；EX增加clk/rst_n和四输入标志、实例化既有div_rem_unit，用IDEX操作数送包装，产生start/signed/EX暂停及完成写回。保留普通ALU/访存/跳转已有行为；DIV等待分支维持默认无副作用，不能无条件使所有EX写回都受div_done控制。顶层连接EX暂停至已有三处。x0不应导致漏掉请求/解除暂停，可沿用现有写x0保护。
- 先提交本组RTL新增片段评审，随后统一流水线TB，暂不额外要求完整TB或重跑独立218例。当前新增启动/暂停/一次写回仅已讲解待亲写，尚无流水线DIV/REM代码/PASS。此前包装218例、unsigned211例等本人PASS保持。
- 助手本轮读取入口文档和当前addi_decode接口/默认值/部分译码，核对官方编码及静态评审聊天片段，维护四份学习文件；未修改核心RTL/TB，未运行HDL/Python。下一次直接接整组RTL/具体疑问，不重做保持分支或旧测试。

## 历史教学（2026-10-29）：包装218例PASS后保持机制，随后暂停片段已提交

- 用户指定工作区tb_div_rem_unit.v并报告本人日志：Directed arithmetic and back-to-back checks passed；Busy isolation and ignored-start checks passed；Reset cancellation and restart checks passed；Unsigned random checks passed: 100 cases；Signed random checks passed: 100 cases；PASS: all div_rem_unit checks passed, completed_cases=218。
- 助手已实际读取默认Vivado sim_1/new/tb_div_rem_unit.v全文件：13组定向（四种正负、模式差异、最小负数/1及/-1、除零）+3组干扰+2组复位重启+100 unsigned随机+100 signed随机=218；两次取消本身不计完成数。参考模型先除零再signed溢出，再分signed变量运算/unsigned运算，独立于DUT的简化路径。每种随机前50全宽、后50小除数，signed小除数正负各25。
- TB覆盖E0～E32忙且结果保持，E33完成，连续run_case使E34立即受理并清前次done；E2/E32/E33干扰模式和输入/start，之后空闲排除缓存；cancel_operation(3)及(33)，每次复位后check_idle(35)并重启；使用!==、下降沿驱动/沿后#1采样、固定seed及全局超时。未发现本TB功能问题，按本人日志验收独立包装层，不要求重跑。
- 已同时实际读取默认sources_1/new/div_rem_unit.v与div_unit.v：包装与聊天实现一致，只有quotient_neg/remainder_neg/divisor_zero三个标签的简化成立；内核trial/rem_work为[32:0]的33位，5位计数、32轮、末轮next输出正确。旧注释“start上升沿”“第四轮”仍有措辞残留，非功能问题，不单独卡教学。助手未运行HDL/Python，未修改核心RTL/TB；代码/运行PASS归用户，静态审阅/文档维护归助手。218例为独立模块验证，不是流水线DIV/REM已通过。
- 下一主题进入流水线多周期暂停。助手已静态读取pc_reg/fetch_unit/if_id/id_ex、pipeline_core及ex接口/部分逻辑；当前PC每拍递增或重定向，IFID/IDEX无stall入口，EX为组合接口无clk/rst_n且尚无DIV/REM控制字段。现有旁路由EX写回信号到ID两源，后续完成周期可复用，不新增除法专用旁路。
- 本轮先讲并由用户亲写寄存器保持机制，暂不要求一次接完整除法流水线：pc_reg新增stall_i，优先级同步复位>分支/跳转重定向>stall保持>PC+4；if_id/id_ex新增stall_i，优先级同步复位>flush清除>stall全字段保持>原装载。保持含valid/PC/数据/rd/全部控制，不能仅清valid当暂停。通过fetch_unit透传到PC，pipeline_core将同一stall_pipeline线接三处，现阶段可临时绑定0维持原运行行为，后续由EX除法等待产生；若模块级验证可从TB驱动stall，不强制本轮新TB。
- 整体讲解边界：DIV/REM占据EX时，IDEX保留当前指令及操作数/rd，IFID保留下一条，PC保留再下一条；除法器时钟继续运行。下一步还需只启动一次、等待时关闭写回及其他副作用、完成时仅提交一次再释放暂停；不能只靠busy产生stall（启动前busy尚0），不能只冻结PC，不能门控整个clk。包装E33沿后done有效，未来CPU在E34沿提交/推进，复用EX到ID旁路让紧邻依赖获得结果。
- 当前唯一亲写任务：用户修改pc_reg/if_id/id_ex暂停入口和时序分支，并补fetch_unit/pipeline_core的统一暂停连线，提交新增端口/优先级分支/连线片段即可；不用重交整文件，不改现有div内核/包装、不重做218例、不先催全套DIV译码EX及TB。评审后再接除法请求/等待/完成写回，四条DIV/DIVU/REM/REMU按同机制整组推进与统一验证。当前流水线暂停仅已解释待实现，尚无其代码/PASS。

## 历史教学（2026-10-29）：包装RTL静态评审后，随后本人218例PASS

- 用户聊天提交完整div_rem_unit及自己的设计说明。包装实例化既有div_unit，组合产生幅值与core_start=start_i&&!busy_o；只保存quotient_neg/remainder_neg/divisor_zero三个标签，忙时等待core_done，完成时修正并寄存商余数。未发现本包装功能问题；不要求为符合先前示例而增加冗余overflow或原被除数寄存器。
- 用户简化推导成立：除零时unsigned内核R返回输入幅值；包装按锁存的被除数符号二次取负，可恢复原始A位模式（包括80000000），所以不用额外保存原A。signed 80000000/FFFFFFFF时幅值为80000000/1，内核Q=80000000/R=0，两个负数的商负标签为0，普通路径自然得到规定溢出结果；无需单独overflow标志。仅除零商要覆盖FFFFFFFF，避免负被除数时误将其取负为1。
- 时序静态结论：E0包装与内核同时锁存；E1～E32包装busy保持；E32内核完成但包装仍busy且输出保持；E33包装读取core_done及稳定core结果、清busy置done；E34清done并可受理新请求。E32～E33仍用包装busy阻止内核提前接收请求，core_busy作为观察线未用于控制无功能问题。标签只在空闲start时锁存，外部signed_i变化不会影响本次运算。
- 局部措辞修正：用户注释“start上升沿”应为“clk上升沿且start_i=1、busy_o=0时受理”；电路并不检测start_i上升沿。用户对busy=0时两层空闲的推导正确，限定在本协议/复位后的正常状态。
- 当前唯一任务：沿用已有TB结构编写包装层统一自检TB，DUT换div_rem_unit并加入signed_i；检查E0～E32 busy=1/done=0/旧结果保持，E33正确结果/busy=0/done=1，E34清done；两模式均固定时延。参考模型先分除零，再分signed最小负数/-1溢出，再按signed/unsigned求/和%；signed参考使用reg signed[31:0]的两个操作数，不用unsigned直接除后强转。
- 定向覆盖四种±13/±3、-1/2、unsigned FFFFFFFF/2、signed及unsigned的80000000/FFFFFFFF、signed 80000000/1、负被除数及80000000除零、0/0等。可两种模式各100随机，兼顾全宽及小除数，signed小除数覆盖正负。所有参考结果使用32位位模式与输出比较。
- 包装协议覆盖：忙时改变signed_i/A/B并在E2/E32/E33注入start均忽略；结果保持和done单拍；E34最早重新受理；中途复位取消后观察至少35拍再重启，并覆盖E32内核已完成后在E33沿复位，确认取消包装待交结果。
- 证据归属：用户提交包装代码及简化理由，助手静态核对代数/位模式/时序并维护四份文档；未核对落盘、未改核心RTL/TB、未运行HDL/Python。当前无包装仿真PASS，不把内核211例PASS扩展为包装验收；包装数据通路/握手均已提交静态通过，下一次直接接TB/本人日志或疑问，不重写已正确包装、不重做unsigned练习。通过包装验证后才开始流水线暂停与一次提交机制。

## 历史教学（2026-10-29）：unsigned211例PASS后包装讲解，随后包装RTL已提交

- 用户报告上一轮要求的修改已完成，并提供本人日志：Directed arithmetic and timing checks passed: 8 cases；Busy-input isolation and ignored-start checks passed；Reset cancellation and restart checks passed；Full-width random checks passed: 100 cases；Small-divisor random checks passed: 100 cases；PASS: all div_unit checks passed, completed_cases=211。按本人修改说明与日志验收32位独立unsigned阶段，原11例+200随机=211，不要求重交/重跑旧练习。
- 证据边界：新增证据为用户本人运行日志和“修改完成”的报告；助手未读取修订后RTL/TB，未核对33位临时量与35拍观察窗是否实际落盘，不声称逐行确认新版文件。此前聊天RTL/TB已静态审阅；助手本轮只读入口文档、核对官方M规范、维护学习记录，未改核心RTL/TB，未运行HDL/Python。
- 新主题为统一signed/unsigned包装div_rem_unit，内部实例化已通过的div_unit。新输入signed_i（1为有符号、0为无符号），其余沿用32位输入/商余数输出、start/busy/done和低有效同步复位。输入端signed模式按符号取32位二补码绝对值送unsigned内核；商负标志=signed_i&&(A[31]^B[31])，余数负标志=signed_i&&A[31]。80000000的绝对值位模式仍为80000000，作为unsigned的2^31交给内核有效。
- 已讲解RISC-V语义：商向零截断，非零余数与被除数同号；-13/3=-4余-1，13/-3=-4余1，-13/-3=4余-1。除零在两模式均商FFFFFFFF/余数原被除数，优先于普通符号修正；signed且A=80000000/B=FFFFFFFF时溢出结果商80000000/余0，可显式覆盖。规范来源：https://docs.riscv.org/reference/isa/v20260120/unpriv/m-st-ext.html 第11.1.2节。
- 本轮包装选择独立输出寄存器并额外用一拍修正/保存，属于教学实现选择：E0包装和内核同时受理（core_start为start_i&&!busy_o的组合信号，幅值输入亦组合产生，勿先用NBA寄存请求导致内核推迟一拍）；包装在E0锁存q_neg/r_neg/div_zero/overflow及原被除数，并置自身busy。E1～E32内核迭代，E32内核寄存输出/core_done变1；包装同沿读到旧core_done=0，因此E33读取core结果、应用锁存标志并写输出，busy=0/done=1；E34清done。所有输入包括特殊情况均按该固定33周期完成。
- 包装有自己的busy_o/done_o和结果寄存器，不直接连内核busy/done；E32到E33期间仍busy，防止提前接新请求。结果启动及运算时保持，忙时忽略start及signed_i/输入变化，复位同步清包装状态并同时复位内核。内核输出只接wire，不能由包装过程驱动；包装无需复制内核计数器。
- 当前唯一亲写任务：依本轮规格实现div_rem_unit包装RTL（输入幅值组合逻辑、受理时锁存元信息、实例化div_unit、等待core_done、结果特殊情况优先/符号修正/寄存输出、复位与状态），先提交包装代码评审；不要求本轮再写完整TB，不代写整模块。评审后统一验证signed/unsigned边界与协议，之后才接流水线暂停/一次提交。当前signed包装只是已讲解待实现，尚无其用户代码或PASS。

## 历史教学（2026-10-29）：32位定向PASS后的覆盖补充，随后本人211例PASS

- 用户聊天提交32位div_unit RTL、tb_div_unit及本人日志：Directed arithmetic and timing checks passed: 8 cases；Busy-input isolation and ignored-start checks passed；Reset cancellation and restart checks passed；PASS: all div_unit checks passed, completed_cases=11。8组定向+2组干扰+1组重启=11；被取消的14/3不计完成数。
- RTL静态评审：Q/R/D及next/端口32位，取Q[31]、左移Q[30:0]、R取[31:0]正确；5位cnt从0到31，E32使用末轮next输出，busy优先、输入锁存、done脉冲与结果保持符合约定，未发现功能错误。trial/rem_work写为[33:0]实际34位；其unsigned表达式会零扩展，多一位在本算法合法状态不破坏结果，但建议改[32:0]为所需33位。末轮注释“第四轮”应改“第三十二轮”。32'h0000是合法32位零，无需更改。
- TB静态评审：参考操作数/输出为unsigned32位且除零单独处理；检查E0～E31保持busy/旧结果、E32完成、E33清done；E2/E32注入start、改变外部输入均有覆盖；复位取消后可重启。当前确有11组本人PASS，但尚未加入原任务建议的随机用例。取消后repeat(6)沿用4位窗口，仅证明这6拍未迟到；32位取消在第二轮后，原运算还有约30轮，需延长空闲观察以覆盖原完成时刻。
- 当前唯一补充任务：顺手调整上述位宽与注释，并在现有TB增加200组随机（例如100组全宽无符号A/B，100组全宽A且B取1～256），用现有run_case参考/时序检查；每次随机值先存reg[31:0]，避免signed参考。全宽均匀随机常产生商0或1，小除数组补足多位商覆盖。取消后空闲观察改repeat(35)，期间持续检查busy/done/结果为0，再重启。原11组记录保留，不要求单独重跑旧组；同TB整体运行后若其余结构不变应completed_cases=211。
- 下一次直接接补充的TB片段/修正说明与本人日志或疑问；不要求重交整个已评审RTL、不重新手推4位或重讲busy/done。补齐后进入signed包装的原理与亲写任务，随后才流水线暂停。
- 证据归属：代码与TB为用户聊天提交，日志为用户本人运行；助手仅静态审阅并维护四份入口文档，未核对是否落盘，未修改核心RTL/TB，未运行HDL/Python。34→33位更正、随机200组和35拍取消观察尚无新日志，不能写成已修复/已验证；当前为32位定向PASS，不宣称完整RV32M或流水线除法通过。此前4位259例PASS及其他指令组PASS保持。

## 历史教学（2026-10-29）：4位PASS后扩32位，随后已有32位定向PASS

- 用户聊天提交完整tb_div_unit及本人日志：Exhaustive arithmetic and timing checks passed: 256 cases；Busy-input isolation and ignored-start checks passed；Reset cancellation and restart checks passed；PASS: all div_unit checks passed, completed_cases=259。
- 助手静态核对TB：256组遍历含16组除零，参考结果对非零使用/和%、除零显式Q=F/R=被除数；每例逐拍检查E0装载、E1～E3忙与旧结果保持、E4完成、新结果、E5～E7清done及结果保持。下降沿驱动，上升沿后#1采样，!==覆盖X/Z，有全局超时。
- 额外完成例为11/3和15/0两例注入干扰，以及复位后的13/3重启一例，256+2+1=259；14/3执行两轮被复位取消，不计入完成数。干扰例在E1～E4使用与原输入取反的数据、E2/E4注入start，之后保持空闲检查未缓存请求；取消后观察6拍无迟到done/结果。未发现本TB与约定行为不符的问题。
- 验收：4位独立unsigned原型在用户所运行TB中算术及上述控制检查PASS。源码证据为聊天提交的单轮组合片段、时序片段与TB，未核对最终完整DUT是否落盘；助手未运行HDL/Python、未修改核心RTL/TB。用户运行PASS不扩展为32位、signed或流水线除法已验证。已通过4位练习不重做。
- 当前唯一主题：用户沿用现有结构亲自扩32位独立unsigned除法器及统一TB。输入/输出/Q/R/D/q_next/r_next为32位；trial/rem_work为33位；取Q[31]、左移拼Q[30:0]、截余数[31:0]；比较/减法仍将D零扩展到33位。cnt用5位索引0～31，末轮判断5'd31、步进5'd1；同步复位和其他协议保持。E0受理，E1～E32迭代，E32输出next并busy=0/done=1，E33清done；所有输入含除零固定32轮。
- TB沿用任务结构，端口/参考量/held量改32位，循环32轮；E32注入完成沿start并检查无缓存，复位取消与重启、结果保持继续覆盖。用定向边界（13/3、0/7、7/1、2/3、FFFFFFFF/2、80000000/FFFFFFFF、0/0和FFFFFFFF/0）及例如200组随机替代不可行的32位全遍历。参考操作数/结果须为unsigned reg[31:0]，integer仅用于循环计数，除零显式处理；RTL不用/和%。随机量先存32位无符号变量再求参考。
- 下一次接32位RTL/TB及本人日志或具体疑问；先评审/验证32位unsigned，再推进signed包装，最后流水线暂停与一次提交。四位原型的算法与握手机制不重复讲解。助手本轮仅静态评审聊天材料并维护四份学习入口文档。

## 历史教学（2026-10-29）：4位时序评审通过，随后原型本人仿真PASS

- 用户已在聊天提交时序always块：同步低有效复位清Q/R/D/cnt及输出；非复位默认done_o<=0；busy分支保存q_next/r_next；cnt==2'b11时输出next、busy<=0、done<=1，否则cnt加1；空闲start装载输入、R=0、cnt=0、busy=1。与原4位组合片段配合，未发现本段功能问题。
- 静态核对结论：E0装载，E1/E2/E3沿后cnt=1/2/3，E4沿前cnt=3完成且沿后cnt保持3；末轮结果用next正确；busy含完成沿忽略start，D锁存，输出在启动/运算/空闲保持；done仅完成一周期，复位取消并清输出。cnt应声明为2位，时序输出需可过程赋值（Verilog output reg），聊天注释外星号按富文本标记处理，实际源文件勿保留。
- 证据归属：这是用户聊天提交代码的助手静态评审；未读取/核对本段是否落盘，未编译、未运行HDL/Python，尚无除法仿真PASS，不将代码通过等同独立掌握或32位/流水线验证。原手推、组合片段及之前乘法/访存PASS保持，不重做。
- 当前唯一任务：用户将已评审两段组合成4位独立原型，自写一个统一自检TB并本人运行。建议遍历16×16共256组输入：非零除数在TB用/和%求参考；除零显式检查商4'hF、余数等于被除数，所有输入均E0受理、E1～E4迭代。增加busy期间改输入并脉冲start（含E4完成沿）、结果保持、done脉宽、复位取消/重启等协议场景。
- 验证教学：在下降沿驱动输入，上升沿后稍延时（如TB中#1，须短于半周期）检查非阻塞赋值后的状态；逐拍检查E0～E3 busy=1/done=0、E4 busy=0/done=1、E5 done=0。等待完成必须有超时。TB参考可用/和%，可综合除法RTL仍不用。
- 下一次接用户4位原型TB/本人日志或疑问；先完成4位原型验证，再扩32位，随后才signed包装和流水线暂停。不再要求重写已正确时序块。助手本轮仅维护四份学习入口文档，未修改核心RTL/TB或代跑仿真。

## 历史教学（2026-10-29）：4位除法时序控制讲解，随后已提交并评审

已恢复2026-10-28最新断点；11/3手推及单轮组合逻辑评审通过保持，不重答、不重交，不重跑此前乘法/访存PASS。

- 本轮主题：沿用原4位组合逻辑，补齐最小时序控制。接口为clk、低有效同步rst_n、start_i、4位dividend_i/divisor_i、busy_o/done_o和4位quotient_o/remainder_o。
- 教学约定：采用2位round_reg表示当前即将执行的轮索引0～3；E0空闲受理请求，装载Q=被除数、R=0、D=除数、round=0、busy=1；E1～E4各保存一轮q_next/r_next。E4沿前round=3，完成时结果寄存器取最后一轮next，busy=0、done=1；E5清done。结果除复位或完成外保持，启动不清旧结果。
- 控制优先级：同步复位最高，其后busy迭代，再空闲start装载；忙时（包括完成沿）忽略start和外部输入变化。done每个非复位周期默认清零，仅完成时置1。计数只在非末轮加1，末轮可保持3，下一请求重新装载0。
- 本轮讲解重点：组合电路在两时钟沿之间计算next，上升沿只采样一轮；非阻塞赋值读取沿前值，因此末轮输出必须用q_next/r_next，不能误取q_reg/r_reg。busy本身足以区分空闲/运算，无需本轮另加多状态FSM。
- 当前唯一亲写任务：保留已评审组合片段，提交新增接口/时序寄存器声明及always @(posedge clk)控制块，包含复位、启动、四轮迭代、完成和done脉冲；允许直接贴聊天代码。先评审该控制块，再安排4位原型统一验证；本轮不要求完整TB，不直接扩32位或接流水线。
- 证据边界：上述控制仍为助手讲解、待用户尝试，尚无新用户时序代码或除法仿真PASS；原组合片段是否落盘仍未核对。助手本轮仅读取教学资料和维护四份入口文档，未修改核心RTL/TB，未运行HDL/Python。

## 历史收尾（2026-10-28）：接续前的4位除法断点

本次学习已按用户要求结束，不新增练习、不补跑仿真。用户提交4位11/3四轮手推及一轮组合逻辑，助手静态评审均正确；当前没有待答手推题或待修组合片段。

- 手推原答案：四轮取位1/0/1/1，T=1/2/5/5，商新位0/0/1/1，R=1/2/2/2，Q=0110/1100/1001/0011。最终商3、余数2，11=3×3+2。
- 用户聊天提交的组合片段：trial={r_reg,q_reg[3]}；rem_work默认trial；q_next默认左移补0；trial>={1'b0,d_reg}时商最低位置1并减除数；r_next=rem_work[3:0]。5位临时量和unsigned比较正确、默认赋值完整、使用阻塞赋值，无发现本轮组合功能问题。按算法的合法迭代状态使用。
- 证据归属：用户依讲解提交手推及Verilog片段；助手仅静态审阅并维护文档，未运行HDL/Python，未修改核心RTL/TB。聊天片段尚未核对是否落盘，不能记为已保存的完整divu_unit；本轮不是除法器仿真PASS。
- 掌握证据限于能手推这组逐位除法，并提交正确单轮组合逻辑。start/busy/done、时序装载、迭代计数、最终next值输出及复位/忙时行为仅已讲解待练习；尚无完整多周期除法器、32位除法或流水线除法证据。
- 下次唯一入口：直接沿用这段正确的4位组合逻辑，先讲清并由用户亲写最小4位时序控制（复位、start装载Q/R/D、忙时每拍保存next、4轮计数、完成时输出最后一轮next并产生done）。四位原型验证后再扩32位，随后才做signed包装与流水线暂停。不重复11/3手推，不要求重交已评审组合片段，不直接催32位整模块/TB。
- 原乘法组本人PASS保持：57条指令/35条乘法；逻辑立即数28条、对齐SW/LW11条、字节/半字访存本人PASS及更早验收保持。乘法TB/配套程序头部注明助手编写，用户本人运行，与用户RTL成果分开记录。

## 历史教学任务（2026-10-28前置讲解，手推与组合片段现已完成）

用户明确从未用Verilog编写除法器、前置原理不足，要求先非常详细、浅显地讲解并使用比喻。本轮已改为补齐原理；此前整模块/TB提交任务暂缓，不将其当作下一条必须提交的作业。

本轮讲解范围：除法与余数定义；十进制竖式带位到二进制带位；T=2R+b及D>0时T<2D、每轮最多减一次；4位13/3完整R/Q状态与Q兼任待处理位队列和商位容器；比较/减法组合电路与时钟寄存器反馈；4位单轮组合逻辑最小示例；阻塞/非阻塞赋值及next值；start/busy/done与E0受理、E1～E32迭代；位宽/计数和除零说明。示例与过程均为助手讲解，未记作用户回答或用户实现。

当前唯一小练习：按给出的过程手推4位11/3（Q初值1011、R初值0000、D=0011）的四轮T、新商位、R、Q。等用户尝试/疑问后再评审，理解单轮后逐步写组合单轮逻辑，再接启动/迭代/完成控制。不重做乘法，不直接催交完整除法器，不提前进入有符号包装或流水线停顿。

证据状态：无divu_unit用户代码/仿真；原乘法PASS保持。助手本轮仅读取记录/教学指南、核对Vivado文档和维护四份学习文档，未修改核心RTL/TB，未运行HDL或Python。

## 后续目标（2026-10-28原任务）：独立无符号多周期除法器，待前置理解后恢复

乘法组已由用户运行定向PASS（57条指令、35条乘法）。助手静态核对RTL/TB和全部机器码参考预期，未发现本组功能问题；不重跑旧PASS。手算中MULH/MULHSU两项错误已解释，原题已回答，不再作为待交题。

下一主题引入新的逐周期迭代与start/busy/done机制，因此先验证独立除法器；商和余数共享数据通路，不按DIVU/REMU逐条拆课。用户亲写实现，后续再加signed包装和流水线停顿，不一次跨完三个机制。
- 下一项完整小主题是独立divu_unit：32位unsigned被除数/除数，同时输出32位商/余数；用逐位比较减法，每周期处理一位，不用RTL的 / 或 %，暂不改流水线。
- 接口契约：clk，低有效同步rst_n，start_i（空闲时一拍请求），dividend_i/divisor_i[31:0]，busy_o，done_o，quotient_o/remainder_o[31:0]。E0受理并锁存；E1～E32迭代，E32输出最后一轮next值、busy=0且done=1，随后done清零。busy期间忽略start和外部输入变化；结果保留至下次完成，复位取消运算并清零。
- 数据通路：32位Q初值被除数、32位R初值0、32位D锁存除数；33位T={R,Q[31]}。Q左移一位，T>=零扩展D时R取T-D且商新位1，否则R取T且商新位0。迭代32次，最后输出更新后的Q/R，不能误用末轮旧寄存器值。
- 所有输入包括除数0均固定迭代32次；除零商FFFFFFFF、余数等于被除数。计数器若表示剩余32～1需6位，若表示索引0～31则5位即可。
- 用户亲写模块与统一TB；覆盖13/3、0/7、7/1、2/3、FFFFFFFF/2、80000000/FFFFFFFF和除零，以及busy期间改输入/请求、结果保持、done脉宽、复位取消与重启。未提交前状态仅已讲解待练习，后续再做有符号包装和流水线停顿/一次提交。

## 历史任务（2026-10-28乘法教学，随后已PASS）

本轮按长期节奏讲解MUL/MULH/MULHSU/MULHU，随后等待用户亲写实现与统一验证。新增的是EX乘法数据通路，沿用旁路/写回/valid/flush，不重复先前PASS。

- 编码：opcode=0110011、funct7=0000001，funct3依次000/001/010/011；保留原R型译码边界。
- 语义：MUL低32位；MULH、MULHSU、MULHU分别为SS、SU、UU的高32位。MULHSU固定rs1有符号、rs2无符号。
- 建议实现路径：先将两个操作数分别符号/零扩展到33位signed，再存66位signed乘积，结果选[31:0]或[63:32]；这只是避免混合符号表达式问题的教学选择，不是ISA新增66位寄存器。
- 一项整组任务：用户修改译码、支持valid、顶层连线、ID/EX reset/flush/capture及EX valid内部选择，自写一个统一自检TB并自行仿真。
- 覆盖0/1、普通正数、FFFFFFFF、80000000、7FFFFFFF；MULHSU交换两源；生产者→乘法两个源和乘法→ADD/ADDI紧邻依赖；x0、无访存/跳转副作用、沿后写回、完成/超时。
- 待交预测：rs1=80000000、rs2=FFFFFFFF，四条各写回什么。可与RTL/TB及本人日志同回复提交；无需先单独答预测。

目前仅已讲解待练习，尚无本轮用户实现/验证；下一次直接接提交或疑问。资料对应中文手册第4.1节的乘法段落及图4.2，语义已核对RISC-V官方M扩展规范。

历史版本说明：2026-10-28早前收尾，当时待乘法；现以文件顶部除法器任务为准。

## 目标和起点

最终成果由用户亲自逐步完成：RV32IM 核心、三级流水线、CSR/机器模式异常与中断、RIB、存储器、外设、调试接口及 FPGA 集成。每一步同时练习设计、Verilog、testbench 和定位问题。

已有 FPGA 工程经验和上游跑通经历；用户补充能从零写 LED、计数器、分频器及异步 FIFO，熟悉上升沿和时钟波形。按有 RTL 实践经验、CPU/RISC-V 入门安排课程，直接把已有技能迁移到 CPU 模块。具体薄弱点随练习补齐。

每周 5～8 小时，每次一个小主题。按掌握情况推进，不承诺固定周数。原项目RTL和上游目录用于后期对照；当前练习RTL/TB在下述Vivado目录，rebuild内RTL/TB为旧副本。此前AI完整代码已归档，不计入学员进度。

## 当前默认代码来源（2026-10-24更新）

- 练习RTL：`D:\Study\RISC-V\rebulid_tinyriscv\vivado_prj\rebulid_riscv.srcs\sources_1\new`。
- 练习testbench：`D:\Study\RISC-V\rebulid_tinyriscv\vivado_prj\rebulid_riscv.srcs\sim_1\new`。
- 当前核心/TB评审默认从以上目录读取；旧`rebuild/rtl`、`rebuild/tb`不再作默认来源，不自动双向复制，不要求用户同步旧副本。历史记录中的旧路径只说明当时的代码来源。
- 聊天中用户明确提交的版本仍可直接评审；需要编译/修改时才核对实际工程来源。本次仅确认新目录存在，未逐项核对其中源码与今日聊天版本一致。

## 每次课的工作方式

1. 先读取 AGENTS.md、LEARNING_PLAN.md、LEARNING_PROGRESS.md、LEARNING_SESSION_PROMPT.md；以进度顶部快照和最新收尾为当前断点，历史待办不覆盖最新状态。
2. 若有未答题或待提交代码，直接接续；不重复起点题、25 ns 复盘或已正确回答的问题。确需复习时只用 1～3 个已学内容短问题，未学术语先讲再练。
3. 默认每轮完成一个完整、适量的小主题：说明在 CPU/SoC 中的作用，讲清所需概念与硬件行为，再布置一项亲写/验证任务。根据回答、代码和仿真证据随时增减深度，避免过细过慢，也不连续堆多个新主题。
4. 保持学习链：需求 → 输入输出 → 时序/状态 → 用户预测 → 用户写小段 Verilog → 评审 → 用户修改 → 一起确定测试并由用户仿真。行数是参考，不是硬门槛；不把每个声明、数字或小修正拆成单独对话。
5. 讲解使用具体数字、必要的生活例子、硬件含义与周期表；比喻后说明真实电路。需要预期波形时使用 WaveDrom，不能把示意图当作实际仿真证据。
6. 局部小错：指出错误、原因、修改位置，让用户下一条顺手修正，同时继续给不受影响的下一步。只有错误较多、关键概念不清或阻碍后续推理时才停下来修复。提示 → 伪代码 → 最小片段，不默认贴完整答案。
7. 核心 RTL 和完整 testbench 默认由用户亲写。可帮助环境、脚本和记录维护；用户明确索要某范围答案时才提供。用户主动提交更完整的小模块或 TB 时正常评审，不要求拆开重交。
8. 可在同一回复提交预测、代码和日志；用户能独立运行的简单仿真由用户运行。助手核对结果并说明证据边界，不重复要求跑同一场景，不把日志观察写成自动断言或完整 ISA 合规。
9. 每个小步骤记录用户原回答、代码归属、预期/实际结果、误解与下一步；讲过记为“已解释待练习”，能做出的证据再提升掌握状态。环境准备和助手维护不计为用户掌握。
10. 收尾同步四份入口文件，保存当前程序/关键日志、未完成题目或代码任务、下一次唯一动作；区分聊天代码与磁盘版本。下一会话直接续接，不重新讲已经完成的流程。
11. 用户于2026-10-20说明核心工程文件后续自行覆盖同步；助手不代写覆盖、不反复催同步，以聊天提交及日志评审，实际工具编译/修改前再核对版本。

## 实现路线与阶段交付

| 阶段 | 从理解到亲手实现 | 达标证据 |
|---|---|---|
| 0 起点校准（已询问） | 已知具备基础模块和异步 FIFO 经历，跳过重复入门；计算与状态保存的差别结合 PC 澄清 | 后续在实际 CPU 代码和预测题中验证，不另布置 LED/计数器重做 |
| 1 CPU 整体直觉 | 理解程序是一串操作、指令与数据、寄存器、PC；从计数器逐步做 PC 和小指令存储模型 | 能用自己的话讲清“取出下一条操作”的过程并验证 PC |
| 2 第一条指令 | 先理解把 5 放入工作寄存器的需求，再引入 addi；逐步做必要的译码、立即数、运算、写回 | 自己接通只支持少数指令的最小核心，并用短程序验证 |
| 3 扩展单周期数据通路 | 逐组加入运算/移位/比较、lui/auipc、分支/跳转、字节/半字/字访存；随用随学格式、符号扩展和地址 | 每组有手算、本人 RTL、定向测试；说明当前支持子集和未支持行为 |
| 4 自己改成三级流水线 | 从已写的数据通路拆阶段，逐步增加流水线寄存器、相关处理、暂停、冲刷，再对照上游 | 能画连续指令周期表，解释依赖与跳转测试，并独立修复一个错误 |
| 5 完成 RV32IM 与特权功能 | 加入乘除法及多周期控制；学习 CSR、异常入口、返回与中断；先用测试信号模拟中断 | 覆盖符号边界、除零、停顿、CSR 副作用、异常/中断返回，记录规范差异 |
| 6 RIB 与最小 SoC | 在核心可验证后实现 ROM/RAM、地址译码、仲裁和暂停；将核接入 RIB | 从一条 load/store 追踪到目标存储器；冲突与暂停测试通过 |
| 7 外设和软件闭环 | GPIO → Timer → 定时器中断 → UART → SPI；逐个写寄存器、状态机和测试；按需引入汇编、启动代码、链接脚本、C 驱动 | 每个外设有寄存器说明、总线测试、协议波形和可运行程序 |
| 8 下载、调试与板级集成 | UART 下载、JTAG 和跨时钟握手；综合、约束、时序、逐项上板；再做综合演示与 FreeRTOS 集成学习 | 验证下载、读写、暂停/恢复及外设程序；区分仿真、时序和板上证据 |
| 9 独立迁移 | 合上原 RTL，依据自己的规格实现一个有小变化的核心或子系统 | 能自己划分接口、写 RTL/测试、解释取舍并排错 |

单周期版本是逐步搭建的教学中间产物，不要求先写两套完整处理器。先让最小子集运行，再逐步扩展和流水线化。后续发现缺少前置知识时插入短练习。

## 资料、接口与验证约定

- 根目录 RISC-V 中文手册：第 1 章建立 ISA 概念；第 2 章随指令学习；第 3 章用于汇编、调用和链接；第 4 章用于 RV32M；第 10 章用于机器模式。每课只选相关小节。
- 根目录 Reference card：需要编码和寄存器速查时使用，不要求一开始背表。两份资料为转换文本，疑似 OCR/排版错误先核实；规范与项目实现不一致时分别标注。
- 每个模块实现前逐步写明接口、复位极性、采样时刻、延迟、优先级及边界行为。教学接口可以简单；接入上游时单独设计适配，不把教学接口称为已兼容 RIB。
- WaveDrom 用于预期时序说明，实际行为以仿真日志和波形为证。波形示意必须标注采样边沿和每周期含义。
- 模块定向测试 → 核心短程序 → 上游 ISA/signature 回归 → 外设系统测试 → 综合与时序 → 板上测试。测试失败、超时和未执行分别记录。
- 上游路径：D:\Study\RISC-V\TinyRiscV\tinyriscv-master。保留原文件，不将上游跑通等同于自主实现。原测试与 C 例程本会话尚未重新验证。
- Vivado XSim 已验证能运行此前演示。Python 如有需要必须用工作区 .venv，包由 UV 管理。文件操作用 PowerShell，不能使用 rg。
- 原 Artix-7 35T 示例与邻近升腾 Mini FGG484 板级记录不能混用约束；板级阶段核实实际器件和引脚。最终 RV32IM 范围明确后再谈合规，不用历史少数测试宣称完全符合规范。

## 上次收尾安排：接续 RV32M 乘法组

本次会话已结束，当前没有待修复的用户代码或待重跑仿真。已完成并记录：

- XORI/ORI/ANDI：28条定向PASS，覆盖符号立即数、边界、紧邻依赖和x0保护。
- SW/LW与跳转取消：11条定向PASS，覆盖组合RAM读回、同步写、load旁路和错误路径store取消。
- LB/LBU/LH/LHU/SB/SH：本人PASS，覆盖四个byte lane、两个自然对齐半字、符号/零扩展、写掩码和跳转取消副作用。

下次从`MUL/MULH/MULHSU/MULHU`整组开始。共享R型`opcode=0110011`和`funct7=0000001`，`funct3=000/001/010/011`。MUL取64位乘积低32位；后三条取高32位，分别为signed×signed、signed×unsigned、unsigned×unsigned。用户亲写译码、valid/IDEX、EX组合乘法结果选择和统一TB，覆盖符号/无符号高位差异及紧邻消费。先不引入除法、余数、busy/done或多周期停顿。

下次启动时读取四份入口文档，直接接收用户的M组预测、RTL/TB和仿真日志；不复习或重做上述PASS。

















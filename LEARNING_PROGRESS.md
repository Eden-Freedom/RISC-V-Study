# TinyRISC-V 学习进度

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

## 历史收尾（2026-10-28）：4位除法手推及单轮组合逻辑正确，尚未进行除法仿真

本次学习已按用户要求结束，不新增练习、不补跑仿真。用户提交4位11/3四轮手推及一轮组合逻辑，助手静态评审均正确；当前没有待答手推题或待修组合片段。

- 手推原答案：四轮取位1/0/1/1，T=1/2/5/5，商新位0/0/1/1，R=1/2/2/2，Q=0110/1100/1001/0011。最终商3、余数2，11=3×3+2。
- 用户聊天提交的组合片段：trial={r_reg,q_reg[3]}；rem_work默认trial；q_next默认左移补0；trial>={1'b0,d_reg}时商最低位置1并减除数；r_next=rem_work[3:0]。5位临时量和unsigned比较正确、默认赋值完整、使用阻塞赋值，无发现本轮组合功能问题。按算法的合法迭代状态使用。
- 证据归属：用户依讲解提交手推及Verilog片段；助手仅静态审阅并维护文档，未运行HDL/Python，未修改核心RTL/TB。聊天片段尚未核对是否落盘，不能记为已保存的完整divu_unit；本轮不是除法器仿真PASS。
- 掌握证据限于能手推这组逐位除法，并提交正确单轮组合逻辑。start/busy/done、时序装载、迭代计数、最终next值输出及复位/忙时行为仅已讲解待练习；尚无完整多周期除法器、32位除法或流水线除法证据。
- 下次唯一入口：直接沿用这段正确的4位组合逻辑，先讲清并由用户亲写最小4位时序控制（复位、start装载Q/R/D、忙时每拍保存next、4轮计数、完成时输出最后一轮next并产生done）。四位原型验证后再扩32位，随后才做signed包装与流水线暂停。不重复11/3手推，不要求重交已评审组合片段，不直接催32位整模块/TB。
- 原乘法组本人PASS保持：57条指令/35条乘法；逻辑立即数28条、对齐SW/LW11条、字节/半字访存本人PASS及更早验收保持。乘法TB/配套程序头部注明助手编写，用户本人运行，与用户RTL成果分开记录。

### 本轮聊天代码归档（仅文档记录，非核心RTL落盘）

以下去除了聊天富文本标记，保留用户提交的Verilog语义。它与此前助手讲解示例一致，记录为用户依讲解提交的正确片段，不据此声称用户已独立设计完整除法器。

```verilog
reg [3:0] q_reg;
reg [3:0] r_reg;
reg [3:0] d_reg;

reg [3:0] q_next;
reg [3:0] r_next;

reg [4:0] trial;
reg [4:0] rem_work;

always @(*) begin
    trial = {r_reg, q_reg[3]};
    rem_work = trial;
    q_next = {q_reg[2:0], 1'b0};

    if (trial >= {1'b0, d_reg}) begin
        q_next[0] = 1'b1;
        rem_work = trial - {1'b0, d_reg};
    end

    r_next = rem_work[3:0];
end
```

### 收尾后的接续边界

没有新的待答题；不再把旧的11/3手推或整模块/TB催交条目作为当前任务。start/busy/done等控制先前只有助手讲解，下一次从4位原型时序行为继续，等待用户实现再评审/验证。会话结束后不继续教学或运行测试。

## 历史教学快照（2026-10-28前置讲解，随后手推与组合逻辑已通过静态评审）

用户明确从未用Verilog编写除法器、前置原理不足，要求先非常详细、浅显地讲解并使用比喻。本轮已改为补齐原理；此前整模块/TB提交任务暂缓，不将其当作下一条必须提交的作业。

本轮讲解范围：除法与余数定义；十进制竖式带位到二进制带位；T=2R+b及D>0时T<2D、每轮最多减一次；4位13/3完整R/Q状态与Q兼任待处理位队列和商位容器；比较/减法组合电路与时钟寄存器反馈；4位单轮组合逻辑最小示例；阻塞/非阻塞赋值及next值；start/busy/done与E0受理、E1～E32迭代；位宽/计数和除零说明。示例与过程均为助手讲解，未记作用户回答或用户实现。

当前唯一小练习：按给出的过程手推4位11/3（Q初值1011、R初值0000、D=0011）的四轮T、新商位、R、Q。等用户尝试/疑问后再评审，理解单轮后逐步写组合单轮逻辑，再接启动/迭代/完成控制。不重做乘法，不直接催交完整除法器，不提前进入有符号包装或流水线停顿。

证据状态：无divu_unit用户代码/仿真；原乘法PASS保持。助手本轮仅读取记录/教学指南、核对Vivado文档和维护四份学习文档，未修改核心RTL/TB，未运行HDL或Python。

## 历史快照（2026-10-28乘法验收后，随后用户说明除法前置不足）

### 本人提交与纠错

- 用户原回答：rs1=80000000、rs2=FFFFFFFF；MUL=80000000、MULH=FFFFFFFE、MULHSU=7FFFFFFE、MULHU=7FFFFFFF。MUL/MULHU正确；MULH正确值00000000，因为(-2^31)×(-1)=+2^31，完整积00000000_80000000；MULHSU正确值80000000，因为(-2^31)×(2^32-1)=-2^63+2^31，完整积80000000_80000000。已解释，未新增重复预测题，不能把本轮PASS记为用户手算全对。
- 用户称修改后的RTL/TB位于约定目录，并报告本人PASS: all MUL/MULH/MULHSU/MULHU checks passed, instructions=57, multiplies=35。没有要求补跑该通过测试。
- 归属：RTL为用户提交实现；tb_mul.v与mul_imem_case.txt头部声明Assistant-authored/requested by learner，按辅助TB/程序记录，本人运行仿真归用户；不据文件同步认定全部测试独立亲写。

### 助手实际核对与证据边界

- 实际静态读取约定Vivado目录的addi_decode、pipeline_core、id_ex、ex、imem、tb_mul及配套程序。四条译码funct7/3、valid支持集合、顶层连线、IDEX reset/flush/capture正确；EX两个33位signed扩展量、66位signed积及[31:0]/[63:32]选择均在预期路径。乘法写回处于valid内部。
- PowerShell BigInteger参考计算：59项ROM，按执行路径比对TB全部57条检查的PC/rd/data/两源/控制/跳转目标，35条乘法，0不匹配；最终PC=E8、x19=55、x21=56。此为静态参考核对，不是HDL仿真或独立第二份PASS。
- TB覆盖普通正数、零/1、FFFFFFFF、80000000、7FFFFFFF、SU交换两源、运算前后两路紧邻依赖、四条写x0与真实读口/旁路保护、EX及沿后写回、非访存副作用、reset/flush气泡、完成计数和10000ns超时。
- JAL@D0跳到DC，监视D4/D8错误路径MUL/MULHU不得进入有效EX；目标x21=56验证x19未被污染。终点JAL@E8已检查提交后的valid清零和idle，区别于此前在终点提交前结束的TB。
- 助手仅静态核对、执行PowerShell参考计算和维护学习文档，未改RTL/TB，未运行HDL或Python。本组证据不扩大为完整RV32M、除法、多周期控制或目标频率达标。

### 当前唯一待办：独立无符号迭代除法器（已讲解待用户实现）
- 下一项完整小主题是独立divu_unit：32位unsigned被除数/除数，同时输出32位商/余数；用逐位比较减法，每周期处理一位，不用RTL的 / 或 %，暂不改流水线。
- 接口契约：clk，低有效同步rst_n，start_i（空闲时一拍请求），dividend_i/divisor_i[31:0]，busy_o，done_o，quotient_o/remainder_o[31:0]。E0受理并锁存；E1～E32迭代，E32输出最后一轮next值、busy=0且done=1，随后done清零。busy期间忽略start和外部输入变化；结果保留至下次完成，复位取消运算并清零。
- 数据通路：32位Q初值被除数、32位R初值0、32位D锁存除数；33位T={R,Q[31]}。Q左移一位，T>=零扩展D时R取T-D且商新位1，否则R取T且商新位0。迭代32次，最后输出更新后的Q/R，不能误用末轮旧寄存器值。
- 所有输入包括除数0均固定迭代32次；除零商FFFFFFFF、余数等于被除数。计数器若表示剩余32～1需6位，若表示索引0～31则5位即可。
- 用户亲写模块与统一TB；覆盖13/3、0/7、7/1、2/3、FFFFFFFF/2、80000000/FFFFFFFF和除零，以及busy期间改输入/请求、结果保持、done脉宽、复位取消与重启。未提交前状态仅已讲解待练习，后续再做有符号包装和流水线停顿/一次提交。

下面保留历史记录；旧待交预测/乘法实现任务均已被本次验收取代。

## 历史教学断点（2026-10-28乘法组，随后已提交并PASS）

- 用户本轮要求恢复断点；四份入口文档最新状态一致，旧PASS不重做，无待修失败日志。
- 本轮教学范围：MUL低32位；MULH SS、MULHSU SU、MULHU UU高32位；重点解释FFFFFFFF位模式的不同数值、MULHSU的rs1/rs2方向及Verilog符号/位宽。
- 示例由助手给出：FFFFFFFF×FFFFFFFF，SS完整积0000000000000001，SU完整积FFFFFFFF00000001，UU完整积FFFFFFFE00000001。它们不是用户预测或仿真结果。
- 可选实现建议：两个33位signed扩展操作数、66位signed中间乘积，保持取[31:0]/[63:32]；先扩展再相乘，不能把混合signed/unsigned表达式直接当作SU数学乘法。组合EX一个周期完成是假定的教学时序，尚无综合/目标频率证据。
- 唯一待办：用户整组亲写decode/valid/顶层/IDEX/EX和统一TB，自行运行后提交。覆盖符号边界、SU两源交换、两路源旁路与乘法结果紧邻消费、x0/valid及无RAM/redirect副作用、完成/超时。
- 待用户预测：rs1=80000000、rs2=FFFFFFFF时，MUL/MULH/MULHSU/MULHU各写回什么；允许和代码/日志一并提交。
- 证据归属：本轮尚无用户回答、M组实现或PASS。助手读取入口文档、教学技能、中文手册4.1节与当前Vivado ex接口，核对官方M扩展资料并维护文档；未改核心RTL/TB，未运行HDL/Python。除法/余数/busy/done另开主题。

下面保留上次收尾与历史验收；其中“会话结束/下次”均指当时，不能覆盖上述当前任务。

## 上次收尾快照：2026-10-28；三组流水线扩展完成

### 本次会话完成与证据

- 用户先提交并报告XORI/ORI/ANDI：`PASS: all XORI/ORI/ANDI checks passed, instructions=28`。助手静态确认三条I型逻辑立即数接入decode、valid、顶层、ID/EX reset/flush/capture和EX，参考计算28条rd/结果与TB一致。证据覆盖正/零/负立即数、-2048/2047、高位位模式、紧邻依赖和x0读口/旁路。
- 用户随后提交并报告对齐SW/LW与跳转取消：`PASS: all memory/jump checks passed, instructions=11`。助手静态确认S/I立即数、RAM组合读/同步写、SW写掩码1111、LW写回、load旁路和JAL flush接线。TB证明memory[16]=42、memory[17]=43，LW→ADDI/ADD和ADDI→SW依赖正确，0x24错误路径SW未执行。
- 用户最后提交并报告LB/LBU/LH/LHU/SB/SH：`PASS: LB/LBU/LH/LHU/SB/SH checks passed`。助手静态确认六条控制、lane选择、符号/零扩展和写掩码接入pipeline。TB以`80FF7F01`覆盖byte偏移0/1/2/3、半字偏移0/2，SB四个lane、SH低/高半字，目标LW和紧邻ADDI；最终memory[16]=`33441122`，JAL@0x6C取消0x70/0x74错误路径。
- 本会话所有RTL/TB修改和仿真日志归用户；助手只做静态审阅、机器码/预期参考计算和四份文档维护。助手未修改核心RTL/TB、未代跑HDL/Python。测试均为定向证据，不宣称完整RV32I/RV32IM、异常、非对齐/越界或同步存储器适配。

### 当前状态与暂停点

- 本次学习按用户请求结束；没有未处理失败日志、未完成修复或需要补跑的已通过测试。
- 已掌握/完成的流水线机制证据：valid保护、ID/EX控制字段传递、已有EX→ID旁路、JAL flush取消寄存器和存储副作用、组合RAM load回写、字节/半字lane选择与扩展。
- “已通过代码”记录为用户实现和用户仿真证据；不把助手静态核对当作用户独立掌握证明，也不把定向TB扩大成完整ISA覆盖。

### 下次唯一入口：RV32M乘法组（已解释待用户实现／验证）

- 当前代码搜索未发现`funct7=0000001`或M型控制。下次整组接`MUL/MULH/MULHSU/MULHU`：R型`opcode=0110011`，funct3=`000/001/010/011`。
- EX使用64位组合乘积：MUL取低32位；MULH为SS高32位；MULHSU为SU高32位；MULHU为UU高32位。源操作数复用旁路，结果复用写回和紧邻消费旁路。
- 用户提交统一TB时覆盖正数、`FFFFFFFF`、`80000000`、signed/unsigned高位差异及紧邻ADD/ADDI依赖，检查EX/沿后写回、无访存/跳转副作用和完成条件。
- 除法/余数、busy/done、多周期停顿与异常优先级不并入本组；当前没有M组用户代码或日志。
## 历史验收：2026-10-28；流水线字节/半字访存本人PASS，会话收尾前待RV32M乘法

- 用户说明修改后的代码和`tb_store_load.v`已在约定目录，报告本人`PASS: LB/LBU/LH/LHU/SB/SH checks passed`。助手实际静态读取decode、pipeline_core、id_ex、ex、ram、imem和TB；未修改核心RTL/TB、未运行HDL或Python。
- 当前六条已从decode进入valid支持集合、ID/EX字段和EX。LB/LBU/LH/LHU使用完整字节地址读取RAM字，按地址低两位选择byte/半字后分别符号或零扩展；SB/SH按地址低位生成lane写掩码并保留未选byte。自然对齐半字地址为00/02。
- TB初始化`memory[16]`为`80FF7F01`，覆盖LB/LBU偏移0/1/2/3，LH/LHU偏移0/2，检查结果`1/7F/FFFFFFFF/80/7F01/7F01/FFFF80FF/80FF`；随后SB四个lane形成`DDCCBBAA`，SH低/高半字形成`33441122`。目标LW读回该字，紧邻ADDI得到`33441123`。
- JAL@0x6C跳到0x78；TB监视0x70/0x74错误路径SB/SH不得进入有效EX，最终memory[16]仍为`33441122`。reset/写掩码/扩展与旁路证据由用户PASS给出；不扩大为非对齐、越界、异常或完整ISA验证。

### 下一唯一动作：流水线RV32M乘法组（已解释待实现／验证）

- 当前代码搜索未发现M型控制或`funct7=0000001`译码。下一批为`MUL/MULH/MULHSU/MULHU`四条，共享R型opcode `0110011`，funct3分别000/001/010/011且funct7固定0000001。
- 先把组合乘法器接入现有EX写回：MUL取低32位；其余三条取64位乘积高32位，分别使用signed×signed、signed×unsigned、unsigned×unsigned。两个源操作数复用旁路，结果复用写回和紧邻消费旁路。
- 这是新数据通路但不是多周期练习。除法/余数、busy/done、停顿和多周期副作用另开主题，不把乘法PASS写成完整RV32M。
- 统一TB覆盖正数、`0xFFFFFFFF`、`0x80000000`、signed/unsigned高32位差异及紧邻ADD/ADDI依赖；检查EX和沿后写回、非访存/非跳转副作用、完成/超时。当前无本组用户代码或日志；不重做已通过SW/LW或六条字节半字访存。
## 历史验收：2026-10-28；流水线SW/LW与跳转取消本人PASS，当时待字节/半字访存

- 用户说明修改后的RTL和`tb_store_load.v`已放入约定目录，报告本人`PASS: all memory/jump checks passed, instructions=11`。助手实际静态检查decode、pipeline_core、id_ex、ex、ram、imem和TB；未修改核心RTL/TB、未运行HDL或Python。
- 当前SW/LW已从decode经valid和ID/EX字段进入EX，RAM实例使用组合读、上升沿同步写。EX中SW计算`rs1+S立即数`、发送rs2和`1111`写掩码且关闭寄存器写；LW计算`rs1+I立即数`，把RAM读回值送寄存器写回。默认信号受valid保护。
- TB共11条有效检查，PC顺序为0x00、04、08、0C、10、14、18、1C、20、28、2C；其中0x24错误路径不计入有效指令。检查reset空闲、SW两处地址/数据/掩码、memory[16]=42与memory[17]=43、LW三处读回与沿后写回、LW→ADDI rs1旁路、LW→ADD rs2旁路、ADDI→SW rs2旁路。JAL@0x20要求target=0x28、flush有效，并监视0x24不进入有效EX，最终确认memory[16]未被错误store修改。
- 静态参考提取ROM得到12个入口：`04400093, 02A00113, FE20AE23, FFC0A183, 00118213, 0040A023, 0000A283, 00500333, 0080006F, FE00AE23, FFC0A383, 0000006F`；TB检查调用11次。与用户PASS一致。完成点JAL自身的link/redirect被检查，但仿真随后结束，不扩大为动态JAL提交后行为或完整访存ISA。
- 本批证明了新的流水线RAM连接、组合load回写、已有旁路复用和跳转对存储副作用的取消。尚未证明LB/LBU/LH/LHU/SB/SH、非对齐/越界异常或同步读RAM适配；不重跑已通过单周期SW/LW。

### 下一唯一动作：流水线LB/LBU/LH/LHU/SB/SH（已解释待实现／验证）

- `addi_decode`已有六个控制，`addi_execute`保留单周期lane选择参考；当前pipeline只接SW/LW。用户下一轮整组新增控制与ID/EX、valid、顶层和EX处理，复用当前RAM/旁路/flush。
- 新增关键行为：SB按地址低两位写一个byte，SH按低/高半字写`0011/1100`；LB/LBU按byte选取后分别符号/零扩展；LH/LHU按自然对齐低/高半字选取后分别符号/零扩展；其余lane保持。读写完整字节地址，RAM索引取`[6:2]`。
- 统一TB覆盖byte地址00/01/02/03、半字地址00/02、符号位为1与零扩展差异、SB/SH保留其他lane、紧邻load消费和跳转取消SB/SH副作用。先限定自然对齐和当前RAM窗口；非对齐半字、越界和异常不在本轮。
- 当前只有任务说明，无本组用户代码/日志；此前逻辑立即数28条、U型17条、ALU70条、分支、旁路、JAL/JALR及本轮SW/LW均已通过，不重复。
## 历史验收：2026-10-28；逻辑立即数本人PASS，当时进入流水线访存

- 用户说明修改后的RTL和tb_logic_imm.v位于约定Vivado目录，报告本人`PASS: all XORI/ORI/ANDI checks passed, instructions=28`。助手实际静态读取decode/core/id_ex/ex/imem/TB与当前ram.v，并对比单周期addi_core的地址接线；未读取上游答案、未改核心RTL/TB、未运行HDL或Python。
- 三条控制均纳入valid、顶层和IDEX reset/flush/capture；decode只按opcode/funct3识别普通I立即数，符号扩展全部12位，I型rs2读x0；EX在valid内部用rs1与immi按位运算，无发现本批功能错误。
- 助手用临时PowerShell参考计算ROM的28条受检指令：ADDI2、ADD4、XORI8、ORI7、ANDI7，rd/结果全部与TB一致。ROM29项，末项JAL@0x70为0000006F。此为静态核对，不是助手HDL运行或独立第二份PASS。
- tb_logic_imm每项在下降沿等待valid、查PC/EX写回与无redirect/flush，在下一上升沿#1查非零寄存器并计数。数据覆盖0/正/负立即数、-2048/2047、FFFFFFFF与高位掩码。0x4C查XORI→ORI锁存rs1/rs2=666/0，0x50查ORI→ANDI=6E6/0，0x54查ANDI→ADD=0/E6；0x58/60/68三次写x0时直接查真实读口/旁路均0，后继0x5C/64/6C查锁存0/0。
- 完成条件为有效EX且is_jal、PC=0x70、checked=28与最终寄存器值；有5000ns超时。终点JAL尚未提交即结束，不称新增控制动态flush覆盖或完整ISA合规。用户本批定向验收；此前U型17条/ALU70条/条件分支等验收保留，不重做。

### 下一唯一动作：流水线对齐SW/LW（已解释待实现／验证）

- pipeline_core访存控制仍空接，无RAM实例，不能将单周期访存证据记作流水线完成。当前用户ram.v组合读、上升沿同步字节使能写，32字深度，单周期core以有效字节地址[6:2]接RAM字索引。先接0～127字节窗口内自然对齐字通路，再整组接LB/LBU/LH/LHU/SB/SH。
- 新机制为RAM读回进入EX写回及原EX→ID旁路、SW同步副作用及flush取消。讲解：LW在EX沿间由地址→组合RAM→写回/旁路，后继ID在同一沿锁存该数据，因此当前模型可复用旁路，不机械添加load-use停顿；同步读BRAM/总线延迟以后另讲。访存语义复用已有单周期练习，本轮新增的是流水线RAM连接与相关处理。
- 用户亲写is_sw/is_lw与S立即数跨级、valid/顶层/EX RAM接口/RAM实例；SW用旁路后的rs1/rs2，sel1111，不写寄存器；LW用I立即数并写回RAM读值；RAM读写使能受valid保护，默认禁用。范围仅自然对齐及教学窗口，截位不等于高地址译码/越界/非对齐异常支持。
- 建议统一程序详见LEARNING_PLAN当前入口：基址68、数据42，SW/LW -4；load→ADDI得43→SW 0；LW→ADD的rs2依赖；JAL@20跳过24处SW x0,-4，28处LW回读42，2C终点。最终memory16=42、memory17=43、x3=x7=42、x4=x5=x6=43。检查访存接口/提交后RAM、load写回、依赖操作数、无效不写及完成/超时。可同回复交代码/机器码/TB/本人日志，无须重做旧单周期测试。
- 当前访存仅助手解释与任务，无用户本轮预测/实现/仿真；用户已完成逻辑立即数代码与测试，不自动等于独立掌握任意访存时序。
## 历史验收：2026-10-28；U型修复后本人PASS，当时待逻辑立即数

- 用户报告修正后本人结果`PASS: all LUI/AUIPC checks passed, instructions=17`。助手实际读取当前ex.v:252～262，LUI/AUIPC已移入if(valid_ex_i)内部的指令选择链，外层else保留无效输出处理。原59项FAIL对应的层级错误已修复，本批定向验收，不继续旧修复待办。
- 本轮复核tb_u_type，17条check_step检查PC/EX写使能/rd/data和下一上升沿后#1非零寄存器值，计算指令另断言redirect/flush均0；直接检查LUI→ADDI及AUIPC→ADD/ADDI的锁存操作数，以及两次写x0时的真实读口/旁路和后续0/0锁存。完成条件为有效EX到达is_jal且PC=0x44、checked=17及x1～x15最终值。
- 该PASS覆盖当前程序U字段零/普通/最高位/全1、非零PC AUIPC与旁路/x0行为；没有实际跨32位加法回绕用例，且TB在终点JAL提交前结束，不虚报回绕/动态flush/完整ISA验证，不要求补跑已通过程序。
- 代码修正与HDL PASS由用户完成；此前助手已静态核对全部17条机器码的rd/预期结果。本轮只静态确认修正/TB、检查后续范围及维护四份学习文档，未代改RTL/TB、未运行HDL或Python。此前ALU70条矩阵、条件分支及其他验收保持。
- 用户完成的是依提示修复有效控制的分支层级并提供PASS；此证据不自动等于已独立掌握任意控制结构排错。保留这次经验：valid外层管副作用资格，内部指令链管具体运算。

### 下一唯一动作：XORI/ORI/ANDI整组（已解释待用户实现／验证）

- 静态检查当前decode/执行路径仍缺逻辑立即数三条，先补齐此组。opcode=0010011，funct3为100/110/111；使用全部12位I立即数并先符号扩展，不能限制funct7。与R型逻辑相同的按位运算，只改变第二操作数来源。
- 用户新增三控制信号并接入valid支持集合、顶层、ID/EX reset/flush/capture和EX valid内部运算，复用现有I立即数/写回/两路旁路，不另做单周期版本、不代写模块、不逐条拆题。
- 同一自检TB覆盖三条的正/零/负立即数、-2048/2047边界和带高位数据的掩码/取反，并安排新结果紧邻消费、完成/超时与沿后写回检查。示例源值12345678且imm=-1，XORI预期EDCBA987、ORI为FFFFFFFF、ANDI保留12345678；这是助手示例，不是用户回答或日志。
- 当前只有上述说明，没有用户本组新代码/测试结果；下一回复接整组提交或疑问。访存为后续主题，按当前RAM组合读/同步写实际时序判断，未在此轮布置访存代码。

## 历史诊断：2026-10-28；U型首轮59项FAIL，随后已修复并PASS

- 用户已提交约定Vivado目录的U型RTL、imem和tb_u_type.v，并提供本人完整失败日志`FAIL: 59 checks failed`及`Fatal: U-type test failed`。LUI/AUIPC已尝试实现，尚未通过；原ALU矩阵70条PASS及此前验收保持。
- 助手静态读取decode、pipeline_core、id_ex、ex、imem和tb_u_type。两条valid集合/顶层连线、U立即数宽度、ID/EX reset/flush/capture及EX运算表达式未发现明显错误；PowerShell核对17条受检机器码的rd/结果全部与TB一致，完成JAL位于0x44。此为静态核对，未运行HDL。
- 根因在当前ex.v:251提前结束`if(valid_ex_i)`，253/258行的`else if(is_lui_ex_i)`、`else if(is_auipc_ex_i)`成为valid判断的外层else-if。有效U型进入valid分支，却未命中内层指令选择，EX写回保持默认0/0/0；反而只有valid为0时外层U分支才有可能被选择，破坏valid屏蔽约定。
- 日志连锁表现：首条LUI未写x1，紧邻ADDI读0得到1；AUIPC未写x6/x12，后续ADD得到0、ADDI得到FFFFFFFF。59个FAIL包含EX输出、沿后写回、依赖操作数及最终重复检查，不能解释为59个独立问题。用户日志时间60000与本TB timescale对应60ns，不是首条指令等到60us。
- 给用户的最小修正：将LUI/AUIPC两个分支整体移入valid内部，接在is_jalr内层分支后、当前第251行结束valid的end前；保留外层else处理无效输出。算式不变，不代写整模块或覆盖核心RTL/TB。
- 下一唯一动作：由用户调整分支层级后重新编译并运行原tb_u_type，提交本人结果；这是失败用例修复验证，不重跑已通过的ALU/分支矩阵，不扩展新主题。当前无修正后代码或PASS。
- 助手仅静态审阅、PowerShell机器码/预期核对及学习文档维护，未改核心RTL/TB、未运行HDL或Python。

## 历史验收：2026-10-28；ALU整批本人PASS，随后进入LUI/AUIPC

### 用户提交、静态评审与验收

- 用户说明修改后的RTL和tb_alu_matrix已放入约定工作目录，并报告本人仿真`PASS: all ALU matrix checks passed, instructions=70`。本批13条流水线迁移定向验收通过；不重做本批或历史已通过练习。
- 助手实际静态读取Vivado目录pipeline_core.v、id_ex.v、ex.v、addi_decode.v、imem.v、tb_alu_matrix.v和regfile/if_id，并确认单周期addi_execute的LUI/AUIPC现有运算。13条控制均接入valid集合和顶层实例，ID/EX reset/flush/capture齐全，EX受valid保护，移位/有符号比较/SLTIU立即数解释及x0保护未发现明显功能错误。
- 助手用PowerShell提取ROM机器码和TB check_step列表，逐条按字段计算期望：70条受检编码的rd/结果全部与TB一致，ROM共71项，末项0x118为0000006F。数量为ADDI7、ADD1、AND3、OR4、XOR6、SLL5、SRL5、SRA6、SLLI4、SRLI4、SRAI4、SLT5、SLTU5、SLTI5、SLTIU6。这是静态参考计算，不是HDL仿真或第二份PASS。
- TB check_step在下降沿等待valid并检查本指令PC/EX写使能/rd/data，在下一上升沿后#1检查真实非零寄存器，累计70次。覆盖逻辑位模式、寄存器移位0/1/31/32/33、立即数移位0/1/31、正负右移、比较相等/大小/符号边界和12位立即数边界。
- 0x100/104/108/10C依赖链最终x20=6、x21=7、x22=7、x23=0；TB在0x104直接检查rs1/rs2=6/1，0x108为FFFFFFFF/7，0x10C为7/7，分别覆盖新ALU结果rs1/rs2/双源紧邻旁路。0x110 XOR写x0时检查两个真实读口和旁路均零；0x114检查锁存0/0且最终x31=0。
- 完成检查要求valid EX到达is_jal且PC=0x118、checked=70及初始化/最终保留值。70包含初始化和辅助指令，不等于70种指令；终点JAL另查不计数。TB在该JAL提交前结束，不记录新增控制字段的运行时flush覆盖；当前结果为定向矩阵PASS，不称完整RV32I/RV32IM合规。
- 代码/TB/仿真PASS归属用户提交及本人运行。助手仅静态审阅、PowerShell机器码/预期核对和同步四份学习文档；未修改用户核心RTL/TB，未运行HDL或Python。不要求用户补跑同一矩阵。

### 下一唯一动作：LUI/AUIPC整组（已说明待练习）

- 两条已有单周期基础，当前decode有is_lui/is_auipc和imm_typeu，单周期execute已实现；pipeline_core两控制和U立即数仍空接，流水线ID/EX与EX尚无该组，不记已迁移。
- 用户整组接两控制和32位U立即数，经ID/EX reset/flush/capture后到EX并纳入valid。LUI写已拼好低12位零的U值；AUIPC加本指令随流水线保存的PC，取低32位，不能用当前取指PC或重复左移。普通写回/旁路机制可复用，不发起跳转；保持现有is_xxx写法。
- 统一TB建议U字段0/0x12345/0x80000/0xFFFFF，非零PC AUIPC及回绕、两种结果的紧邻消费，保留完成/超时和写回检查。例如LUI uimm=0x12345写12345000；AUIPC@0x14且uimm=1写00001014，uimm=0写00000014，uimm=0xFFFFF写FFFFF014。示例为助手预期，不是用户回答/代码/日志。
- 当前没有该组新用户预测、代码、TB或日志，状态仅已说明待练习；下一回复接用户整组提交或疑问，不逐条拆题，不重做已验收ALU/分支等场景。

## 历史恢复：2026-10-28；ALU逻辑／移位／比较当时待迁移

- 已按用户要求读取四份入口文档，以2026-10-27日终收尾恢复阶段4；条件分支矩阵本人PASS及此前BEQ、循环、RAW/旁路、JAL/JALR验收保留，不要求重做。
- 助手实际静态读取约定Vivado目录的addi_decode.v、addi_execute.v、pipeline_core.v、id_ex.v、ex.v；结合单周期历史，确认本批为XOR/OR/AND，SLL/SRL/SRA与SLLI/SRLI/SRAI，SLT/SLTU与SLTI/SLTIU，共13条。当前decode与单周期execute已有这些控制/运算，pipeline_core对应decode输出仍空接，ID/EX与流水线EX尚无对应字段/执行分支，不记流水线已实现。
- 本轮讲解与任务：整组接通decode→ID/EX→EX，将13条加入valid支持集合；新增控制字段纳入reset/flush/capture，EX受valid保护并复用原写回与两路旁路。现有rs1/rs2/I立即数数据字段足够，按当前结构判断无需新增流水线机制；保留is_xxx风格，不要求重构。状态为已说明待用户实现/验证。
- 必要行为提醒：寄存器移位只取rs2低5位，立即数移位取I立即数低5位；SRA/SRAI对左操作数做signed解释后算术右移；SLT/SLTI为signed比较，SLTU/SLTIU为unsigned比较，但SLTIU仍先符号扩展I立即数。已核对官方RV32I 2.1整数计算小节和本地中文手册第2.4节，未要求背编码表。
- 统一验证安排：全部13条在同一自检TB/回归验证；逻辑位模式，移位0/1/31及寄存器移位量32/33、负数右移，比较小于/等于/大于及符号边界、SLTIU负立即数；安排新ALU结果紧邻依赖覆盖现有rs1/rs2旁路，并保留完成/超时和真实x0读行为检查。无需为每条单独启动仿真或先逐条答题，用户可一次提交RTL、测试程序/机器码、TB及本人日志，也可先交RTL或问疑点。
- 当前没有用户本批新预测、修改代码、TB或日志；不提升实现/掌握/通过状态。助手仅静态读取、规范核对和维护本进度，未修改核心RTL/TB，未运行HDL或Python。
- 下一唯一动作：接用户对上述13条整批迁移的实现或疑问；默认从约定Vivado目录或用户聊天提交评审，不回退rebuild旧副本。

## 历史日终收尾：2026-10-27；条件分支整批统一仿真通过

### 今日完成与证据

- 用户报告本人运行结果：`PASS: all branch matrix checks passed`。此前`tb_branch_matrix`首次只运行到1000ns并打印到达信息；按建议继续仿真后，用户报告最终PASS。
- 用户在约定Vivado路径完成条件分支流水线RTL修改，新增`tb_branch_matrix.v`并设为仿真顶层。助手此前静态审阅decode、pipeline_core、id_ex、ex、imem及TB，并用PowerShell核对15条分支机器码和目标；没有代跑HDL或修改用户RTL/TB。
- 当前TB以sticky `reached_jal`记录有效EX到达`JAL x0,0 @0x84`，等待后检查x1/x2/x3初始化值、x10～x24分支标记及到达标志。PASS表示这些TB检查通过；矩阵覆盖BNE/BLT/BGE/BLTU/BGEU对`(1,1)`、`(FFFFFFFF,1)`、`(1,FFFFFFFF)`三组输入的taken/not-taken结果。
- 证据边界：用户只报告最终PASS，没有逐拍内部信号日志；不外推为PC/flush内部时序直接断言或完整RV32I/RV32IM合规。此前已通过的BEQ、有限循环、RAW/旁路、JAL/JALR结果保留，不重做。

### 收尾归属与下一步

- 用户明确结束今天的学习。本轮仅同步AGENTS.md、LEARNING_PLAN.md、LEARNING_PROGRESS.md、LEARNING_SESSION_PROMPT.md；没有修改核心RTL/TB，没有运行HDL或Python，不新增今天的练习或补测要求。
- 下次唯一入口：已有单周期基础的ALU逻辑、移位与比较指令整组迁入流水线。范围结合用户提交代码确认；复用已学机制，不逐条拆题。该批目前无新代码、TB或日志，未记实现/通过。

## 历史诊断：2026-10-27分支整批已提交；当时仿真顶层仍使用旧tb_check

- 用户说明RTL/TB已放在约定Vivado目录，提供本人FAIL：t511ns，x1=1/x2=1/x3=FFFFFFFF/x5=0/x6=0，却仍检查上一轮JALR的8/9/55/17/33。本批现已有用户代码与失败日志，不能再记为尚未提交；尚无新矩阵PASS。
- 助手实际静态读取当前decode、pipeline_core、id_ex、ex、imem、tb_check及取指/寄存器文件。新增五条分支的valid集合、两路旁路、ID/EX reset/flush/capture、顶层接线、EX有符号/无符号谓词和双flush未发现明显功能错误；PowerShell核对34条程序位域，其中15条条件分支与三行矩阵、+8目标一致。此为静态核对，不是HDL运行或通过证据。
- 直接原因证据：tb_check.v第20行模块名已改为tb_branch_matrix；compile.log第30行也分析tb_branch_matrix，但同目录elaborate.bat第20行仍指定xil_defaultlib.tb_check，elaborate.log实际编译旧tb_check。新程序配旧TB解释了五个旧JALR预期与新初始化结果的冲突。用户应将Simulation Sources顶层设为tb_branch_matrix，关闭旧仿真并重新启动编译/elaboration。
- 独立TB问题：check_pc_stuck在任意终点要求取指pc_o==0x84；当前流水线JAL x0,0会让取指PC经过0x84/0x88/0x8C再重定向，不能据此判定完成。建议记录valid_idex_o且pc_idex_o==0x84（可同时限定is_jal_idex_o）的执行到达标志，最终检查到达标志及现有标记寄存器，保留超时失败；由用户亲自修改TB。
- 新TB等待150个posedge再#1，按当前时钟/复位检查时刻为3011ns；旧生成Tcl只run 1000ns，重新启动后需Run All使TB自行完成。下一步仅修正本批顶层/完成检查并由用户运行统一矩阵，不重跑历史已通过场景。
- 助手仅读取源码/构建日志、进行PowerShell静态位域核对并维护本进度文件；未修改用户RTL/TB/工程设置，未运行HDL或Python。现有证据不足以验收本批通过。

## 历史续接：2026-10-27恢复；当时剩余条件分支整组待实现/验证

- 已按用户要求读取四份入口文档，恢复阶段4最新断点：一次迁入BNE/BLT/BGE/BLTU/BGEU，保留BEQ；不重复已答问题或已验收的BEQ/循环/RAW/两路旁路/JAL/JALR练习。
- 本轮接续原有整批任务，复用B立即数、两路旁路、目标计算和双flush；检查新增控制字段的ID/EX reset/flush/capture、顶层接线与valid集合。统一矩阵与证据要求继续沿用下方2026-10-26收尾，不新增逐条预测门槛。
- 当前仍待用户整组RTL、机器码/测试安排、统一自检TB及本人日志；允许一次提交，也可先讨论实现疑点。没有本批新预测、代码或仿真证据，不记实现/通过。
- 助手本轮仅恢复教学上下文并维护本进度文件；未修改核心RTL/TB，未运行HDL或Python。后续评审默认使用约定Vivado目录或用户聊天提交版本。

## 历史日终收尾：2026-10-26，本次会话结束；下次整批迁移剩余条件分支

### 收尾状态与下次唯一动作

- 用户明确要求结束本次会话，按流程总结记录；本轮只维护四份入口文档，不新增当日任务、不要求测试。阶段4继续，下次直接接BNE/BLT/BGE/BLTU/BGEU整组实现或用户疑问，BEQ已验收不重做。
- 本批尚无用户预测、迁移RTL、统一TB或日志，状态为已说明待用户实现/验证，不得写成已通过。原单条BNE任务已撤销为历史，不再逐条分轮出题。
- 用户可下次直接提交整组代码/机器码/TB/本人日志，无需先分条答题。默认评审Vivado sources_1/new与sim_1/new；不回退旧rebuild副本，不代写核心或完整TB，不催双版本同步。

### 本次会话完成与证据归属

| 主题 | 用户本人证据 | 结论及范围 |
|---|---|---|
| 流水线JAL正偏移 | 链接08/目标14/最终x1=8、x2=9、x3=55、x6=9预测正确；提交RTL/TB及PASS | t91双valid清零且x1=8；t151 x2=9，t171 x3=55。链接写回与冲刷并存的本程序定向通过 |
| JAL负偏移与rd=x0 | 本人逐拍TB/PASS，最终x1=4、x2=5、x3=55、x6=9；检查真实x0双读端口 | t71/151/231双valid清零；t291最终结果通过，rd=x0不阻止跳转。PC顺序漏08及注释错位已指出，不另要求重答/重跑 |
| JALR正向紧邻依赖 | ADDI x5=17后JALR x1,x5,4，本人TB/PASS；最终x5=17、x1=8、x2=9、x3=55、x6=0 | t91双flush且链接8，t151 x2=9，t171 x3=55。静态旁路连接及功能结果支持本程序通过；TB未直接断言内部rs1/target。用户口头链接14错误已纠正，TB实际检查8正确 |
| JALR -2边界诊断 | 用户截图目标0x0E，PC随后0x12/16等，errors递增 | 计算0x11-2=0x0F清bit0得0x0E正确，但非4字节对齐目标超出当前正常取指范围；不记PASS。助手选例疏漏，不归咎用户；异常未实现，不清低两位规避 |
| JALR -4修正场景 | 当前imem为FFC280E7，用户本人PASS；TB保留复位EX检查和五个最终断言 | t25解除复位后25个posedge并#1，t511检查x1=8/x2=9/x3=55/x5=17/x6=33。旧逐拍检查全部注释，仅记本程序最终结果定向通过，不虚报本次内部时序覆盖 |

- 上述代码和PASS均归属用户本人。助手在前面轮次实际读取约定Vivado源码/TB、核对机器码和截图、做静态评审及文档维护；没有代跑HDL、没有修改用户核心RTL/TB。聊天代码与磁盘版本只对实际核对范围作结论，不称整工程逐文件一致或完整RV32IM合规。
- 先前已验收的BEQ taken/not-taken、有限倒计数循环、RAW和两路旁路保留通过状态，下次不重做。

### 永久节奏更新：用户已明确并确认

- 按是否新增流水线硬件机制分组，而非一条指令一轮：单周期已熟、仅需复用已有运算/控制/连线的同类指令整批实现、统一仿真、一次提交。已有两路旁路/flush不因换opcode而重讲。
- 新旁路来源、停顿/load-use、访存延迟/握手、多周期busy/done、异常/副作用优先级等机制出现时才单独讲解，验证代表机制后再扩同类。load是否需要暂停取决于实际RAM时序，不机械套用其他流水线结论。
- 一份统一自检TB应覆盖各指令必要场景，但不要求每条单独启动仿真或逐轮交作业。普通ALU、移位/比较、高位立即数组在已有基础上可合并；不把访存/M/CSR等未学机制不加区别塞到同一批。

### 下次保留批次与验收矩阵（本日不新增执行要求）

一次接BNE/BLT/BGE/BLTU/BGEU，复用B立即数、已有两路旁路、pc_idex+imm_b目标及双flush；只增加控制字段与比较谓词，分支不写通用寄存器。ID/EX reset/flush/正常捕获和顶层valid集合都需纳入；signed比较两操作数均做signed解释。沿用is_xxx即可，不强迫重构。

| rs1 | rs2 | BNE | BLT | BGE | BLTU | BGEU |
|---|---|---|---|---|---|---|
| 00000001 | 00000001 | N | N | T | N | T |
| FFFFFFFF | 00000001 | T | T | N | N | T |
| 00000001 | FFFFFFFF | T | N | T | T | N |

统一TB自动切用例或有限程序均可。保留每例完成标志/检查点、taken错误路径取消和not-taken顺序效果，避免未执行也PASS。参考中文手册2.6节与Reference card分支编码，必要时查表，不要求背诵。下次直接接用户尝试，不再布置原单条BNE作业，不加入访存/暂停/异常。

### 本次收尾维护边界

仅同步AGENTS.md、LEARNING_PLAN.md、LEARNING_PROGRESS.md、LEARNING_SESSION_PROMPT.md。未更改RTL/TB/机器码，未运行HDL或Python，未将新待办记为用户完成。旧快照保留为历史，以本顶部日终快照为续接依据。


## 历史过程：2026-10-26；用户要求同类批量推进（以上方日终快照为准）

- 用户明确说明单周期很多指令已熟悉，要求没有新增知识、只需运算/字段/连线迁移的同类指令一次实现、统一仿真；例如六类条件分支只差条件/符号解释，不应再逐条练习。遇到单周期未涉及的新旁路机制、冲刷、暂停等新知识才单独讲解。助手接受并同步四份入口文档为长期约定；当前旁路/flush已学可复用，不重复整课。
- 当前任务从单独BNE变为BNE/BLT/BGE/BLTU/BGEU整组迁入流水线；BEQ已验收无需重做。原BNE专属六条程序不再必交，不要求新一轮先单独答预测。用户可直接交整组RTL/机器码/统一TB/本人日志；尚无本批证据。
- 实现范围：已有decode比较控制经ID/EX（复位/flush/捕获），加入valid支持集合，EX用旁路后的rs1/rs2比较；有符号两边均signed解释，无符号保持unsigned；共用B型立即数目标/现有双flush，条件不成立不冲刷，分支不写寄存器。不强制重构控制编码。
- 统一测试矩阵：rs1/rs2为1/1时BNE/BLT/BGE/BLTU/BGEU结果N/N/T/N/T；FFFFFFFF/1时T/T/N/N/T；1/FFFFFFFF时T/N/T/T/N。一次TB自动运行全部用例，不逐条启动或逐轮确认。每个条件都覆盖taken/not-taken，并有完成/路径副作用检查，不把统一等同无覆盖。
- 后续已有ALU逻辑/移位/比较可合并，LUI/AUIPC可合并；load/store、乘除、CSR等先讲新增时序/机制，再扩指令族。每轮一个主题改按新机制或指令族划分，而非opcode条数。
- JALR -4最新本人PASS与最终五寄存器检查继续有效，已通过程序不重复。此轮仅更新长期约定与学习计划，无用户新代码/测试，无助手HDL/Python运行或核心文件修改。


## 历史快照：2026-10-26较早；JALR -4通过，单条BNE任务后被批次替代

### 最新用户证据

- 用户本条仅报告更改指令后`PASS: all checks passed`。助手实际读取当前Vivado imem/tb_check，指令为FFC280E7：x5=17，JALR x1,x5,-4；目标计算预期0x11-4=0x0D，清bit0得0x0C。
- 当前TB原t31～t171逐拍valid/寄存器检查已全部注释。仍执行t15复位EX默认值检查；t25解除复位后等待25个posedge并#1，在t511检查x1=8/x2=9/x3=55/x5=17/x6=33，随后PASS/finish。当前保留的t191注释不对应实际检查时刻；不将注释当成执行时间。
- 依据当前源码检查项与用户本人PASS，记录负I立即数与bit0清零场景最终结果定向通过。未直接断言本次PC/target/EX操作数或flush时序，不虚报覆盖。助手未代跑HDL、未改核心RTL/imem/TB、未运行Python；不要求用户为补覆盖重跑。
- 主动纠正助手前轮选例：建议x5=17、imm=-2导致0x0E，未考虑当前RV32I目标4字节对齐，是助手测试设计疏漏，不是用户操作错误。0x0E计算正确但异常路径未实现，不能将其记录为合规执行；不能把JALR改为清低两位来规避。

### 下一项：流水线BNE（已说明待用户实现/测试）

- 单周期BNE已学，当前将其迁入流水线。目标仍pc_idex+imm_b，taken谓词rs1!=rs2，taken才重定向/双flush，BNE不写通用寄存器；复用两路旁路。用户待接is_bne经ID/EX的reset/flush/capture及支持valid集合，EX新增不等比较。
- 任务PC00/04/08/0C/10/14依次为ADDI x1,x0,1；ADDI x2,x0,2；BNE x1,x2,+12；ADDI x6,x0,11；ADDI x6,x0,22；ADDI x3,x0,55。先接用户执行路径与最终x6/x3预测、本人机器码/相关RTL/TB/日志，可同回复交；再仅将x2初值改1验证not-taken。此任务尚无用户回答/实现/运行证据。
- 不重做BEQ/循环/旁路/JAL/JALR已验收程序，不同时增加访存、暂停或异常。助手仅维护四份学习文档。


## 历史快照：2026-10-26较早；JALR -2后当时待重测

### 用户最新提交及证据

- 用户把imem的0x04指令改为`FFE280E7`，即JALR x1,x5,-2；提交XSim截图。截图t70附近显示`is_jalr_ex_i=1`、`pc_brench_addr_ex_o=0x0000000E`，符合`x5=0x11`加符号扩展`-2`得0x0F、再清bit0得0x0E。
- 当前imem只对0x00、0x04、0x08、0x0C、0x10、0x14、0x18返回指令；目标0x0E不在表内，之后PC以+4变为0x12、0x16、0x1A等，同样不命中。截图波形可见PC从0x0E继续递增，`errors`后续出现1、3、5等递增，说明现有TB预期与错位取指流不一致。
- 这是测试地址与当前教学核心取指模型不匹配，不是从波形可判定的JALR加法/清bit0错误。官方RV32I语义是JALR先将符号扩展I立即数加到rs1，再将结果最低位清零；目标若未满足当前4字节取指对齐，完整实现应有instruction-address-misaligned异常路径。本核心当前尚未实现异常，本轮不把0x0E当作正常可执行目标。
- 本轮没有用户PASS日志；不记JALR负立即数/bit0边界通过。助手只查看截图、当前imem/TB和已有RTL，未运行HDL或修改核心/TB。

### 当前唯一任务：JALR -4 对齐目标重测（已解释待练习）

- 保留x5=17，改为`JALR x1,x5,-4`，机器码`FFC280E7`。计算：0x11-4=0x0D，清bit0后目标0x0C，既覆盖负I立即数又覆盖奇数结果清bit0；目标落在现有imem入口。
- 继续检查JALR执行沿的双valid清零、x1链接=0x08、错误路径0x08不写x6，以及目标0x0C之后的0x10/0x14/0x18。按当前程序预期最终x5=17、x1=8、x2=9、x3=55、x6=33。
- 预计PC架构顺序为0x00→0x04→0x0C→0x10→0x14→0x18（流水线前端会同时短暂持有并冲刷0x08等年轻位置）；待用户提交本人TB/日志。当前未通过，不重做已验收JALR正向旁路。
- 不扩展instruction-address-misaligned异常、调用栈、访存或暂停。

## 历史快照：2026-10-26较早；JALR正向通过，负I边界待测

### 用户最新提交及验收

- 用户预测加法结果21、目标0x14、最终x5=17/x1=8/x2=9/x3=55/x6=0；最终结果和目标路径判断正确。第1项将链接地址口述为0x14是局部错误，正确为JALR@0x04的pc+4=0x08；用户TB t91检查x1=8，实际实现/证据正确，不要求重答或重跑。
- 用户提交TB和本人日志`PASS: all checks passed`。t31/t51 valid为(1,0)/(1,1)且寄存器未写回；t71 x5=17；t91 valid=(0,0)、x1=8、x5=17；t111 valid=(1,0)；t131 valid=(1,1)且x6=0；t151 x2=9；t171 valid=(1,0)、x3=55、x6=0。随后等待六个posedge，无额外断言。
- 助手实际读取当前约定目录pipeline_core、id_ex、ex、addi_decode、imem、tb_check。静态核对：decode的is_jalr接入顶层；valid支持集合包含is_jalr；is_jalr、I立即数和旁路rs1经过ID/EX的reset/flush/capture；EX对有效JALR同时生成pc+4写回、`(rs1+imm_i)&32'hFFFFFFFE`目标、PC重定向和双级间flush。未修改核心RTL/TB、未运行HDL或Python。
- 证据边界：t91双valid清零并x1=8证明JALR自身写回不被flush误杀；t151 x2=9证明链接值可被目标路径使用；t171 x3=55且x6=0证明目标为0x14而错误路径未改变x6。TB没有直接检查pc_o、pc_brench_addr_ex_o或rs1_data_idex_o，因此不虚报这些内部信号的直接断言覆盖。
- 结论：流水线JALR正向紧邻ADDI旁路、目标跳转、链接写回及年轻路径冲刷定向通过，PASS归属用户本人。JALR边界尚未覆盖。

### 当前唯一任务：JALR负I立即数与目标bit0清零（已解释待练习）

- 重点是I立即数符号扩展后参与加法，目标计算顺序为`(rs1+imm_i)&32'hFFFFFFFE`。不要清立即数的bit0或直接把地址向下取整后再加。
- 若x5=17，`JALR x1,x5,-1`：相加为0x10，清bit0后仍为0x10；若要真正看到清bit0效果，`JALR x1,x5,-2`：相加为0x0F，目标变为0x0E。新测试应先安排对应目标地址和目标指令。
- 待用户先提交执行PC顺序、加法/清位目标、链接及最终寄存器预测，再亲写机器码/TB和本人日志，可同条交。当前边界没有用户实现/日志，不记为通过。
- 不重做已通过的BEQ/循环/旁路/JAL或本次JALR正向程序，不扩展调用栈、访存或暂停。
- 本轮助手只做静态RTL/TB审阅、证据边界说明和学习文档维护；无核心文件修改、无HDL/Python运行。

## 历史快照：2026-10-26较早；JALR当时待验证

### 用户最新提交及验收

- 用户预测PC为00→0C→10→04→18，漏掉04后实际生效的JAL@08；已给出正确顺序00→0C→10→04→08→18，属于局部漏项，不要求单独重答或重跑。最终x1=4/x2=5/x3=55/x6=9预测全部正确。
- 用户提交本人initial检查片段与PASS: all checks passed。助手实际读取约定目录imem和tb_check，磁盘TB与聊天对应，check_x0_read_ports确实同时检查两个读地址为0且两个输出为0。
- 机器码00C000EF/00108113/0100006F/00900313/FF5FF06F/01600313/03700193，经PowerShell位域提取核对为原任务；三次JAL目标依次0C/04/18，其中FF5FF06F确为JAL x0,-12。首轮核对仅目标格式化类型报错，修正整数类型后全部输出成功，不算HDL运行。
- 实际沿后#1采样：t31=(1,0)，t51=(1,1)，四个寄存器全0；t71=(0,0)，x1=4；t91=(1,0)，t111=(1,1)，x6仍0；t131=(1,1)，x6=9；t151=(0,0)，x0双读端口检查；t171=(1,0)，t191=(1,1)，x2仍0；t211=(1,1)，x2=5；t231=(0,0)，t251=(1,0)，t271=(1,1)，x3仍0；t291=(1,0)，x3=55并结束。x1始终保留4，x6自t131起保持9。t151、191、211、231、251、271、291均调用x0读端口检查。
- 用户TB第二个t211注释实际对应t231，后续注释231/251/271实际应为251/271/291；检查次序和值正确，仅提示顺手改注释，不代改、不要求重跑。
- 结论：本程序流水线JAL负偏移、rd=x0仍跳转/丢弃链接、重复flush与错误路径无寄存器副作用定向通过。用户本人PASS，助手未运行HDL/Python、未改核心RTL/TB。TB未直接断言PC/target，不虚报内部覆盖或完整ISA合规，不为补齐建议重跑。

### 当前唯一任务：流水线JALR（已解释待练习）

- 单周期JALR先前已经实现，当前addi_execute.v仍保留正确rs1+I立即数后清bit0及pc+4链接逻辑；不重讲单周期整课。当前pipeline_core仍空接decode的is_jalr输出，ID/EX/流水线EX待用户接入，不能记为已迁移。
- 只增加is_jalr级间字段及reset/flush/capture、支持valid集合；复用已有imm_i与rs1_data_idex。目标=(rs1+imm_i)&32'hFFFFFFFE，链接=pc_idex+4；同时重定向PC、flush两个年轻位置并保留自身写回。
- 本轮新重点：ADDI在EX、紧随JALR在ID时，寄存器堆尚未提交最新rs1；原有EX→ID旁路应将最新数值送入ID/EX。I立即数不额外左移，先加后清bit0。
- 新程序PC 00/04/08/0C/10/14/18：ADDI x5,x0,17；JALR x1,x5,4；ADDI x6,x0,11；ADDI x6,x0,22；ADDI x6,x0,33；ADDI x2,x1,1；ADDI x3,x0,55。
- 待用户预测加法结果、清bit0后的目标、链接及最终x5/x1/x2/x3/x6，提交本人RTL/机器码/TB/日志，可同条提交。建议新测试核对JALR的rs1锁存值、跳转target/PC、跳转沿双valid与链接写回和最终值。不扩展调用栈、访存或暂停。
- 官方RV32I 2.1 §1.1.5.1已核对JALR语义：I型12位符号扩展、rs1基址、先加后清最低位、链接pc+4。规范地址：`https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html`。本地Reference card简表省略清bit0，完整规则不能仅由简表推导。
- 助手本轮仅静态阅读当前用户代码/资料、核对机器码并维护四份入口文档。新JALR任务尚无用户预测/流水线实现/仿真，不记通过。

## 历史快照：2026-10-26较早；JAL正向通过，边界当时待测

### 用户提交与本轮验收

- 用户预测链接0x08、目标0x14，最终x1=8、x2=9、x3=55、x6=9，全部正确。用户称08/0C/10因跳转不执行；补充流水线含义：08处于ID、0C处于IF后被取消，10在本程序中未取到，均不产生架构写回；此为措辞细化，不要求单独重答。
- 用户说明RTL在约定目录并提交完整initial片段和本人日志PASS: all checks passed。助手实际读取当前Vivado sources_1/new的pipeline_core、ex、id_ex、if_id、addi_decode的JAL相关译码、imem、regfile、fetch_unit、pc_reg，以及sim_1/new/tb_check；磁盘TB与聊天initial一致。
- 静态审阅：JAL纳入valid支持集合；is_jal及32位imm_j经过ID/EX，复位/flush/正常捕获齐全；EX在valid下同时生成pc+4写回、pc+imm_j目标及flush；写回直接进入regfile，未被clear_valid误屏蔽。两个级间均接flush；无发现本任务功能错误。
- 助手用PowerShell核对七条机器码：00900313/010000EF/00B00313/01600313/02100313/00108113/03700193，符合原程序；此不是助手运行HDL的证据。
- 用户TB沿后#1：t31 valid=(1,0)、x6=0；t51=(1,1)、x6=0；t71=(1,1)、x6=9；t91=(0,0)、x6=9且x1=8；t111=(1,0)、t131=(1,1)，二者均检查x6=9/x1=8；t151=(1,1)、x2=9；t171=(1,0)、x1=8/x2=9/x3=55/x6=9。再等两个posedge加#1，到t211结束，无额外断言。
- 结论：本程序流水线JAL正偏移链接写回、双级间flush及目标路径结果定向通过；PASS来自用户本人。未直接断言PC/跳转target，不称完整JAL边界或ISA合规，也不要求重跑本程序补断言。助手未修改核心RTL/TB，未运行仿真或Python。

### 当前唯一任务：负偏移JAL与rd=x0（已解释待练习）

- 负偏移使用32位符号扩展imm_j与本指令PC相加；rd=x0仍执行跳转/flush，链接写入丢弃。当前regfile有wr_addr!=0、旁路有rd!=0，EX对rd=0保留wr_en=1本身不是功能错误。现有代码先不默认修改，用新程序验证。
- 新程序PC 00/04/08/0C/10/14/18依次为：JAL x1,+12；ADDI x2,x1,1；JAL x0,+16；ADDI x6,x0,9；JAL x0,-12；ADDI x6,x0,22；ADDI x3,x0,55。
- 待用户提交实际执行顺序、最终x1/x2/x3/x6预测、亲写机器码/TB和本人日志，可同回复交。建议检查三次跳转后的PC与双valid、链接保留、错误路径无副作用及x0读端口。当前reg_file[0]未复位且不用于读x0，不用check_regfile(0,0)作检查。
- 不重做已验收BEQ/循环/旁路/正向JAL，不扩展到JALR、函数调用栈、访存或暂停。当前新任务无用户尝试或PASS，状态不得提前提升。
- 本轮助手仅静态审阅、PowerShell机器码提取、教学与维护四份入口文档；用户代码与日志归属单列如上。

## 历史恢复记录：2026-10-26较早，流水线JAL当时待提交

- 用户请求读取四份入口文档，按最新收尾继续；已核对2026-10-24日终断点，以下旧记录中的结束指令仅指10月24日。
- 当前仍为阶段4的流水线JAL，状态为已解释待练习。继续原七条指令程序，待用户提交链接地址、目标地址、最终x1/x2/x3/x6预测及本人RTL/TB/日志；允许同条提交。
- 本轮提示范围：JAL自身链接写回、PC重定向、两个年轻位置同步flush；is_jal/32位imm_j经ID/EX并纳入valid支持集合。不重做已验收BEQ/循环/旁路，不加入JALR、函数调用栈、访存或暂停。
- 助手本轮仅读取教学文档/教学技能并维护四份入口文档；未读取或修改核心RTL/TB，未运行仿真或Python。尚无新的用户回答、实现或PASS证据，不提升完成状态。
- 下一动作：接用户对下方原JAL程序的预测或实现尝试。原任务及10月24日证据保留在下方历史快照。

## 历史日终快照：2026-10-24；BEQ与有限循环通过，JAL待练习

### 下次唯一入口与当前状态

- 用户已明确结束今日学习，本轮仅收尾，不再新增当日任务。阶段4继续；先前三层流水线算术集成、RAW复现及两路旁路不重做，今天BEQ taken/not-taken和有限循环也不重跑。
- 当前尚未完成的是上轮已经讲解的流水线JAL：用户尚未提交链接/目标/最终寄存器预测、JAL迁移代码、定向TB或运行日志。“已解释待练习”不能写为已实现/掌握/通过。
- 下次直接接这一任务；用户已有尝试则先评审，勿重复提问BEQ、PC复盘或循环。允许预测、代码、本人日志同一回复提交，小错误顺带指出并继续，不代写整模块或完整TB。

### 今天完成与证据归属

| 小主题 | 用户亲写／本人证据 | 验收与边界 |
|---|---|---|
| BEQ taken行为预测 | E1～E5预测，E3 PC=0x10且两个级间valid=0 | 预测正确；IF/ID与ID/EX两条年轻错误路径均需取消 |
| 首轮冲刷失败与修复 | 首轮本人6项FAIL；仅IF/ID输入清valid，错误路径x1=11；后给两个级间寄存器同时接flush | 静态定位漏冲刷ID/EX；另纠正TB采样NBA前旧值、过早期待目标写回 |
| 同步flush时序 | 用户补交if_id/id_ex内部always块及顶层接线 | 两者reset > flush > normal capture；valid及当前所有payload清零，无发现遗漏。清payload是整洁选择，副作用屏蔽关键为valid |
| BEQ taken定向验证 | 本人PASS；t71两个valid=0、t131 x2=44、t151 x1=0/x3=55 | 错误路径取消、目标路径写回通过；本次并未直接新增PC断言 |
| BEQ not-taken | 正确E1～E5预测；本人PASS，t31/51/71 valid检查，t190终值x1..5=1/22/33/44/55 | 顺序路径效果通过；BEQ在t70进入EX、t90才根据结果推进，未直接断言t90 PC/flush/valid，不虚报内部覆盖 |
| 有限倒计数循环 | 用户五条机器码、逐拍TB和本人PASS；x1=3→2→1→0，重复冲刷、退出后x2=55 | 本程序正负分支、旁路与冲刷组合功能定向通过，非完整控制流/ISA验证 |
| 流水线JAL | 助手已解释自身链接写回与年轻指令flush并存的行为，给出一项任务 | 用户尚未提交新预测/实现/日志，状态已解释待练习 |

### 最后通过程序与关键实际采样

| PC | 机器码 | 指令 |
|---|---|---|
| 0x00 | 00300093 | ADDI x1,x0,3 |
| 0x04 | FFF08093 | ADDI x1,x1,-1 |
| 0x08 | 00008463 | BEQ x1,x0,+8 |
| 0x0C | FE000CE3 | BEQ x0,x0,-8 |
| 0x10 | 03700113 | ADDI x2,x0,55 |

- 上述机器码本日由助手PowerShell位域提取核对；全部PASS由用户本人运行并报告，助手未重跑HDL。
- clk上升沿t10/30/50/...，t25解除复位；用户检查在各沿后#1。t71 x1=3；t91 x1=2；t191 x1=1；t291 x1=0。
- t131/231回跳flush后(valid_ifid,valid_idex)=(0,0)；t151/251=(1,0)；t171/271=(1,1)。t311退出flush=(0,0)；t331=(1,0)；t351=(1,1)。t311/331/351均直接断言x2=0；t371=(1,0)、x1=0、x2=55。
- 最后额外等待七个posedge并#1到t511报告PASS/finish，没有增加新的断言，不描述为持续监控尾段。用户本轮未展示直接PC/EX比较操作数/branch taken/target断言或超时；无需为补齐旧建议再跑本程序。
- 当前算术教学子集把尾部00000000过滤为bubble，不称合法NOP。仅目前定向测试的ADDI/ADD/SUB/BEQ已接入并验收，不称单周期全部指令已迁移或完整RV32IM。

### 今日澄清／已指出的误解

- 用户口头循环预测多列初值3，最后又把到0x10标成not-taken；正确BEQ@0x08只比较2/1/0，结果not-taken/not-taken/taken。用户实际TB已经符合正确时序，助手指出局部错，不要求重新证明。
- 分支比较的是锁存的rs1与rs2，旁路使其拿到减1后的最新x1，不是“读写数据相等”就跳转。
- BEQ处于EX、产生taken与下一边沿执行PC/valid更新分开：t111/211回跳处于EX，t131/231才完成flush；t291退出分支处于EX，t311才完成退出冲刷。
- taken取消两个年轻位置，恢复目标EX需要重新填充；不能笼统记成只浪费一拍。t131和t151的ID/EX均无效，t171才有效。
- 助手此前“not-taken目标路径不执行”表述不严谨，已纠正：不重定向不等于目标地址永不执行；顺序执行到目标时照常执行。保持“预测/代码/日志通过不等于全部知识掌握”的证据边界。

### 下次保留任务：流水线JAL（尚未收到用户尝试）

行为：有效JAL写rd=pc_idex+4，跳到pc_idex+imm_j；同一上升沿完成JAL自身写回、PC重定向和IF/ID、ID/EX冲刷。flush取消年轻指令，不能禁止JAL自身写回。

接线范围：is_jal及32位imm_j经ID/EX传递，新增字段加入reset/flush/正常捕获，JAL加入支持指令valid判定，EX增加链接写回/跳转行为；复用既有旁路与flush机制。不同时加入JALR、函数调用栈、访存、暂停。

保留原任务程序，不在日终新增：0x00 ADDI x6,x0,9；0x04 JAL x1,+16；0x08 ADDI x6,x0,11；0x0C ADDI x6,x0,22；0x10 ADDI x6,x0,33；0x14 ADDI x2,x1,1；0x18 ADDI x3,x0,55。

下次先接用户对链接地址、目标地址、最终x1/x2/x3/x6的预测，然后由用户亲写机器码/RTL/TB并运行；同条提交可直接评审。参考中文手册第2.7节“RV32I无条件跳转”。不默认给出完整答案。

### 工作区路径约定与本轮维护边界（2026-10-24更新）

- 当前练习RTL默认读取：`D:\Study\RISC-V\rebulid_tinyriscv\vivado_prj\rebulid_riscv.srcs\sources_1\new`。
- 当前练习testbench默认读取：`D:\Study\RISC-V\rebulid_tinyriscv\vivado_prj\rebulid_riscv.srcs\sim_1\new`。
- 用户今天明确更换默认路径；原`rebuild/rtl`、`rebuild/tb`不再作当前版本依据。旧记录中的路径保留历史含义，不自动回退、不复制两套、不要求用户同步旧目录。
- 收尾仅确认两个新目录存在并列举文件，未逐项校验其内容与今日聊天实现一致。聊天提交不等于已落盘；确需实际编译/编辑时再核对工程来源，不把同步当教学门槛。
- 用户代码、用户本人PASS/FAIL和助手维护分别记录。助手今天仅静态审阅、机器码位域核对、资料核对和文档维护，未运行HDL或Python、未修改核心RTL/TB；日终只修改学习/目录入口文档，无移动复制源文件。

## 历史记录说明

以下是保留的过程证据；所有“当前/下一步/待办”均为当时状态，以顶部2026-10-26最新快照为续接依据；较早恢复记录及10月24日快照保留历史任务和验收证据。

## 历史过程：2026-10-24；有限循环通过后讲解JAL（以上方日终快照为准）

### 用户最新提交及验收

- 用户提供循环口头预测、五条机器码、逐拍TB及本人`PASS: all checks passed`，助手未代跑HDL。
- 机器码00300093/FFF08093/00008463/FE000CE3/03700113由助手本轮用PowerShell位域提取核对为：ADDI x1,x0,3；ADDI x1,x1,-1；BEQ x1,x0,+8；BEQ x0,x0,-8；ADDI x2,x0,55。对应PC为0/4/8/C/10，正负分支目标均正确。
- 用户口头预测局部错误：初始化3不是BEQ@8的一次比较；该分支实际比较2、1、0，结果not-taken、not-taken、taken；最后到0x10应标taken。其TB已按正确时序验证，不将口头错误泛化为实现错误，不要求重做循环。
- 本人TB实际采样（注释的边沿时间之后#1）：t71 x1=3；t91 x1=2；t191 x1=1；t291 x1=0；t131/231两个valid=(0,0)，t151/251=(1,0)，t171/271=(1,1)；t311退出flush=(0,0)，t331=(1,0)，t351=(1,1)，t371=(1,0)且x1=0、x2=55。t311/331/351直接检查x2=0。
- 后续七个posedge加#1到t511结束，但未增加新的断言，不说成对整个尾段持续监控。本轮未直接断言PC、EX比较操作数、branch taken/target，也未展示超时；记录为本程序功能定向通过，不声称已覆盖这些内部信号或完整ISA，不为补齐旧建议要求重跑。

### 本轮澄清的硬件含义

- 旁路使BEQ在进入ID/EX时拿到前一条减法的最新结果；不是因为“读取和写入数据相等”而跳转。比较对象是锁存的rs1与rs2，即最后的0与x0=0。
- t111/211回跳BEQ开始处于EX，t131/231才是重定向和同步flush之后；t291退出BEQ处于EX，t311才冲刷错误路径回跳BEQ。
- 当前实现taken取消两个年轻位置，回跳后连续两个沿后ID/EX为invalid，再恢复目标EX；不要只记作浪费一拍。valid控制副作用，清payload是波形整洁选择而非额外功能必要条件。

### 当前下一项：流水线JAL（已解释待亲写）

- 有效JAL同时产生链接写回`rd=pc_idex+4`和重定向`pc_idex+imm_j`，同沿执行链接写回、PC跳转、两个年轻位置flush；不能用自身flush禁止自己的wr_en。
- 待用户接通is_jal、32位imm_j经ID/EX（含复位/flush），将JAL纳入valid支持集合，新增EX行为；不改已有flush机制。
- 任务程序：0x00 ADDI x6,x0,9；0x04 JAL x1,+16；0x08/0x0C/0x10分别ADDI x6,x0,11/22/33；0x14 ADDI x2,x1,1；0x18 ADDI x3,x0,55。待用户预测链接、目标和最终x1/x2/x3/x6，亲写相关代码/TB/机器码并提交本人日志；尚未实现或验证。
- 归属：用户聊天核心/TB与本人PASS；助手仅静态评审、PowerShell机器码核对、官方规范核实与学习文档维护。未修改核心RTL/TB、未运行HDL/Python、未核对最新聊天版本磁盘同步。

## 历史快照：2026-10-24；BEQ not-taken通过（有限循环现已完成）

### 最新用户回答与代码证据

- 用户E1～E5预测正确，按所列程序顺序理解为0x00 ADDI x1,x0,1、0x04 BEQ x1,x0,+16、0x08 ADDI x2,x0,22、0x0C ADDI x3,x0,33、0x10 ADDI x4,x0,44、0x14 ADDI x5,x0,55。完整imem未在本次聊天提交，按预测/最终期望推定，未核对磁盘；表中的ADDI@22等使用立即数命名，建议以后@后统一写PC地址。
- 用户聊天TB在t25解除复位，t31检查(valid_ifid,valid_idex)=(1,0)，t51/t71检查(1,1)；之后六个posedge到t190，检查最终x1..5=1,22,33,44,55。用户本人报告PASS。
- 此程序BEQ在t70进入EX、t90进行not-taken正常流动；本轮未直接断言t90 PC/flush/valid，不能把t71 valid当成该行为的直接证明。最终顺序路径效果支持本程序not-taken定向验收，不要求重跑。
- 最后x5预期t170写回，t190终值检查前已稳定；末尾缺#1不阻挡验收。注释110ns不准确，实际为190ns。建议将未来采样统一写成@(posedge clk); #1。
- 本轮x1紧邻BEQ，依当前结构BEQ操作数应由EX→ID旁路得到1；没有直接断言该操作数，因此仅记录场景效果，不虚报内部信号覆盖。
- 纠正助手此前不严谨说法：not-taken不表示目标地址永不执行；若顺序执行到该地址仍会执行。本例分支地址0x04加16是0x14，x5=55顺序写回是正确行为。

### 当前新任务：已有指令的有限循环（已解释待练习）

程序：0x00 ADDI x1,x0,3；0x04 ADDI x1,x1,-1；0x08 BEQ x1,x0,+8；0x0C BEQ x0,x0,-8；0x10 ADDI x2,x0,55。不增加核心功能，先按现有RTL运行。

- 新重点：负B立即数符号扩展与使用分支自身PC、循环分支读减1后的旁路值、回跳/退出时重复同步冲刷。
- 待用户预测：各轮x1/退出分支结果；待用户亲写imem编码和TB关键日志/检查及超时保护；最终检查x1=0、x2=55，避免退出标记在循环未结束时错误写回。
- 用户尚未提交新循环的预测、代码或日志。下一次先接其尝试，不重复已通过单次BEQ测试。
- 所有新增预测/代码/PASS来自用户聊天与本人仿真；助手仅静态评审、核对规范和维护学习文档，未运行HDL/Python，未修改核心RTL/TB或要求磁盘同步。

## 历史快照：2026-10-24；BEQ taken冲刷内部时序审阅通过（not-taken现已完成）

### 当前结论与下一步

- 2026-10-23以前的无依赖三级流水线集成、RAW旧值复现、用户亲写EX→ID两路旁路，以及rs2／双源／连续相关／SUB负值／x0屏蔽六条定向验证均已验收，不重做。
- 本轮BEQ taken控制冒险与冲刷定向验证完成。用户补交的`if_id`、`id_ex`内部代码确认：`reset > flush > normal capture`，flush时同步清除valid和payload；结合用户此前`PASS: all checks passed`，本主题功能与关键时序结构均已确认。
- 不重跑taken程序。下一小主题为BEQ not-taken的PC+4和valid正常流动，仅验证不跳转的顺序路径。

### 本轮内部代码审阅

- `if_id`：复位分支先于`flush_ifid_i`，flush分支清零valid、PC和指令，正常分支捕获输入；满足同步冲刷要求。
- `id_ex`：复位分支先于`flush_idex_i`，flush分支清零valid、PC、两个操作数、I/B立即数、rd和控制信号，正常分支完整捕获；没有发现功能性遗漏。
- 同一个taken flush在PC、IF/ID、ID/EX的时钟边沿被各自寄存器采纳；BEQ位于EX的当前内容不被ID/EX清除逻辑误伤，清除的是更年轻的错误路径内容。
- 代码归属：内部RTL由用户提交；PASS日志由用户运行并提供；助手仅作静态审阅和文档维护，未运行HDL、未修改核心RTL/TB。

### 下一步任务定义

用不满足条件的`BEQ x1,x0,+16`构造短程序，预测E1～E5的PC、IF/ID、ID/EX及valid；预期taken信号始终为0，PC顺序递增，两个valid不被flush。之后用户亲写/修改TB并提交本人日志。暂不加入BNE/JAL、暂停或访存。
### 今日完成与证据

| 小主题 | 用户本人证据 | 验收与边界 |
|---|---|---|
| 无依赖ADDI/ADD/SUB三级集成 | 用户pipeline_core、修正版联合TB和本人PASS；70..150ns沿前5次写回逐项检查，并检查级间状态／最终寄存器 | 本5条程序通过；IF/ID原复位输出直接断言缺口已由联合TB补上 |
| 集成排错 | 用户修正32位I立即数、未用decode输出留空、x0检查改实际读口后PASS | 修正后未知值消失；未逐项故障注入，不倒推声称精确X首发路径已实测 |
| RAW旧值复现 | 用户观测t70后x1=5、ID/EX rs1=0、EX rd2/data7，t90后x2=7；本人FAIL | 确认相邻指令读旧值；日志期望0D小错已指出正确12=0C，诊断已结束 |
| EX→ID两路旁路 | 用户聊天两条assign及ID/EX接线，匹配源／目的、EX写有效、目的非x0才选EX结果；本人rs1依赖PASS | 寄存器前选择器正确，未形成EX组合反馈；用户已实现，不重布置 |
| 六条相关程序 | 用户聊天完整tb_check和本人PASS；EX输出逐项!==与errors；最终x1..5检查和实际x0读口检查 | 本程序rs2、双源、连续相关、负值及x0屏蔽定向功能验收通过；不是全部冒险／ISA证明 |

### 最后一次tb_check的实际时序与核对

- 用户明确无需按未修改的t=xxns注释评审；以执行语句为准。clk每10ns翻转，t25释放复位；两次@(posedge clk)等待到t30、t50，再#8，于t58首次检查EX。
- 实际EX检查表（时间均ns）：t15：(en0,rd0,data0)；t58：(1,1,5)；t78：(1,2,5)；t98：(1,3,10)；t118：(1,4,FFFFFFF6)；t138：(1,0,FFFFFFF7)；t158：(1,5,7)；t178：(0,0,0)。t183检查实际两个读口地址0／数据0，及最终x1..5=5,5,10,FFFFFFF6,7，随后finish。
- 这些是沿间稳定EX输出检查，不是posedge NBA更新前的逐沿提交监控。依既有RTL，非零目的实际写回边沿预期70/90/110/130/170ns；用户本轮未直接在边沿逐项计数，不能把上述推导写成新增提交轨迹证据。t138观察到写x0请求，预计t150被regfile丢弃，不能称架构x0写入-9。
- 末条于t170正常写回；t178已观察EX bubble、t183最终状态稳定，本次定向功能证据足够通过，不因早于t190结束要求重跑。旧任务建议190ns检查只是另一观察安排；本轮没有执行到t190，不能记为已测。所有注释旧时间不作为功能缺陷，也不为清理注释新增作业。
- check_idex任务已定义但未调用；因此本轮不记为新增直接验证ID/EX两个操作数（例如两路均5），仅据EX结果和最终状态确认场景功能。测试没有重新检查完整PC／级间bundle／复位所有字段，不覆盖已有测试结果，不虚报新增覆盖。

### 最后程序基线（机器码此前由助手PowerShell核对，本轮没有重跑HDL）

| 地址 | 机器码 | 指令 | 预期效果 |
|---|---|---|---|
| 00 | 00500093 | addi x1,x0,5 | x1=5 |
| 04 | 00100133 | add x2,x0,x1 | rs2旁路，x2=5 |
| 08 | 002101B3 | add x3,x2,x2 | 两源旁路，x3=10 |
| 0C | 40300233 | sub x4,x0,x3 | rs2旁路，x4=-10=FFFFFFF6 |
| 10 | 00120013 | addi x0,x4,1 | EX结果-9=FFFFFFF7，架构写入丢弃 |
| 14 | 00700293 | addi x5,x0,7 | 禁止错误转发写x0结果，x5=7 |

后续00000000由当前算术教学子集过滤为bubble，不称合法NOP。若错误向末条转发-9，x5会变成-2=FFFFFFFE；本轮本人PASS符合屏蔽预期。

### 归属、证据边界与长期节奏

- 核心RTL／TB尝试来自用户聊天及用户说明；所有PASS／FAIL是用户本人运行日志。助手只做静态审阅、先前机器码核对与本轮学习文档维护；本轮未运行HDL仿真／Python、未修改核心RTL／TB、未核对聊天修正版磁盘同步，不从归档重建用户代码。
- 已展示用户能写两路旁路选择、选择正确级间落点、复现并修复这个RAW场景、用!==及errors自动自检。不能仅由PASS宣称所有概念完全掌握；下次若确需确认只结合新主题做少量检查，不重考旧题。
- 当前流水线只验ADDI/ADD/SUB算术子集与这些相关程序；流水线分支／跳转／访存未接入，暂停／冲刷未实现，load-use、复杂时序、完整RV32IM、综合／板级／ISA合规均无本轮证据。单周期早先支持的其他指令不等于已迁移到流水线。
- 继续遵循整体作用→必要硬件行为→一个适量亲写／验证任务；小错顺手改不单独卡一轮，不代写整模块／整套TB；核心文件由用户自行同步，不反复催同步。今日收尾只更新四份入口，无新作业。


## 历史过程：2026-10-23，rs1旁路通过后布置覆盖（现已完成，不作为续接入口）

### 本轮用户提交与验收

- 用户说明已把I立即数改32位、未用decode输出留空并移除绑零、TB的x0改查实际读口；本人仿真结果PASS: all checks passed，并在聊天提交完整修正版TB。助手按聊天代码评审，未重新核对本轮磁盘副本／未修改RTL或TB／未代跑仿真。
- 修正版TB在posedge active region、NBA更新前调用check_wr，30/50ns检查无写回，70/90/110/130/150ns依次检查(en=1,rd=1..5,data=5/7/FFFFFFFF/0/0)，170ns检查无写回；逐边沿使能检查已约束该观察窗口内恰好五次连续提交，不再要求重做旧程序或机械添加另一计数器。
- 沿后#1检查PC、IF/ID、ID/EX的valid/PC/rd/三控制及寄存器值；t15包含同步复位后IF/ID清零；t171/t176确认两个读地址为0且读数据为0，避免直接检查未初始化的reg_file[0]。结合用户PASS，本程序集成定向验收通过，IF/ID旧复位断言缺口已随联合测试补上。
- 小范围说明：仿真t176结束，case 9对应t190从未执行；不能记录为已验证t190无写回。末尾00000000按当前子集处理为bubble，不是合法NOP；未加入写x0指令，不能称覆盖写x0丢弃。上述注释／未执行冗余分支不阻挡推进，不要求为此单独重跑。
- 当前结论仅为本5条无RAW ADDI/ADD/SUB短程序下三级IF/ID/EX（EX含写回）集成通过，不等同完整指令集／冒险处理／流水线访存或跳转已通过；用户能否自行解释RAW还待下一练习。先前X在用户合并修正后消失，但未逐项故障注入，不能追认精确根因传播实测结论。

### RAW复现证据：2026-10-23（已完成，不重做未修改核心的诊断）

- 用户回答／观测：t70沿后x1=5、rs1_data_idex_o=0、EX写回地址2／数据7；t90沿后x2=7。本人日志FAIL [91000] x2: actual=00000007 expected=0000000d；FAIL: 1 checks failed。与旧值RAW推导一致，当前依赖功能未通过。
- 局部TB期望小错：5+7=12=0x0000000C，而日志0x0000000D为13；下一条顺手改为32'd12或32'h0000000C，不为此单独要求重跑RAW诊断。即使修正期望，actual=7仍是实质RAW错误，不能把7当正确功能结果。
- 助手依据聊天回答／日志核对，没有新读／改核心文件、没有代跑仿真。单条FAIL不等于所有其他冒险或边界已覆盖；现已复现旧值，不重新提同一预测题。

### 本轮旁路实现与证据：2026-10-23

- 用户聊天亲写两条assign：对应decode源地址等于EX目的、wr_en有效、EX目的非0时选择wr_data_ex_o，否则选择原rs1/rs2_data_o；ID/EX两数据口已改接rs1/rs2_data_forward_o。条件、两路独立选择和寄存器前落点正确，不形成EX组合反馈。
- 用户本人日志PASS: all checks passed。结合上轮两条ADDI的修复任务，当前rs1相邻依赖场景验收通过；本轮未重新贴TB或70/90ns内部轨迹，不冒称新增实测轨迹或rs2／x0等分支已通过。两个forward信号声明在片段中未展示，按要求应保持32位，不因省略声明要求重交整核。
- 助手按聊天片段与用户PASS静态评审，仅PowerShell核对下一程序机器码与维护文档；未改核心RTL/TB、未代跑仿真、未核对用户本轮磁盘同步。旧无依赖与已完成RAW诊断不重做。

### 历史任务规格：旁路定向覆盖（已于置顶日终快照验收）

- 用户复用现有旁路，不改核心，只改一个独立短程序及TB期望，验证rs2命中、双源同时命中、连续相关、SUB负值、写x0结果不得转发、末尾bubble无写回。程序由助手PowerShell组合字段核对，TB仍用户亲写，不代写整套。
- 六条程序依次：00500093 addi x1,x0,5；00100133 add x2,x0,x1；002101B3 add x3,x2,x2；40300233 sub x4,x0,x3；00120013 addi x0,x4,1；00700293 addi x5,x0,7；其后零编码过滤为bubble。
- 预期EX写回请求在70/90/110/130/150/170ns分别(en=1,rd/data)：1/5、2/5、3/10、4/FFFFFFF6、0/FFFFFFF7、5/7；190ns无写回。注意150ns是有效EX写x0请求但regfile丢弃，不能称x0已提交-9；6次wr_en与5次非零目的有效写入分开。
- 最终x1=5、x2=5、x3=10、x4=FFFFFFF6、x5=7，x0以读口确认0。双源I3两路都应取5。I5得到-9但目的为0，I6读x0必须保持0；若错误转发-9则I6得-2=FFFFFFFE，非7。
- 沿用t25复位释放与20ns周期，用户同步调整旧TB的PC／bundle／tuple期望，结束时间延至190ns沿后（例如196ns）以真的执行排空检查，不残留旧5条程序期望。交关键自检和本人日志；该场景尚未执行，invalid EX保护也未被独立故障注入验证，不夸称全部RAW／边界覆盖。
- 继续只研究当前ADDI/ADD/SUB算术子集，不引入load-use、暂停、分支／访存／冲刷；不催磁盘同步。

## 历史诊断：2026-10-23首轮集成失败（当前已修正通过）

- 当时用户11项FAIL：9项重复观察x1/x2/x3为X，2项直接读reg_file[0]为X。只读核对的rebuild与Vivado相关副本当时哈希相同，已有elaborate.log报告I立即数1位与32位端口不匹配；其他未用decode输出也被顶层常量额外驱动。
- 聊天旧版valid名称／AND逻辑错误，但磁盘当时已改为valid_ifid_o & (is_addi_o | is_add_o | is_sub_o)，不重复要求用户修已正确项。x0实际读口特判0，内部reg_file[0]未初始化不等于架构x0错误。
- 助手当时只静态定位与维护文档，无新增仿真或核心文件修改；本轮通过证据来自用户修正版TB与本人PASS。

## 历史收尾与证据：2026-10-22（已恢复；当日结束状态不作为今日暂停要求）

### 本日完成与证据

| 小主题 | 用户实现／运行证据 | 当前结论 |
|---|---|---|
| SW/LW | 基址加偏移、写RAM再读回并参与后续ADDI；用户日志最终x3=42、x4=43 | 本次定向程序通过 |
| LB/LBU、LH/LHU | 用户提交译码、执行、连接和日志；覆盖byte/halfword选取及符号／零扩展 | 已展示对齐场景通过，不重复原测试 |
| SB | 修正“只移动sel、不移动低8位数据”的错误；memory16依次12345678→12348078→80348078，用户LW回读一致 | 修复后的定向测试通过 |
| SH | rs2低16位移到目标半字，sel=0011/1100；memory16依次12345678→1234FF80→FF80FF80，LW回读一致 | 两种自然对齐位置通过 |
| 混合访存自动自检 | 用户亲写6个独立!==检查和errors汇总；x4=00000080、x5=FFFFFF80、x6=00001280、x7=FFFFFF80、x8=FF805678、memory16=FF805678；用户PASS | 已从人工看日志推进到自动判定最终状态 |
| IF/ID | 用户改为同步低有效复位；valid/PC/instr整包采样，A/B/bubble/C及沿间保持检查，用户PASS | 独立模块通过；复位清零直接断言尚待联合测试顺手补 |
| ID/EX | 用户亲写9字段bundle寄存器；TB检查复位、采样、保持及invalid时payload仍更新；用户PASS | 独立模块通过 |
| EX算术子集 | 用户组合实现ADDI/ADD/SUB与valid门控；TB六组向量检查写使能/rd/data及无时钟变化；用户PASS | 独立模块通过，尚非集成流水线通过 |

### 下次唯一入口（已经讲过规格，待用户动手）

- 用户亲写最小pipeline_core与独立TB，复用fetch_unit→IF/ID→decode/regfile读→ID/EX→ex→regfile写；保留单周期addi_core作基线。教学三级为IF、ID、EX（含写回），不额外增加EX/WB。
- 仅集成ADDI/ADD/SUB，先用5条全部从x0读的无依赖程序。分支、访存回接、数据冒险、旁路、暂停、冲刷均未实现／验证，不在下次同时展开。
- 验收既看连续5次提交的顺序、次数、rd/data，也看最终寄存器；不能只凭x4/x5最后为0判定ADD/SUB执行。具体机器码、连线约束及采样时刻见下方详细规格。
- 当前没有另悬的待答概念题；待交的是集成连接、用户本人TB检查和仿真结果。若用户已完成，直接评审，不重新布置EX或旧访存／级间寄存器单测。
- 联合TB可补IF/ID同步复位输出断言，但不据此要求重做已通过的单模块测试。支持依赖指令的流水线回归要等相关处理加入之后。

### 证据边界与长期节奏

- RTL／TB尝试和PASS来自用户聊天、附件及本人运行日志；助手做静态评审、编码／预期核对及学习文档维护。助手未代跑上述HDL仿真，未在收尾修改核心RTL或TB。
- 聊天提交不等于所有最终文件均已同步到磁盘；用户自行同步核心工程，助手不覆盖或反复催同步。需要实际编译时才核对文件版本。
- 已解释集成原理不等于已实现，更不等于完整RV32IM或TinyRISC-V工程完成。自然对齐、地址高位别名、未实现异常等边界继续保留。
- 继续采用一个适量完整小主题：作用→必要硬件行为→一项用户亲写／验证任务；局部错误指出并顺带推进，关键概念障碍才暂停；不默认代写整模块或整套TB。
- 今日收尾仅维护记录，不新增练习、不要求今晚继续提交。下次读取四份入口文档后直接恢复本断点。

## 历史集成规格（2026-10-22布置，2026-10-23已验收；不再作为待办）

- 用户聊天提交ex组合模块，默认wr_en/addr/data清零，valid外层门控，ADDI/ADD/SUB分别选择imm/rs2并输出rd。附件TB逐项!==检查使能/地址/数据，六向量包括5+7、2+3、9-4、valid0且3控制全1、无时钟切换到10+20和50-08。本人结果PASS。静态评审与这些自检一致，未代跑/核落盘/改核心代码。
- 确认EX为组合逻辑，不再增加EX/WB寄存器：既定教学三级为IF、ID、EX（包含写回），当前EX结果在regfile下一上升沿提交。下一步应接通已有模块，不重复写已实现ALU或重新设计整核。
- 新主题已解释待做：顺序无依赖三级小核集成。保留旧addi_core基线，建议用户亲写pipeline_core及独立TB；复用fetch_unit、if_id、addi_decode、regfile、id_ex、ex。fetch跳转flag/addr明确接0，只用ADDI/ADD/SUB，无分支/访存/旁路/暂停/冲刷。
- 连线约定：fetch PC/instr→IF/ID（输入valid可常1）；decode只接IF/ID instr，寄存器读地址来自decode；ID/EX接IF/ID PC、寄存器读数据、I立即数、rd、3控制和有效位；ID/EX valid=IF/ID valid AND 三操作任一识别，故未支持/末尾零编码产生bubble，不能冒称零编码合法NOP。EX所有操作数/控制/rd/valid均来自ID/EX输出，不得绕接当前decode或regfile读口。EX wr_en/addr/data→regfile写口。
- 周期约定：复位解除后的第1个posedge令I1进入IF/ID、第2个进入ID/EX并在沿后得到EX组合结果、第3个posedge才提交x1；同一边沿新ID/EX数据不能立刻被regfile采到。之后每沿可提交一条。取指PC、ID PC、EX PC须区分，不能看fetch PC推定当前写回指令。
- 新程序5条均从x0读，避免RAW：00500093（addi x1,x0,5）、00700113（addi x2,x0,7）、FFF00193（addi x3,x0,-1）、00000233（add x4,x0,x0）、400002B3（sub x5,x0,x0）。预期写回rd1..5，data5/7/FFFFFFFF/0/0，每条只提交一次，填充后连续5次写回，最终x1..x5相同值。仅检查x4/x5=0不足证明两条指令执行，应同时检查写回序列/次数。
- 当前唯一任务：用户提交pipeline_core关键连接与本人TB/日志；检查连续5条提交顺序和最终寄存器，不能直接用旧混合访存依赖程序。TB在posedge边沿采样更新前EX输出才是本沿提交tuple，posedge#1看到的可能已是下一条待提交EX；寄存器最终状态放更新后观察。可先沿间监控级间PC/valid，不能混淆观察时刻。
- 证据边界：PowerShell核对5条编码，未仿真集成小核。EX模块已通过，新集成仍待用户实现/验证；IF/ID旧TB复位清零断言缺口仍保留待联合测试补，不重复旧单测。

## 历史快照：2026-10-22，ID/EX已通过、EX当时待实现

- 用户聊天提交ID/EX RTL及附件tb_id_ex文本。RTL为同步低有效复位，valid/pc/rs1/rs2/imm/rd/addi/sub/add共9字段在同一posedge清零或采样，沿间由寄存器保持；展示实现正确。
- 附件TB有check_bus，使用!==逐字段比较和errors；检查t11/t31复位全清、t42 A输入前沿间保持、t51捕获A、t62保持A、t71捕获B、t82保持B、t91捕获valid=0 bubble但payload全字段更新、t102保持bubble、t111捕获C、t122保持C及t131稳定C。组合覆盖有效不同字段防串包、操作控制位、复位、气泡采样、持有。用户结果PASS: all checks passed。此单模块验收通过，不是CPU流水线整体通过。
- 证据来源：RTL和TB为用户聊天/附件提交，PASS为用户本人仿真结果。助手静态审阅附件，没有在本轮运行仿真或核对代码落盘、未改文件。
- 追踪的旧小缺口：之前IF/ID TB没显式断言同步复位输出清零；本次ID/EX自己的TB已检查复位，不能误写成IF/ID那项也已补测。今后共同复位回归再补，不阻挡推进。
- 当前新主题已说明待练：ID/EX之后的EX组合算术子集消费bundle；ADDI=rs1+imm，ADD=rs1+rs2，SUB=rs1-rs2；产生结果/rd和有效写回使能；valid门控副作用，即invalid包即使payload控制位意外为1也不得写回。组合逻辑无时钟，TB改变输入后留delta/#1检查。此子集不含分支、load/store、M、暂停/冲刷/冒险。
- 当前唯一任务：用户亲写ex_alu.v（或同义自定模块名）及组合TB，接口valid、三个算术控制、rs1/rs2/imm、rd → wr_en、wr_addr、wr_data。检查ADDI 5+7=12、ADD 2+3=5、SUB 9-4=5、invalid且某控制为1时wr_en=0，并改输入观察组合输出无时钟延迟。代码/日志待用户提交。

## 历史快照：2026-10-22，IF/ID已通过、ID/EX当时待实现

- 用户聊天提交IF/ID RTL，现为仅posedge clk的同步低有效复位；三项valid/PC/instr以<=同时清零或采样。符合此前规格。用户TB用A/B/bubble/C依次驱动，并在51/61/71/81/91/101/111/121ns检查整包：既验证采样也验证下一posedge前保持，含valid=0气泡payload采样。用户提供PASS: all checks passed。
- 复位在时间0保持低，posedge10实际采样复位，但用户TB未显式检查该时刻三个输出为零；所以PASS只证明列出的包与保持检查，复位清零目前代码静态正确但TB未断言。作为小覆盖缺口记录，不要求重跑整题，未来统一加reset断言。
- TB在posedge30附近驱动valid/input，但所测A随后在40ns设置并于posedge50采样；实际被检查的A/B/bubble/C都在下降沿附近改变，驱动/采样关系足够清楚。错误计数和最终PASS存在。未检查valid=0包下游无架构副作用（独立IF/ID只负责传位，此行为由下游实现）。
- 助手按聊天代码/日志评审，未确认落盘/代跑/修改模块；未把模块单测PASS说成CPU流水线PASS。
- 新主题：ID/EX寄存器将译码结果和操作数作为同一bundle跨边界，避免控制位、rd、操作数错配。先限add/addi/sub功能子集：valid、pc、rs1/rs2数据、I立即数、rd地址及is_addi/is_add/is_sub；每个posedge同步复位全清或整体采样，沿间保持。组合流水线边界不自行计算；无效包仍可采样payload，但EX必须以valid屏蔽副作用。这里仍是孤立模块练习，不接整核、不引入冒险/旁路/暂停/冲刷。
- 当前唯一任务：用户亲写id_ex.v和tb_id_ex.v，覆盖bundle整组传递/连续包不串线/中间保持/bubble有效位，以及复位代码静态检查。TB沿间驱动、posedge后比较；延续!==和错误计数。接口及验收用例下一条说明。

## 历史快照：2026-10-22，混合访存自检通过、IF/ID当时待完成

- 用户聊天提交if_id模块：posedge clk或negedge rst_n异步低有效复位；valid/PC/instr三项使用非阻塞赋值同时清零/采样。作为异步复位流水寄存器，核心包传递写法正确，PC与instr配对。
- 课程先前约定的是同步低有效复位；当前敏感表实现为异步复位，是接口行为偏差（并非普遍错误）。默认下一步改回posedge clk单敏感事件，以遵守已定接口；若用户想改异步，需明确更新接口契约并针对异步assert另测。本次TB没有在有效时钟边沿检查复位三输出。
- 用户TB激励以25ns释放复位，40/60/80/100ns在下降沿附近依次驱动A/B/bubble/C；posedge位于10/30/50/70/90/110ns，故输入设置后于下一posedge采样，51/71/91/111ns检查四个包配对。未出现posedge激励竞争。本人结果PASS: all checks passed，支持四个包valid/PC/instr采样行为。
- 证据缺口：TB未在A→B等新输入已改变、下个posedge尚未来到的窗口检查输出保持；未验证复位输出清零，也没有逐条PASS/失败数报告以外的覆盖。20ns固定间隔是此次显式TB驱动节奏，不是通用握手/流水线协议。其余检查逻辑有效，不要求推倒重写。
- 助手已静态评审聊天源码与PASS，没有确认新文件已落盘或自行跑仿真；核心及TB未被助手修改。
- 当前唯一任务：小幅修正/补测同一个IF/ID契约——使用同步复位敏感表；添加复位边沿输出清零检查；在某次negedge改输入后、下一posedge前检查输出仍是旧包；再检查posedge后整包一起更新（valid0也采样payload）。保留已有四包测试。用户提交修正版片段及本人PASS日志。
- 此模块通过后再开始下一个流水级边界ID/EX的规格，不将IF/ID单模块通过称为流水线核完成。

## 历史快照：2026-10-22，混合访存自检通过，IF/ID当时待实现

- 用户聊天提交本人自检initial段：errors清零，wait(rst_n===1)，20个下降沿等待，6个独立!==检查x4/x5/x6/x7/x8/memory16，失败逐项报告并计数，零错误才PASS，统一finish。预期分别80/FFFFFF80/1280/FFFFFF80/FF805678/FF805678。检查逻辑在展示范围正确。
- 用户本人运行结果为“PASS: all checks passed”；结合已展示条件检查，六项最终状态自检通过。不重复该程序，不要求再跑同样测试。此次仅有最终PASS而无中间轨迹，不冒称新增观测到全部中间信号，也无故障注入/完整ISA/流水线合规证据。errors声明未贴，但不因片段省略要求重交完整TB。
- 助手本轮只读现有fetch_unit.v、pc_reg.v、addi_core.v的取指连接以准备下一步：PC同步低有效复位，imem组合读，fetch的PC/instr直连decode且pc送execute。磁盘core仍是较早接口版本，不据此否定用户最新聊天代码和PASS，也不催同步。未改核心RTL/TB、未代跑仿真/Python。
- 新主题已解释待练习：教学三级流水线拟分IF取指、ID译码/读寄存器、EX执行/访存/写回；先做IF/ID寄存器，PC与指令必须作为同一包跨边界，后续PC相对运算不能错用实时fetch PC。此时只做独立模块，不直接插入全核；暂停、冲刷、数据相关和ID/EX后续再讲，不宣称已是流水线核。
- 当前唯一亲写任务：用户新增if_id.v和独立tb_if_id.v，接口clk/rst_n（同步低有效）、valid_i/pc_i[31:0]/instr_i[31:0]→valid_o/pc_o[31:0]/instr_o[31:0]。posedge且rst_n=0时三个输出全部清零；否则每个posedge同时采样三项输入；沿间输出保持。valid_i=0仍采样payload，但valid_o=0表示气泡/不得引起架构副作用，不把payload0说成合法NOP。没有hold/flush口。
- 独立验证范围：复位清空、连续两包PC/指令配对、沿间输入变化不穿透、valid0气泡再恢复valid1；TB下降沿驱动，上升沿更新完成后（如#1）检查或随后下降沿检查。无需完整CPU、无需重跑旧回归。可采用A=(valid1,pc0,instr04000093)，B=(1,4,F8000193)，bubble=(0,8,0020A023)，C=(1,C,0000A203)。包内容只是寄存器采样数据，尚不执行。
- 下一步：等待用户亲写IF/ID与独立TB/日志，评审时先核同步复位、非阻塞赋值、配对与有效位。模块/仿真尚未提交，仅已解释待实现。

## 历史快照：2026-10-22，SH已通过、混合访存自检当时待写

- 用户补交本人SH日志：90ns memory16=12345678；110ns SH addr40/sel0011/data0000FF80；130ns memory16=1234FF80；150ns x4=1234FF80，第二SH addr42/sel1100/dataFF800000；170ns memory16=FF80FF80；190ns x5=FF80FF80。两种自然对齐SH、其他半字保留、SW初始化及LW回读通过，不再要求重跑或重交已有代码。
- 范围：此前LW/LB/LBU/LH/LHU/SW/SB/SH均已有部分定向证据，但不是完整访存覆盖或RV32I合规。非对齐/越界异常、高地址完整译码仍未支持，sel0000不写内存不等于实现异常。
- 本轮新增小主题：把人工看monitor升级为用户亲写自检TB，在新的混合宽度/负偏移程序上自动比较最终结果。不是重跑SH旧测试，不新增CPU指令/数据通路，先补一条可用于后续流水线回归的自检证据。
- 助手读取当前rebuild/tb/tb_addi_core.v确认已有时钟/复位、monitor及#500无条件finish，无自动检查；不覆盖该文件。已讲!==能把X/Z当不匹配；时钟上升沿有非阻塞更新，不在同沿过早检查；复位释放后预留20个下降沿再比对，错误计数由TB保存、逐项报告，仅全匹配才打印PASS，统一finish。该固定等待仅是当前单周期小程序裕量，不当通用流水线完成协议。
- 当前唯一亲写任务：用户改imem测试程序并在现有TB加入最终自检，不改核心功能；提交本人检查代码和运行PASS/FAIL。新程序：04400093、12345137、67810113、FE20AE23、F8000193、FE308F23、FFE0C203、FFE08283、FFE09303、FE309F23、FFE09383、FFC0A403（PC00到2C）。x1=68；SW -4、SB -2、LBU/LB/LH -2、SH -2、LH -2、LW -4。
- 新覆盖：S/I负立即数、高位S立即数拼接，SB byte lane2，LB非零lane，LH高半字负值，混合宽度数据保持；既有证据不重复。预期memory16从12345678到12805678到FF805678；最终x4=00000080、x5=FFFFFF80、x6=00001280、x7=FFFFFF80、x8=FF805678、memory16=FF805678。程序尚未运行，不记通过。
- 助手维护：PowerShell按字段核对12条指令及部分写结果；未运行仿真/Python、未修改核心RTL/TB。下一步先评审用户自检证据，不提前写流水线。

## 历史快照：2026-10-22，SH代码已提交、日志当时待补

- 用户聊天提交本人SH译码（STORE funct3=001）、执行分支（00/10分别sel0011/1100，始终将rs2低16位放低/高数据lane）及decode→execute控制连接，展示的自然对齐路径正确。依赖原组合块完整ram_wr_data_o=0、wr_en_o=0，以及新增is_sh_o默认清零；本次未展示完整默认值，不要求重复贴全部代码。
- 用户“结果”一节实际重复粘贴decode/execute实例连接，没有time/PC/地址/sel/写数据/内存/寄存器日志；不能推定仿真通过，也不能推定仿真失败。状态是“代码静态正确，运行证据待补”，不要求用户重新写SH或默认重跑已完成仿真。
- 本轮澄清SH default边界：ram_wr_en_o此前为1，但sel=0000；在用户当前RAM写逻辑（总写使能与各sel位共同决定实际byte更新）下，所有byte均不更新，因此不会写坏RAM。不要误报此处一定发生写入；可顺手default清ram_wr_en_o使接口更明确。这仍不是非对齐访问/异常支持，load端不能直接类比。
- 当前唯一下一步：用户补发已有SH仿真日志（若尚未仿真才运行原SH任务），只需从SW初始化到最后LW提交。检查第一SH addr40/sel0011/data0000FF80，memory16及x4=1234FF80；第二SH addr42/sel1100/dataFF800000，memory16及x5=FF80FF80。暂不推进新指令或流水线，不重复已通过SB。
- 证据边界：仅按聊天代码静态评审，没有收到SH运行日志，未检查新版本落盘，助手未运行仿真/Python或修改核心RTL，仅维护学习文档。

## 历史快照：2026-10-22，SB已通过，SH当时待亲写

- 用户聊天提交本人修正SB分支：各地址lane始终使用rs2_data_i[7:0]，分别赋给写数据[7:0]/[15:8]/[23:16]/[31:24]，对应sel0001/0010/0100/1000。配合原组合块完整ram_wr_data_o=0默认赋值，此部分切片赋值正确，其余位为0，不是锁存；全字默认赋值必须保留。本轮以聊天版本评审，未重新核对本次修正是否落盘，不要求用户先同步。
- 用户本人新日志：110ns SB addr0x41/sel0010/data00008000；130ns memory16=12348078；150ns x4=12348078，SB addr0x43/sel1000/data80000000；170ns memory16=80348078；190ns x5=80348078，后续稳定。SB offset1/3写对低8位、其他byte保持、SW初始化及LW回读闭环通过，不再重测。
- 掌握证据：用户亲自完成源byte到目标lane修正，代码和日志验证数据对齐；没有单独文字复述，不冒称已能完整讲解所有访存。SB lane0/2尚未独立测试，非完整ISA合规。
- 本轮新增已解释待练习：SH始终取rs2低16位，按自然对齐目标地址低2位00/10产生sel0011/1100，并把低16位放写数据低/高半字；RAM已支持多个byte同沿更新，无需改模块或新增总线宽度。不能从源寄存器高16位取高地址半字；无需符号扩展。沿用byte-address输出/core[6:2]换索引。
- 当前唯一任务：用户亲写SH译码（STORE opcode0100011、funct3=001）、execute和必要控制连接，保留组合默认值及SW/SB；不代写整分支。只验证偶数地址，01/11非对齐及异常仍未支持，勿让未处理地址误打开RAM写使能，不新增完整异常框架。
- 建议新测试仅把已通过程序两条SB替换为SH：PC14=00309023（sh x3,0(x1)），PC1C=00309123（sh x3,2(x1)）；其他指令不变，x3=FFFFFF80。预期低16位FF80；第一次addr40/sel0011/data0000FF80，memory16=1234FF80、x4=1234FF80；第二次addr42/sel1100/dataFF800000，memory16=FF80FF80、最后x5=FF80FF80。日志覆盖到最后LW提交即可，不需延长空指令尾巴。
- 助手维护：PowerShell核对两条SH机器码及预期部分写结果，查询手册SH条目并维护学习文档；未运行仿真/Python或修改核心RTL。SH尚无用户代码/日志，不记为通过。

## 历史快照：2026-10-22，SB首次失败，数据对齐当时待修复

- 用户提交本人SB译码、execute、RAM按byte更新、core连接及本人仿真日志，并告知已同步练习源码。助手实际读取rebuild/rtl/addi_decode.v、addi_execute.v、addi_core.v、ram.v、imem.v；本次相关落盘版本与聊天一致，不再写作“尚无SB代码”。用户所称rebulid/rtl实际练习目录为rebuild/rtl。
- 核对通过部分：SB译码及默认清零、S立即数、rs2读取、sel连接正确；execute默认wr_en_o=0，SB不写回通用寄存器；SW sel=1111；core统一[6:2]换word index；RAM四个独立if按对应数据lane写入且保留其他byte。ram_wr_sel命名可用，不必改成strb。
- 唯一核心功能错误：addi_execute.v第340-349行SB只移动sel，数据仍整字直通rs2_data_i。RAM第55-65行按同位置lane取数据，因此offset1/3取到rs2[15:8]/[31:24]=FF，而SB规范要求无论目标地址均取rs2[7:0]=80。地址选择决定目的byte，不决定源寄存器byte。
- 用户日志证据：SW后90ns memory16=12345678；110ns SB byte地址0x41、sel0010、写数据FFFFFF80；130ns memory16=1234FF78；150ns x4=1234FF78且SB地址0x43、sel1000；170ns memory16=FF34FF78。日志吻合当前错误电路，不能据此记SB指令通过。用户称“好像与我的预期相同”，已解释电路预测正确与ISA行为错误可以同时成立，等待用户修正反馈。
- 170ns末条LW尚未在寄存器提交（x5仍0）；不能说日志已经观测到x5=FF34FF78。修正后观察至190ns或末条LW提交之后，预期x5=80348078。
- 当前唯一任务：只由用户修正execute的SB写数据路径，始终取rs2低8位，放到地址低2位指定的32-bit目标lane；非目标lane本任务填0。保留已正确的sel、RAM更新、译码和连接，不改SW，不扩SH。提示方式为“低8位→补成32位→按byte offset移动”，不代写整分支。
- 继续原失败测试验证修复（不是重做已通过练习）：offset1时sel0010/写数据00008000，offset3时sel1000/写数据80000000；memory16应依次12345678→12348078→80348078，x4=12348078，最后LW提交后x5=80348078。用户可以同条回复给修正片段和本人新日志。
- 证据边界：助手静态核对磁盘源码、原日志与根目录中文手册sb条目，并查询官方规范；未运行仿真/Python、未修改核心RTL。学习文档由助手维护；SB仍为待修复未通过。

## 历史快照：2026-10-22，LH/LHU通过，SB当时待实现

- 用户聊天提交本人LH/LHU译码（funct3=001/101）、execute（地址低2位00/10选低/高16，LH复制bit15/31、LHU补0）、decode/execute连接和本人仿真日志。展示的自然对齐路径正确；用户已把load注释修为“写回通用寄存器”。未检查未展示的完整默认赋值/声明，也未覆盖磁盘核心文件。
- 用户日志证据：70ns LH地址0x40；90ns x3=FFFF8000；110ns x4=00008000、LH地址0x42/offset10；130ns x5=00001234；150ns x6=00001234、LW地址0x40；170ns x7=12348000。低半字负值的符号/零扩展、高半字正值选择及LW回归通过，不重复该测试。
- 覆盖边界：仅自然对齐LH/LHU；高半字负值未独立测试。case无01/11且wr_en提前置1：若外层wr_data默认0，奇数地址会误写0；无完整默认则存在保持旧值/锁存风险。此为未支持的非对齐路径，不说已实现异常或非对齐访问；提示后继续下一主题，不重做已通过对齐程序。
- 地址约定不变：execute输出有效byte address，core RAM实例读写端口取[6:2]转32-word索引；高位别名限制已知。本轮未修改核心RTL/代跑仿真。
- 本轮新主题已解释待练习：SB只把rs2低8位写入指定byte，不能覆盖同word其他3字节。为当前RAM新增4-bit字节写使能（建议ram_wr_strb_o/ram_wr_strb_i），每位控制对应8-bit切片；execute同时产生对齐32-bit写数据和byte strobe。此为教学接口设计，不是ISA规定的端口名/唯一实现。
- SB opcode0100011、funct3=000，沿用S型符号扩展立即数；wr_en_o=0（不写通用寄存器），RAM写使能=1。原SW需适配strb=1111；默认strb=0000。SB低2位00/01/10/11的strobe=0001/0010/0100/1000；仅rs2[7:0]放对应写数据lane，其余位本任务填0。
- 当前唯一任务：用户亲写SB的decode/execute、core必要连接、RAM按byte条件更新。RAM同一时钟沿各lane可同时写，用独立条件而非互斥else-if；未选中lane保持旧值，不保留会覆盖它们的无条件整字赋值。仅扩SB，SH下轮再讲。
- 新测试待用户运行：04000093、12345137、67810113、0020A023、F8000193、003080A3、0000A203、003081A3、0000A283。准备x1=64、x2=12345678，经SW初始化，再令x3=FFFFFF80；SB offset1后LW x4应12348078，SB offset3后LW x5应80348078。SB byte地址0x41/0x43，word index都0x10；strobe0010/1000，写数据00008000/80000000。
- 助手维护：PowerShell字段核对新指令编码和两次部分写后的预期值；首次预期值计算遇PowerShell有符号十六进制转换错误，已改用Convert.ToUInt32后重算成功。没有仿真/Python/核心RTL变更，SB未收到用户实现或日志。

## 历史快照：2026-10-22，LB/LBU通过，LH/LHU当时待实现

- 用户聊天提交本人decode片段（LOAD funct3=010/000/100分别LW/LB/LBU）、execute的四路byte选择与符号/零扩展、core连接及本人仿真日志。LB各lane复制所选byte最高位，LBU补24个0；展示范围内逻辑正确。组合默认赋值和完整模块声明未展示，不宣称已检查全部源码。
- 用户更改地址边界：execute输出原始有效byte address，byte选择用ram_rd_addr_o[1:0]；core在RAM实例口统一用ram_rd_addr_o[6:2]和ram_wr_addr_o[6:2]转换word index。此前execute输出word index的设计已是历史，不再要求用户恢复旧方案。SW/LW对应执行分支未完整展示，不把未展示代码记成已逐行审查。
- 用户日志：70ns LB addr0x40/offset00；90ns x3=FFFFFF80且LBU addr0x40；110ns x4=00000080且LBU addr0x41/offset01；130ns x5=000000FF且LW addr0x40；150ns x6=FFFFFF80。当前byte lane0的符号/零扩展、lane1的LBU与LW回归通过。助手未重跑仿真/覆盖核心文件。
- 边界提醒：[6:2]仅索引32个word（当前128-byte小RAM）；高地址位被丢弃，0x40/0xC0会别名，不是完整地址译码。本轮地址均在范围内，不要求立刻扩展总线。byte lane2/3及非零lane的LB尚无独立测试证据，不重复已通过场景，也不记为全覆盖。
- 小注释修正：load写回的是通用寄存器，不是“指令寄存器”；只提示用户顺手改，不单独停一轮。
- 本轮新主题已解释待练习：LH/LHU读取16-bit后分别符号扩展/零扩展；沿用byte-address输出及RAM边界换算。仅自然对齐半字（有效地址bit0=0）范围，bit1选择低16/高16，符号位分别bit15/bit31。奇数地址非对齐处理/异常尚未实现，不当作清bit0即可支持。
- 当前唯一任务：用户增加LH/LHU译码与execute/连接，LOAD opcode0000011，funct3=001/101，提交相关片段与本人日志。暂不增加SB/SH。
- 建议测试程序（待用户运行）：04000093、12348137、0020A023、00009183、0000D203、00209283、0020D303、0000A383；即x1=64、LUI x2得到12348000、SW后LH/LHU offset0写x3/x4、LH/LHU offset2写x5/x6、LW写x7。预期x3=FFFF8000、x4=00008000、x5=x6=00001234、x7=12348000；读byte地址0x40/0x42映射同一word index0x10。
- 助手维护：更新学习文档，PowerShell字段构造核对LUI和5条load编码成功；第一次数组表达式核对命令报错后已修正重跑。未运行Python/仿真，未编辑核心RTL。

## 历史快照：2026-10-22，SW/LW offset=4通过，LB/LBU当时待实现

- 用户聊天提交imem程序：04000093、02A00113、0020A223、0040A183、00118213，及本人仿真monitor日志；未要求核心RTL落盘或覆盖同步。
- 用户日志证据：50ns SW的RAM word index=0x11、写数据0x2A；70ns memory[17]=0x2A、LW index=0x11、写回x3数据0x2A；90ns x3=0x2A；110ns x4=0x2B。非零低位S/I偏移4的字级store-load闭环通过，不再重复该测试。
- 证据边界：有效byte address=0x44由已知基址和偏移推算，日志直接观察的是word index0x11。该场景不代表所有S/I立即数高位、负偏移或完整访存ISA合规。助手未运行仿真，未改核心RTL。
- 本轮新增讲解：LB/LBU读取一个byte后分别符号扩展/零扩展；小端下effective byte address低2位选择32-bit RAM读字中的byte lane，word index与byte offset必须从移位前的有效地址分别取得；当前RAM整字接口可保持不变。此项仅已解释待用户实现，不记掌握/通过。
- 当前唯一任务：用户在decode/execute及必要连接中亲写LB/LBU，保留LW与SW；提交相关片段和本人仿真日志。opcode=0000011；LB funct3=000、LBU=100、LW=010；沿用I型符号扩展地址偏移。
- 建议新测试：x1=64；addi x2,x0,-128得到FFFFFF80；SW到0(x1)；LB x3,0(x1)应得FFFFFF80；LBU x4,0(x1)应得00000080；LBU x5,1(x1)应得000000FF；LW x6,0(x1)应仍得FFFFFF80。RAM index均为0x10，byte offset分别0/0/1/0。本场景待运行。
- 助手维护：学习文档；PowerShell核对四条load机器码（00008183、0000C203、0010C283、0000A303），未运行Python或仿真。未扩展LH/LHU/SB/SH。

## 历史快照：2026-10-22恢复时，非零偏移补测当时待执行

- 用户第二轮修正将有效字节地址右移2位后作为RAM索引：SW地址输出0x10、数据0x2A；LW地址0x10读回0x2A。内部探针进一步显示`memory[16]`初始X、复位后0、SW写入后0x2A。最终x3=0x2A、x4=0x2B，日志证明store→load→算术闭环通过。
- 用户询问30-bit切片连接32-bit RAM地址口是否导致错误。解释：Verilog端口连接宽度不等本身不是这里的根因；30-bit无符号向量接32-bit端口会零扩展。此前错误在RAM把byte address 0x40直接当数组下标64，而数组只到31，属于索引单位/越界问题。`addr[31:2]`和unsigned `addr >> 2`均将对齐byte address转word index；必须只转换一次。
- 当前RTL用户将转换放在execute，输出0x10，core原样连接RAM；该边界位置统一且当前实测通过。若将来改为execute输出byte address，则应在core或RAM边界转换，不可两处重复移位。
- 测试仅SW/LW offset=0，虽然有效地址0x40验证了word index16，但没有充分独立覆盖S型立即数非零低位拼接。下次唯一任务：保留x1=64、x2=42，改为`sw x2,4(x1)`（机器码`0020A223`）和`lw x3,4(x1)`（`0040A183`），预期字节地址0x44、word index17、x3=42、x4=43；用此非零偏移测试补验S型立即数拼接。通过后再进入byte/halfword扩展。
- 证据：用户源码修改、两轮日志与RAM memory[16]探针均由用户提供；助手静态审查并解释，没有运行仿真/Python，也未修改核心RTL。
## 2026-10-22 会话恢复：接续非零偏移测试，尚无新测试结果

- 助手已读取四份入口文档，沿用2026-10-21最新收尾；不重复JALR、SW/LW offset=0或地址换算已验证练习。
- 本轮任务仍是用户修改测试程序中的SW/LW偏移为4，观察RAM word index17（0x11）、memory[17]、x3=42及x4=43。沿用已有TB，不代写核心RTL或完整TB。
- 证据边界：本轮仅恢复断点、说明测试检查点并维护学习文档；尚未收到用户新回答、代码或日志，助手未运行仿真。非零偏移测试仍为待验证，不记为通过。
- 下一步：等待用户提交该场景日志；若失败按有效地址→word index→存储内容→load写回定位，通过后再讲byte/halfword访问。
## 历史记录（以下旧待办只供追溯，以顶部快照为准）
## 2026-10-21 历史断点：JAL 正向通过，负偏移当时待测

- 用户独立预测正确：PC 0x04→0x0C、链接值 x5=0x08、最终 x6=8。
- 用户提交 JAL opcode 分支、execute 局部实现及 core 实例连接；执行片段同时产生 `wr_data=PC+4` 和 `pc_brench_addr=PC+imm_j`，行为正确。未展示 J 型立即数连续赋值及控制信号默认值，不能声称完整源码/全部字段已检查；不要求重新提交已通过的测试。
- 用户日志：30ns PC=0x04/008002EF、跳转flag=1、目标0x0C、wr_en=1；50ns PC=0x0C、x5=8、x6=0；70ns PC=0x10、x5=x6=8、零指令wr_en=0。JAL 在50ns上升沿同时完成PC改写及x5写回，目标处ADDI在70ns提交x6。
- 证据归属：用户亲写RTL片段、独立预测和自跑monitor日志；助手只评审并维护记录，未重跑仿真、未覆盖核心文件。
- 下一项小任务：只换两条指令验证 JAL 的负偏移与丢弃链接：0x00=`00130313`（addi x6,x6,1），0x04=`FFDFF06F`（jal x0,-4）。机器码用PowerShell按字段构造核对，尚未仿真。期望0/4/0/4循环、imm_j=FFFFFFFC、x6逐次增加；x0读取恒零。沿用当前实现时JAL可保持wr_en=1、wr_addr=0，由regfile屏蔽x0写入，不要求改成“所有跳转都不写回”。
- 已解释待验证：rd=x0只丢弃链接值，不取消PC跳转；不要把JAL链接值与目标地址混淆。新增RTL与完整TB仍由用户亲写。

## 更早历史记录（当时待办不作为当前入口）
## 2026-10-21：JAL 主题讲解完成，等待用户亲写实现

- 从六种 B 型分支验证通过后进入 JAL。已解释 JAL 同时产生两个结果：`rd=PC+4`（返回链接地址）和 `PC=PC+imm_j`（无条件跳转）；目标相对当前 JAL 指令 PC，而非 PC+4。
- 已讲 J 型立即数字段重排、符号扩展、低位补0：`{{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0}`；opcode=`1101111`。指出写回和 PC 更新需要在同一上升沿分别采样各自组合结果。
- 参考根目录中文手册第2章格式表（J-type，约第644行）和 `jal rd, offset` 指令条目（约第4939-4945行）：`x[rd]=pc+4; pc += sext(offset)`。
- 给出小型测试程序意图：`0x00 addi x1,x0,1; 0x04 jal x5,+8; 0x08 addi x6,x0,99（跳过）; 0x0C addi x6,x5,0`。曾给出用于核对的机器码候选 008002EF（JAL）和 00028313（读取链接值），预期 x5=8、x6=8；但 RTL 需用户亲写。
- 尚无用户对该主题的预测、代码、编译或仿真证据。下一步用户在 decode 增加 J 型立即数与 is_jal，在 execute 产生 PC+4 写回和 PC-relative target，并接通 core；提交相关片段与日志。助手未修改核心 RTL、未运行仿真。

## 2026-10-21：BLT/BGE/BLTU/BGEU 双向符号边界测试通过

- 用户提供本人仿真日志。第一组 x1=FFFFFFFF、x2=1：BLT@08 taken→10；BGE@10 not-taken→14；BLTU@14 not-taken→18；BGEU@18 taken→20，符合 signed(-1<1) 与 unsigned(FFFFFFFF>1) 的区分。
- 第二组 x1=1、x2=FFFFFFFF：BLT@28 not-taken→2C；BGE@2C taken→34；BLTU@34 taken→3C；BGEU@3C not-taken→40，反向组合也符合预期。
- PC 序列略过 0C、1C、30、38；四类分支日志的 wr_en 均为0。x4 在 250ns 仍为0，270ns 变为6：250ns 后 PC=0x40 对应 ADDI 的组合输出，270ns 上升沿才提交 x4=6。
- 结论：完整六种教学 B 型条件分支（BEQ/BNE/BLT/BGE/BLTU/BGEU）的条件选择、正/负偏移基础和无写回行为均有用户定向日志验证；不等同于完整 RV32I 合规或全面编码回归。
- 用户提供仿真证据，助手仅核对日志，未重跑仿真、未改核心 RTL。下一主题建议 JAL：无条件 PC 相对跳转及 rd=PC+4 链接值。

## 2026-10-21：为剩余 B 型分支提供定向指令程序（待用户运行）

- 用户请求测试指令。助手给出双向操作数符号差异的 17 条小程序：先 x1=-1/x2=1，再交换为 x1=1/x2=-1；四种 funct3 均用 +8，taken/not-taken 路径可直接从 PC 序列观察。
- 提供的机器码：BLT/BGE/BLTU/BGEU（rs1=x1,rs2=x2,+8）分别为 0020C463/0020D463/0020E463/0020F463；由位字段逐项构造并用 PowerShell 算术核对。参考 RISC-V 官方 ISA 的 B 型字段表和 signed/unsigned 分支语义。
- 当前证据仅为指令测试向量已给出；用户尚未报告代码修改、编译或仿真结果。下一步接收用户 PC/分支标志/比较值/wr_en/寄存器结果日志并评审。

## 2026-10-21：剩余 B 型分支代码片段评审（待定向仿真）

- 用户提交译码增量：opcode=1100011 下 funct3=100/101/110/111 分别产生 BLT/BGE/BLTU/BGEU 标志，且组合入口默认清零；映射正确，default 冗余清零无害。
- 用户提交执行增量：BLT/BGE 使用 `$signed(rs1_data_i)` 比较；BLTU/BGEU 使用 `$unsigned(...)`；成立时选择 PC+imm_typeb_i，不成立时 PC+4，写回关闭。按所贴局部代码，比较语义和 PC/写回行为正确。
- 需要编译/整体代码检查时仍需确认新增标志已加入 decode/execute 端口、core 的 wire 声明与实例连接；用户仅贴了组合体和部分连接，不能据此断言全部接口完整。注意 execute 中层级缩进不规整，但按所贴 begin/end 配对看可读性需整理，功能仍须由编译验证。
- 核心概念：BLT/BGE 是有符号关系；BLTU/BGEU 是无符号关系。关键辨别输入可用 x1=FFFFFFFF、x2=00000001：signed 视为 -1<1，unsigned 视为 4294967295>1；预期 BLT taken、BGE not-taken、BLTU not-taken、BGEU taken。交换操作数再覆盖相反组合。
- 官方参考：RISC-V RV32I 分支均采用 B 型；funct3 映射 BLT=100、BGE=101、BLTU=110、BGEU=111，规范也定义 signed/unsigned 条件。来源为 RISC-V Ratified Specifications Library 的 RV32I Base Integer Instruction Set。
- 用户提交的是聊天代码片段，未提供编译或新仿真日志；助手只评审片段、未改 RTL、未运行仿真。下一步用户可先做上述高位符号差异测试，提交译码标志、比较数据、PC 选择和 wr_en 日志。

## 2026-10-21：BNE 负偏移回环验证通过，BEQ/BNE 子集完成

- 用户将错误指令替换为 `32'hFE209CE3` 并自行仿真。90ns 日志：PC=0x10、rs1=x1=1、rs2=x2=2、is_bne=1、imm_typeb=FFFFFFF8、branch_flag=1、branch_addr=0x08、wr_en=0，完全符合 BNE x1,x2,-8。
- 后续 PC=0x08（110ns）→0x0C（130ns），与分支回跳后继续顺序取指一致。由于该程序会再次执行 PC=0x10 的相同 BNE，预期继续形成 0x10→0x08 的稳定循环；本轮日志尚未显示下一个 150ns 行，但 90ns 已直接验证负偏移目标。
- 用户提供仿真日志，助手核对；未重跑仿真，未修改核心 RTL。正向四种条件路径与负向 BNE 偏移均有用户日志证据。BEQ/BNE 教学子集达到当前定向验证目标；这不代表完整 B 型全部六种分支或完整 RV32I 合规。
- 下一主题建议：补全 B 型剩余比较分支 BLT/BGE（有符号）与 BLTU/BGEU（无符号），先聚焦 signed/unsigned 比较语义和编码译码，再由用户扩展实现与测试。

## 2026-10-21：负偏移回环测试编码诊断（用户待改）

- 用户计划在 PC=0x10 测 BNE x1,x2,-8，提供编码 `32'h80209443`。日志的 `imm_typeb_o=FFFFF008`、`is_bne_o=0`、`pc_brench_flag_o=0`、PC 顺序到0x14，结果符合当前输入位模式的译码，不是立即数拼接逻辑再次失效的证据。
- 编码核对：`32'h80209443[6:0]=7'h43`，而条件分支 opcode 必须为 `7'h63`，因此这不是 BNE；funct3/寄存器等字段也无法把它识别为 B 型分支。目标指令 BNE x1,x2,-8 的正确编码为 `32'hFE209CE3`，其立即数应为 `32'hFFFFFFF8`；x1=1、x2=2时应 taken，PC 0x10→0x08，wr_en=0。
- 参考 RISC-V 官方 RV32I 规范的 B 型字段排列、signed offset 加到 branch instruction PC 的规则（官网 RV32I Conditional Branches / instruction formats）。
- 用户提供源码片段与 monitor；助手静态解码编码并解释，未改核心文件、未运行仿真。下一步用户替换指令编码并贴回相关日志，确认 opcode=0x63、is_bne=1、imm=FFFFFFF8、目标=0x08。

## 2026-10-21：BEQ/BNE 正向偏移四种条件日志通过

- 用户修正 `imm_typei_o` 拼写后自行仿真并提交日志；x1/x2 均读出已知值，X 问题消失。
- 四种条件均被执行：PC=0x08 的 BEQ 相等成立，目标 0x10；PC=0x14 的 BNE 相等不成立，顺序至 0x18；PC=0x1C 的 BEQ 不相等不成立，顺序至 0x20；PC=0x24 的 BNE 不相等成立，目标 0x2C。PC 序列跳过 0x0C、0x28。
- 四条分支日志均 `wr_en=0`；初始化 ADDI 读值 x1=x2=1，随后 ADDI 将 x2 改为2，比较输入和值符合预期。
- 用户本人提供运行日志；助手核对日志，未实际运行仿真。日志没有直接显示 x3/x4 存储值，因此可由执行路径推断相应写入指令为 0x10 的 x3=7、0x2C 的 x4=6，但这两个寄存器值未在本段 monitor 中直接观察。
- B 型正向 +8 编码/拼接、相等/不等条件、taken/not-taken PC 选择获得定向验证；先前错误的“分支成立时写回”表格项已在讲解中纠正，分支无论是否成立都不写寄存器。
- 尚未由运行日志验证负偏移量的符号扩展；下一步可用简短循环验证 `PC=0x10, BNE x1,x2,-8`（x1!=x2）跳回 0x08，保持条件稳定以重复观察。

## 2026-10-21：BEQ/BNE 第二轮日志诊断（定位到立即数信号拼写）

- 用户按建议更新 B 型 rs2 选择；本轮日志的 BEQ/BNE 均显示 rs1_addr=1、rs2_addr=2，译码修正已生效。
- 静态检查当前磁盘 `rebuild/rtl/addi_decode.v` 第 62 行发现明确拼写错误：模块输出声明及 core 连接名为 `imm_typei_o`，实际连续赋值左值却写成 `imm_typeoi_o`（多了字母 `o`）。这会使正式 I 型立即数输出悬空，而错拼标识符成为未声明隐式网络/编译问题，ADDI 的写回数据无法正确生成，解释寄存器读值 X；X 参与 BEQ/BNE 比较又导致条件不可信，仿真 if 对 X 常走非真分支，故分支 flag 显示 0、PC 顺序递增。
- 当前日志中分支立即数、opcode/funct3 识别与 rs2 地址正常；PC 顺序路径是因为 branch condition 基于 X 数据，并非足以说明 B 型拼接或指令编码错误。
- 证据仍需补足：请将第62行左值改为 `imm_typei_o`，并在下一次日志显示 `wr_addr/wr_data`、必要时 `imm_typei_o`；期待两条初始化 ADDI 向 x1/x2 写入 1，后续 BEQ x1,x2,+8 跳至 0x10。分支本身仍不写寄存器。
- 助手只读静态检查并维护学习记录，未运行仿真、未修改核心 RTL；此前用户已提供本轮仿真日志。

## 2026-10-21：BEQ/BNE 首轮代码与日志诊断（待修正）

- 用户独立预测四种分支目标：BEQ 成立 PC=0x10、不成立 PC=0x0C；BNE 不成立 PC=0x14、成立 PC=0x08。目标地址预测正确，但表中把“分支成立”标成写回；需纠正：BEQ/BNE 都不写 rd，成立与否只影响 PC。
- 用户提交本地仿真日志。指令编码核对：`00100093`=addi x1,x0,1；`00100113`=addi x2,x0,1；`00208463`=beq x1,x2,+8；`00209463`=bne x1,x2,+8；日志中这些编码与程序意图吻合。
- 已定位关键 RTL 问题：`addi_decode.v` 的 `rs2_addr_o` 仅对 R 型 `opcode=0110011` 输出 rs2，未包含分支 `1100011`，故分支日志中 rs2_addr=0，导致比较的是 x1 与 x0 而不是 x1 与 x2。
- 已定位组合逻辑问题：`addi_execute.v` 的 `pc_brench_flag_o` / `pc_brench_addr_o` 仅在 BEQ/BNE 分支内赋值，在非分支默认路径和过程入口未赋默认值，形成锁存/初始 X。需要组合块入口给分支控制/地址默认值，并确保所有路径赋值；写回输出现有分支路径明确为不写回。
- `imm_typeb_o` 对非分支指令显示非零属于当前无条件提取位段的自然结果，不单独说明指令错误；`PC=0x08` 时分支目标应为 0x10，现日志的 0x0C 是不成立路径（但因 rs2 错误且 rs1 出现 X，当前日志不能验证比较正确）。
- 日志中分支时 rs1_data_o=X；按已展示的复位/写回结构，前两条 ADDI 后应为 x1=x2=1。需在后续日志同时观察 wr_addr/wr_data 和 reg_file[1]/[2]，核实实际仿真版本及寄存器写入；不能仅凭当前行断言根因。
- 证据归属：用户提供程序源码片段所在工作区及本人仿真 monitor 日志；助手静态读取并评审 rebuild/rtl 源码，未运行仿真、未修改核心 RTL。
- 下一步：用户先修正 rs2 提取与分支控制默认赋值，再提供更新后的 RTL/日志；查看连续 PC 是否跳过 0x0C、0x28，并观察 x3=7、x4=6。分支写回保持关闭。

更新时间：2026-10-20，本日 U 型 LUI/AUIPC 实现与定向日志通过；下一次从 B 型条件分支 BEQ/BNE 开始。

## 历史断点与当时下一动作（2026-10-20，已完成，不作为当前入口）

本日用户完成了 ADDI、ADD、SUB、R 型 AND/OR/XOR、R/I 型移位、R/I 型比较以及 U 型 LUI/AUIPC 的教学子集实现和定向日志。核心 RTL 文件仍由用户自行同步；本次没有读取或覆盖核心工程文件，证据以聊天提交代码和用户提供日志为准。

### 2026-10-20 今日最后主题：U 型 LUI/AUIPC

- 用户预测正确：x1=`00012000`、x2=`00002004`、x3=`FFFFF000`、x4=`FFFFF00C`。
- 用户新增 U 型立即数：`imm_typeu_o={instr_i[31:12],12'b0}`，并保留 I 型符号扩展立即数 `imm_typei_o`；U 型立即数不在 execute 中重复左移，接口含义清楚。
- 用户在 decode 中正确识别 LUI=`opcode=0110111`、AUIPC=`opcode=0010111`，新增控制信号默认清零。
- 用户在 execute 中正确实现：LUI 写回 `imm_typeu_i`，AUIPC 写回 `pc_i + imm_typeu_i`；core 将当前 `pc_o` 接到 `pc_i`。
- 用户日志完整：10ns LUI 写 x1=`00012000`；30ns AUIPC 写 x2=`00002004`；50ns LUI 写 x3=`FFFFF000`；70ns AUIPC 写 x4=`FFFFF00C`；90ns 零指令不写回。PC、识别标志、目的寄存器、写回总线和固定寄存器一致。
- 评审结论：本次 U 型立即数构造、LUI/AUIPC 译码、PC 相对加法、core 连接和写回证据通过；用户请求结束今天学习，助手没有重跑仿真或 Python，也没有据此宣称完整 ISA 合规。
- 粘贴文本中的 `*`、HTML 转义和注释乱码仍视为传输格式痕迹；若实际源码含有它们才需要单独修复。当前日志证明实际运行版本语法有效。

### 历史下一主题：B 型条件分支 BEQ/BNE（现已完成）

下一次从条件分支的整体行为开始：比较两个寄存器，条件成立时把 PC 改为 `PC + branch_imm`，否则继续 `PC + 4`。先做 BEQ/BNE 的 B 型立即数拼接、分支目标和 PC 选择，不重复已经通过的算术、移位、比较或 LUI/AUIPC 练习。具体编码和测试程序下次开始时再预测与设计。

## 今日收尾记录（2026-10-20）

- 用户回答/预测：本日 SLTI/SLTIU 结果及 LUI/AUIPC 结果均独立预测正确。
- 用户亲写代码：decode/execute/core 增量覆盖 R/I 型算术、逻辑、移位、比较和 U 型 LUI/AUIPC；本日提交的 LUI/AUIPC 片段已评审。
- 用户提供证据：SLTI/SLTIU 日志以及 LUI/AUIPC 的 10/30/50/70/90ns 日志；本日最后日志在 90ns 零指令确认不写回。
- 助手实际运行结果：未重跑仿真、未运行 Python、未修改核心 RTL；只用 PowerShell 维护学习文档。
- 掌握边界：上述证据证明教学子集在给定定向程序中通过，不等于完整 RV32I、完整异常行为或综合/上板验收。
## 2026-10-20 最新完成：AND/OR/XOR 逻辑组

- 用户预测70ns x3=8、90ns x4=14、110ns x5=6，全部正确。
- 用户提交decode：新增is_xor_o/is_or_o/is_and_o，组合块入口全部默认清零；R型opcode=7'h33下按funct3=4/6/7和funct7=0分别识别XOR/OR/AND，保留ADD/SUB与ADDI路径。使用3'h/7'h等窄写法位宽合法；无漏赋值路径。
- 用户提交execute：新增xor/or/and三分支，分别使用按位`^`、`|`、`&`；优先级在已有ADD/SUB/ADDI之后，无效分支完整清零。core译码/执行连接三组控制线正确。
- 用户日志：50ns AND写x3=00000008；70ns固定x3=8且OR待写x4=0000000E；90ns固定x4=14且XOR待写x5=00000006；110ns固定x5=6且零指令不写回。日志同时显示x1=12、x2=10，证明依赖读回路径继续有效。
- 结论：本轮AND/OR/XOR的预测、代码片段、控制连接和写回证据通过；未重跑仿真、未检查完整磁盘实现、无完整ISA覆盖或综合结论。用户工程文件继续由本人自行覆盖同步。

## 2026-10-20 较早记录：SUB 与负数结果依赖（历史）

- 用户原预测：FFFFFFFE、-2、5，全部正确（分别为70ns后x3的位模式/有符号解释及90ns后x4）。
- 用户提交decode组合块：三个标志默认清零，opcode=7'h33/funct3=3'h0时用funct7=7'h0识别ADD、7'h20识别SUB，保留ADDI=7'h13/funct3=0；位宽/十六进制比较正确，组合赋值完整。
- 用户提交execute组合块：新增is_sub_i分支使用rs1_data_i-rs2_data_i，保留ADDI/ADD与无效清零；core的is_sub_o→is_sub_i连接正确。本轮提交为局部片段，不据此声称已检查完整端口声明。
- 用户日志50ns PC=8/instr=402081B3、is_sub=1、wr_en=1、wr_addr=3、wr_data=FFFFFFFE；70ns PC=C/instr=00218233、固定x3=FFFFFFFE、wr_addr=4、wr_data=00000005；90ns PC=10零指令、固定x3=FFFFFFFE/x4=00000005、写回输出0/0/0。
- 本轮有固定x3/x4存储观察，确认该SUB→ADD场景的写回结果与预测一致；补齐了之前仅看写回总线的证据局限，但不是完整编码/边界覆盖或完整ISA合规。
- 用户明确说明工作区文件后续自行覆盖。助手未读取/覆盖核心RTL/TB，本次只读取学习入口与本地中文手册2.4/Reference card，核对用户日志并维护文档；用PowerShell位运算核对下一课R型编码，未运行仿真、Python、综合。

## 2026-10-20 较早记录：ADD 执行与依赖读回（历史）

- 用户预测原程序70ns后x3=12、90ns后x4=10，正确。
- 用户聊天提交execute：新增is_add_i、rs2_data_i，以else-if实现ADD分支rs1+rs2；ADDI保持rs1+imm；三个写回输出所有分支均赋值，代码评审通过。core聊天新增两输入连接正确。
- 局部清理：聊天代码中的rs2_addr_i未使用、实例未连接；不影响当前已使用数据路径，但应删除多余接口，不需给执行单元传递源寄存器地址。
- 用户运行日志50ns PC=8/instr=002081B3、rs1=5、rs2=7、wr_en=1、wr_addr=3、wr_data=0000000C；70ns PC=C/instr=FFE18213、rs1_addr=3、rs1_data=0000000C、wr_addr=4、wr_data=0000000A；90ns零指令写回总线0/0/0。
- 证据结论：ADD写x3=12有下一条实际读回证据，随后ADDI正确计算待写10；未打印x4固定存储值，不能称已直接观察90ns x4=10。不要求重复相同场景，后续新场景加入固定寄存器观察。
- 本轮助手实际读取磁盘execute/core/TB/imem，仍为上一阶段“只接双读口、未执行ADD”的版本，未同步聊天中的ADD执行、新连接或第四条ADDI程序。实现/新运行证据来自用户聊天，不能声称本工作区最终版已落盘。需要工具编译时再确认实际工程来源，不覆盖用户文件或要求重做学习。
- 助手只读文件、核对用户日志、查阅本地中文手册2.4与Reference card ADD/SUB行并维护记录；没有代写RTL/TB，没有运行仿真、Python或综合。

## 2026-10-20 较早记录：第二读口接入 rs2（历史）

- 用户亲写并提交 core：增加5位rs2_addr_o、32位rs2_data_o、1位is_add_o，连接译码输出与regfile第二读口，移除core固定x1_o调试端口；执行单元仍仅支持ADDI。
- 用户TB使用层次引用观察内部地址/数据和译码标志，观察方式正确。
- 用户日志：30ns PC=4、instr=00700113；50ns PC=8、instr=002081B3、rs1_addr=1、rs2_addr=2、rs1_data=5、rs2_data=7、is_addi/is_add=0/1、wr_en=0；70ns和90ns零指令均不写回。日志符合当前“识别并读出ADD操作数，但尚不执行”的阶段。
- 代码评审及本场景日志通过，不重复要求跑相同的第二读口测试。日志为用户运行后提交，助手未实际重跑，无综合或完整覆盖结论。
- 助手实际检查磁盘：core与用户聊天提交一致；TB层次观察与程序imem已同步落盘。TB仍有一条未使用的wire [31:0] x1_o声明，可顺手删除，不影响功能也不阻碍继续。
- 代码归属：用户实现和用户运行日志；助手仅评审、解释并维护学习文档，未修改RTL/TB、未运行仿真/Python/综合。

## 2026-10-20 较早记录：ADD 译码提交与证据（历史）

- 用户三条译码预测全部正确：ADD 为 rs1/rs2/rd=1/2/3 且仅 is_add=1；SUB 同地址但两个识别输出均为0；ADDI 机械 rs2=4 且仅 is_addi=1。
- 首版聊天代码的 R 型 funct3!=000 路径未赋值；用户随后亲自加入组合块默认赋值，消除了此处未赋值路径。分支中的冗余清零无功能错误；未强制重构。
- 用户提供的新日志（助手仅核对，未重跑）：30ns PC=4、instr=002081B3、rs1/rs2/rd=1/2/3、is_addi/is_add=0/1；50ns PC=8、instr=002091B3、相同寄存器地址、标志0/0；70ns SUB 标志0/0；90ns ADDI 标志1/0。
- 结论：代码评审确认已消除这处组合赋值遗漏，用户定向日志验证 ADD→SLL 识别不残留；不是完整编码空间覆盖、综合无锁存报告或完整 ISA 合规证据。
- 助手本次实际读取了磁盘 `rebuild/rtl/addi_decode.v`，内容已包含用户提交的 rs2/is_add 扩展和默认赋值修正。用户聊天代码与此文件一致，不再记为未落盘。
- 本次也读取 core/execute/TB：core 第二读口仍固定读 x1，execute 仍仅支持 ADDI；磁盘 imem 仍为原连续 ADDI 程序，并非用户新译码日志使用的程序。运行工程/激励版本仍需区分，不据日志声称 imem 已同步。
- 助手维护学习记录，未修改任何核心 RTL/TB，未运行仿真、Python 或综合。此前 2026-10-19 的磁盘缺失记录仅代表当时检查状态。

## 永久讲解节奏（已同步到其余入口文件）

每轮推进一个完整、适量的小主题：先整体作用，再必要原理/硬件行为，随后一项用户亲写或验证任务。依据后续表现动态调节，避免把一个数字/一行声明拆成单独一轮，也不连续堆多个新主题。行数仅参考。

局部小错指出原因和修改处，让用户下一条顺手改正，同时继续不受影响的下一步；只有错误较多或关键概念影响后续时才暂停。允许同一回复提交预测、代码与日志。用户自己运行简单仿真，助手按证据评审，不重复要求同一测试。

核心 RTL/完整 TB 默认由用户写；辅助脚本、环境和记录归助手维护。遵循需求→接口→时序→预测→用户实现→评审→修改→仿真。此节奏长期生效，下次无需用户再次提醒。

## 2026-10-19 完成情况与证据

| 主题 | 用户行为/结果 | 当前证据与掌握状态 |
|---|---|---|
| PC 日志复盘 | 解释25 ns无上升沿所以PC保持，rst_n变化触发monitor | 用户复述正确；无需再问 |
| 字节地址与取指 | 预测0xC/0x10对应32位字下标3/4；亲写imem与无时钟TB | 用户日志四项标记值与越界零输出吻合 |
| 取指连接 | 亲写fetch_unit，修正pc_o为输出 | 用户日志PC=0/4/8/C，指令跟随；真实00500093编码也验证 |
| ADDI 字段与译码 | opcode修正为19；亲写立即数符号扩展、rs1/rd提取和is_addi判断 | 正数5、负数FFFFFFFF、非ADDI的用户日志正确 |
| 寄存器堆 | 亲写32×32数组、同步写、组合双读、x0保护；复位清x1～x31 | 用户日志x0恒零、写后x1=5；复位后x1未单独观察，TB与上升沿竞争待规范 |
| ADDI 执行 | 两组预测正确；亲写addi_execute | 用户日志0+5=5、5+FFFFFFFF=4、FFFFFFFF+1=0、无效时0/0/0 |
| 最小写回闭环 | 亲写addi_core并修改连接后运行 | 用户日志30ns写5、50ns写FFFFFFFF，后续非ADDI不写 |
| 连续读写依赖 | 独立预测x1=5/8/7/7并修改程序运行 | 30/50/70/90ns日志完全吻合；验证下一条能使用前条结果 |
| ADD 扩展 | 助手讲了两个寄存器操作数、R型格式、funct7区别 | 已解释待练习，未实现/未仿真，不计为掌握 |

用户在指导下完成上述模块，并有独立预测、亲写和运行证据；不将助手给出的提示/最小片段记为用户独立设计。ADDI 核心只是教学子集，不是完整 ISA 合规或流水线验收。

## 最新程序、时序和用户日志

本表记录用户实际测试程序，不代表磁盘 imem.v 已更新。

| 字节地址 | 编码 | 行为 |
|---|---|---|
| 0x00000000 | 00500093 | addi x1,x0,5 |
| 0x00000004 | 00308093 | addi x1,x1,3 |
| 0x00000008 | FFF08093 | addi x1,x1,-1 |
| 0x0000000C | 005000B3 | 当前仅支持ADDI，因而忽略此ADD编码 |
| 其他地址 | 00000000 | 当前教学模型不写回 |

时钟初值0，每10ns翻转，周期20ns，上升沿10/30/50/70/90ns；rst_n初值0，25ns释放；低有效同步复位。

用户最后一次预测：30ns x1=5；50ns x1=8；70ns x1=7；90ns x1=7。以下为用户自行运行后在聊天提供的 monitor 输出，助手只核对，未实际重跑；无自动断言或工具命令/原始日志文件归档证据。

```text
time =  0ns,pc_o = xxxxxxxx,instr_o = xxxxxxxx,wr_en = x,wr_addr = x,wr_data = xxxxxxxx,x1_o = xxxxxxxx
time = 10ns,pc_o = 00000000,instr_o = 00500093,wr_en = 1,wr_addr = 1,wr_data = 00000005,x1_o = 00000000
time = 30ns,pc_o = 00000004,instr_o = 00308093,wr_en = 1,wr_addr = 1,wr_data = 00000008,x1_o = 00000005
time = 50ns,pc_o = 00000008,instr_o = fff08093,wr_en = 1,wr_addr = 1,wr_data = 00000007,x1_o = 00000008
time = 70ns,pc_o = 0000000c,instr_o = 005000b3,wr_en = 0,wr_addr = 0,wr_data = 00000000,x1_o = 00000007
time = 90ns,pc_o = 00000010,instr_o = 00000000,wr_en = 0,wr_addr = 0,wr_data = 00000000,x1_o = 00000007
```

关键理解：同一个上升沿，PC更新到下一条，而寄存器堆采样的是沿前已稳定的写回结果；monitor在组合信号稳定后显示新PC的待写数据与刚提交的x1值。比如30ns x1=5，wr_data=8，这两项含义不同。

## 用户代码接口与文件归属

- pc_reg：输入clk/rst_n，输出pc_o[31:0]；低有效同步复位、顺序加4。
- imem：addr_i[31:0]→instr_o[31:0]，组合读取，未匹配地址输出0。教学抽象；上游对应ROM并经RIB连接，不存在同名imem模块。
- fetch_unit：clk/rst_n→pc_o/instr_o；用户修正pc_o方向后已提供通过日志。
- addi_decode：instr_i→imm_o[31:0]、rs1_addr_o[4:0]、rd_addr_o[4:0]、is_addi_o；用户明确将原rs1_o/rd_o重命名。
- regfile：clk/rst_n；wr_en_i、wr_addr_i[4:0]、wr_data_i[31:0]；rs1_addr_i/rs2_addr_i[4:0]；rs1_data_o/rs2_data_o[31:0]。复位清1～31，0号数组元素未用，读x0强制0、写x0忽略。
- addi_execute：is_addi_i、imm_i[31:0]、rs1_data_i[31:0]、rd_addr_i[4:0]→wr_en_o、wr_addr_o[4:0]、wr_data_o[31:0]。
- addi_core：clk/rst_n→pc_o/instr_o、wr_en、wr_addr[4:0]、wr_data[31:0]、x1_o[31:0]。内部实例由用户写；建议补显式连线位宽、第二读口固定1并直连x1_o后，用户提供结果正确的日志，但修正后的完整源码未重贴。
- 用户亲写TB：tb_imem、tb_fetch_unit（后加入译码）、tb_regfile、tb_addi_execute（提供日志）、顶层ADDI闭环TB（提供日志；未贴最终源码）。
- 助手工作：讲解、评审、学习文档和此前辅助环境维护；今天没有代写/恢复整核，也没有将聊天中未提交的修正版伪装成用户原码。

收尾实际检查：本工作区 rebuild/ 下仅确认 rtl/pc_reg.v、rtl/imem.v、tb/tb_pc_reg.v、tb/tb_imem.v。磁盘imem仍为11111111/22222222/33333333/44444444标记值版本；没有发现fetch_unit/addi_decode/regfile/addi_execute/addi_core等.v文件。它们的本次进度证据是聊天代码和用户日志，实际工程保存位置未确认。下次需要工具编译时才核对来源，不因缺文件让用户重做已完成学习，也不覆盖为助手推测的最终版。

## 纠正和仍需注意的事项

- 已纠正：opcode取低7位为0x13/19；模块边界决定pc_o是输出；内部连接必须显式声明位宽，不能依赖隐式1位wire；x1观察不能误接当前rs1读口。
- x0：外部读口恒零、写入被忽略即可满足当前模型，不要求未使用的reg_file[0]物理存储必须为0；清x1～x31是本教学复位选择。
- regfile TB 50/70ns在上升沿同时修改写信号，存在竞争；下次新增时序激励应在下降沿或远离采样沿驱动。现有日志不能证明复位后每个寄存器均为0或完整读写边界覆盖，不重复机械重跑本场景。
- 当前非ADDI编码不写回，是教学子集选择；尚未实现非法指令异常。开始支持ADD后，005000B3不再是“应忽略”的反例，需要更换测试期望。
- 没有流水线、完整指令回归、综合/时序和上板证据；今天也未新增运行中复位、x0整核写入、源/目标多编号等完整验证。
- 参考：中文手册2.2指令格式、2.4整数计算；Reference card ADD/SUB/ADDI行，ADD识别及SUB反例已核对。

## 历史逐步记录（保留追溯，不作为当前入口）

以下按原会话记录保留。旧条目中的“下次”“待确认”“未仿真”只描述当时状态；当前快照和2026-10-19收尾优先，不得据旧条目重复起点问答或把历史待办当作当前任务。
## 学员信息与证据

| 项目 | 已知情况 | 证据/限制 |
|---|---|---|
| FPGA 经历 | 做过 FPGA 项目，曾按 README 跑通并移植 tinyriscv | 用户自述，不能等同掌握 CPU 原理 |
| Verilog | 用户自述能从零完成 LED、计数器、分频器和异步 FIFO | 具备 RTL 实践基础，课程直接迁移到 CPU；具体实现正确性未在本会话验证 |
| CPU/RISC-V | 从基础开始 | 用户反馈原五题全部不会 |
| 时间 | 每周 5～8 小时，一次一个小主题 | 用户选择 |
| 教学偏好 | 必须从零引导自己写，禁止上来给完整代码 | 2026-10-17 用户明确纠正 |
| 硬件 | 用户选 Artix-7 35T 同款；邻近目录有升腾 Mini xc7a35tfgg484-2 记录 | 封装/引脚最终需核实 |

## 工程准备和学习掌握分开记录

- 工程准备：UV 创建了本工作区 .venv；Vivado 2024.2 XSim 曾运行助手演示短程序。
- 2026-10-17 历史结果：演示打印 RV32I CORE TEST PASS，覆盖短程序中的 addi/add/sw/lw/beq/jal/auipc。仅做了编译、展开、仿真，未做综合、完整指令回归或上板验证。
- 上游原 ISA/compliance/C 例程：本轮尚未重新运行；没有通过证据。
- 工具发现：Icarus/VVP/GTKWave/Verilator/Make 未在 PATH 找到，不等于系统未安装。
- 用户亲自完成：rebuild/rtl/pc_reg.v，32 位输出、非阻塞赋值、低有效同步复位、顺序加 4。
- 已有练习证据：正确预测 PC 从 0x20 到 0x24，能写本模块端口和加 4 的时序逻辑。复位契约已修正并完成基础仿真；字节编址与数据宽度后续结合存储器确认。
- 截至 2026-10-17：只完成 PC；此项为历史状态。2026-10-19 已推进到最小 ADDI 闭环，见顶部当前快照。

## 代码位置

- 上游完整工程：D:\Study\RISC-V\TinyRiscV\tinyriscv-master。
- 根目录 rtl：原项目参考快照，保留不变。
- rebuild/rtl/pc_reg.v 和 rebuild/tb/tb_pc_reg.v：用户提交、助手保存的 PC 与测试文件；保留 1ns/1ps 时间单位声明。
- archive/2026-10-17-assistant-demo：此前助手提前给出的完整代码、脚本、日志及波形草图；仅历史留存，不是用户成果，不默认阅读。

## 本次纠正记录

- 用户：此前五道题全不会，需要先讲基础，再一步一步引导写出整个项目。
- 助手：原诊断难度过高，提前给完整代码违背学习方式；已归档演示并重写计划。
- 新会话改问 1～3 个已学内容或起点问题；答不上来先补基础，不继续堆题。
- 路线改为“一个实际需求 → 硬件行为 → 小段代码 → 预测结果 → 仿真 → 用户解释”，完整项目按里程碑累计完成。

## 已完成的起点问答（不要重复询问）

1. 用户从零写过 LED、计数器、分频器、异步 FIFO；不是 Verilog 新手。
2. 用户将“计算/保存”解释为“马上计算/以后需要再计算”。需要澄清：保存意味着保持状态，不决定何时计算；既可以存操作数，也可以存计算结果。课堂用“PC 加法器算下一个地址，PC 寄存器保存当前地址”连接已有 RTL 知识。
3. 用户看过时钟仿真波形，明确知道上升沿。

## 本次教学与验证

- 用户已写出 PC：32 位，低有效同步复位，上升沿清零或加 4；已明确不含暂停/跳转。
- 用户写出 testbench：clk 初值 0、每10ns翻转；rst_n 初值0、25ns释放；实例化正确；增加 $monitor("time = %d,rst_n = %b,pc_o = %h",$time,rst_n,pc_o) 与 #80 $finish。
- $time 是系统函数，%d 是合法十进制格式；本文件 timescale 为 1ns/1ps，整数时间输出对应 ns。格式文字 time 只是标签。无需强制改 %0t，%0d 可减少前导空白。
- 初次误跑旧版 tb（未保存 monitor/finish）没有结果，已用 Ctrl+C 中止；不算用户代码失败。保存最新用户代码后重新编译运行。
- 仿真工具：Vivado 2024.2 xvlog / xelab / xsim；Tcl 使用 run 100 ns、quit 给出运行上限，实际 $finish 在80ns发生。
- 日志：rebuild/sim/pc_reg_verified_20261017_165536/xsim.log。
- 实际输出：0ns rst_n=0 pc=X；10ns 0/0；25ns 1/0；30ns 1/4；50ns 1/8；70ns 1/12；80ns结束。与用户预测的四个上升沿结果一致。
- 结论：基础复位/顺序计数场景经日志核对通过；没有 HDL 自动断言，没有运行中重新复位或回绕测试，未综合/上板。不称为完整处理器验收。
- 本次解释：同步复位尚未遇到第一个上升沿时 PC 初始为 X 是正常仿真行为；$monitor 关注参数变化，不仅在上升沿打印，25ns因 rst_n 变化输出。
- 纠正历史教学错误：上升沿间隔就是周期；每10ns翻转一次对应20ns周期。用户曾明确假设0ns立即翻转，其0/20/40/60ns答案在该假设下成立；当前实际 always #10 的上升沿则为10/30/50/70ns。不能把旧题歧义当作用户知识缺陷。

## 历史接续安排（2026-10-17，已完成，不再执行）

PC 和 testbench 不必重新抄写。下次第一步只让用户用自己的话解释：为什么 25 ns 有 monitor 输出但 PC 没有加 4；答案应涉及 rst_n 变化触发 `$monitor`、没有 posedge、同步复位只在上升沿生效。确认后给出“PC → 指令存储器 → 指令总线”的整体思路，再让用户先设计指令存储器接口，暂不写完整存储器代码。用户掌握：PC 步长、同步复位、基础 TB 和预期波形有亲写/预测/仿真证据；日志解释待复述确认。

## 后续记录格式

每次小步骤后填写：日期；主题；用户原回答摘要；已解释内容；用户亲写文件/片段；预测值；实际命令、结果与日志；尚未理解之处；下一步唯一动作。掌握状态使用“未接触 / 已解释待练习 / 能在提示下完成 / 能独立完成 / 待复习”。资料、脚本与助手示例生成不能提升掌握等级。

用户要求结束、换会话或完成一个小步骤时更新记录；未完成的问题原样保留以防中断。













## 会话收尾（2026-10-17）

- 本次用户完成：`rebuild/rtl/pc_reg.v` 与 `rebuild/tb/tb_pc_reg.v`。
- PC 行为：`rst_n` 低有效同步复位；在 `posedge clk` 时复位清零，否则 `pc_o + 32'h4`；不含跳转、暂停和等待。
- testbench 行为：`clk=0`，`always #10 clk = ~clk`；`rst_n=0` 后在 25 ns 释放；monitor 打印 `$time/rst_n/pc_o`；80 ns `$finish`。
- 仿真命令：Vivado 2024.2 `xvlog` → `xelab` → `xsim`，运行 `run 100 ns; quit`。
- 仿真日志路径：`rebuild/sim/pc_reg_verified_20261017_165536/xsim.log`。
- 日志关键结果：0 ns `pc_o=X`；10 ns 复位清零；25 ns rst_n 改变但无时钟沿、PC 保持 0；30/50/70 ns PC 为 4/8/12；80 ns 正常结束。
- 掌握证据：用户独立写出端口、同步复位、加 4、时钟/复位激励和 monitor；正确预测 PC 表并能区分翻转与上升沿。尚待用户用自己的话复述 25 ns 日志原因。
- 明确不计入用户成果：`archive/2026-10-17-assistant-demo` 中的完整核心及历史演示；本次只验证 PC 小模块。
- 结束时唯一下一步：先复述 25 ns 的 monitor 输出原因，然后设计指令存储器的接口。

## 2026-10-19 会话继续：25 ns 日志复盘

- 用户回答：25 ns 时钟上升沿还没有到来。
- 评审：回答正确，但只覆盖了 PC 没有更新的原因；尚待补充 `$monitor` 为什么仍然输出。
- 已解释：25 ns 时 `rst_n` 从 0 变为 1，触发 `$monitor` 重新打印；`pc_reg` 的 `always @(posedge clk)` 没有被触发，因此同步复位/加 4 逻辑都没有在此刻执行，PC 保持 0。
- 用户代码归属：无新增代码。
- 实际测试证据：沿用 `rebuild/sim/pc_reg_verified_20261017_165536/xsim.log`，尚未重新运行。
- 当前待答：指出 25 ns `$monitor` 输出由 `rst_n` 的变化触发。
- 下一步：确认该点后，说明 PC 连接指令存储器的整体思路，只推进接口设计。

## 2026-10-19 会话继续：25 ns 日志复盘完成

- 用户补充回答：输出由 `rst_n` 变化触发；`$monitor` 因监视信号变化打印，而 `always @(posedge clk)` 只响应时钟上升沿，因此打印不会改变 PC。
- 评审：正确理解了事件触发与同步时序逻辑的区别。
- 掌握状态：能独立解释基础仿真日志中的 `$monitor`、`rst_n` 变化、时钟上升沿和 PC 保持行为。
- 用户代码归属：无新增代码。
- 实际测试证据：沿用 `rebuild/sim/pc_reg_verified_20261017_165536/xsim.log`；本次未重新运行。
- 新小目标：设计 PC 到指令存储器的最小接口；先明确输入输出和组合读取行为，暂不实现完整存储器。

## 2026-10-19 会话继续：指令存储器接口初步设计

- 用户回答：地址输入和指令输出均为 32 位；最小指令存储器不需要 `clk`，因为采用组合逻辑读取。
- 评审：接口方向正确，符合当前教学模型。
- 已解释内容：PC 输出当前指令地址，指令存储器根据地址组合地产生 32 位指令；教学示例使用地址 `0x0/0x4/0x8` 对应连续指令。
- 用户代码归属：无新增代码。
- 实际测试证据：尚未实现或仿真指令存储器。
- 当前待练习：理解 RISC-V 的字节地址与 32 位指令存储数组下标之间的关系。
- 下一步唯一动作：预测地址 `0/4/8` 如何映射到四字节指令数组的下标。

## 2026-10-19 会话继续：字节地址到指令下标

- 用户预测：PC=`0x0000000C` 映射到数组下标 3；PC=`0x00000010` 映射到数组下标 4。
- 评审：计算正确，理解连续 32 位指令地址每次增加 4，以及数组下标等于 PC 除以 4。
- 掌握状态：能独立完成具体地址映射预测。
- 用户代码归属：无新增代码。
- 实际测试证据：尚未实现或仿真指令存储器。
- 下一步：用户亲自写 `imem` 模块的输入输出声明，暂不写读取逻辑。

## 2026-10-19 会话继续：教学节奏调整与上游模块对应

- 用户提交接口：`module imem(input wire [31:0] addr_i, output wire [31:0] instr_o);`，端口方向和位宽正确。
- 用户反馈：希望每次讲授一个稍完整的小主题，节奏根据后续理解动态调整，避免过细过慢。
- 已检查上游工程：没有名为 `imem` 的模块。上游使用 `rtl/perips/rom.v` 作为指令存储器，并通过 `rtl/core/rib.v` 和 `rtl/soc/tinyriscv_soc_top.v` 连接；核心的 `pc_reg` 输出 PC，核心接口命名为 `rib_pc_addr_o` / `rib_pc_data_i`。
- 原项目选择：`rom.v` 支持时钟写入、复位时组合读出零值、正常情况下按 `addr_i[31:2]` 组合读出；RIB 根据地址高位选择 ROM 等从设备。
- 教学选择：先用 `imem` 抽象“PC 地址到 32 位指令”的局部行为，暂时隐藏 RIB 和地址译码；之后再把这个抽象映射回上游的 ROM/RIB 结构。
- 用户代码归属：`rebuild/rtl/imem.v` 接口声明由用户提交；尚未实现存储内容和读取逻辑。
- 实际测试证据：尚未仿真 `imem`。
- 下一步：完成“固定四条指令的组合读取”小主题，明确越界/未初始化地址的行为后，由用户写最小读取逻辑。

## 2026-10-19 会话继续：组合指令存储器实现

- 用户提交并实现 `rebuild/rtl/imem.v`：使用 `always @(*)`，输出为 `reg [31:0]`；对地址 `0x0/0x4/0x8/0xC` 返回四个固定 32 位标记值，其他地址返回零。
- 评审：组合敏感表写法正确；所有分支都给 `instr_o` 赋值，没有明显锁存风险；地址比较与当前固定地址教学模型一致。
- 用户代码归属：`rebuild/rtl/imem.v` 的完整当前实现由用户提交。
- 实际测试证据：尚未仿真。
- 当前掌握状态：能独立完成最小组合指令存储器；尚未用 testbench 验证输入地址到输出数据的映射。
- 下一步：为 `0x0/0x4/0x8/0xC/0x10` 写最小定向仿真并核对预期输出；暂不引入时钟。

## 2026-10-19 会话继续：imem 组合读取仿真完成

- 用户提交 `rebuild/tb/tb_imem.v`：实例化 `imem`，依次测试地址 `0x0/0x4/0x8/0xC/0x10/0x14`，用 `$monitor` 输出，80 ns 结束；未加入时钟，符合组合存储器模型。
- 用户报告实际仿真日志：0 ns 返回 `11111111`；10 ns 返回 `22222222`；20 ns 返回 `33333333`；30 ns 返回 `44444444`；40 ns 和 50 ns 越界地址返回零。
- 评审：地址变化触发组合输出变化，日志与预期一致；额外的 `0x14` 越界测试也通过。
- 实际测试证据：用户亲自运行仿真并提供日志；本助手未重新运行工具。
- 掌握状态：能独立编写并验证固定地址组合读取模块和无时钟 testbench。
- 下一步唯一动作：设计并连接 `pc_reg` 与 `imem`，预测复位和连续取指时序；暂不进入译码。

## 2026-10-19 会话继续：PC 与 imem 取指时序预测

- 用户预测：30 ns 上升沿后 PC 为 `32\'h00000004`，指令为 `32\'h22222222`；原因是 `imem` 为组合逻辑，地址改变后输出随之改变。
- 评审：预测正确。补充仿真语义：PC 的非阻塞赋值在时钟事件后更新，`imem` 在后续 delta cycle 响应，通常仍显示相同的时间戳；真实硬件中对应组合传播延迟。
- 掌握状态：能独立解释同步 PC 更新与组合指令读取的连接关系。
- 用户代码归属：尚未新增连接模块。
- 实际测试证据：尚未仿真 PC 与 imem 的组合连接。
- 下一步唯一动作：用户编写最小取指连接模块，将已有 `pc_reg` 和 `imem` 实例化并连接。

## 2026-10-19 会话继续：fetch_unit 首次连接尝试

- 用户提交 `fetch_unit`：实例化 `pc_reg` 和 `imem`，将 `pc_o` 连接到 `imem.addr_i`，将 `instr_o` 连接到 `imem.instr_o`。
- 评审：实例连接和内部数据路径方向基本正确。
- 关键问题：用户将 `pc_o` 声明为 `input wire`，但该信号实际由内部 `pc_reg` 的输出驱动并向模块外提供，因此应为 `output`；输入端口不能作为该模块内部子模块的输出承载端。
- 用户代码归属：本次 `fetch_unit` 尝试由用户提交；尚未修正。
- 实际测试证据：尚未编译或仿真 `fetch_unit`。
- 下一步：用户只修正 `pc_o` 的端口方向，并重新贴出模块声明/文件。

## 2026-10-19 会话继续：PC → imem 连接与仿真完成

- 用户修正 `fetch_unit`：`pc_o` 改为 `output wire [31:0]`；内部 `pc_reg` 产生 PC，`imem` 使用 PC 作为地址，`instr_o` 对外输出。
- 用户提交 `tb_fetch_unit`：时钟每 10 ns 翻转、低有效同步复位在 25 ns 释放、`$monitor` 观察 `rst_n/pc_o/instr_o`，100 ns 结束。
- 用户提供实际日志：10 ns 得到 PC=`0x0`/指令=`0x11111111`；30/50/70 ns 依次得到 `0x4/0x22222222`、`0x8/0x33333333`、`0xC/0x44444444`；90 ns 得到 `0x10/0x0`；与预期一致。
- 评审：模块连接、端口方向、组合读取和同步 PC 时序均正确。0 ns 的 PC/指令为 X 是初始状态尚未经过时钟和组合输入变化的仿真表现，不影响后续验证。
- 实际测试证据：用户亲自运行并提供 `tb_fetch_unit` 日志；本助手未重新运行工具。
- 掌握状态：能独立连接并验证 PC 与组合指令存储器。
- 下一主题：把固定标记值替换为真实的 RV32I 指令编码，先理解一条 `addi` 指令在取指路径中的位置。

## 2026-10-19 会话继续：真实指令编码的取指预测

- 用户预测：把地址 `0x00000000` 的内容改为 `32\'h00500093` 后，`tb_fetch_unit` 在 10 ns 会输出该编码。
- 评审：预测正确。当前取指路径只传递 32 位位模式，不执行 `addi`，因此尚无寄存器写回。
- 掌握状态：能区分“取到指令编码”和“执行指令产生结果”。
- 用户代码归属：尚未修改 `imem.v`。
- 实际测试证据：尚未运行真实指令编码版本。
- 下一步：将 `imem` 地址 `0x0` 的返回值改为 `32\'h00500093`，复用现有 `tb_fetch_unit` 运行并记录日志。

## 2026-10-19 会话继续：真实 addi 编码取指验证完成

- 用户修改 `imem` 后提供实际日志：10 ns 时 PC=`0x00000000`，`instr_o=0x00500093`；25 ns PC 不变；30/50/70 ns 继续取到后续标记值；90 ns 越界返回零。
- 评审：真实 RV32I 指令编码已成功接入既有 PC→imem 路径；取指仍未执行指令，符合当前阶段边界。
- 实际测试证据：用户亲自运行 `tb_fetch_unit` 并提供日志。
- 掌握状态：能独立验证 PC 地址与真实指令编码的对应关系；已理解取指和执行是不同阶段。
- 下一步唯一动作：从 `0x00500093` 中手算 `opcode/rd/funct3/rs1/imm`，为后续最小 `addi` 译码准备输入。

## 2026-10-19 会话继续：addi 指令字段手算

- 用户从 `0x00500093` 提取字段：`rd=1`、`funct3=0`、`rs1=0`、`imm=5`，均正确。
- 用户将 `opcode` 写为十进制 12，评审发现错误。
- 已纠正：低 7 位为 `7\'b0010011 = 7\'h13 = 19`；`0x93` 的最低 7 位不是把整个低字节直接当 opcode。
- 当前待确认：用户补充 `opcode=0x13`（十进制 19）。
- 其他掌握证据：能正确提取 I 型指令的 rd、funct3、rs1 和立即数。
- 下一步：确认 opcode 后，用字段组合识别 `addi`，再设计只支持该指令的最小译码输出。

## 2026-10-19 会话继续：节奏反馈与 opcode 修正

- 用户确认字段：`opcode=19`、`rd=1`、`funct3=0`、`rs1=0`、`imm=5`，全部正确。
- 用户反馈：单个简单错误不应单独占用一个对话；指出错误后应让用户顺手改正，并继续给出下一步，只有较多或重大错误才暂停。
- 教学调整：后续按“指出局部错误 → 用户在下一条确认/修正 → 同时推进下一知识点”的节奏进行。
- 已讲授下一主题：最小 `addi` 译码需要用 `opcode=7\'h13` 与 `funct3=3\'b000` 判断有效性，并对 `[31:20]` 做符号扩展。
- 下一步：用户亲自实现 `rebuild/rtl/addi_decode.v`，输出 `is_addi_o/rs1_o/rd_o/imm_o`。

## 2026-10-19 会话继续：addi_decode 首版评审

- 用户提交 `addi_decode`：连续赋值提取 I 型立即数并符号扩展，切片提取 `rs1/rd`，组合块以 `opcode==7\'b0010011 && funct3==3\'b000` 产生 `is_addi_o`。
- 评审：逻辑正确，端口方向/类型匹配；组合块两个分支均赋值，无锁存风险。当前即使非 addi 指令也会输出相应位段，但由 `is_addi_o=0` 表示不应按 addi 解释，属于明确可接受的接口约定。
- 用户代码归属：`rebuild/rtl/addi_decode.v` 由用户编写并提交；工作区文件尚未核对/仿真。
- 实际测试证据：无，待定向仿真。
- 掌握状态：能在提示下独立实现 addi 的字段提取、符号扩展与基本识别。
- 下一步：用正立即数、负立即数和非 addi 指令验证译码器；需预测 `0x00500093`、`0xFFF00093`、`0x005000B3` 的有效标志及立即数，再写/运行小型 testbench。

## 2026-10-19 会话继续：addi_decode 定向验证

- 用户预测：`0x00500093` → addi/立即数 5；`0xFFF00093` → addi/立即数 -1；`0x005000B3` → 非 addi/位段值 5。语义预测正确。
- 用户 testbench：在现有 `fetch_unit` 后接入 `addi_decode`，通过 imem 顺序提供上述编码，monitor 观察指令、立即数、rs1、rd 和有效标志；测试时钟/复位仍用于驱动 PC 地址序列。
- 用户提供仿真结果：10 ns `00500093` → imm=`00000005`, rs1=0, rd=1, valid=1；30 ns `FFF00093` → imm=`FFFFFFFF`, rs1=0, rd=1, valid=1；50 ns `005000B3` → imm=`00000005`, rs1=0, rd=1, valid=0；后续无效数据也被标记为非 addi。
- 评审：与预期一致；负立即数以 32 位二进制 `FFFFFFFF` 表示，十进制有符号解释为 -1。testbench 名仍为 `tb_fetch_unit` 但测试功能已扩展至取指+译码，命名不影响结果。
- 实际测试证据：用户亲自运行并提供仿真日志；日志显示观察值，未使用自动断言。
- 掌握状态：能实现并验证 addi 字段识别、立即数符号扩展及非匹配指令标记。
- 下一步唯一动作：理解寄存器堆在 `addi x1,x0,5` 中如何提供源值并保存结果；先做行为预测，再定接口，不立即写完整执行核心。

## 2026-10-19 会话继续：寄存器堆行为预测

- 用户预测：初始读取 `x0` 得到 0；执行 `addi x1,x0,5` 后读取 `x1` 得到 5；尝试写 `x0` 后读取仍为 0。
- 评审：三项均正确，理解了 `x0` 常零语义及写入忽略规则。
- 掌握状态：能独立预测最小 addi 数据通路中的源寄存器读取和目标寄存器写回结果。
- 用户代码归属：尚未实现寄存器堆。
- 实际测试证据：尚无寄存器堆 RTL 或仿真证据。
- 下一步：设计寄存器堆接口，明确同步写、组合读、双读口和 x0 特殊处理。

## 2026-10-19 会话继续：regfile 首版实现评审

- 用户提交 `regfile`：定义时钟、低有效复位、写端口、双读端口和 32×32 位寄存器数组；两个读口对地址 0 强制输出零，否则组合读取数组。
- 用户额外实现了同步写逻辑。
- 正确部分：端口结构、双读口、组合读取、`x0` 读出恒零的外部行为基本正确。
- 待修正问题：复位只清除 `reg_file[0]`，`x1` 到 `x31` 复位后可能保持 X；写逻辑没有阻止 `wr_addr_i==0`，可能修改内部 `reg_file[0]`，虽然读口旁路仍返回零。
- 教学调整：继续进入寄存器堆定向测试，同时让用户修正复位初始化和 x0 写保护。
- 用户代码归属：`rebuild/rtl/regfile.v` 首版由用户提交，尚未确认文件落盘或仿真。
- 实际测试证据：无。
- 下一步：修正写逻辑后，测试复位、写 x1、读 x1、尝试写 x0、读取 x0 和双读口。

## 2026-10-19 会话继续：regfile 实现与仿真完成

- 用户修正并提交 `regfile.v`：复位循环清零 `reg_file[1]` 到 `reg_file[31]`；同步写入增加 `wr_addr_i != 0` 保护；两个组合读口对地址 0 返回零。
- 用户提交 `tb_regfile`：测试复位、写 `x1=5`、尝试写 `x0=123`、双读口读取。
- 用户提供日志：复位后读口为 0；写入后 `rs2_addr_i=1` 时读到 5；`rs1_addr_i=0` 始终读到 0；写 x0 未改变可见结果。
- 评审：功能结果符合预期，用户已亲自完成寄存器堆基本验证。复位从 1 到 31 清零是可接受的，因为 x0 读口强制为零且写入被禁止；后续可将 `reg_file[0]` 也显式清零以保持内部不变量。
- 测试平台注意：在 50 ns 和 70 ns 恰逢 `posedge clk` 改变输入，存在事件调度竞争；本次日志结果正确，但后续 testbench 应避开上升沿驱动写信号。
- 掌握状态：能独立实现并验证同步写、组合双读、x0 特殊规则。
- 下一主题：把 `rs1_data_o` 与符号扩展立即数送入加法器，形成 `addi` 执行/写回控制。


## 2026-10-19：addi_execute 首版评审与验证任务

- 用户预测：有效输入 0+5、rd=1 时写使能/地址/数据为 1/1/5；无效输入时为 0/0/0，均正确。
- 用户代码：addi_execute 采用完整 if/else 组合块，有效时输出 rs1_data_i+imm_i 和 rd_addr_i，无效时关闭写入并清零其余输出；端口名称变化不影响功能。代码评审通过，未实际编译/仿真。
- 硬件说明：组合加法器和输出选择逻辑；输出为 32 位时保留低 32 位，符号扩展的负数可直接参与补码加法；模块不需要时钟或复位，真正的状态写入仍在 regfile 上升沿。
- 下一练习：用户自行写 tb_addi_execute，观察有效正数 0+5=5、5+FFFFFFFF=4、FFFFFFFF+1=0，以及无效输入时三项输出均为零。待用户提交日志后再连接数据通路。
- 文件归属核查：本次磁盘枚举仅发现 imem.v/pc_reg.v 及对应 TB；其余模块当前证据来自聊天提交和用户运行日志，不记为已确认在本工作区落盘。助手未补写用户核心文件。
- 校正历史证据边界：regfile 用户日志只观察到 x0 恒零和最终 x1=5；没有直接观察复位后的 x1，且写激励与上升沿重合，所以不能将其写成已完成无竞争的全部复位/写入验证。复位清零全部可写寄存器是我们的教学选择。
- 已读教学技能 fpga-verilog-understand-reimplement 及 learning-verilog-guide；当前为用户提交模块评审，不读取原项目或归档答案。

## 2026-10-19：addi_execute 定向仿真完成

- 用户提供实际仿真日志，覆盖四组输入：`0+5=5`、`5+FFFFFFFF=4`、`FFFFFFFF+1=0`、无效 `is_addi_i=0`。
- 结果全部符合预期：有效输入产生 `wr_en_o=1`、原样传递目标寄存器地址、输出低 32 位加法结果；无效输入输出 `0/0/0`。
- 用户额外将无效测试的 `rd_addr_i` 设为 4，验证了执行模块在无效时会屏蔽目标地址并输出 0。
- 实际测试证据：用户亲自运行并提供日志；本助手未重新运行仿真。
- 掌握状态：能独立实现并验证组合 `addi` 执行单元，包括补码负数和 32 位模加法回绕。
- 下一小主题：连接 `fetch_unit → addi_decode → regfile → addi_execute → regfile`，完成最小 `addi` 写回闭环；先明确组合路径和上升沿写回时刻，再由用户实现顶层连接。


## 2026-10-19：addi_core 首版连接评审

- 用户提交：实例化 fetch_unit、addi_decode、regfile、addi_execute；将 addi_decode 的 rs1_o/rd_o 改名为 rs1_addr_o/rd_addr_o（用户说明）。端口重命名和写回主路径连接合理。
- 问题 1：imm_o、rs1_addr_o、rd_addr_o、is_addi_o、rs1_data_o 未声明；默认允许隐式 net 的 Verilog 工具可能产生 1 位 wire，导致 32 位立即数/数据或 5 位地址截断，严格设置会报错。需要明确声明位宽。
- 问题 2：rs2_addr_o 没有驱动，未固定为 5'd1；无法通过第二读口观察 x1。
- 问题 3：assign x1_o = rs1_data_o 实际输出当前源寄存器值；现有程序 rs1=0 时始终观察到 0。应将第二读口地址接 5'd1，第二读口数据直接接 x1_o，并删除该 assign，避免多驱动。
- 已讲授：命名端口连接 .子模块端口(本层信号)；父层连线不会因为子模块端口为 32 位就自动成为 32 位。
- 下一步练习：用户完成上述局部修正，可同时准备 tb_addi_core；沿用 clk 初值 0、每 10 ns 翻转、25 ns 释放复位，观察 x1 在 10/30/50/70 ns 稳定后的 0/5/FFFFFFFF/FFFFFFFF。说明 monitor 显示上升沿后下一条指令的组合写回信号，不能把它当作该沿刚提交的结果。
- 代码归属：所有核心实现由用户提交；助手仅给局部修正建议，没有代写顶层。磁盘仍仅发现 PC/imem 及两份对应 TB，其他模块依据聊天评审，未编译/仿真 addi_core。

## 2026-10-19：addi_core 首次写回闭环日志核对

- 用户提供顶层仿真日志：10 ns PC=0、指令00500093、组合写数据5、x1=0；30 ns PC=4、指令FFF00093、组合写数据FFFFFFFF、x1=5；50 ns PC=8、非addi、wr_en=0、x1=FFFFFFFF；70/90 ns 写使能保持0，x1保持FFFFFFFF。
- 评审：日志与原程序预期一致，第一条 addi 已通过 PC→取指→译码→读寄存器→加法→上升沿写回的路径。上升沿后组合写数据属于新 PC 对应指令，x1反映刚完成的写入。
- 证据边界：用户自行运行并提供 monitor 日志，助手未重跑；修正后源码尚未贴出或本地核对。当前两条有效指令均读取x0，尚未覆盖读取前一条写回的非零源值；不据此宣称完整ISA验证。
- 用户核心 RTL 与 TB 成果归用户；本步助手仅评审日志和维护记录。
- 下一主题：读取刚写回的寄存器。建议仅修改用户 imem 的四项程序为00500093（addi x1,x0,5）、00308093（addi x1,x1,3）、FFF08093（addi x1,x1,-1）、005000B3（非addi，继续忽略）。默认零保持原约定。
- 已说明：rs1地址为1时会从regfile读出x1当前保存值；组合运算结果等到下一上升沿才写入，regfile将反馈路径隔开，不增加流水线级。
- 待完成练习：用户预测30/50/70/90 ns上升沿后x1，再用原tb_addi_core运行并核对，允许同一回复提交预测与日志。助手核对用预期为5/8/7/7，但暂未将其作为用户预测证据。

## 2026-10-19：连续 addi 读取前一结果验证完成

- 用户预测：30/50/70/90 ns 的 x1 为 5/8/7/7，全部正确。
- 用户实际日志：30 ns PC=4、instr=00308093、wr_data=8、x1=5；50 ns PC=8、instr=FFF08093、wr_data=7、x1=8；70/90 ns 非 addi，wr_en=0，x1保持7。
- 评审：当前单周期教学路径的顺序写回、非零源寄存器组合读取、负立即数运算与非支持指令写入屏蔽均在该短程序中符合预期。此处不是流水线相关处理测试，不宣称完整 RV32I 合规。
- 证据归属：用户独立预测、修改程序并自行运行仿真，提供 monitor 日志；助手未重跑，无自动断言或完整回归记录。
- 参考资料核对：中文手册第2.2节（指令格式）、第2.4节（整数计算）；Reference card 的 ADD/SUB/ADDI 行。ADD opcode=0110011/funct3=000/funct7=0000000，SUB 的 funct7=0100000。
- 下一主题：ADD 从两个寄存器获取操作数，ADDI 从寄存器和立即数获取操作数；新增 rs2 编号位段为 instr[24:20]，funct7 为 instr[31:25]。
- 下一步唯一练习：保留现有 addi_decode 行为，用户自行新增 5 位 rs2_addr_o、1 位 is_add_o，提取 rs2 并用 opcode/funct3/funct7 三项识别 ADD。先评审此局部修改，再调整执行和顶层；模块名暂时保留。
- 后续连接注意（尚未实施）：regfile 第二读口当前固定读 x1 用于观察，接 ADD 时需改为读取 rs2，届时一并调整观察方式。


## 会话收尾（2026-10-19）

- 用户明确要求今天结束；未继续布置新任务或补写ADD答案。
- 最新掌握证据、原回答摘要、关键日志、代码归属/磁盘差异、已纠正问题和下一步已整理到文件顶部。
- 本日用户完成的最重要里程碑：亲写最小ADDI取指/译码/执行/寄存器写回闭环，并独立预测和验证连续程序x1=5→8→7→7。
- 未完成原题保留：在现有addi_decode增加rs2_addr_o[4:0]和is_add_o，提取rs2并联合opcode/funct3/funct7识别ADD；用户尚未提交，状态“已解释待练习”。
- 下次直接续此局部练习，不再问PC复盘或重做ADDI。评审后再推进译码验证、执行和第二读口连接。
- 今日节奏反馈永久写入AGENTS.md、LEARNING_PLAN.md和LEARNING_SESSION_PROMPT.md，无需用户每次提醒。
- 文件改动仅为四份学习入口文档；核心RTL、用户TB、原项目与历史归档没有改写。收尾未运行仿真或Python。














































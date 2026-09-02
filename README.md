# cpu31

一个基于 Vivado 的 **31 条指令单周期 MIPS CPU**。

仓库包含完整的 RTL 源码、指令/数据存储器模型、仿真与实现脚本、板级顶层与约束，覆盖
**前仿真 → 综合后时序仿真 → 实现后时序分析 → 下板** 四个环节。
本 README 面向希望复刻或二次开发本工程的读者。

## 目录

- [1. 仓库文件结构](#1-仓库文件结构)
- [2. 项目简介](#2-项目简介)
- [3. 环境要求](#3-环境要求)
- [4. 快速开始](#4-快速开始)
  - [4.1 前仿真（功能验证）](#41-前仿真功能验证)
  - [4.2 综合后时序仿真](#42-综合后时序仿真)
  - [4.3 实现后时序与网表导出](#43-实现后时序与网表导出)
  - [4.4 生成下板 bitstream](#44-生成下板-bitstream)
  - [4.5 与黄金模型比对](#45-与黄金模型比对)
  - [4.6 更换测试程序](#46-更换测试程序)
- [5. 设计结构](#5-设计结构)
  - [5.1 为什么指令存储器要用 IP 核](#51-为什么指令存储器要用-ip-核)
  - [5.2 两个版本的数据存储器](#52-两个版本的数据存储器)
  - [5.3 下板的慢速步进](#53-下板的慢速步进)
- [6. 指令集（31 条）](#6-指令集31-条)
  - [6.1 R 型（`opcode = 0x00`，17 条）](#61-r-型opcode--0x0017-条)
  - [6.2 I 型（12 条）](#62-i-型12-条)
  - [6.3 J 型（2 条）](#63-j-型2-条)
- [7. 地址映射](#7-地址映射)
- [8. 复刻前需要修改的硬编码路径](#8-复刻前需要修改的硬编码路径)
- [9. 时序结果](#9-时序结果)
- [10. 校验过的状态](#10-校验过的状态)
- [11. 许可证](#11-许可证)

---

## 1. 仓库文件结构

下面列出的是**实际会提交到仓库的文件**。Vivado 运行产物、IP 核生成内容、课程 PDF
与本机日志均已被 `.gitignore` 忽略，不在其中。

```text
cpu31/
├── .gitattributes
├── .gitignore
├── LICENSE                                   # MIT
├── README.md
├── timing_report.txt                         # 20 ns 约束下的实现后时序报告
│
├── coe/                                      # 测试程序（MIPS 机器码，十六进制）
│   │                                         # 命名规则：<指令>_<难度>.coe
│   ├── add_2.coe      addi_1.coe     addiu.coe       addu_2.coe
│   ├── and_2.coe      andi_2.coe     beq_3.coe       bne_3.coe
│   ├── booth.coe      final.coe      j_3.coe         jal_3.coe
│   ├── jr_4.coe       lui_1.coe      lwsw_2.coe      lwsw2_2.coe
│   ├── nor_2.coe      or_2.coe       ori_2.coe       sll_2.coe
│   ├── sllv_2.coe     slt_2.coe      slti_2.coe      sltiu_2.coe
│   ├── sltu_2.coe     sra_2.coe      srav_2.coe      srl_2.coe
│   ├── srlv_2.coe     sub_2.coe      subu_2.coe      test1.coe
│   ├── xor_2.coe      xori_2.coe
│   │                                         # 31 条指令各有独立用例；
│   │                                         # final.coe / booth.coe / test1.coe 为综合程序
│
├── cpu31-test.srcs/
│   ├── constrs_1/new/                        # 约束文件
│   │   ├── icf.xdc                           # 板级引脚 + 100 MHz 时钟（下板用）
│   │   ├── board_test.xdc                    # 与 icf.xdc 同内容，带注释版（下板用）
│   │   ├── postsim.xdc                       # 后仿真/时序分析专用（20 ns，仅时钟约束）
│   │   └── postsim_xdc.xdc                   # postsim.xdc 的精简副本
│   │
│   ├── sim_1/new/                            # 仿真 testbench
│   │   ├── _246tb_ex9_tb.v                   # 前仿真 tb，例化 sccomp_dataflow
│   │   └── postsim_tb.v                      # 后仿真 tb，例化 postsim_top
│   │
│   └── sources_1/
│       ├── new/                              # RTL 源码
│       │   ├── scpc.v                        # PC 寄存器（复位值 0x00400000）
│       │   ├── regfile.v                     # 32×32 通用寄存器堆（$0 恒为 0）
│       │   ├── sccontroller.v                # 控制器（组合逻辑译码）
│       │   ├── scalu.v                       # ALU（14 种运算）
│       │   ├── sccpu.v                       # CPU 核心：PC + 寄存器堆 + 控制器 + ALU
│       │   ├── scdatamem.v                   # 数据存储器（通用版，支持 IO 开关映射）
│       │   ├── scdatamem_postsim.v           # 数据存储器（后仿真版，容量小、便于观测）
│       │   ├── scinstmem.v                   # 指令存储器 wrapper（仿真）
│       │   ├── scinstmem_board.v             # 指令存储器 wrapper（下板）
│       │   ├── sccomp_dataflow.v             # 前仿真顶层，输出 pc / inst
│       │   ├── postsim_top.v                 # 后仿真顶层，输出 pc / inst / mem0 / mem1
│       │   ├── cpu31_board.v                 # 下板逻辑顶层：CPU + 慢速步进 + 显示数据
│       │   ├── test.v                        # 板级顶层：cpu31_board + seg7x16
│       │   ├── seg7x16.v                     # 七段数码管动态扫描驱动
│       │   ├── mips_31_mars_simulate.mem     # 仿真用程序镜像
│       │   └── mips_31_mars_board_switch.mem # 下板用程序镜像
│       │
│       └── ip/imem/                          # 指令存储器 IP（Distributed Memory Generator）
│           ├── imem.xci                      # IP 配置（唯一权威来源）
│           ├── imem.mif                      # ROM 初始化镜像（二进制，32 位/行）
│           ├── imem_stub.v                   # 黑盒 wrapper（下板脚本读取）
│           ├── imem.dcp                      # IP 的 OOC 综合 checkpoint
│           └── sim/imem.v                    # IP 的行为级仿真模型（第三方仿真器可用）
│
└── verify/                                   # 自动化验证脚本与工具
    ├── coe/                                  # 官方 MARS 测程原始 coe（.mem / .mif 的来源）
    │   ├── mips_31_mars_simulate.coe
    │   └── mips_31_mars_board_switch.coe
    ├── run_vivado_behav_xsim.tcl             # 前仿真（自建临时工程，不需要 .xpr）
    ├── run_vivado_postsynth_xsim.tcl         # 综合后时序仿真
    ├── run_vivado_postsim_new.tcl            # 实现后导出网表 + SDF + 时序报告
    ├── run_vivado_postsim_impl_20ns.tcl      # 20 ns 约束下的实现后时序分析
    ├── run_board_bitstream_direct.tcl        # 下板 bitstream 生成（自建工程，不需要 .xpr）
    ├── reference_mips31.py                   # 纯 Python MIPS 指令集参考模型（黄金模型）
    ├── normalize_frontsim_result.py          # 前仿真结果归一化，便于与黄金模型逐行比对
    ├── convert_coe_to_mif.ps1                # coe → mif 转换
    ├── test_case_list.txt                    # 31 条指令对应的用例清单
    └── mars_usage_notes.txt                  # 用 MARS 生成测程的命令行说明
```

---

## 2. 项目简介

单周期 MIPS CPU，一个时钟周期执行完一条指令，不流水。

| 项目         | 取值                                               |
| ------------ | -------------------------------------------------- |
| 目标器件     | Artix-7 `xc7a100tcsg324-1`                         |
| 开发工具     | Vivado 2016.2（其他版本一般可用，未做全面验证）    |
| 指令条数     | 31 条                                              |
| 数据通路宽度 | 32 位                                              |
| 寄存器堆     | 32 × 32 bit，`$0` 硬件恒零                         |
| 指令存储器   | 2048 × 32 bit ROM（Vivado IP `imem`）              |
| 数据存储器   | 1024 × 32 bit 分布式 RAM                           |
| PC 复位值    | `0x00400000`                                       |
| 下板时钟     | 100 MHz，经 5×10⁷ 分频后 CPU 每 0.5 s 执行一条指令 |

设计上有两条并行的验证线：

- **仿真线**：功能正确 → 综合后时序仿真一致 → 实现后时序收敛。
- **下板线**：在 FPGA 上稳定运行，用七段数码管观察 `inst` 逐条变化。

---

## 3. 环境要求

- **Vivado**（脚本在 2016.2 上验证通过），需要命令行可用：
  ```bash
  vivado -mode batch -source <script>.tcl -notrace
  ```
- **Python 3.8+**（仅用于黄金模型与结果归一化，无第三方依赖）。
- **PowerShell 5+**（仅 `convert_coe_to_mif.ps1` 需要；Windows 自带）。
- **MARS**（可选，仅当你想自己从 `.asm` 生成测程时需要，见 `verify/mars_usage_notes.txt`）。

> 本仓库**不包含** `cpu31-test.xpr`。Vivado 工程文件内含本机绝对路径，
> 不做版本管理；所有流程都通过 `verify/` 下的 TCL 脚本从源码现场重建工程。

---

## 4. 快速开始

所有命令在仓库根目录下执行。

### 4.1 前仿真（功能验证）

```bash
vivado -mode batch -source verify/run_vivado_behav_xsim.tcl -notrace
```

- 顶层：`sccomp_dataflow`，tb：`_246tb_ex9_tb`
- 时钟周期 10 ns，仿真时长 30 µs
- 每个时钟沿打印 `pc`、`instr`、`regfile0..31`，写入 tb 中 `$fopen` 指定的文件

### 4.2 综合后时序仿真

```bash
vivado -mode batch -source verify/run_vivado_postsynth_xsim.tcl -notrace
```

- 顶层：`postsim_top`，tb：`postsim_tb`
- 约束：`cpu31-test.srcs/constrs_1/new/postsim.xdc`（20 ns）
- 先跑 `synth_1`，再以 `-mode post-synthesis -type timing` 启动 XSim，带门延迟与线延迟

### 4.3 实现后时序与网表导出

```bash
vivado -mode batch -source verify/run_vivado_postsim_new.tcl -notrace
```

产物写在仓库根目录：

- `postsim_top_new.dcp` — 布线后 checkpoint
- `postsim_timesim_new.v` / `postsim_timesim_new.sdf` — 带时序反标的网表
- `postsim_impl_timing_summary_new.rpt` — 时序报告

只关心 20 ns 下的时序收敛，也可以直接跑：

```bash
vivado -mode batch -source verify/run_vivado_postsim_impl_20ns.tcl -notrace
# 报告输出到 tmp/postsim_impl_timing_summary_20ns.rpt
```

### 4.4 生成下板 bitstream

```bash
vivado -mode batch -source verify/run_board_bitstream_direct.tcl -notrace
```

- 顶层：`test`，约束：`cpu31-test.srcs/constrs_1/new/icf.xdc`
- 产物：`cpu31-test.runs/board_direct/test.bit`
- 之后用 Vivado Hardware Manager 下载到板子即可

> **注意**：脚本第 27 行默认读取 `cpu31-test.runs/imem_synth_1/imem.dcp`（本机 IP OOC
> 综合产物，未入库）。复刻时请改成仓库内已提供的
> `cpu31-test.srcs/sources_1/ip/imem/imem.dcp`，或自己先跑一次 IP OOC 综合。

### 4.5 与黄金模型比对

`verify/reference_mips31.py` 是一个纯 Python 的 MIPS 解释器，用 `imem.mif` 作为
ROM 镜像，逐周期打印 `pc / instr / regfile0..31`。

```bash
python verify/reference_mips31.py          # 生成 verify/reference_result_simulate.txt
python verify/normalize_frontsim_result.py # 把前仿真输出归一化成同一格式
diff verify/normalized_frontsim_result.txt verify/reference_result_simulate.txt
```

两者格式一致即可用 `diff` 直接比对。归一化脚本会去掉仿真开头两个无效周期、
对 PC 做固定偏移修正，并在检测到 CPU 进入稳态循环时截断输出。

> 这两个 `*.txt` 是生成物，已加入 `.gitignore`；需要时按上面的命令重建。

### 4.6 更换测试程序

```powershell
powershell -File verify/convert_coe_to_mif.ps1 `
  -CoePath coe\booth.coe `
  -MifPath cpu31-test.srcs\sources_1\ip\imem\imem.mif
```

然后**重新生成 `imem` IP**（在 Vivado 中把 coefficient file 指向同一个 coe），
否则 IP 内部固化的 ROM 内容与 `imem.mif` 会不一致，黄金模型比对将失去意义。

> `imem.xci` 里记录的 coefficient file 是相对路径 `../../../../../coe/booth.coe`，
> 指向仓库之外的目录。换机器后请务必在 Vivado 中重新指定为 `coe/` 下的某个文件。

---

## 5. 设计结构

```
                 ┌──────────┐
      clk_in ───►│  scpc    │──► pc ──────┐
      reset  ───►│ (PC reg) │            │
      clk_en ───►└──────────┘            │
                                          ▼
                                   ┌────────────┐
                                   │  scinstmem │  (imem IP, ROM)
                                   └────────────┘
                                          │ inst
                                          ▼
      ┌─────────────┐  控制信号   ┌──────────────┐
      │ sccontroller│◄───────────│    sccpu     │
      └─────────────┘            │  (数据通路)   │
                                 └──────────────┘
                                    │      │    ▲
                        ┌───────────┘      │    │
                        ▼                  ▼    │
                 ┌───────────┐      ┌───────────────┐
                 │  regfile  │◄────►│    scalu      │
                 │ (32×32)   │      │  (14 种运算)  │
                 └───────────┘      └───────────────┘
                                          │ alu_result = 访存地址
                                          ▼
                                   ┌────────────┐
                                   │ scdatamem  │  (分布式 RAM + IO 开关)
                                   └────────────┘
```

| 层   | 文件                                             | 职责                                               |
| ---- | ------------------------------------------------ | -------------------------------------------------- |
| 核心 | `sccpu.v`                                        | 把 PC、寄存器堆、控制器、ALU 串成数据通路          |
| 控制 | `sccontroller.v`                                 | 纯组合逻辑译码，输出 8 组控制信号                  |
| 运算 | `scalu.v`                                        | 算术/逻辑/移位/比较，同时给出 `eq_flag` 供分支判断 |
| 状态 | `scpc.v` / `regfile.v`                           | PC 与通用寄存器，都带 `clk_en` 便于下板步进        |
| 存储 | `scinstmem*.v` / `scdatamem*.v`                  | 指令 ROM 与数据 RAM 的 wrapper                     |
| 顶层 | `sccomp_dataflow.v` / `postsim_top.v` / `test.v` | 分别服务前仿真、后仿真、下板                       |

### 5.1 为什么指令存储器要用 IP 核

后仿真要求综合后网表参与仿真，下板也要求指令存储器走 IP 方式。因此把
`imem` 做成 Vivado `Distributed Memory Generator`（ROM，2048×32），
由 `scinstmem.v` / `scinstmem_board.v` 包一层地址换算。

### 5.2 两个版本的数据存储器

| 文件                  | 用途         | 特点                                                            |
| --------------------- | ------------ | --------------------------------------------------------------- |
| `scdatamem.v`         | 前仿真、下板 | 深度 1024，支持把某个地址映射成拨码开关输入（`IO_SWITCH_ADDR`） |
| `scdatamem_postsim.v` | 后仿真       | 深度 64，关掉 IO 映射，输出 `mem0` / `mem1` 便于观测            |

### 5.3 下板的慢速步进

`cpu31_board.v` 里有一个分频计数器 `step_counter`，每数满
`CPU_STEP_DIVISOR = 50_000_000` 个 100 MHz 周期，就产生一个周期的
`cpu_clk_en`。效果是 CPU 每 0.5 秒执行一条指令，人眼可以清楚看到数码管变化。

这款设计**不改变 CPU 逻辑**，只是在时钟使能上做门控，也不需要额外的按键或引脚。

数码管显示的是 `inst`（当前指令）而不是 `pc`，更适合直接检查：

- 程序是否切到了下一条指令
- 分支与跳转是否生效
- 指令流是否按预期变化

---

## 6. 指令集（31 条）

### 6.1 R 型（`opcode = 0x00`，17 条）

| 助记符 | funct  | 说明               | 助记符 | funct  | 说明               |
| ------ | ------ | ------------------ | ------ | ------ | ------------------ |
| `sll`  | `0x00` | 逻辑左移（立即数） | `slt`  | `0x2A` | 有符号小于置 1     |
| `srl`  | `0x02` | 逻辑右移（立即数） | `sltu` | `0x2B` | 无符号小于置 1     |
| `sra`  | `0x03` | 算术右移（立即数） | `add`  | `0x20` | 加法（溢出不检查） |
| `sllv` | `0x04` | 逻辑左移（寄存器） | `addu` | `0x21` | 无符号加法         |
| `srlv` | `0x06` | 逻辑右移（寄存器） | `sub`  | `0x22` | 减法               |
| `srav` | `0x07` | 算术右移（寄存器） | `subu` | `0x23` | 无符号减法         |
| `jr`   | `0x08` | 跳转到 `$rs`       | `and`  | `0x24` | 按位与             |
|        |        |                    | `or`   | `0x25` | 按位或             |
|        |        |                    | `xor`  | `0x26` | 按位异或           |
|        |        |                    | `nor`  | `0x27` | 按位或非           |

### 6.2 I 型（12 条）

| 助记符  | opcode | 说明                     |
| ------- | ------ | ------------------------ |
| `beq`   | `0x04` | 相等则分支               |
| `bne`   | `0x05` | 不等则分支               |
| `addi`  | `0x08` | 立即数加法（符号扩展）   |
| `addiu` | `0x09` | 立即数无符号加法         |
| `slti`  | `0x0A` | 小于立即数置 1（有符号） |
| `sltiu` | `0x0B` | 小于立即数置 1（无符号） |
| `andi`  | `0x0C` | 立即数按位与（零扩展）   |
| `ori`   | `0x0D` | 立即数按位或（零扩展）   |
| `xori`  | `0x0E` | 立即数按位异或（零扩展） |
| `lui`   | `0x0F` | 立即数装载到高 16 位     |
| `lw`    | `0x23` | 取字                     |
| `sw`    | `0x2B` | 存字                     |

### 6.3 J 型（2 条）

| 助记符 | opcode | 说明                             |
| ------ | ------ | -------------------------------- |
| `j`    | `0x02` | 直接跳转                         |
| `jal`  | `0x03` | 跳转并链接（返回地址写入 `$ra`） |

写回来源由 `wb_sel` 选择：ALU 结果 / 存储器读出 / `pc+4`（`jal`）/ `lui` 立即数。
写回目的由 `reg_dst_sel` 选择：`rt` / `rd` / `$ra`。

---

## 7. 地址映射

| 区域            | 基地址       | 说明                                                  |
| --------------- | ------------ | ----------------------------------------------------- |
| 指令 ROM        | `0x00400000` | 2048 × 32 bit，地址取 `pc[12:2]`                      |
| 数据 RAM        | `0x10010000` | 1024 × 32 bit（后仿真版 64 × 32 bit）                 |
| IO 开关（下板） | `0x10010010` | 读该地址返回 `IO_SWITCH_DATA`（默认 `0x00008000`）    |
| IO 开关（仿真） | `0x10020000` | `scdatamem` 默认 `IO_SWITCH_ADDR = BASE + 0x00010000` |

仿真 ROM 与下板 ROM 不是同一个镜像：

| 场景            | 文件                                                  |
| --------------- | ----------------------------------------------------- |
| 前仿真 / 后仿真 | `mips_31_mars_simulate.mem`                           |
| 下板            | `mips_31_mars_board_switch.mem` 与 `ip/imem/imem.mif` |

---

## 8. 复刻前需要修改的硬编码路径

以下位置写死了原作者机器上的绝对路径，换机器后**必须先改**：

| 文件                                         | 位置               | 当前值                                                         |
| -------------------------------------------- | ------------------ | -------------------------------------------------------------- |
| `cpu31-test.srcs/sim_1/new/_246tb_ex9_tb.v`  | `$fopen`           | `D:/computer_composition/cpu31-test/tmp/_246tb_ex9_result.txt` |
| `cpu31-test.srcs/sim_1/new/postsim_tb.v`     | `$fopen`           | `D:/computer_composition/cpu31-test/tmp/postsim_result.txt`    |
| `verify/normalize_frontsim_result.py`        | `src`              | `cpu31-test.sim/sim_1/behav/_246tb_ex9_result.txt`             |
| `verify/run_board_bitstream_direct.tcl`      | `read_checkpoint`  | `cpu31-test.runs/imem_synth_1/imem.dcp`                        |
| `cpu31-test.srcs/sources_1/ip/imem/imem.xci` | `coefficient_file` | `../../../../../coe/booth.coe`                                 |

前仿真结果文件的实际落点由 tb 里的 `$fopen` 决定；`normalize_frontsim_result.py`
的 `src` 必须与它保持一致（改任意一处即可）。

---

## 9. 时序结果

`timing_report.txt` 是在 `xc7a100tcsg324-1`、`postsim_top` 顶层、20 ns 时钟周期
（50 MHz）下的实现后时序报告摘要：

| 指标 | 数值                                             |
| ---- | ------------------------------------------------ |
| WNS  | `6.477 ns`                                       |
| TNS  | `0.000 ns`                                       |
| WHS  | `0.353 ns`                                       |
| THS  | `0.000 ns`                                       |
| WPWS | `8.750 ns`                                       |
| 结论 | `All user specified timing constraints are met.` |

裕量充足，20 ns 不是极限；想摸底可自行调紧 `postsim.xdc` 里的 `create_clock` 周期重跑。

---

## 10. 校验过的状态

- 前仿真通过（31 条指令逐条用例 + 综合程序）
- 综合后时序仿真通过与黄金模型一致
- 20 ns 约束下实现后时序收敛
- 下板 bitstream 生成成功，数码管可观察到 `inst` 变化

---

## 11. 许可证

本仓库的**原创代码**（RTL 源码、验证脚本、文档）采用 **MIT License**，详见 `LICENSE`。

需要注意的两点：

1. `seg7x16.v`（数码管驱动）和 `icf.xdc`（板级引脚约束）由课程提供方给定，
   按要求原样使用，**不属于本仓库的 MIT 授权范围**，请勿将其视作可自由再发布的作品。
2. `coe/` 与 `verify/coe/` 下的测试程序、以及 `cpu31-test.srcs/docs/` 中的课程 PDF
   同样来自课程资料。PDF 未被纳入版本管理；测试程序仅作为工程输入随源码一并保留，
   如需对外再发布请先取得课程提供方许可。

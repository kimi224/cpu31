# cpu31

这是一个基于 Vivado 的 31 条指令单周期 MIPS CPU 实验工程，包含前仿真、后仿真、时序分析和下板验证的完整流程。

项目当前的实现目标有两条线：

1. 仿真线：保证功能正确、前后仿真一致、时序分析通过。
2. 下板线：在 FPGA 上稳定运行，并通过七段数码管观察 `inst` 的变化。

## 工程结构

建议将项目文件按下面结构放置：

```text
cpu31/
  cpu31-test.xpr
  cpu31-test.srcs/
    sources_1/
      new/
        scpc.v
        regfile.v
        sccontroller.v
        scalu.v
        scinstmem.v
        scinstmem_board.v
        scdatamem.v
        scdatamem_postsim.v
        sccpu.v
        sccomp_dataflow.v
        cpu31_board.v
        postsim_top.v
        test.v
        seg7x16.v
        mips_31_mars_simulate.mem
        mips_31_mars_board_switch.mem
      ip/
        imem/
          imem.xci
          imem.mif
          imem.dcp
          imem_stub.v
          ...
    constrs_1/
      new/
        icf.xdc
        postsim_xdc.xdc
        board_test.xdc
  verify/
    run_board_bitstream_direct.tcl
    run_board_bitstream.tcl
    ...
```

## 设计分层

### 1. CPU 核心

核心逻辑在以下模块中：

- `scpc.v`：PC 寄存器
- `regfile.v`：32 个通用寄存器
- `sccontroller.v`：控制器
- `scalu.v`：ALU
- `sccpu.v`：把控制器、寄存器堆、ALU、PC 串起来

这部分是单周期 CPU 的主体，前仿真和后仿真都共用。

### 2. 指令存储器

指令存储器使用 Vivado IP 核 `imem` 实现，原因是：

- 后仿真要求综合后网表参与仿真
- 下板时也要求指令存储器走 IP 核方式

对应文件：

- `cpu31-test.srcs/sources_1/ip/imem/imem.xci`
- `cpu31-test.srcs/sources_1/ip/imem/imem.mif`
- `cpu31-test.srcs/sources_1/ip/imem/imem.dcp`
- `cpu31-test.srcs/sources_1/ip/imem/imem_stub.v`

其中 `imem.mif` 是由老师给的 `mips_31_mars_board_switch.coe` 转换得到的初始化文件。

### 3. 数据存储器

数据存储器分成两个版本：

- `scdatamem.v`：通用版本，用于正常仿真和普通测试
- `scdatamem_postsim.v`：后仿真版本，适配后仿真观察

### 4. 仿真顶层

- `sccomp_dataflow.v`：前仿真顶层，输出 `pc` 和 `inst`
- `postsim_top.v`：后仿真顶层，输出 `pc`、`inst`、`mem0`、`mem1`

### 5. 下板顶层

下板相关核心文件：

- `cpu31_board.v`
- `test.v`
- `seg7x16.v`
- `icf.xdc`

其中：

- `test.v` 是板级顶层
- `cpu31_board.v` 负责把 CPU、指令存储器、数据存储器和数码管显示串起来
- `seg7x16.v` 是老师给的七段数码管模块，按要求原样使用
- `icf.xdc` 是老师给的板级约束文件，按要求使用

## 实现方式

### 前仿真

前仿真使用的是仿真程序 ROM：

- `mips_31_mars_simulate.mem`

验证目标是：

- 指令译码正确
- 寄存器写回正确
- 分支、跳转、访存行为正确

### 后仿真

后仿真必须先综合，再基于综合后的网表做时序仿真。

这里的关键点是：

- 指令存储器必须使用 IP 核
- `postsim_top.v` 保留 `inst`、`pc`、`mem0`、`mem1`
- 后仿真时关注门延迟和线延迟下的功能一致性

### 下板

下板的显示目标是让人眼能观察到 `inst` 变化。

当前实现策略是：

- CPU 主时钟仍接板上 100MHz 时钟
- 在 `cpu31_board.v` 里加入分频/步进使能
- 每隔较长时间放行一次 CPU 执行
- 七段数码管显示当前 `inst`

这样做的好处是：

- 不需要额外改板级引脚
- 不需要新的按键输入
- 即使没有手动单步按钮，也能明显看到指令逐条变化

## 关键实现细节

### 1. 慢速步进

下板时 `cpu31_board.v` 中加入了一个步进使能 `cpu_clk_en`。

它的作用不是改变 CPU 逻辑，而是让 CPU 在板上慢慢执行，便于观察数码管变化。

### 2. 指令显示

数码管显示的是 `inst`，不是 PC。

这样更适合检查：

- 程序是否正确切换到下一条指令
- 分支和跳转是否生效
- 指令流是否按预期变化

### 3. ROM 初始化

下板 ROM 使用的是：

- `mips_31_mars_board_switch.coe`

该文件转成了 `imem.mif`，供 IP 核读取。

注意：

- 仿真 ROM 和下板 ROM 不是同一个文件
- 仿真时若要复测原实验程序，需要切回 `mips_31_mars_simulate.coe`

## Vivado 流程

### 1. 仿真

先跑前仿真，确认 CPU 逻辑正确。

然后跑后仿真，确认综合后时序下仍然正确。

### 2. 时序

时序报告重点看：

- `WNS`
- `WHS`
- 是否有 `All user specified timing constraints are met`

本项目在 20ns 时钟周期下通过。

### 3. 生成 bitstream

下板最终目标是生成：

- `test.bit`

生成成功后，再在 Vivado Hardware Manager 里下载到板子。

## 文件说明

- `cpu31-test.xpr`：Vivado 工程文件
- `srcs/sources_1/new/*.v`：RTL 源码
- `srcs/sources_1/ip/imem/*`：指令存储器 IP 相关文件
- `srcs/constrs_1/new/icf.xdc`：板级约束
- `verify/*.tcl`：自动化验证和 bitstream 生成脚本

## 当前状态

本工程已经完成：

- 前仿真通过
- 后仿真通过
- 时序通过
- 下板 bitstream 生成成功

下板 bitstream 路径：

```text
cpu31-test.runs/board_direct/test.bit
```


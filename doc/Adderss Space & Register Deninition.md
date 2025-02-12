# 🦂 Scorpio-CIM：地址空间与寄存器定义

## 地址空间

Scorpio 芯片的地址位宽共 XX bit，地址空间划分如下：
| Peripherals          | Base Addr | End Addr | Addr Capacity | Addr Bitwidth |
|:---------------------|:---------:|:--------:|:-------------:|:-------------:|
| CIM-NPU (AXI4)       |  0x0_0000 | 0x7_FFFF |               |           19b |
<!-- | D2Ds Ctrl (AXI Lite) |  0x4_0000 | 0x4_xxxx |               |             b | -->

CIM-NPU 的内部地址空间划分如下：
| Modules         | Access   | Base Addr | End Addr | Addr Capacity | Addr Bitwidth |
|:----------------|:--------:|:---------:|:--------:|:-------------:|:-------------:|
| CIM Weight      | WO       | 0b000_0000_0000_0000_0000 (0x0_0000) | 0b000_0000_0001_1111_1111 (0x0_01FF) |   4Kb  |  9b |
| Input Buffer0   | R/W      | 0b001_0000_0000_0000_0000 (0x1_0000) | 0b001_0000_0111_1111_1111 (0x1_07FF) |  16Kb  | 11b |
| Input Buffer1   | R/W      | 0b010_0000_0000_0000_0000 (0x2_0000) | 0b010_0000_0111_1111_1111 (0x2_07FF) |  16Kb  | 11b |
| Input Buffer2   | R/W      | 0b011_0000_0000_0000_0000 (0x3_0000) | 0b011_0000_0111_1111_1111 (0x3_07FF) |  16Kb  | 11b |
| Input Buffer3   | R/W      | 0b100_0000_0000_0000_0000 (0x4_0000) | 0b100_0000_0111_1111_1111 (0x4_07FF) |  16Kb  | 11b |
| Output Buffer   | R/W      | 0b101_0000_0000_0000_0000 (0x5_0000) | 0b101_0000_0011_1111_1111 (0x5_03FF) |   8Kb  | 10b |
| Config Register | R/W      | 0b110_0000_0000_0000_0000 (0x6_0000) | 0b110_0000_0011_1111_1111 (0x6_03FF) |   8Kb  | 10b |
| RSAM Memory     | R/W      | 0b111_0000_0000_0000_0000 (0x7_0000) | 0b111_0000_0111_1111_1111 (0x7_07FF) |  16Kb  | 11b |

<!-- | CIM Bitmask     | WO       | 0b00_0100_0000_0000_0000 (0x0_4000) | 0x0_43FF |  32Kb | 10b | -->

## CIM-NPU 的寄存器定义

### 0x0 - Version (`VERSION`)

| Field         | Access   | Bit Offset | Bit Width | Description |
|:--------------|:--------:|:----------:|:---------:|:------------|
| `ID`          | RO       | 15:0       | 16        | `0xF0`      |
| `TEST`        | R/W      | 31:16      | 16        | Just for register read/write test. |

### 0x8 - Global Control (`GLOB_CTRL_0`)

| Field         | Access   | Bit Offset | Bit Width | Description |
|:--------------|:--------:|:----------:|:---------:|:------------|
| `EXEC_ITER`   | R/W      | 31:0       | 32        | Glocal count of instruction execution. |

### 0x10 - Global Control (`GLOB_CTRL_1`)

| Field         | Access   | Bit Offset | Bit Width | Description |
|:--------------|:--------:|:----------:|:---------:|:------------|
| `START`       | R/W      | 0          | 1         | Write anything to kick-off a Calculation. |
| `COMPLETE`    | RO       | 1          | 1         | Internal complete flag. |

### 0x18 - IBUF Address Loop 0 (`IBUF_ADDR_0`)

| Field         | Access   | Bit Offset | Bit Width | Description |
|:--------------|:--------:|:----------:|:---------:|:------------|
| `BASE_ADDR`   | R/W      | 6:0        | 7         | Base address. |
| `LOOP0_ITER`  | R/W      | 13:7       | 7         | Iteration count of Loop 0. |
| `LOOP0_STEP`  | R/W      | 20:14      | 7         | Iteration step of Loop 0. |

### 0x20 - IBUF Address Loop 1 (`IBUF_ADDR_1`)

| Field         | Access   | Bit Offset | Bit Width | Description |
|:--------------|:--------:|:----------:|:---------:|:------------|
| `LOOP1_ITER`  | R/W      | 6:0        | 7         | Iteration count of Loop 1. |
| `LOOP1_STEP`  | R/W      | 14:7       | 7         | Iteration step of Loop 1. |

### 0x28 - OBUF Address Loop 0 (`OBUF_ADDR_0`)

| Field         | Access   | Bit Offset | Bit Width | Description |
|:--------------|:--------:|:----------:|:---------:|:------------|
| `BASE_ADDR`   | R/W      | 6:0        | 7         | Base address. |
| `LOOP0_ITER`  | R/W      | 13:7       | 7         | Iteration count of Loop 0. |
| `LOOP0_STEP`  | R/W      | 20:14      | 7         | Iteration step of Loop 0. |

### 0x30 - OBUF Address Loop 1 (`OBUF_ADDR_1`)

| Field         | Access   | Bit Offset | Bit Width | Description |
|:--------------|:--------:|:----------:|:---------:|:------------|
| `LOOP1_ITER`  | R/W      | 6:0        | 7         | Iteration count of Loop 1. |
| `LOOP1_STEP`  | R/W      | 14:7       | 7         | Iteration step of Loop 1. |


### 0x38 - CIM Mode Control (`CIMC_MODE`)

| Field          | Access   | Bit Offset | Bit Width | Description |
|:---------------|:--------:|:----------:|:---------:|:------------|
| `BIT_CNT`      | R/W      | 7:0        | 8         | Activation bit count. |
| `STATION_CNT`  | R/W      | 15:8       | 8         | Stationary cycle count. |
| `ALIGNED_EXP`  | R/W      | 23:16      | 8         | Aligned weight exponent. |

### 0x40 - RSAM Mode Control (`RSAM_MODE`)

| Field          | Access   | Bit Offset | Bit Width | Description |
|:---------------|:--------:|:----------:|:---------:|:------------|
| `CONFIG`       | R/W      | 63:0       | 64        | RSAM mode control. |

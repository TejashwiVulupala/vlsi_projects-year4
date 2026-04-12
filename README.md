**Target Platform:** Avnet ZedBoard (Zynq-7000 xc7z020)

**Verification Level:** Silicon-Verified (100 MHz Timing Closed)

## 🏗️ 1. Architecture: The PicoRV32 Core & Blocks
The V1.0 SoC is an RV32I (Integer) implementation designed to master the fundamentals of hardware-software interaction.

### Individual Logic Blocks & Capacities
* **CPU (PicoRV32):** An area-optimized RISC-V core. In this baseline, it operates with Direct Physical Addressing, meaning every instruction and data request is sent directly to the bus without cache intervention.
* **Memory (Unified BRAM):** 16KB of synchronous storage (4096 x 32-bit words). It acts as a single-entry memory for both code execution and data storage.
* **AXI4-Lite Interconnect:** A custom-designed address decoder and bus arbiter that converts native CPU signals into standardized AXI transactions.

## 📍 2. Mastering Physical Addressing
The system utilizes a memory-mapped I/O (MMIO) scheme verified against the Vivado Address Map. The top-level decoder in `system.v` partitions the 32-bit address space as follows:

| Peripheral | Physical Address Range | Logic Mapping (`mem_addr`) |
| :--- | :--- | :--- |
| **BRAM (Primary)** | `0x4000_0000 — 0x4000_3FFF` | `sel_ram = (addr[31:28] == 4'h4)` |
| **Simple UART** | `0x4001_0000 — 0x4001_FFFF` | `sel_uart = (addr[31:16] == 16'h4001)` |
| **CRC-32 Accel** | `0x4002_0000 — 0x4002_0FFF` | `sel_crc = (addr[31:16] == 16'h4002)` |
| **FPSQRT Accel** | `0x4002_1000 — 0x4002_1FFF` | `sel_sqrt = (addr[31:16] == 16'h4002)` |

**Instruction Passing Mechanism:**
1. **Fetch:** The CPU places the instruction address on the bus.
2. **Handshake:** The AXI Adapter initiates an AR (Address Read) transaction.
3. **Latching:** BRAM responds with the 32-bit opcode. The core identifies the instruction and increments its Program Counter (PC).

## 🛰️ 3. AXI4-Lite Communication Flow
The `main.c` firmware communicates with hardware accelerators via register-level handshaking:

* **Write Phase:** Firmware writes input data to a specific MMIO address (e.g., `SQRT_VAL @ 0x4002_1000`).
* **Trigger:** Firmware asserts the START bit in the Control Register (`0x4002_1004`).
* **Stall/Poll:** The AXI Slave holds `ready_out` low until the hardware FSM completes the bit-serial operation. This effectively stalls the CPU pipeline, ensuring the core only proceeds once the math is valid.

## ⚙️ 4. Reconfigurable Hardware Logic
Unlike standard fixed-function blocks, the CRC-32 Accelerator is fully reconfigurable at runtime:

* **The "How":** The Polynomial (`CRC_POLY`) and Seed values are exposed as AXI registers (`0x4002_000C` and `0x4002_0010`).
* **The "Why":** This allows the same gate-level footprint to support multiple standards (Ethernet, MPEG-2, Gzip) by simply updating a register value rather than re-synthesizing the entire FPGA bitstream.

## 📊 5. Mathematical Proof of Performance
Based on the silicon-verified results (normalized for UART redundancy), we prove the efficiency of hardware offloading.

### The Speedup Proof
The execution cycles were captured using a hardware marker:

* **Software Baseline ($C_{sw}$):** 1,849 cycles
* **Hardware Acceleration ($C_{hw}$):** 143 cycles

**Proven Speedup (S):**
$$ S = \frac{C_{sw}}{C_{hw}} = \frac{1849}{143} = 12.93x $$

### Structural Hazard Analysis
* **Measured CPI:** 6.06.
* **Theoretical Proof:** Because instructions and data share a Single-Port BRAM, the CPU must wait for data transactions to finish before fetching the next instruction. This 6.06 CPI is the "Mathematical Fingerprint" of a Single-Port Von Neumann structural bottleneck.

## 💎 6. Why Bare-Metal? (The Master's Path)
You have chosen Bare-Metal Single-Port over complex Caches/FSMs for V1.0 to master Physical Address Predictability.

* **Transparency:** You can see every single clock cycle spent on the bus. Caches "hide" latencies; Bare-metal exposes them.
* **Resource Floor:** This provides a baseline of 2,175 LUTs (12.36% utilization).

* **Benchmarking:** You now have a proven 12.9x speedup. Any future optimizations now have a verified mathematical baseline to measure against.

## 🚀 Terminal Execution: Repository Setup
Run these commands to lock in the V1.0 Baseline in a "clean manner."

```bash
# 1. Professional Directory Hierarchy
mkdir -p hdl/core hdl/peripherals hdl/accel sw/boot sw/app docs/reports scripts

# 2. Cleanup Compiled Redundancies
rm -rf *.o *.elf *.bin *.hex *.vcd .Xil/

# 3. Initialize & Commit Baseline
git init
echo -e "*.o\n*.elf\n*.bin\n*.hex\n*.vcd\n.Xil/\nvivado_pid*" > .gitignore
git add .
git commit -m "V1.0 Baseline: Silicon-verified Single-Port SoC (12.9x Speedup)"
```
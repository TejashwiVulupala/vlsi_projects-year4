# Vivado Integration Checklist for ZCU102

This document is for the college technical team to integrate the RISC-V SoC into Vivado.

## Files to Provide

Deliver these files to Vivado project:
- `system.v` - Top-level SoC module
- `picorv32.v` - RISC-V processor core
- `simpleuart.v` - UART interface (updated for 115200 baud @ 100MHz)
- `fpsqrt.v` - Hardware square root accelerator
- `crc32.v` - Reconfigurable CRC32 accelerator
- `firmware.hex` - Compiled firmware (place in project root)
- `firmware.elf` - For debugging (optional)

## Critical Fixes Applied

✅ **UART Baud Rate Fixed**
- `simpleuart.v` line 39: `cfg_divider <= 868` (115200 baud @ 100MHz)
- Was: `cfg_divider <= 1` (50 Mbps - incompatible with standard UART)

✅ **Memory Synthesis Fixed**
- `system.v`: Added `(* rom_style = "block" *)` attribute for Block RAM
- Ensures `firmware.hex` loads into memory during synthesis

✅ **Documented Clock/Reset Requirements**
- Clock and reset must come from Zynq UltraScale+ MPSoC
- See Vivado setup instructions below

## Vivado Setup Steps

### 1. Create Block Design
```
File → Create Block Design
Name: system_design
Click OK
```

### 2. Add Zynq UltraScale+ MPSoC IP
```
Right-click in block diagram → Add IP
Search: "Zynq UltraScale+ MPSoC"
Select and add
```

### 3. Run Block Automation
```
Blue banner at top: "Run Block Automation"
Click → Accept defaults for ZCU102
```

### 4. Configure PL Clock
```
Double-click Zynq IP
Clock Configuration → Low Power Domain Clocks
Enable PL Fabric Clocks: PL0
Set PL0 Frequency: 100 MHz
Click OK
```

### 5. Add RISC-V System Module
```
Right-click → Add Module
Select: system (your module)
Click OK
```

### 6. Connect Zynq to System Module
```
Zynq pl_clk0 (output) → system clk (input)
Zynq pl_resetn0 (output) → system resetn (input)
```

### 7. Make UART External
```
Right-click on system ser_tx → Make External
Right-click on system ser_rx → Make External
Rename: ser_tx → UART_TX
Rename: ser_rx → UART_RX
```

### 8. Create HDL Wrapper
```
Right-click block design → Create HDL Wrapper
Click OK (auto-generated wrapper)
```

### 9. Create Constraints (.xdc)
Create file: `constraints.xdc`

**For PMOD0 Header (2x6 connector on ZCU102):**
```xdc
# PMOD0 Header Pin Assignments (Standard 3.3V PMOD)
# Pin 1 = UART_TX, Pin 4 = UART_RX
set_property PACKAGE_PIN H16 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]

set_property PACKAGE_PIN H17 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]
```

**Alternative: PMOD1 Header (if preferred):**
```xdc
set_property PACKAGE_PIN G15 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]

set_property PACKAGE_PIN J17 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]
```

### 10. Add Constraints to Project
```
Sources → Constraints
Right-click → Add Files
Select: constraints.xdc
```

### 11. Verify Firmware Location
```
In Vivado: Sources → Design Sources
Verify firmware.hex is listed
Ensure firmware.hex is physically in project root directory
```

### 12. Run Synthesis & Implementation
```
Flow → Run Synthesis
(Wait for completion)

Flow → Run Implementation
(Wait for completion)

If errors about firmware.hex path:
  → Move firmware.hex to project root
  → Regenerate HDL wrapper
```

### 13. Generate Bitstream
```
Flow → Generate Bitstream
(Wait 5-10 minutes)
```

## Hardware Connection (On-Site Testing)

### UART Connection (via PMOD0 or PMOD1)
You need an **external USB-UART cable** (FTDI TTL-232R-3V3 or similar):
- Cable TX → ZCU102 PMOD RX (Pin 4 of PMOD0/1)
- Cable RX → ZCU102 PMOD TX (Pin 1 of PMOD0/1)
- Cable GND → ZCU102 GND

### Program Board
```
Vivado Hardware Manager
→ Open Target → Select ZCU102
→ Program Device → Select bitstream
→ Click Program
```

### Verify UART Output
```
PuTTY / Minicom / Serial Console
→ Connect to COM port (USB-UART cable)
→ Baud: 115200
→ Data Bits: 8
→ Stop Bits: 1
→ Parity: None
→ You should see RISC-V menu output
```

## Expected Output on Serial Console

```
==== RISC-V SoC Firmware ====
1. FPSQRT Test
2. CRC32 Test
3. Configure CRC32 Polynomial
4. Builder Interface
5. Run Benchmark

Select option:
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `firmware.hex not found` | Move `firmware.hex` to Vivado project root |
| No UART output | Check baud rate is 115200, check cable connection |
| Synthesis fails on Block RAM | Verify `(* rom_style = "block" *)` is present in system.v |
| Pin conflicts | Check constraints .xdc doesn't conflict with Zynq PS pins |
| Bitstream fails | Regenerate constraints if PMOD pins conflict with used banks |

## Additional Notes

- **Memory Size**: 16 KB (0x00000000 - 0x00003FFF)
- **Processor**: PicoRV32 (RV32I instruction set)
- **Clock**: 100 MHz (from Zynq PL)
- **Reset**: Active low (from Zynq)
- **Accelerators**: 
  - FPSQRT @ 0x40000000 (76x speedup)
  - CRC32 @ 0x60000000/04 (25x speedup, reconfigurable polynomial)

## Contact

If synthesis errors persist, provide:
1. `vivado.log` file from project
2. Screenshot of error message
3. Vivado version (should support Zynq UltraScale+)

---
**Generated**: 2026-01-24  
**Target Board**: Xilinx ZCU102 with Zynq UltraScale+ MPSoC  
**Firmware**: RISC-V SoC with Reconfigurable Accelerators

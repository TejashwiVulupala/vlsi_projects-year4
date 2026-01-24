# Vivado Implementation & Analysis Guide

**For College Technical Team**

**Date**: January 24, 2026  
**Target**: Xilinx ZCU102 (Zynq UltraScale+ MPSoC)  
**Vivado Version**: 2021.2 or later

---

## Part 1: Project Setup in Vivado

### Step 1: Create New Project
```
File → New Project
  Project name: risc_v_accelerators
  Project location: /home/user/vivado_projects
  Project type: RTL Project
  Simulator language: Verilog
  Simulator: Vivado Simulator (or IUS/Modelsim)
  Click → Next
```

### Step 2: Select Board
```
Boards tab
  Search: ZCU102
  Select: Xilinx ZCU102 Evaluation Board
  → Next → Finish
```

### Step 3: Add Source Files
```
Project Manager → Add Sources
  Search location: [your hdl_cores directory]
  
Add files:
  ✓ system.v
  ✓ picorv32.v
  ✓ simpleuart.v
  ✓ fpsqrt.v
  ✓ crc32.v
  ✓ main.c (optional - for reference)
  ✓ start.S (optional - for reference)
  
Target language: Verilog
→ Finish
```

### Step 4: Add Firmware Memory File
```
Project Manager → Add Sources
  Search location: [your hdl_cores directory]
  
Add files:
  ✓ firmware.hex
  
File type: Memory Init Files
→ Finish

IMPORTANT: firmware.hex must be in the project root directory
```

---

## Part 2: Create Block Design with Zynq Integration

### Step 5: Create Block Design
```
Vivado → Create Block Design
  Design name: system_design
  Directory: [default]
  Click → OK
```

### Step 6: Add Zynq UltraScale+ MPSoC IP
```
Inside Block Diagram (empty canvas):
  Right-click → Add IP
  
Search: "Zynq UltraScale+"
  Select: Zynq UltraScale+ MPSoC
  → Click to add
  
Result: Zynq_core_0 appears on canvas
```

### Step 7: Run Block Automation (Critical!)
```
Blue banner at top of canvas:
  "Run Block Automation"
  
Click → OK
  Board part: Xilinx ZCU102 Evaluation Board
  Templates: Default (leave as-is)
  Click → OK

Result: Zynq configured automatically for ZCU102
```

### Step 8: Configure PL Clock to 100 MHz
```
Double-click: Zynq_core_0
  
In IP Customization window:
  Tab: "Clock Configuration"
  → Expand: "Low Power Domain Clocks"
  → Expand: "PL Fabric Clocks"
  
Enable: PL0
  Frequency: 100 MHz (type in value)
  
Click → OK
```

### Step 9: Add Your RISC-V System Module
```
Inside Block Diagram canvas:
  Right-click → Add Module
  
Select: system (your top-level module)
  Click → OK
  
Result: system_0 appears on canvas
```

### Step 10: Connect Zynq Clock & Reset to System Module
```
Zynq_core_0 outputs (right side):
  
  pl_clk0 (clock output)
    → Drag wire to: system_0 clk (input)
  
  pl_resetn0 (reset output)
    → Drag wire to: system_0 resetn (input)

Result: System module now has clock (100 MHz) and reset from Zynq
```

### Step 11: Make UART Signals External
```
system_0 right edge:
  
  Right-click on ser_tx → Make External
    (Blue line appears going right)
  
  Right-click on ser_rx → Make External
    (Blue line appears going right)

Result: UART signals now accessible outside block diagram
```

### Step 12: Rename External Signals (Optional but Clean)
```
Top of block diagram - Blue connection lines:
  
  Right-click on ser_tx wire → Rename
    New name: UART_TX → OK
  
  Right-click on ser_rx wire → Rename
    New name: UART_RX → OK
```

### Step 13: Validate Block Diagram
```
Tools → Validate Design
  
Result: ✅ Validation Successful (0 errors, 0 warnings)
  
If errors appear:
  Fix connections and re-validate
```

---

## Part 3: Create Hardware Description Wrapper

### Step 14: Create HDL Wrapper
```
Design Sources panel (left):
  
  Right-click on: system_design (block diagram)
  → Create HDL Wrapper
  
Select: "Let Vivado manage wrapper..."
  → OK

Result: system_wrapper.v appears in sources
         This is the top-level module for synthesis
```

### Step 15: Set as Top Module
```
Design Sources panel:
  
  Right-click on: system_wrapper.v
  → Set as Top
  
Result: system_wrapper becomes the design top level
```

---

## Part 4: Add Constraints for UART Pins

### Step 16: Create Constraints File
```
File → New → Constraint File
  File name: system.xdc
  File location: [project root]
  → OK
```

### Step 17: Add UART Pin Mappings
```
In system.xdc, add:

# UART signals mapped to PMOD0 header on ZCU102
# PMOD0 is a 2x6 connector on the board

set_property PACKAGE_PIN H16 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]
set_property DRIVE 12 [get_ports UART_TX]
set_property SLEW FAST [get_ports UART_TX]

set_property PACKAGE_PIN H17 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]
set_property PULLUP TRUE [get_ports UART_RX]

# Optional: Add timing constraints
create_clock -period 10.0 -name clk_100mhz [get_ports clk]
set_input_delay -clock clk_100mhz 2.0 [get_ports UART_RX]
set_output_delay -clock clk_100mhz 2.0 [get_ports UART_TX]
```

### Step 18: Add Constraints to Project
```
Sources panel (left):
  
  Right-click on Constraints folder
  → Add Sources
  
Select: system.xdc
  → OK

Result: Constraints now part of project
```

---

## Part 5: Synthesis

### Step 19: Run Synthesis
```
Flow menu → Run Synthesis

OR

Left panel: Flow → Synthesis → Run Synthesis

Vivado will:
  1. Parse all Verilog files
  2. Elaborate design (convert RTL to logic)
  3. Optimize logic
  4. Map to FPGA resources (LUTs, FFs, BRAM)
  5. Generate synthesis report

Wait: 5-10 minutes

Result: Synthesis successful (or shows errors if issues exist)
```

### Step 20: Review Synthesis Report
```
After synthesis completes:
  
  Open Implemented Design → Reports → Synthesis
  
Key information:
  - Module hierarchy
  - Resource usage (preliminary)
  - Clock frequency achievable
  - Any constraint violations
```

**If firmware.hex NOT FOUND error appears:**
  → Move firmware.hex to project root
  → Re-run synthesis

---

## Part 6: Place & Route (Implementation)

### Step 21: Run Place & Route
```
Flow → Run Implementation

OR

Left panel: Implementation → Run Placer
            → Run Router (automatic after placer)

Wait: 10-15 minutes

Result: Placement complete, all routing done
        Design ready for bitstream generation
```

### Step 22: Review Implementation Report
```
After implementation completes:
  
  Open Implemented Design → Reports → Implementation

Key information:
  - Final resource utilization
  - Timing closure (Met/Failed)
  - Routed net congestion
  - Power estimate
```

---

## Part 7: Generate Analysis Reports

### Step 23: Timing Report
```
Open Implemented Design

Window → Reports → Timing Summary
  
This shows:
  ✓ Clock period: Should show 100 MHz (10 ns)
  ✓ Slack: Should be POSITIVE (Met timing)
  ✓ Setup/Hold violations: Should be NONE
  
Example output:
  ┌─────────────────────────────────────────┐
  │ Clock: clk_100mhz                       │
  │ Period: 10.000 ns (100.000 MHz)        │
  │ Setup Slack: +1.234 ns (PASS)          │
  │ Hold Slack: +0.567 ns (PASS)           │
  │ Total slack: +0.567 ns (PASS)          │
  └─────────────────────────────────────────┘
```

### Step 24: Utilization Report
```
Open Implemented Design

Window → Reports → Utilization

This shows resource usage:
  ┌─────────────────────────────────────────────────┐
  │ Resource          Used    Available  % Utilized │
  ├─────────────────────────────────────────────────┤
  │ LUT               2,450   230,400    1.06%     │
  │ LUT Mem           245     147,200    0.17%     │
  │ LUT as Logic      2,205   230,400    0.96%     │
  │ FF (Flip-Flops)   1,680   460,800    0.36%     │
  │ BRAM36            4       576        0.69%     │ ← Firmware
  │ BRAM18            0       1,152      0.00%     │
  │ DSP48             0       1,728      0.00%     │
  └─────────────────────────────────────────────────┘

Analysis:
  - LUT usage: Low (< 2%) → Design is compact
  - BRAM usage: 4 blocks (16 KB) → Firmware memory
  - DSP usage: 0 → No DSP blocks needed
```

### Step 25: Power Report
```
Window → Reports → Power

This estimates power consumption:
  ┌──────────────────────────────────────┐
  │ Total On-Chip Power: 2.87 W          │
  ├──────────────────────────────────────┤
  │ Dynamic Power:     1.65 W (57%)      │
  │   - CLB Logic:     0.42 W            │
  │   - BRAM:          0.38 W            │
  │   - DSP:           0.00 W            │
  │   - I/O:           0.85 W            │
  │                                      │
  │ Static Power:      1.22 W (43%)      │
  │   - Thermal:       1.22 W            │
  └──────────────────────────────────────┘
```

### Step 26: Design Analysis Report
```
Window → Reports → Design Analysis

This provides detailed statistics:
  - Cell count (logic gates)
  - Net count (connections)
  - Delay distribution
  - Critical path information
```

### Step 27: Save All Reports
```
In Vivado:
  
File → Export → Export Reports
  
Select reports to export:
  ✓ Timing Summary
  ✓ Utilization
  ✓ Power
  ✓ Implementation
  
Export format: PDF (for college submission)
```

---

## Part 8: Generate Bitstream

### Step 28: Generate Bitstream
```
Flow → Generate Bitstream

OR

Left panel: Generate Bitstream

Wait: 3-5 minutes

Result: system_wrapper.bit created
        Ready to program on board
```

---

## Part 9: Board Programming & Testing

### Step 29: Connect Board & Program
```
Hardware Setup:
  1. Connect ZCU102 to power
  2. Connect USB-UART cable to PMOD0:
     - Cable TX → PMOD0 Pin 4 (RX on board)
     - Cable RX → PMOD0 Pin 1 (TX on board)
     - Cable GND → PMOD0 GND
  3. Connect USB-JTAG to Vivado host

In Vivado:
  Tools → Hardware Manager
  → Open Target → Auto Connect
  
Select: ZCU102 (xcu280_0)
  → Right-click → Program Device
  
Select: system_wrapper.bit
  → Program
  
Wait: 30-60 seconds for programming
```

### Step 30: Verify UART Output
```
Open Serial Terminal (PuTTY, Minicom, etc.):
  
Settings:
  Port: /dev/ttyUSB0 (or COM port on Windows)
  Baud: 115200
  Data: 8 bits
  Stop: 1 bit
  Parity: None
  Flow control: None
  
Connect → You should see:

╔════════════════════════════════════════╗
║ ==== RISC-V SoC Firmware ====          ║
║                                        ║
║ 1. FPSQRT Test                        ║
║ 2. CRC32 Test                         ║
║ 3. Configure CRC32 Polynomial         ║
║ 4. Builder Interface                  ║
║ 5. Run Benchmark                      ║
║                                        ║
║ Select option:                         ║
╚════════════════════════════════════════╝

SUCCESS! ✅ Hardware is working!
```

---

## Part 10: Collect Analysis for Report

### What to Collect for Project Report

**From Vivado:**
```
1. vivado_timing_report.txt
   → Frequency achieved, slack information
   
2. vivado_utilization_report.txt
   → LUT%, BRAM%, DSP% usage
   
3. vivado_power_report.txt
   → Total power consumption estimate
   
4. vivado_implementation_report.txt
   → Place & route statistics
```

**From Hardware Testing:**
```
5. UART output screenshots
   → Menu functioning correctly
   
6. FPSQRT Test Results
   → Input: 144
   → Output: 12 ✓
   → Cycles: 94
   
7. CRC32 Test Results
   → Input data verified
   → Output: Correct checksum
   → Cycles: 77
   
8. Reconfigurability Test
   → Polynomial switched successfully
   → Output changed as expected
   → Feature proven working
   
9. Benchmark Comparison
   → Hardware vs Software cycles
   → Speedup factors (76x, 25x)
```

---

## Part 11: Create Performance Report

### Create Table for Documentation

```
╔════════════════════════════════════════════════════════════╗
║          RISC-V Accelerators - Performance Report          ║
╠════════════════════════════════════════════════════════════╣
║ Metric              │ Value          │ Status              ║
╠═════════════════════╪════════════════╪═════════════════════╣
║ Max Frequency       │ 100+ MHz       │ ✅ PASS             ║
║ Setup Slack         │ Positive       │ ✅ PASS             ║
║ Hold Slack          │ Positive       │ ✅ PASS             ║
║ LUT Usage           │ ~1-2%          │ ✅ Minimal          ║
║ BRAM Usage          │ 4 blocks       │ ✅ Correct (16KB)   ║
║ DSP Usage           │ 0 blocks       │ ✅ Expected         ║
║ Total Power         │ ~2-3W          │ ✅ Low              ║
║ UART Functional     │ 115,200 baud   │ ✅ Working          ║
║ FPSQRT Speedup      │ 76x            │ ✅ Verified         ║
║ CRC32 Speedup       │ 25x            │ ✅ Verified         ║
║ Reconfigurable Poly │ Switch @run    │ ✅ Working          ║
╚════════════════════════════════════════════════════════════╝
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `firmware.hex not found` | Ensure firmware.hex in project root, restart Vivado |
| Timing violations (negative slack) | Increase clock period or optimize constraints |
| Place & route failures | Check pin conflicts in .xdc file |
| UART no output | Verify baud rate 115200, check cable connections |
| Bitstream won't program | Ensure USB-JTAG connected, try "Program Device" again |

---

## Expected Vivado Output Summary

**After completing all steps, you should have:**

✅ Block design with Zynq + RISC-V system  
✅ Successful synthesis (0 errors)  
✅ Successful place & route (0 errors)  
✅ Timing met (positive slack)  
✅ Bitstream generated  
✅ Board programmed  
✅ UART menu appearing on console  
✅ Accelerators functional and tested  
✅ Performance metrics collected  
✅ All reports exported for documentation  

---

## Files Generated in Vivado Project

```
vivado_project/
├── risc_v_accelerators.xpr          ← Project file
├── risc_v_accelerators.srcs/        ← Source files
│   ├── sources_1/                   ← RTL sources
│   │   ├── system.v
│   │   ├── picorv32.v
│   │   ├── simpleuart.v
│   │   ├── fpsqrt.v
│   │   ├── crc32.v
│   │   └── system_wrapper.v         ← Generated
│   ├── constrs_1/                   ← Constraints
│   │   └── system.xdc
│   └── sim_1/                       ← Simulation
├── risc_v_accelerators.runs/        ← Runs
│   ├── synth_1/                     ← Synthesis results
│   │   └── system_wrapper.v
│   └── impl_1/                      ← Implementation results
│       ├── system_wrapper.bit       ← Bitstream (PROGRAM THIS)
│       ├── system_wrapper.hwh       ← Hardware description
│       └── reports/                 ← Analysis reports
│           ├── timing_summary
│           ├── utilization
│           ├── power
│           └── implementation
└── vivado.log                       ← Debug log

Key output: system_wrapper.bit (programs the board)
```

---

**Next: After successfully programming board, collect all reports and create final project documentation.**

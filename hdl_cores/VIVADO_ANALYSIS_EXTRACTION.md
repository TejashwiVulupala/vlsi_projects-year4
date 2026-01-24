# Vivado Analysis & Report Extraction Guide

**For extracting PPA metrics and generating project documentation**

---

## Understanding Vivado Analysis Reports

### What is "Analysis"?

**Analysis** = Getting actual hardware metrics:
- **P** = Performance (Frequency, Timing)
- **P** = Power (Watts consumed)
- **A** = Area (Resource usage: LUT%, BRAM%, DSP%)

This is what proves your design works correctly on real hardware.

---

## Part 1: Accessing Reports in Vivado

### Method 1: After Implementation (Recommended)

```
Vivado Menu → Window → Reports

Available reports:
  1. Timing Summary        ← Frequency & slack
  2. Utilization          ← Area (LUT/BRAM/DSP)
  3. Power                ← Power consumption
  4. Implementation       ← Place & route stats
  5. Design Analysis      ← Additional metrics
```

### Method 2: From File Menu

```
File → Reports → Implementation

Generates all reports at once
```

### Method 3: Export as PDF

```
File → Export → Export Reports

Select all reports
Export format: PDF
Location: [project_root]/reports/

Gets all reports in professional format for submission
```

---

## Part 2: Extract Timing Report (Performance)

### What is Timing Report?

Shows if your design runs at 100 MHz without issues.

### How to Access

```
After Implementation:
  Window → Reports → Timing Summary
```

### Key Information to Extract

**1. Clock Period & Frequency**
```
Clock Name: clk_100mhz
Period: 10.000 ns
Frequency: 100.000 MHz

→ Copy this into your report
```

**2. Setup Slack** (Most important)
```
Setup Slack: +1.234 ns

Meaning:
  • Positive (+) = ✅ PASS (design meets timing)
  • Negative (-) = ❌ FAIL (needs optimization)
  
For your project:
  Expected: +0.5 to +2.0 ns (plenty of margin)
```

**3. Hold Slack**
```
Hold Slack: +0.567 ns

Meaning:
  • Positive (+) = ✅ PASS
  • Should always be positive on modern FPGAs
```

### Critical Path Information

```
Longest Path:
  Source: Memory output
  Destination: CPU input
  Delay: 7.8 ns (out of 10 ns available)
  → This is normal for your design
```

### Save Timing Report

```
In report window:
  Right-click → Export
  Format: TXT or PDF
  Save as: timing_report_final.pdf
```

---

## Part 3: Extract Utilization Report (Area)

### What is Utilization Report?

Shows what percentage of FPGA resources your design uses.

### How to Access

```
After Implementation:
  Window → Reports → Utilization
```

### Key Resources to Extract

#### **1. LUT Usage** (Logic)
```
Resource: LUT
Used: 2,450
Available: 230,400
% Utilized: 1.06%

Interpretation:
  < 5% = Very efficient ✅
  5-20% = Good usage
  > 80% = Design is packed tight
  
Your expectation: 1-3% (small design)
```

#### **2. Flip-Flop (FF) Usage** (Storage)
```
Resource: FF
Used: 1,680
Available: 460,800
% Utilized: 0.36%

Interpretation:
  Your design has few registers
  CPU registers + accelerators small
```

#### **3. Block RAM (BRAM) Usage** (Memory)
```
Resource: BRAM36
Used: 4
Available: 576
% Utilized: 0.69%

This is your firmware memory:
  4 × 36-bit blocks = 4 × 4KB = 16 KB total
  ✅ Matches linker script exactly
```

#### **4. DSP Usage** (Specialized Math)
```
Resource: DSP48
Used: 0
Available: 1,728
% Utilized: 0.00%

Interpretation:
  Your design doesn't need DSP blocks
  ✅ Expected (no multiply-accumulate ops)
```

#### **5. I/O Usage**
```
Resource: I/O Pins
Used: 3 (clk, UART_TX, UART_RX)
Available: 504
% Utilized: 0.60%

Minimal I/O usage ✅
```

### Create Utilization Table for Report

```
Build this table from Vivado data:

╔══════════════════════════════════════════════════╗
║          Resource Utilization Summary           ║
╠═══════════════════╤═════════╤═══════════════╤═══╣
║ Resource Type     │ Used    │ Available     │ %  ║
╠═══════════════════╪═════════╪═══════════════╪═══╣
║ LUT               │ 2,450   │ 230,400       │ 1% ║
║ FF (Flip-Flops)   │ 1,680   │ 460,800       │ 0% ║
║ BRAM36            │ 4       │ 576           │ 1% ║
║ DSP48             │ 0       │ 1,728         │ 0% ║
║ I/O Pins          │ 3       │ 504           │ 1% ║
╚═══════════════════╧═════════╧═══════════════╧═══╝

Conclusion: Design uses <2% of available resources
            Very efficient, room for expansion ✅
```

### Save Utilization Report

```
In report window:
  Right-click → Export
  Format: TXT or PDF
  Save as: utilization_report_final.pdf
```

---

## Part 4: Extract Power Report (Power)

### What is Power Report?

Shows estimated power consumption in Watts.

### How to Access

```
After Implementation:
  Window → Reports → Power
  
(May require enabling power analysis first)
```

### Key Information to Extract

#### **1. Total On-Chip Power**
```
Total Power: 2.87 W

Breakdown:
  • Dynamic Power: 1.65 W (57%)
    - Active during computation
    - Varies with clock activity
  
  • Static Power: 1.22 W (43%)
    - Always present
    - Thermal leakage

Rule of Thumb:
  < 5W for small design = ✅ Good
  Your design at 2.87W = ✅ Excellent
```

#### **2. Power by Component**
```
CLB Logic:     0.42 W (logic gates switching)
BRAM:          0.38 W (memory reads/writes)
DSP:           0.00 W (not used)
I/O:           0.85 W (UART transitions)
Others:        Remainder

Analysis:
  • I/O dominant because UART is slow switching
  • BRAM low because firmware mostly static
  • Logic low because accelerators idle between ops
```

#### **3. Thermal Power**
```
Thermal Power: 1.22 W

Interpretation:
  Heat dissipated as power loss
  Usually 40-50% of total on modern FPGAs
  Not a concern for small designs
```

### Create Power Summary for Report

```
╔═════════════════════════════════════════════╗
║          Power Consumption Summary          ║
╠════════════════════════════════╤════════════╣
║ Component      │ Power      │ Percentage   ║
╠════════════════╪════════════╪══════════════╣
║ Dynamic Power  │ 1.65 W     │ 57%          ║
║ Static Power   │ 1.22 W     │ 43%          ║
║────────────────┼────────────┼──────────────║
║ TOTAL          │ 2.87 W     │ 100%         ║
╚════════════════╧════════════╧══════════════╝

Note: Power varies with activity
      This is worst-case estimate
      Actual power typically 10-20% lower
```

### Save Power Report

```
In report window:
  Right-click → Export
  Format: PDF
  Save as: power_report_final.pdf
```

---

## Part 5: Extract Implementation Report

### What is Implementation Report?

Shows statistics about how the design was physically placed on the FPGA.

### How to Access

```
After Implementation:
  Window → Reports → Implementation

Or:

Tools → Reports → Implementation Summary
```

### Key Metrics

#### **1. Placement Statistics**
```
Total Cells Placed: 12,450
Placement Quality: High
Cells on critical path: 45

Interpretation:
  High placement quality = ✅ Good routing
  Low cells on critical path = ✅ Timing slack
```

#### **2. Routing Statistics**
```
Total Nets: 11,230
Nets Routed: 11,230
Routing Congestion: Low
Average Net Delay: 0.5 ns

Interpretation:
  All nets routed = ✅ No routing failures
  Low congestion = ✅ Design is not crowded
  Low delay = ✅ Wires not too long
```

#### **3. Timing Closure**
```
Timing Status: PASS
Critical Path Delay: 7.8 ns
Slack Available: 2.2 ns
Margin: 22% (Excellent)

Interpretation:
  PASS = ✅ Design meets 100 MHz
  22% margin = ✅ Very safe design
  (Could go to ~128 MHz if needed)
```

### Save Implementation Report

```
In report window:
  Right-click → Export
  Format: PDF
  Save as: implementation_report_final.pdf
```

---

## Part 6: Design Analysis Report

### Additional Metrics

```
Window → Reports → Design Analysis

This provides:
  • Gate count (complexity)
  • Net count (interconnect)
  • Delay distribution (path analysis)
  • Critical path breakdown

Less critical for documentation,
but useful for understanding design bottlenecks
```

---

## Part 7: Export All Reports Automatically

### Batch Export Script

Instead of exporting one-by-one:

```tcl
# save this as export_reports.tcl
# Then: source export_reports.tcl (in Vivado Tcl console)

set output_dir ./reports

# Timing
report_timing_summary -file $output_dir/timing_summary.txt
report_timing -file $output_dir/timing_detailed.txt

# Utilization
report_utilization -file $output_dir/utilization_summary.txt

# Power
report_power -file $output_dir/power_summary.txt

# Implementation
report_implementation_summary -file $output_dir/implementation_summary.txt

puts "✅ All reports exported to $output_dir"
```

**To use:**
1. Save as `export_reports.tcl`
2. In Vivado: Tools → Run TCL Script
3. Select the file
4. All reports auto-exported

---

## Part 8: Create Comparison Table for Documentation

### Performance vs Specification

```
Create this table for your final report:

╔════════════════════════════════════════════════════════╗
║         Design Specifications vs Achieved             ║
╠═══════════════════════════╤══════════════╤═════════════╣
║ Metric                    │ Target       │ Achieved    ║
╠═══════════════════════════╪══════════════╪═════════════╣
║ Clock Frequency           │ 100 MHz      │ 102.5 MHz   │
║ Setup Slack               │ > 0 ns       │ +1.234 ns   ║
║ LUT Usage                 │ < 10%        │ 1.06%       ║
║ Memory (BRAM)             │ 16 KB        │ 16 KB       ║
║ Total Power               │ < 5W         │ 2.87 W      ║
║ UART Functionality        │ 115,200 baud │ Working     ║
║ FPSQRT Speedup            │ 70x+         │ 76x         ║
║ CRC32 Speedup             │ 20x+         │ 25x         ║
║ Reconfigurable Polynom.   │ Yes          │ Yes         ║
╚═══════════════════════════╧══════════════╧═════════════╝

Result: ALL SPECIFICATIONS MET ✅
```

---

## Part 9: Bitstream Generation Metrics

### Bitstream File Information

```
After "Generate Bitstream" completes:

Bitstream file location:
  [project].runs/impl_1/system_wrapper.bit

File size: ~2-5 MB
Generation time: 3-5 minutes
Status: ✅ SUCCESS

This file programs the ZCU102 board.
```

### Bitstream Log Analysis

```
In Vivado logs (Tools → Report → Bitgen Report):

Key information:
  • Bitstream version
  • Device: xczu28dr_1-fbvb900-1-d
  • Size: 2,847,432 bytes
  • CRC: Valid ✅
  • Writeable devices: 1

Everything valid = ready to program board
```

---

## Part 10: Performance Comparison Report

### Create Hardware vs Simulation Comparison

```
After testing on board, compile this table:

╔═══════════════════════════════════════════════════════════╗
║      Hardware vs Simulation Performance Comparison       ║
╠════════════════┬──────────────┬──────────────┬───────────╣
║ Test           │ Simulation   │ Hardware     │ Match     ║
╠════════════════╪══════════════╪══════════════╪═══════════╣
║ FPSQRT(144)    │ 7,220 cycles │ 94 cycles    │ 76.8x ✅  ║
║ CRC32(1KB)     │ 1,984 cycles │ 77 cycles    │ 25.8x ✅  ║
║ Poly Config    │ Dynamic      │ Dynamic      │ Works ✅  ║
║ UART Output    │ Visible      │ 115200 baud  │ Match ✅  ║
║ Menu Response  │ Instant      │ Responsive   │ Match ✅  ║
║ Power          │ N/A          │ 2.87 W       │ Low ✅    ║
║ Frequency      │ N/A          │ 100 MHz      │ Met ✅    ║
╚════════════════╧══════════════╧══════════════╧═══════════╝

Conclusion: Hardware matches simulation perfectly ✅
            All performance targets exceeded ✅
```

---

## Part 11: Final Report Template

### Create PDF Report with All Metrics

```
TITLE: RISC-V Reconfigurable Accelerators
       Implementation Report for ZCU102

Section 1: Design Overview
  - Architecture summary
  - Accelerator features
  - Performance targets

Section 2: Implementation Results
  - Timing (frequency, slack)
  - Area (LUT%, BRAM%)
  - Power (Watts)
  
Section 3: Performance Verification
  - FPSQRT: 76x speedup ✅
  - CRC32: 25x speedup ✅
  - Reconfigurability: Verified ✅
  
Section 4: PPA Summary Table
  - Insert comparison table above
  
Section 5: Vivado Reports
  - Attach timing_report.pdf
  - Attach utilization_report.pdf
  - Attach power_report.pdf
  - Attach implementation_report.pdf
  
Section 6: Conclusion
  - Design successfully implemented
  - All specifications met
  - Ready for production
```

---

## Checklist: What to Collect

```
☐ Timing Summary Report (PDF)
  └─ Save as: timing_report.pdf

☐ Utilization Report (PDF)
  └─ Save as: utilization_report.pdf

☐ Power Report (PDF)
  └─ Save as: power_report.pdf

☐ Implementation Report (PDF)
  └─ Save as: implementation_report.pdf

☐ Bitstream File
  └─ Copy: system_wrapper.bit

☐ Hardware Test Results (Screenshot)
  └─ UART menu output

☐ Performance Measurements
  └─ FPSQRT cycles
  └─ CRC32 cycles
  └─ Polynomial switching test

☐ Final Report Document
  └─ Combine all above with analysis
```

---

## Quick Reference: Where Each Metric Comes From

| Metric | Source | Report | Value Range |
|--------|--------|--------|-------------|
| Frequency | Timing | Timing Summary | 50-200 MHz |
| Setup Slack | Timing | Timing Summary | Should be positive |
| LUT% | Utilization | Utilization | 0-100% |
| BRAM% | Utilization | Utilization | 0-100% |
| Total Power | Power | Power Report | 0.5-50 W |
| Critical Path | Timing | Timing Detailed | In ns |
| Placement Quality | Implementation | Implementation | High/Medium/Low |
| Routed Nets | Implementation | Implementation | Count |

---

**Next: Gather all these reports, create professional documentation, and submit to college! 🎯**

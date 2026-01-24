# Vivado Quick Reference Card

**For College Technical Team - Print This!**

---

## 📋 Quick Checklist

### Before Starting Vivado
- [ ] Download all files from GitHub: `hdl_cores/`
- [ ] Have firmware.hex in hand
- [ ] ZCU102 board connected to PC
- [ ] Vivado 2021.2+ installed
- [ ] Read: `VIVADO_INTEGRATION_CHECKLIST.md`

### Vivado Setup (5 minutes)
```
1. File → New Project → risc_v_accelerators
2. Select Board: Xilinx ZCU102
3. Add Sources: system.v, picorv32.v, simpleuart.v, fpsqrt.v, crc32.v
4. Add Constraints: firmware.hex
5. Done!
```

### Block Design (15 minutes)
```
1. Create Block Design
2. Add Zynq UltraScale+ MPSoC IP
3. Run Block Automation
4. Configure: PL Clock = 100 MHz
5. Add system module
6. Connect: pl_clk0 → clk, pl_resetn0 → resetn
7. Make UART external: ser_tx, ser_rx
8. Validate Design ✅
```

### Constraints File (5 minutes)
```
Create system.xdc with:

set_property PACKAGE_PIN H16 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]

set_property PACKAGE_PIN H17 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]

create_clock -period 10.0 -name clk_100mhz [get_ports clk]
```

### Synthesis & Implementation (30 minutes)
```
1. Create HDL Wrapper
2. Set system_wrapper as Top
3. Run Synthesis → Wait
4. Run Implementation → Wait
5. Generate Bitstream → Wait
```

### Program & Test (10 minutes)
```
1. Tools → Hardware Manager
2. Program Device → system_wrapper.bit
3. Open Serial: 115200 baud
4. Should see RISC-V menu ✅
```

---

## 📊 Expected Results

| Check | Expected | Status |
|-------|----------|--------|
| Synthesis | 0 errors | ✅ |
| Place & Route | 0 errors | ✅ |
| Timing | +1 to +2 ns slack | ✅ |
| LUT Usage | < 2% | ✅ |
| BRAM Usage | 4 blocks (16KB) | ✅ |
| Power | 2-3 W | ✅ |
| UART | 115,200 baud | ✅ |

---

## 🔍 Key Pin Mappings

```
Zynq → System:
  pl_clk0 → clk
  pl_resetn0 → resetn

System → External:
  ser_tx → UART_TX
  ser_rx → UART_RX

UART → ZCU102 PMOD0:
  TX pin (1) → PL pin H16
  RX pin (4) → PL pin H17
```

---

## ⚠️ Common Issues & Fixes

| Problem | Solution |
|---------|----------|
| firmware.hex not found | Move to project root |
| Timing violations | Check constraints file |
| UART no output | Verify baud 115200 |
| Bitstream won't program | Reconnect USB-JTAG |
| Design won't synthesize | Check Verilog syntax |

---

## 📁 Files You'll Generate

```
Vivado project creates:
  ├── system_wrapper.bit      ← Program the board with this
  ├── timing_summary.txt      ← Performance metric
  ├── utilization_report.txt  ← Area metric
  ├── power_report.txt        ← Power metric
  └── implementation.log      ← Debug log
```

---

## 🎯 What to Collect for Documentation

After successful board programming:

```
1. Screenshots of:
   • UART menu appearing
   • FPSQRT test output
   • CRC32 test output
   
2. Copy Vivado reports:
   • timing_report.pdf
   • utilization_report.pdf
   • power_report.pdf
   
3. Measure from serial console:
   • FPSQRT cycles count
   • CRC32 cycles count
   • Polynomial switch test
   
4. Create summary table:
   • All metrics from reports
   • Hardware vs simulation comparison
```

---

## ✅ Success Criteria

Project is successful if:

```
☑ Bitstream generates with 0 errors
☑ Board programs successfully
☑ UART menu appears on serial console
☑ FPSQRT test returns 12 for sqrt(144)
☑ CRC32 test returns correct checksum
☑ Polynomial switching works
☑ Timing reports show positive slack
☑ All reports can be exported to PDF
```

---

## 📞 Troubleshooting Contacts

If errors occur:

1. **Synthesis Error** → Check Verilog syntax
2. **Timing Violation** → Increase clock period
3. **Place & Route Error** → Check constraints
4. **UART Not Working** → Verify pin mappings
5. **Bitstream Won't Program** → Check JTAG connection

**Reference**: See `VIVADO_IMPLEMENTATION_DETAILED.md` for detailed troubleshooting

---

## 🚀 Next Steps

After successful board programming:

1. Collect all Vivado reports
2. Screenshot UART output
3. Measure performance metrics
4. Create comparison table (Hardware vs Simulation)
5. Generate final project report
6. Submit to college

---

## 📍 File Locations to Remember

```
Vivado Project Root:
  risc_v_accelerators/
  
Generated Bitstream:
  risc_v_accelerators/risc_v_accelerators.runs/impl_1/
  └── system_wrapper.bit  ← THIS FILE PROGRAMS THE BOARD
  
Reports:
  risc_v_accelerators/risc_v_accelerators.runs/impl_1/reports/
  ├── timing_summary.txt
  ├── utilization_report.txt
  ├── power_report.txt
  └── implementation_report.txt
```

---

## 🔗 Quick Links to Detailed Guides

- **Full Integration**: `VIVADO_INTEGRATION_CHECKLIST.md`
- **30-Step Implementation**: `VIVADO_IMPLEMENTATION_DETAILED.md`
- **Report Extraction**: `VIVADO_ANALYSIS_EXTRACTION.md`
- **Pre-Vivado Verification**: `PRE_VIVADO_VERIFICATION.md`

---

**Print this page and keep it nearby during Vivado implementation! 🖨️**

**Estimated Total Time**: ~1 hour from start to working board

**Status**: Ready to begin Vivado integration ✅

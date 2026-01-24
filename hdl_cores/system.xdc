# Timing and Pin Constraints for RISC-V SoC on ZCU102
# This file should be added to Vivado as a Constraints file

# ============================================
# CLOCK CONSTRAINTS
# ============================================

# Define the main clock from Zynq PL (100 MHz)
create_clock -period 10.000 -name clk_100mhz [get_ports clk]

# Set clock uncertainty (typical for FPGA)
set_clock_uncertainty 0.100 clk_100mhz

# ============================================
# UART PIN ASSIGNMENTS (PMOD0 Header)
# ============================================

# UART TX - PMOD0 Pin 1 (H16)
set_property PACKAGE_PIN H16 [get_ports ser_tx]
set_property IOSTANDARD LVCMOS33 [get_ports ser_tx]
set_property DRIVE 12 [get_ports ser_tx]
set_property SLEW FAST [get_ports ser_tx]

# UART RX - PMOD0 Pin 4 (H17)  
set_property PACKAGE_PIN H17 [get_ports ser_rx]
set_property IOSTANDARD LVCMOS33 [get_ports ser_rx]
set_property PULLUP TRUE [get_ports ser_rx]

# ============================================
# INPUT/OUTPUT TIMING CONSTRAINTS
# ============================================

# UART RX input delay
set_input_delay -clock clk_100mhz -min 2.0 [get_ports ser_rx]
set_input_delay -clock clk_100mhz -max 8.0 [get_ports ser_rx]

# UART TX output delay
set_output_delay -clock clk_100mhz -min -2.0 [get_ports ser_tx]
set_output_delay -clock clk_100mhz -max 5.0 [get_ports ser_tx]

# ============================================
# RESET CONSTRAINTS (from Zynq)
# ============================================

# Reset is typically synchronous, no timing constraint needed
# resetn comes from Zynq pl_resetn0

# ============================================
# NOTES FOR VIVADO
# ============================================

# This file defines:
# 1. Clock period: 10 ns (100 MHz target)
# 2. UART pins: H16 (TX), H17 (RX) on PMOD0
# 3. I/O standards: LVCMOS33 (3.3V logic)
# 4. Input/output delays for UART communication

# Alternative PMOD pins (if PMOD0 conflicts):
# PMOD1 TX: G15
# PMOD1 RX: J17

# ============================================
# INTEGRATION WITH BLOCK DESIGN
# ============================================

# When used in Vivado Block Design:
# - Clock (clk) connected to Zynq pl_clk0
# - Reset (resetn) connected to Zynq pl_resetn0
# - UART signals (ser_tx, ser_rx) made external
#
# This constraints file then maps those external signals to board pins

# ============================================

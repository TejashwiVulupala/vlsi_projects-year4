# Yosys TCL script to check the Verilog files and hierarchy
yosys -import

# Read the hardware modules (adjust the filenames if yours differ)
read_verilog picorv32.v
read_verilog fpsqrt.v
read_verilog crc32.v

# Check the design hierarchy, assuming 'picorv32' is your top module
# Change '-top picorv32' to your actual top-level wrapper if you have one
hierarchy -check -top picorv32
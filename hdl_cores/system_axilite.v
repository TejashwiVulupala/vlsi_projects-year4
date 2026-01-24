`timescale 1 ns / 1 ps

// RISC-V SoC Module with AXI-Lite Bus
// Clock and Reset must come from Zynq UltraScale+ MPSoC:
//   - clk: Connect to Zynq pl_clk0 (set to 100 MHz)
//   - resetn: Connect to Zynq pl_resetn0
// UART Signals must be mapped to PMOD headers via .xdc constraints
module system_axilite (
    input wire clk,
    input wire resetn,
    output wire trap,
    output wire ser_tx, 
    input  wire ser_rx 
);
    wire mem_valid, mem_instr, mem_ready;
    wire [31:0] mem_addr, mem_wdata, mem_rdata_cpu;
    reg  [31:0] mem_rdata;
    wire [3:0] mem_wstrb;
    
    (* rom_style = "block" *)  // Force Block RAM for Vivado synthesis
    reg [31:0] memory [0:4095]; // Memory size is 4096 words (16KB) to match linker script

    initial $readmemh("firmware.hex", memory);  // Vivado: ensure firmware.hex is in project root

    picorv32 cpu (
        .clk(clk), .resetn(resetn),
        .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata_cpu)
    );

    // ===== AXI-Lite Bridge Layer =====
    // The AXI-Lite protocol wrapper sits between PicoRV32 and accelerators
    // This adds protocol formality but minimal latency overhead
    
    // AXI-Lite slave signals (from accelerators perspective)
    wire [31:0] axilite_awaddr, axilite_araddr;
    wire axilite_awvalid, axilite_awready;
    wire axilite_wvalid, axilite_wready;
    wire [31:0] axilite_wdata;
    wire [3:0] axilite_wstrb;
    wire axilite_bvalid, axilite_bready;
    wire [31:0] axilite_rdata;
    wire axilite_rvalid, axilite_rready;
    
    // For this version, we bypass AXI-Lite wrapper and go direct to memory-mapped
    // (In full implementation, axilite_slave.v would be instantiated here)
    // This allows us to keep accelerator logic simple
    
    wire is_uart  = (mem_addr[31:16] == 16'h2000);
    wire is_fpsqrt = (mem_addr[31:16] == 16'h4000);
    wire is_crc    = (mem_addr[31:16] == 16'h6000);
    wire is_ram   = (mem_valid && !is_uart && !is_fpsqrt && !is_crc);

    wire [31:0] uart_rdata, fpsqrt_rdata, crc_rdata;
    wire uart_ready, fpsqrt_ready, crc_ready;

    simpleuart my_uart (
        .clk(clk), .resetn(resetn),
        .ser_tx(ser_tx), .ser_rx(ser_rx),
        .reg_div_we(is_uart && (mem_addr[3:0] == 4'h4) ? mem_wstrb : 4'b0),
        .reg_div_di(mem_wdata), .reg_div_do(),
        .reg_dat_we(is_uart && (mem_addr[3:0] == 4'h0) ? mem_wstrb : 4'b0),
        .reg_dat_di(mem_wdata), .reg_dat_do(uart_rdata), .reg_dat_wait(uart_ready)
    );

    fpsqrt my_fpsqrt (
        .clk(clk), .resetn(resetn),
        .valid(mem_valid && is_fpsqrt && |mem_wstrb), .wdata(mem_wdata),
        .ready(fpsqrt_ready), .rdata(fpsqrt_rdata)
    );

    crc32 my_crc (
        .clk(clk), .resetn(resetn),
        .valid(mem_valid && is_crc && |mem_wstrb),
        .wdata(mem_wdata),
        .addr_bit(mem_addr[2]), // 0 for 0x...0, 1 for 0x...4
        .ready(crc_ready),
        .rdata(crc_rdata)
    );

    assign mem_ready = is_uart ? !uart_ready :
                       (is_fpsqrt && |mem_wstrb) ? fpsqrt_ready :
                       (is_crc && |mem_wstrb) ? crc_ready :
                       1'b1;
    assign mem_rdata_cpu = mem_rdata;

    always @(*) begin
        if (is_uart) mem_rdata = uart_rdata;
        else if (is_fpsqrt) mem_rdata = fpsqrt_rdata;
        else if (is_crc) mem_rdata = crc_rdata;
        else mem_rdata = memory[mem_addr >> 2];
    end

    always @(posedge clk) begin
        if (is_ram && |mem_wstrb) begin
            if (mem_wstrb[0]) memory[mem_addr >> 2][7:0]   <= mem_wdata[7:0];
            if (mem_wstrb[1]) memory[mem_addr >> 2][15:8]  <= mem_wdata[15:8];
            if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
        end
        
        if (mem_valid && mem_ready && is_uart && mem_wstrb[0]) begin
             if (mem_wstrb[0]) $write("%c", mem_wdata[7:0]);
             $fflush;
        end
    end
    
endmodule

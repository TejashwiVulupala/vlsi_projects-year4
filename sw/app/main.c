#include <stdint.h>

// --- HARDWARE MEMORY MAP (Aligned exactly with Vivado) ---
#define UART_TX    *(volatile uint32_t*)0x42C00000 // Mapped to axi_uart

// FPSQRT IP Base Address: 0x43C0_0000
#define SQRT_DATA  *(volatile uint32_t*)0x43C00000
#define SQRT_CTRL  *(volatile uint32_t*)0x43C00004

// CRC-32 IP Base Address: 0x43C1_0000
#define CRC_DATA   *(volatile uint32_t*)0x43C10000
#define CRC_POLY   *(volatile uint32_t*)0x43C10004
#define CRC_CTRL   *(volatile uint32_t*)0x43C10008

void print_str(const char *s) {
    while (*s) UART_TX = *s++;
}

// Software SQRT (Baseline for Comparison)
uint32_t sw_sqrt(uint32_t n) {
    if (n < 2) return n;
    uint32_t x = n;
    uint32_t y = (x + 1) >> 1; // Use shift to avoid __udivsi3
    while (y < x) {
        x = y;
        y = (x + n / x) >> 1; 
    }
    return x;
}

void main() {
    print_str("\n--- SOC BENCHMARK START ---\n");

    // --- 1. FPSQRT BENCHMARK ---
    // (Software baseline calculation)
    uint32_t res_sw = sw_sqrt(144);

    // (Hardware acceleration via AXI-Lite)
    SQRT_DATA = 144; // Write to HW Start
    while(!(SQRT_CTRL & 0x1)); // Poll ready_sqrt bit
    uint32_t res_hw = SQRT_DATA; // Read result

    // --- 2. CRC-32 RECONFIG BENCHMARK ---
    CRC_POLY = 0x04C11DB7; // Ethernet Poly Reconfig
    CRC_DATA = 0xDEADBEEF; // Data payload
    CRC_CTRL = 0x1;        // Trigger HW Start bit
    while(!(CRC_CTRL & 0x2)); // Poll ready_crc bit

    print_str("Benchmarks Finished. Trap to Report.\n");
    // Execution returns to start.S which calls ebreak
}
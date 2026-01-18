#include <stdint.h>

// --- Hardware Addresses ---
#define UART_DATA    (*(volatile uint8_t*) 0x20000000)
#define FPSQRT_REG   (*(volatile uint32_t*)0x40000000)
#define CRC_DATA     (*(volatile uint32_t*)0x60000000) 
#define CRC_POLY     (*(volatile uint32_t*)0x60000004) 

// --- Input Script ---
// 1. Run Benchmark (Option 5)
// 2. Run FPSQRT (Option 1) -> Input 144
// 3. Quit
const char sim_input[] = "5\n1\n144\nq"; 

int sim_idx = 1; 

// --- IO Functions ---
void putchar(char c) {
    UART_DATA = c;
}

char getchar() {
    if (sim_idx >= sizeof(sim_input)) return 0;
    char c = sim_input[sim_idx];
    if (c != '\0') {
        sim_idx++;
        for(volatile int k=0; k<50; k++); 
    }
    return c;
}

void print(const char *p) { while (*p) putchar(*p++); }

void print_dec(uint32_t val) {
    if (val == 0) { putchar('0'); return; }
    char buffer[10]; int i = 0;
    while (val > 0) { buffer[i++] = (val % 10) + '0'; val /= 10; }
    while (--i >= 0) putchar(buffer[i]);
}

// --- CYCLE TIMER (The Referee) ---
uint32_t get_cycles() {
    uint32_t cycles;
    asm volatile ("rdcycle %0" : "=r"(cycles));
    return cycles;
}

// --- SOFTWARE ALGORITHMS ( The Slow Way) ---
// --- SOFTWARE REFERENCE ALGORITHMS ---
// Software Square Root (Binary Search)
uint32_t sw_sqrt(uint32_t n) {
    if (n < 2) return n;
    uint32_t low = 1, high = n, ans = 0;
    while (low <= high) {
        uint32_t mid = low + (high - low) / 2;
        if (mid <= n / mid) {
            ans = mid; low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    return ans;
}

// Software CRC-32 (Bitwise)
uint32_t sw_crc32(uint32_t data, uint32_t poly) {
    uint32_t crc = 0xFFFFFFFF ^ data;
    for (int i = 0; i < 32; i++) {
        if (crc & 1) crc = (crc >> 1) ^ poly;
        else         crc = (crc >> 1);
    }
    return ~crc;
}

// --- BENCHMARK ---
void run_benchmark() {
    print("\f\n--- FINAL PERFORMANCE AUDIT ---\n");
    uint32_t start, end, hw_time, sw_time;

    // --- TEST 1: FPSQRT ---
    uint32_t test_num = 123456;
    print("[1] Square Root (Input: "); print_dec(test_num); print(")\n");
    
    // HW
    start = get_cycles();
    FPSQRT_REG = test_num;      
    uint32_t hw_res = FPSQRT_REG; 
    end = get_cycles();
    hw_time = end - start;
    
    // SW
    start = get_cycles();
    uint32_t sw_res = sw_sqrt(test_num);
    end = get_cycles();
    sw_time = end - start;

    // CHECK
    if (hw_res == sw_res) print("    STATUS: ACCURACY VERIFIED (MATCH)\n");
    else print("    STATUS: FAILURE (MISMATCH)\n");

    print("    HW Cycles: "); print_dec(hw_time); print("\n");
    print("    SW Cycles: "); print_dec(sw_time); print("\n");
    print("    Speedup: "); print_dec(sw_time / hw_time); print("x FASTER\n");

    // --- TEST 2: CRC-32 ---
    print("\n[2] CRC-32 (Input: 0xDEADBEEF)\n");
    CRC_POLY = 0xEDB88320; 

    // HW
    start = get_cycles();
    CRC_DATA = 0xDEADBEEF;   
    hw_res = CRC_DATA;       
    end = get_cycles();
    hw_time = end - start;

    // SW
    start = get_cycles();
    sw_res = sw_crc32(0xDEADBEEF, 0xEDB88320);
    end = get_cycles();
    sw_time = end - start;

    if (hw_res == sw_res) print("    STATUS: ACCURACY VERIFIED (MATCH)\n");
    else print("    STATUS: FAILURE (MISMATCH)\n");

    print("    HW Cycles: "); print_dec(hw_time); print("\n");
    print("    SW Cycles: "); print_dec(sw_time); print("\n");
    print("    Speedup: "); print_dec(sw_time / hw_time); print("x FASTER\n");
}

// --- Parsers ---
char get_first_char() {
    char c;
    while (1) {
        c = getchar();
        if (c == 0) return 0;
        if (c != '\n' && c != '\r' && c != ' ') break; 
    }
    return c;
}

int32_t scan_dec_signed() {
    char c;
    int32_t num = 0;
    int sign = 1;
    
    c = get_first_char();
    if (c == 0) return -999;

    putchar(c);
    if (c == '-') sign = -1;
    else if (c >= '0' && c <= '9') num = c - '0';
    else return 0;

    while (1) {
        c = getchar();
        if (c < '0' || c > '9') break;
        putchar(c);
        num = num * 10 + (c - '0');
    }
    putchar('\n');
    return num * sign;
}

uint32_t scan_hex() {
    char c = get_first_char();
    if (c == 0) return 0;
    putchar(c);
    uint32_t num = 0;
    if (c >= '0' && c <= '9') num = c - '0';
    else if (c >= 'A' && c <= 'F') num = c - 'A' + 10;
    else if (c >= 'a' && c <= 'f') num = c - 'a' + 10;

    while (1) {
        c = getchar();
        if ((c < '0' || c > '9') && (c < 'A' || c > 'F') && (c < 'a' || c > 'f')) break;
        putchar(c);
        if (c >= '0' && c <= '9') num = (num<<4) + (c - '0');
        else if (c >= 'A' && c <= 'F') num = (num<<4) + (c - 'A' + 10);
        else if (c >= 'a' && c <= 'f') num = (num<<4) + (c - 'a' + 10);
    }
    putchar('\n');
    return num;
}

uint32_t poly_builder() {
    uint32_t poly = 0;
    print(">> Enter exponents (type -1 to Finish).\n");
    while(1) {
        print("   Expt > ");
        int32_t exp = scan_dec_signed();
        if (exp == -999) break; 
        if (exp == -1) break; 
        
        if (exp >= 0 && exp < 32) {
            poly |= (1 << exp); 
            print("   (Added x^"); print_dec(exp); print(")\n");
        }
    }
    return poly;
}

// --- Main ---
void main() {
    sim_idx = 0; 
    while(1) {
        print("\nMENU:\n [5] Run Audit\n [q] Quit\n> ");
        print("\nMENU:\n [1] FPSQRT\n [2] CRC-32 Calc\n [3] CRC-32 Config (Hex)\n [4] CRC-32 Config (Builder)\n [5] Run Audit\n [q] Quit\n> ");
        char choice = getchar();
        if (choice == 0) break;
        if (choice == '\n' || choice == '\r') continue;
        putchar(choice); print("\n");

        if (choice == '5') run_benchmark();
        else if (choice == 'q') break;
        if (choice == '1') {
            print("Enter Number: ");
            FPSQRT_REG = (uint32_t)scan_dec_signed();
            for(volatile int i=0; i<10; i++);
            print("Result: "); print_dec(FPSQRT_REG); print("\n");
        } else if (choice == '2') {
            print("Enter Data (Hex): ");
            CRC_DATA = scan_hex();
            for(volatile int i=0; i<10; i++);
            print("Checksum: "); print_hex(CRC_DATA); print("\n");
        } else if (choice == '3') {
            print("Enter Poly (Hex): ");
            CRC_POLY = scan_hex();
            print("Updated.\n");
        } else if (choice == '4') {
            uint32_t new_poly = poly_builder();
            print("Calculated Poly Hex: "); print_hex(new_poly); print("\n");
            CRC_POLY = new_poly;
            print("Updated.\n");
        } else if (choice == '5') {
            run_benchmark();
        } else if (choice == 'q') {
            break;
        }
    }
    print("Done.\n");
    while(1);
}

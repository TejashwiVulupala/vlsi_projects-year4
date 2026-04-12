`timescale 1 ns / 1 ps

module system (
    input clk,
    input resetn,
    output trap,
    output reg [7:0] uart_out_data,
    output reg uart_out_valid
);
    wire mem_valid, mem_instr;
    wire [31:0] mem_addr, mem_wdata;
    wire [3:0] mem_wstrb;
    
    reg mem_ready;
    reg [31:0] mem_rdata;

    // Address Decoding [cite: 29]
    wire sel_uart = (mem_addr[31:28] == 4'h2);
    wire sel_sqrt = (mem_addr[31:28] == 4'h4); 
    wire sel_crc  = (mem_addr[31:28] == 4'h6); 
    wire sel_ram  = (mem_addr[31:28] == 4'h0);

    // --- Synchronous RAM [cite: 30, 31] ---
    reg [31:0] memory [0:4095];
    reg [31:0] ram_rdata_q;
    reg ram_ready_q;

    always @(posedge clk) begin
        if (!resetn) begin
            ram_ready_q <= 0;
        end else begin
            if (mem_valid && sel_ram) begin
                if (mem_wstrb[0]) memory[mem_addr[13:2]][7:0]   <= mem_wdata[7:0];
                if (mem_wstrb[1]) memory[mem_addr[13:2]][15:8]  <= mem_wdata[15:8];
                if (mem_wstrb[2]) memory[mem_addr[13:2]][23:16] <= mem_wdata[23:16];
                if (mem_wstrb[3]) memory[mem_addr[13:2]][31:24] <= mem_wdata[31:24];
                ram_rdata_q <= memory[mem_addr[13:2]];
                ram_ready_q <= 1;
            end else begin
                ram_ready_q <= 0;
            end
        end
    end

    // --- Registered Peripheral Mux [cite: 36, 37] ---
    wire [31:0] rdata_sqrt, rdata_crc;
    wire ready_sqrt, ready_crc;
    reg [31:0] peri_rdata_q;
    reg peri_ready_q;

    always @(posedge clk) begin
        if (!resetn) begin
            peri_rdata_q <= 0;
            peri_ready_q <= 0;
        end else begin
            peri_ready_q <= 0;
            if (mem_valid && !mem_ready) begin
                if (sel_sqrt) begin
                    peri_rdata_q <= rdata_sqrt;
                    peri_ready_q <= ready_sqrt;
                end else if (sel_crc) begin
                    peri_rdata_q <= rdata_crc;
                    peri_ready_q <= ready_crc;
                end else if (sel_uart) begin
                    peri_rdata_q <= 32'h0;
                    peri_ready_q <= 1'b1;
                end
            end
        end
    end

    // --- Final CPU Interface [cite: 42, 43, 44] ---
    always @(*) begin
        if (sel_ram) begin
            mem_rdata = ram_rdata_q;
            mem_ready = ram_ready_q;
        end else begin
            mem_rdata = peri_rdata_q;
            mem_ready = peri_ready_q;
        end
    end

    // UART Output [cite: 45, 46]
    always @(posedge clk) begin
        uart_out_valid <= 0;
        if (resetn && mem_valid && sel_uart && |mem_wstrb) begin
            uart_out_data <= mem_wdata[7:0];
            uart_out_valid <= 1;
        end
    end

    // Instance Connections [cite: 47, 48]
    my_axi_fpsqrt u_sqrt (.clk(clk), .resetn(resetn), .sel(sel_sqrt && mem_valid), .we(|mem_wstrb), .addr(mem_addr[3:0]), .wdata(mem_wdata), .rdata(rdata_sqrt), .ready_out(ready_sqrt));
    my_axi_crc32  u_crc  (.clk(clk), .resetn(resetn), .sel(sel_crc && mem_valid),  .we(|mem_wstrb), .addr(mem_addr[4:0]), .wdata(mem_wdata), .rdata(rdata_crc),  .ready_out(ready_crc));
    
    picorv32 #( .ENABLE_COUNTERS(1), .BARREL_SHIFTER(1), .ENABLE_MUL(1), .ENABLE_DIV(1) ) cpu (
        .clk(clk), .resetn(resetn), .trap(trap),
        .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata)
    );
endmodule
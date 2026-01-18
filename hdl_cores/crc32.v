`timescale 1 ns / 1 ps

module crc32 (
    input wire clk,
    input wire resetn,
    input wire valid,
    input wire [31:0] wdata,
    input wire addr_bit, // 0 = Data (0x60000000), 1 = Poly (0x60000004)
    output reg ready,
    output reg [31:0] rdata
);
    // Registers
    reg [31:0] poly_reg; 
    reg [31:0] crc_reg;
    reg [31:0] temp_crc; 
    integer i;

    always @(posedge clk) begin
        if (!resetn) begin
            crc_reg  <= 32'hFFFFFFFF;
            poly_reg <= 32'hEDB88320; // Default Ethernet Poly
            ready    <= 0;
            rdata    <= 0;
        end else begin
            // Transaction Start
            if (valid && !ready) begin
                if (addr_bit) begin
                    // RECONFIGURATION: Change the Polynomial
                    poly_reg <= wdata;
                end else begin
                    // CALCULATION: Update CRC or Reset
                    if (wdata == 0) begin
                        crc_reg <= 32'hFFFFFFFF; // Reset
                    end else begin
                        // 1-Cycle CRC32 Engine
                        temp_crc = crc_reg ^ wdata;
                        for (i = 0; i < 32; i = i + 1) begin
                            if (temp_crc[0]) temp_crc = (temp_crc >> 1) ^ poly_reg;
                            else temp_crc = temp_crc >> 1;
                        end
                        crc_reg <= temp_crc;
                    end
                end
                // Acknowledge Transaction
                ready <= 1;
            end

            // Handshake Complete
            if (ready && !valid) ready <= 0;
            
            // Output
            rdata <= ~crc_reg; 
        end
    end
endmodule
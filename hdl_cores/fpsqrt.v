`timescale 1 ns / 1 ps

module fpsqrt (
    input wire clk,
    input wire resetn,
    input wire valid,
    input wire [31:0] wdata,
    output reg ready,
    output reg [31:0] rdata
);
    reg busy;
    reg [31:0] val;
    reg [31:0] root;
    reg [31:0] bit_mask;

    always @(posedge clk) begin
        if (!resetn) begin
            ready <= 0;
            busy <= 0;
            rdata <= 0;
            val <= 0;
            root <= 0;
            bit_mask <= 0;
        end else begin
            // Start Command: Only start if valid and not already busy
            if (valid && !busy && !ready) begin
                busy <= 1;
                val <= wdata;
                root <= 0;
                bit_mask <= 32'h40000000; // Start with the highest power of 4
            end

            // Calculation Logic
            if (busy) begin
                if (bit_mask != 0) begin
                    if (val >= (root | bit_mask)) begin
                        val <= val - (root | bit_mask);
                        root <= (root >> 1) | bit_mask;
                    end else begin
                        root <= root >> 1;
                    end
                    bit_mask <= bit_mask >> 2;
                end else begin
                    // Done
                    busy <= 0;
                    ready <= 1;
                    rdata <= root;
                end
            end

            // Handshake Reset: Drop ready when valid goes low
            if (ready && !valid) ready <= 0;
        end
    end
endmodule
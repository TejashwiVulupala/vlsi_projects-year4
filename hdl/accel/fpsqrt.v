`timescale 1 ns / 1 ps

// ============================================================================
//  ACCELERATOR: Integer Square Root (Iterative)
//  Algorithm: Non-restoring digit recurrence
// ============================================================================
(* DONT_TOUCH = "yes" *)
module fpsqrt (
    input wire clk,
    input wire resetn,
    input wire valid,
    input wire [31:0] wdata,
    output reg ready,
    output reg [31:0] rdata,
    output reg busy
);
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
            // Start Command: Only start if valid, not busy, and handshake not pending
            if (valid && !busy) begin
                busy <= 1;
                ready <= 0;
                val <= wdata;
                root <= 0;
                bit_mask <= 32'h40000000; // 1 << 30 (Corresponds to bit 15 of root)
                $display("FPSQRT: Started calculation for %d", wdata);
            end

            // Calculation Logic
            if (busy) begin
                if (bit_mask != 0) begin
                    // Iterative digit-recurrence algorithm
                    if (val >= (root | bit_mask)) begin
                        val <= val - (root | bit_mask); // Subtract
                        root <= (root >> 1) | bit_mask; // Add bit to root
                    end else begin
                        root <= root >> 1; // Shift root
                    end
                    bit_mask <= bit_mask >> 2; // Next pair of bits
                end else begin
                    // Done
                    busy <= 0;
                    ready <= 1;
                    rdata <= root;
                    $display("FPSQRT: Finished. Result = %d", root);
                end
            end
        end
    end
endmodule
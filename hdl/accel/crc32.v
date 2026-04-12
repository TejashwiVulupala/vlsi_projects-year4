`timescale 1 ns / 1 ps

// ============================================================================
//  ACCELERATOR: Reconfigurable CRC32
// ============================================================================
(* DONT_TOUCH = "yes" *)
module crc32 (
    input wire clk,
    input wire resetn,
    input wire start,
    input wire [31:0] data_in,
    input wire [31:0] poly_in,
    input wire [31:0] seed_in,
    output reg [31:0] crc_out,
    output reg done,
    output reg busy
);
    reg [31:0] crc_reg;  // Holds the shifting CRC value
    reg [31:0] data_reg; // Holds the shifting data value
    reg [5:0]  count;    // Iteration counter

    always @(posedge clk) begin
        if (!resetn) begin
            crc_reg <= 0;
            data_reg <= 0;
            busy <= 0;
            done <= 0;
            crc_out <= 0;
        end else begin
            if (start && !busy) begin
                busy <= 1;
                done <= 0;
                // Initialize state to match software algorithm
                crc_reg <= seed_in;
                data_reg <= data_in;
                count <= 0;
            end else if (busy) begin
                if (count < 32) begin
                    // This logic now correctly mirrors the bit-serial C code
                    if ((crc_reg[0] ^ data_reg[0]) == 1'b1)
                        crc_reg <= (crc_reg >> 1) ^ poly_in;
                    else
                        crc_reg <= (crc_reg >> 1);
                    data_reg <= data_reg >> 1; // Process next bit of data
                    count <= count + 1;
                end else begin
                    busy <= 0;
                    done <= 1;
                    crc_out <= ~crc_reg; // Final Inversion
                end
            end else begin
                done <= 0;
            end
        end
    end
endmodule
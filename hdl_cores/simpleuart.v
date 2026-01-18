`timescale 1 ns / 1 ps

module simpleuart (
    input clk,
    input resetn,

    output ser_tx,
    input  ser_rx,

    input  [3:0] reg_div_we,
    input  [31:0] reg_div_di,
    output [31:0] reg_div_do,

    input  [3:0] reg_dat_we,
    input  [31:0] reg_dat_di,
    output [31:0] reg_dat_do,
    output reg_dat_wait
);
    reg [31:0] cfg_divider;

    reg [3:0] recv_state;
    reg [31:0] recv_divcnt;
    reg [7:0] recv_pattern;
    reg [7:0] recv_buf_data;
    reg recv_buf_valid;

    reg [9:0] send_pattern;
    reg [3:0] send_bitcnt;
    reg [31:0] send_divcnt;
    reg send_dummy;

    assign reg_div_do = cfg_divider;

    assign reg_dat_wait = (reg_dat_we[0] && send_bitcnt) || (reg_dat_we[2] && !recv_buf_valid); // Wait if sending OR if no data to read
    assign reg_dat_do = recv_buf_data;

    always @(posedge clk) begin
        if (!resetn) begin
            cfg_divider <= 1;
            recv_state <= 0;
            recv_divcnt <= 0;
            recv_pattern <= 0;
            recv_buf_data <= 0;
            recv_buf_valid <= 0;
            send_pattern <= ~0;
            send_bitcnt <= 0;
            send_divcnt <= 0;
            send_dummy <= 1;
        end else begin
            // --- Configuration (Baud Rate) ---
            if (reg_div_we) cfg_divider <= reg_div_di;

            // --- Receiver Logic ---
            recv_divcnt <= recv_divcnt + 1;
            if (reg_dat_we[2]) recv_buf_valid <= 0; // Clear valid flag on read

            case (recv_state)
                0: begin
                    if (!ser_rx) begin
                        recv_state <= 1;
                        recv_divcnt <= 0;
                    end
                end
                1: begin
                    if (2*recv_divcnt > cfg_divider) begin
                        recv_state <= 2;
                        recv_divcnt <= 0;
                    end
                end
                10: begin
                    if (recv_divcnt > cfg_divider) begin
                        recv_buf_data <= recv_pattern;
                        recv_buf_valid <= 1;
                        recv_state <= 0;
                    end
                end
                default: begin
                    if (recv_divcnt > cfg_divider) begin
                        recv_pattern <= {ser_rx, recv_pattern[7:1]};
                        recv_state <= recv_state + 1;
                        recv_divcnt <= 0;
                    end
                end
            endcase

            // --- Transmitter Logic ---
            send_divcnt <= send_divcnt + 1;
            if (reg_dat_we[0] && !send_bitcnt) begin
                send_pattern <= {1'b1, reg_dat_di[7:0], 1'b0};
                send_bitcnt <= 10;
                send_divcnt <= 0;
            end else if (send_divcnt > cfg_divider && send_bitcnt) begin
                send_pattern <= {1'b1, send_pattern[9:1]};
                send_bitcnt <= send_bitcnt - 1;
                send_divcnt <= 0;
            end
        end
    end

    assign ser_tx = send_pattern[0];

endmodule
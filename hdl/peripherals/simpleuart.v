module simpleuart (
	input clk,
	input resetn,

	output ser_tx,
	input  ser_rx,

	input   [3:0] reg_div_we,
	input  [31:0] reg_div_di,
	output [31:0] reg_div_do,

	input   [3:0] reg_dat_we,
	input  [31:0] reg_dat_di,
	output [31:0] reg_dat_do,
	output        reg_dat_wait,
	output        reg_tx_busy
);
	reg [31:0] cfg_divider;
	reg [31:0] recv_divcnt;
	reg [3:0] recv_state;
	reg [7:0] recv_pattern;
	reg [7:0] recv_buf_data;
	reg recv_buf_valid;
	reg [9:0] send_pattern;
	reg [3:0] send_bitcnt;
	reg [31:0] send_divcnt;
	reg send_dummy;

	assign reg_div_do = cfg_divider;
	assign reg_dat_wait = reg_dat_we && (send_bitcnt || send_dummy);
	assign reg_tx_busy = (send_bitcnt != 0) || send_dummy;
	assign reg_dat_do = recv_buf_valid ? recv_buf_data : ~0;

	always @(posedge clk) begin
		if (!resetn) begin
			cfg_divider <= 1;
			send_pattern <= ~0;
			send_bitcnt <= 0;
			send_divcnt <= 0;
			send_dummy <= 1;
		end else begin
			if (reg_div_we) cfg_divider <= reg_div_di;
			
			send_divcnt <= send_divcnt + 1;
			if (reg_dat_we && !send_bitcnt && !send_dummy) begin
				send_pattern <= {1'b1, reg_dat_di[7:0], 1'b0};
				send_bitcnt <= 10;
				send_divcnt <= 0;
			end else if (send_divcnt > cfg_divider && send_bitcnt) begin
				send_pattern <= {1'b1, send_pattern[9:1]};
				send_bitcnt <= send_bitcnt - 1;
				send_divcnt <= 0;
			end else if (send_divcnt > cfg_divider && send_dummy) begin
				send_dummy <= 0;
				send_divcnt <= 0;
			end
		end
	end
	assign ser_tx = send_pattern[0];
endmodule
module axi_simpleuart (
    input wire clk, resetn,
    input wire axi_awvalid, axi_wvalid, axi_arvalid, axi_rready, axi_bready,
    output wire axi_awready, axi_wready, axi_arready,
    output reg axi_rvalid, axi_bvalid,
    input wire [31:0] axi_awaddr, axi_wdata,
    input wire [3:0] axi_wstrb,
    input wire [31:0] axi_araddr,
    output wire [31:0] axi_rdata,
    output wire ser_tx, input wire ser_rx
);
    wire [31:0] reg_div_do, reg_dat_do;
    wire reg_tx_busy;

    // KEY FIX: Only accept write if UART is NOT busy. This is the hardware flow control.
    assign axi_awready = axi_awvalid && axi_wvalid && !axi_bvalid && !reg_tx_busy;
    assign axi_wready  = axi_awready;
    assign axi_arready = axi_arvalid && !axi_rvalid;

    // Connect to your simpleuart core
    simpleuart simpleuart_inst (
        .clk(clk), .resetn(resetn), .ser_tx(ser_tx), .ser_rx(ser_rx),
        .reg_div_we((axi_awready && axi_awaddr[3:0] == 4'h4) ? axi_wstrb : 4'b0),
        .reg_div_di(axi_wdata), .reg_div_do(reg_div_do),
        .reg_dat_we((axi_awready && axi_awaddr[3:0] == 4'h0) ? 4'b1111 : 4'b0),
        .reg_dat_di(axi_wdata), .reg_dat_do(reg_dat_do), .reg_tx_busy(reg_tx_busy)
    );

    always @(posedge clk) begin
        if (!resetn) {axi_bvalid, axi_rvalid} <= 0;
        else begin
            if (axi_awready) axi_bvalid <= 1;
            else if (axi_bvalid && axi_bready) axi_bvalid <= 0;

            if (axi_arready) axi_rvalid <= 1;
            else if (axi_rvalid && axi_rready) axi_rvalid <= 0;
        end
    end
    assign axi_rdata = (axi_araddr[3:0] == 4'h0) ? reg_dat_do : reg_div_do;
endmodule
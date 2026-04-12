module axi_ram (
    input wire clk, resetn,
    input wire axi_awvalid, axi_wvalid, axi_arvalid, axi_rready, axi_bready,
    output reg axi_awready, axi_wready, axi_arready, axi_rvalid, axi_bvalid,
    input wire [31:0] axi_awaddr, axi_wdata, axi_araddr,
    input wire [3:0] axi_wstrb,
    output reg [31:0] axi_rdata
);
    reg [31:0] mem [0:4095];

    always @(posedge clk) begin
        if (!resetn) begin
            {axi_awready, axi_wready, axi_arready, axi_rvalid, axi_bvalid} <= 0;
        end else begin
            // Default Ready for new transactions
            axi_awready <= !axi_bvalid; 
            axi_wready  <= !axi_bvalid;
            axi_arready <= !axi_rvalid;

            // Write Logic
            if (axi_awvalid && axi_wvalid && axi_awready) begin
                if (axi_wstrb[0]) mem[axi_awaddr[13:2]][7:0]   <= axi_wdata[7:0];
                if (axi_wstrb[1]) mem[axi_awaddr[13:2]][15:8]  <= axi_wdata[15:8];
                if (axi_wstrb[2]) mem[axi_awaddr[13:2]][23:16] <= axi_wdata[23:16];
                if (axi_wstrb[3]) mem[axi_awaddr[13:2]][31:24] <= axi_wdata[31:24];
                axi_bvalid <= 1;
            end else if (axi_bvalid && axi_bready) axi_bvalid <= 0;

            // Read Logic
            if (axi_arvalid && axi_arready) begin
                axi_rdata  <= mem[axi_araddr[13:2]];
                axi_rvalid <= 1;
            end else if (axi_rvalid && axi_rready) axi_rvalid <= 0;
        end
    end
endmodule
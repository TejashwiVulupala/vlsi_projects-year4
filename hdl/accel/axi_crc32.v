module my_axi_crc32 (
    input clk, resetn, sel, we,
    input [4:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata,
    output reg ready_out
);
    // ALL signals declared BEFORE use to satisfy the synthesizer
    reg [31:0] data_in, poly, seed;
    reg start, done_latch;
    wire [31:0] crc_out;
    wire done, busy;

    // Core Instance
    crc32 core_inst (
        .clk(clk), .resetn(resetn), .start(start),
        .data_in(data_in), .poly_in(poly), .seed_in(seed),
        .crc_out(crc_out), .done(done), .busy(busy)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            rdata <= 0; ready_out <= 0; start <= 0; done_latch <= 0;
            poly <= 32'hEDB88320; seed <= 32'hFFFFFFFF; data_in <= 0;
        end else begin
            start <= 0; 
            ready_out <= sel; 
            if (done) done_latch <= 1;

            if (sel) begin
                if (we) begin
                    case (addr)
                        5'h00: data_in <= wdata;
                        5'h08: begin start <= wdata[0]; if (wdata[0]) done_latch <= 0; end
                        5'h0C: poly <= wdata;
                        5'h10: seed <= wdata;
                    endcase
                end else begin
                    case (addr)
                        5'h04: rdata <= crc_out;
                        5'h08: rdata <= {30'b0, (done | done_latch), busy};
                        5'h0C: rdata <= poly;
                        5'h10: rdata <= seed;
                        default: rdata <= 32'b0;
                    endcase
                end
            end
        end
    end
endmodule
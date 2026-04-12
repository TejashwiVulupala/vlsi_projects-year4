module my_axi_fpsqrt (
    input clk, resetn, sel, we,
    input [3:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata,
    output reg ready_out 
);
    reg [31:0] reg_input;
    wire [31:0] core_result;
    wire core_ready, core_busy;
    reg core_valid;

    fpsqrt_final core (
        .clk(clk), .resetn(resetn), .valid(core_valid),
        .wdata(reg_input), .ready(core_ready), .rdata(core_result), .busy(core_busy)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            rdata <= 0; ready_out <= 0; reg_input <= 0; core_valid <= 0;
        end else begin
            core_valid <= 0; 
            
            if (sel) begin
                if (we) begin
                    ready_out <= 1'b1;
                    case (addr)
                        4'h0: reg_input <= wdata;
                        4'h8: if (wdata[0]) core_valid <= 1'b1;
                    endcase
                end else begin
                    case (addr)
                        4'h0: begin rdata <= reg_input; ready_out <= 1'b1; end
                        4'h4: begin 
                                rdata <= core_result; 
                                ready_out <= core_ready; // Stall AXI until math finishes
                              end
                        4'h8: begin rdata <= {30'b0, core_ready, core_busy}; ready_out <= 1'b1; end
                        default: begin rdata <= 32'h0; ready_out <= 1'b1; end
                    endcase
                end
            end else begin
                ready_out <= 1'b0;
            end
        end
    end
endmodule
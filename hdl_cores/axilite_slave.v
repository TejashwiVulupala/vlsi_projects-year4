`timescale 1 ns / 1 ps

/**
 * AXI-Lite Slave to Memory-Mapped Bridge
 * 
 * This module converts AXI-Lite slave protocol to simple memory-mapped interface
 * suitable for PicoRV32 interconnection.
 * 
 * AXI-Lite Channels:
 *   - Write Address Channel (AWADDR, AWVALID, AWREADY)
 *   - Write Data Channel (WDATA, WSTRB, WVALID, WREADY)
 *   - Write Response Channel (BRESP, BVALID, BREADY)
 *   - Read Address Channel (ARADDR, ARVALID, ARREADY)
 *   - Read Data Channel (RDATA, RRESP, RVALID, RREADY)
 * 
 * Memory-Mapped Output:
 *   - mem_addr, mem_wdata, mem_rdata, mem_wstrb
 *   - mem_valid, mem_ready
 */

module axilite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    // AXI-Lite Clock and Reset
    input wire clk,
    input wire resetn,
    
    // ===== AXI-Lite Write Address Channel =====
    input wire [ADDR_WIDTH-1:0] awaddr,
    input wire [2:0] awprot,        // Unused in this implementation
    input wire awvalid,
    output wire awready,
    
    // ===== AXI-Lite Write Data Channel =====
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [(DATA_WIDTH/8)-1:0] wstrb,
    input wire wvalid,
    output wire wready,
    
    // ===== AXI-Lite Write Response Channel =====
    output wire [1:0] bresp,
    output wire bvalid,
    input wire bready,
    
    // ===== AXI-Lite Read Address Channel =====
    input wire [ADDR_WIDTH-1:0] araddr,
    input wire [2:0] arprot,        // Unused in this implementation
    input wire arvalid,
    output wire arready,
    
    // ===== AXI-Lite Read Data Channel =====
    output wire [DATA_WIDTH-1:0] rdata,
    output wire [1:0] rresp,
    output wire rvalid,
    input wire rready,
    
    // ===== Memory-Mapped Interface (to accelerators) =====
    // Output to peripheral side
    output wire [ADDR_WIDTH-1:0] mem_addr,
    output wire [DATA_WIDTH-1:0] mem_wdata,
    output wire [(DATA_WIDTH/8)-1:0] mem_wstrb,
    output wire mem_valid,
    output wire mem_write,              // 1=write, 0=read
    
    // Input from peripheral side
    input wire [DATA_WIDTH-1:0] mem_rdata,
    input wire mem_ready
);

    // FSM States for AXI-Lite Protocol Handling
    localparam IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam READ_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    reg [1:0] state, next_state;
    
    // Internal registers
    reg [ADDR_WIDTH-1:0] write_addr_reg;
    reg [ADDR_WIDTH-1:0] read_addr_reg;
    reg [DATA_WIDTH-1:0] write_data_reg;
    reg [(DATA_WIDTH/8)-1:0] write_strb_reg;
    reg [DATA_WIDTH-1:0] read_data_reg;
    
    // Transaction flags
    reg write_addr_valid;
    reg write_data_valid;
    reg read_addr_valid;
    
    // ===== Write Address Channel Handling =====
    always @(posedge clk) begin
        if (!resetn) begin
            write_addr_reg <= 0;
            write_addr_valid <= 1'b0;
        end else begin
            if (awvalid && awready) begin
                write_addr_reg <= awaddr;
                write_addr_valid <= 1'b1;
            end else if (write_addr_valid && write_data_valid && mem_ready) begin
                write_addr_valid <= 1'b0;
            end
        end
    end
    
    // ===== Write Data Channel Handling =====
    always @(posedge clk) begin
        if (!resetn) begin
            write_data_reg <= 0;
            write_strb_reg <= 0;
            write_data_valid <= 1'b0;
        end else begin
            if (wvalid && wready) begin
                write_data_reg <= wdata;
                write_strb_reg <= wstrb;
                write_data_valid <= 1'b1;
            end else if (write_addr_valid && write_data_valid && mem_ready) begin
                write_data_valid <= 1'b0;
            end
        end
    end
    
    // ===== Read Address Channel Handling =====
    always @(posedge clk) begin
        if (!resetn) begin
            read_addr_reg <= 0;
            read_addr_valid <= 1'b0;
        end else begin
            if (arvalid && arready) begin
                read_addr_reg <= araddr;
                read_addr_valid <= 1'b1;
            end else if (read_addr_valid && mem_ready) begin
                read_addr_valid <= 1'b0;
            end
        end
    end
    
    // ===== Read Data Channel Handling =====
    always @(posedge clk) begin
        if (!resetn) begin
            read_data_reg <= 0;
        end else begin
            if (read_addr_valid && mem_ready) begin
                read_data_reg <= mem_rdata;
            end
        end
    end
    
    // ===== Main FSM =====
    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                // Priority: Write > Read
                if (write_addr_valid && write_data_valid) begin
                    next_state = WRITE_DATA;
                end else if (read_addr_valid) begin
                    next_state = READ_DATA;
                end
            end
            
            WRITE_DATA: begin
                if (mem_ready) begin
                    next_state = WRITE_RESP;
                end
            end
            
            READ_DATA: begin
                if (mem_ready) begin
                    next_state = IDLE;
                end
            end
            
            WRITE_RESP: begin
                if (bready) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // ===== Output Generation: Memory-Mapped Interface =====
    
    // Memory address: select write or read address based on state
    assign mem_addr = (state == WRITE_DATA) ? write_addr_reg : read_addr_reg;
    
    // Memory write data and strobes
    assign mem_wdata = write_data_reg;
    assign mem_wstrb = (state == WRITE_DATA) ? write_strb_reg : 4'b0000;
    
    // Memory operation type
    assign mem_write = (state == WRITE_DATA) ? 1'b1 : 1'b0;
    
    // Memory transaction valid
    assign mem_valid = (state == WRITE_DATA || state == READ_DATA) ? 1'b1 : 1'b0;
    
    // ===== AXI-Lite Output Signals =====
    
    // Write Address Ready: Accept when not in middle of transaction
    assign awready = (state == IDLE || state == WRITE_RESP) && !write_addr_valid;
    
    // Write Data Ready: Accept when write address already captured
    assign wready = (state == IDLE && write_addr_valid && !write_data_valid) ? 1'b1 : 1'b0;
    
    // Write Response Valid and Payload
    assign bvalid = (state == WRITE_RESP) ? 1'b1 : 1'b0;
    assign bresp = 2'b00;  // OKAY response
    
    // Read Address Ready: Accept when not busy
    assign arready = (state == IDLE) && !read_addr_valid;
    
    // Read Data Valid and Payload (returned immediately after mem_ready)
    assign rvalid = (state == IDLE && read_addr_valid == 1'b0) ? 1'b1 : 1'b0;
    assign rdata = read_data_reg;
    assign rresp = 2'b00;  // OKAY response

endmodule

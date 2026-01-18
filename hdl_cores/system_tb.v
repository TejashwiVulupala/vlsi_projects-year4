`timescale 1 ns / 1 ps

module system_tb;
    reg clk = 0;
    reg resetn = 0;
    wire trap;
    wire ser_tx;
    reg ser_rx = 1;

    // Generate Clock (100MHz = 10ns period)
    always #5 clk = ~clk;

    // Instantiate System
    system uut (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        .ser_tx(ser_tx),
        .ser_rx(ser_rx)
    );

    initial begin
        // --- Waveform Dumping ---
        $dumpfile("system.vcd");
        $dumpvars(0);
        $dumpvars(0, system_tb);
        // ------------------------

        // 1. Reset Sequence
        resetn = 0;
        #20;
        resetn = 1; // Release Reset

        // 2. Run Simulation
        // We give the CPU 5,000,000 ns (5ms) to run the program.
        #5000000;
        
        // 3. Finish
        $display("\n--- Simulation Timeout (This is normal) ---");
        $finish;
    end
endmodule

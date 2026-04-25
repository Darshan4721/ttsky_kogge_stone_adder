`default_nettype none
`timescale 1ns / 1ps

module tb ();

    // Signal declarations
    reg clk;
    reg rst_n;
    reg ena;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // 1. Instantiate the Unit Under Test (UUT)
    tt_um_example uut (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );

    // 2. Clock Generation (10MHz)
    always #50 clk = ~clk;

    // 3. Test Procedure
    initial begin
        // Setup Waveform Dumping
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        // Initialize signals
        clk = 0;
        rst_n = 0;
        ena = 1;
        ui_in = 8'h00;
        uio_in = 8'h00;

        // Hold reset for 100ns
        #100;
        rst_n = 1;
        
        // --- TEST CASE 1: 15 + 10 = 25 ---
        
        // Cycle 0: Load A (Input A = 15, Cin = 0)
        @(posedge clk);
        ui_in  = 8'd15; 
        uio_in = 8'd0;  
        $display("Cycle 0: Loading A = %d", ui_in);

        // Cycle 1: Load B (Input B = 10)
        @(posedge clk);
        ui_in = 8'd10;
        $display("Cycle 1: Loading B = %d", ui_in);

        // Cycle 2: Observe Sum
        @(posedge clk);
        #1; // Wait for logic to settle
        $display("Cycle 2: Output Sum = %d (Expected 25)", uo_out);

        // Cycle 3: Observe Carry
        @(posedge clk);
        #1;
        $display("Cycle 3: Output Carry = %d (Expected 0)", uo_out[0]);

        // --- TEST CASE 2: 200 + 100 = 300 (Sum 44, Carry 1) ---
        
        // Cycle 0: Load A
        @(posedge clk);
        ui_in = 8'd200;
        
        // Cycle 1: Load B
        @(posedge clk);
        ui_in = 8'd100;

        // Cycle 2: Observe Sum (300 mod 256 = 44)
        @(posedge clk);
        #1;
        $display("Cycle 2: Output Sum = %d (Expected 44)", uo_out);

        // Cycle 3: Observe Carry
        @(posedge clk);
        #1;
        $display("Cycle 3: Output Carry = %d (Expected 1)", uo_out[0]);

        #100;
        $finish;
    end

endmodule

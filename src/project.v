/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs (Data stream)
    output wire [7:0] uo_out,   // Dedicated outputs (Data stream)
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // FSM State Definitions
    localparam S_LOAD_A    = 2'd0;
    localparam S_LOAD_B    = 2'd1;
    localparam S_OUT_SUM   = 2'd2;
    localparam S_OUT_CARRY = 2'd3;

    reg [1:0] state;
    
    // Internal registers to hold inputs and outputs
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    reg       cin_reg;
    reg [7:0] out_reg;

    // Wires from the adder
    wire [7:0] sum;
    wire       cout;

    // Instantiate the Adder
    kogge_stone_adder #(
        .width(8)
    ) adder_inst (
        .a(a_reg),
        .b(b_reg),
        .cin(cin_reg),
        .sum(sum),
        .cout(cout)
    );

    // FSM and Datapath
    always @(posedge clk) begin
        if (!rst_n) begin
            state   <= S_LOAD_A;
            a_reg   <= 8'd0;
            b_reg   <= 8'd0;
            cin_reg <= 1'b0;
            out_reg <= 8'd0;
        end else begin
            case (state)
                S_LOAD_A: begin
                    a_reg   <= ui_in;         // Grab first 8 bits (A)
                    cin_reg <= uio_in[0];     // Grab Carry-in from IO pin 0
                    state   <= S_LOAD_B;
                end
                S_LOAD_B: begin
                    b_reg   <= ui_in;         // Grab second 8 bits (B)
                    state   <= S_OUT_SUM;
                end
                S_OUT_SUM: begin
                    out_reg <= sum;           // Output the 8-bit sum
                    state   <= S_OUT_CARRY;
                end
                S_OUT_CARRY: begin
                    out_reg <= {7'b0, cout};  // Output the carry out (LSB)
                    state   <= S_LOAD_A;      // Loop back to start
                end
                default: state <= S_LOAD_A;
            endcase
        end
    end

    // Assign registered output to the dedicated output pins
    assign uo_out  = out_reg;
    
    // Set all bidirectional IOs to inputs to be safe
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // List all unused inputs to prevent Verilog warnings
    wire _unused = &{ena, uio_in[7:1]};

endmodule

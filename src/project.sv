/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_ksa_serial (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  parameter WIDTH = 8;

  // Signal mapping
  wire a_sin    = ui_in[0];
  wire b_sin    = ui_in[1];
  wire cin_in   = ui_in[2];
  wire shift_en = ui_in[3];
  wire load_en  = ui_in[4];

  // Registers
  reg [WIDTH-1:0] sipo_a;
  reg [WIDTH-1:0] sipo_b;
  reg [WIDTH-1:0] piso_sum;
  reg cout_reg;

  // Internal KSA wires
  wire [WIDTH-1:0] ksa_sum;
  wire ksa_cout;

  // Instantiate Kogge-Stone Adder
  kogge_stone_adder #(
      .width(WIDTH)
  ) ksa_inst (
      .a(sipo_a),
      .b(sipo_b),
      .cin(cin_in),
      .sum(ksa_sum),
      .cout(ksa_cout)
  );

  // Shift Register Logic
  always @(posedge clk) begin
    if (!rst_n) begin
      sipo_a   <= 0;
      sipo_b   <= 0;
      piso_sum <= 0;
      cout_reg <= 0;
    end else begin
      if (load_en) begin
        piso_sum <= ksa_sum;
        cout_reg <= ksa_cout;
      end else if (shift_en) begin
        // Shift right to support LSB-first serial communication
        sipo_a   <= {a_sin, sipo_a[WIDTH-1:1]};
        sipo_b   <= {b_sin, sipo_b[WIDTH-1:1]};
        piso_sum <= {1'b0, piso_sum[WIDTH-1:1]};
      end
    end
  end

  // Output assignments
  assign uo_out[0] = piso_sum[0]; // Serial Sum Out
  assign uo_out[1] = cout_reg;    // Registered Carry Out
  assign uo_out[7:2] = 0;

  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in, ui_in[7:5], 1'b0};

endmodule

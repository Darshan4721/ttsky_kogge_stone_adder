`default_nettype none

module kogge_stone_adder #(
    parameter width = 8
)(
    input  wire [width-1:0] a,
    input  wire [width-1:0] b,
    input  wire cin,
    output wire [width-1:0] sum,
    output wire cout
);

    localparam final_stage = 3; // log2(8)=3 (avoid $clog2 issues)

    wire [width-1:0] propagate [0:final_stage];
    wire [width-1:0] gen       [0:final_stage];

    // Stage 0
    wire [width-1:0] gen0_raw;

assign propagate[0] = a ^ b;
assign gen0_raw     = a & b;

// properly include cin without multiple drivers
assign gen[0] = gen0_raw | (propagate[0] & { {width-1{1'b0}}, cin });

    // include cin
    assign gen[0][0] = gen[0][0] | (propagate[0][0] & cin);

    genvar i, j;

    generate
        for (i = 1; i <= final_stage; i = i + 1) begin : stage_loop
            for (j = 0; j < width; j = j + 1) begin : bit_loop
                if (j >= (1 << (i-1))) begin
                    assign gen[i][j] =
                        gen[i-1][j] |
                        (propagate[i-1][j] & gen[i-1][j - (1 << (i-1))]);

                    assign propagate[i][j] =
                        propagate[i-1][j] &
                        propagate[i-1][j - (1 << (i-1))];
                end else begin
                    assign gen[i][j]       = gen[i-1][j];
                    assign propagate[i][j] = propagate[i-1][j];
                end
            end
        end
    endgenerate

    // Sum
    assign sum[0] = propagate[0][0] ^ cin;

    assign sum[width-1:1] =
        propagate[0][width-1:1] ^
        gen[final_stage][width-2:0];

    assign cout = gen[final_stage][width-1];

endmodule

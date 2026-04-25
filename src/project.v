`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Control
    wire serial_in = ui_in[0];
    wire sel_ab    = ui_in[1]; // 0=A, 1=B
    wire load      = ui_in[2];
    wire start     = ui_in[3];

    // Registers
    reg [7:0] A, B;
    reg [7:0] result;
    reg [2:0] count;
    reg busy;

    wire [7:0] sum;
    wire cout;

    // Instantiate KSA
    kogge_stone_adder #(.width(8)) ksa (
        .a(A),
        .b(B),
        .cin(1'b0),
        .sum(sum),
        .cout(cout)
    );

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A <= 0;
            B <= 0;
            result <= 0;
            count <= 0;
            busy <= 0;
        end else begin

            // Load serially
            if (load) begin
                if (sel_ab == 0)
                    A <= {serial_in, A[7:1]};
                else
                    B <= {serial_in, B[7:1]};
            end

            // Start computation
            if (start && !busy) begin
                result <= sum;
                busy <= 1;
                count <= 0;
            end

            // Shift out result
            if (busy) begin
                result <= {1'b0, result[7:1]};
                count <= count + 1;

                if (count == 7)
                    busy <= 0;
            end
        end
    end

    // Serial output
    assign uo_out[0] = result[0];

    // Unused outputs
    assign uo_out[7:1] = 0;
    assign uio_out = 0;
    assign uio_oe  = 0;

    wire _unused = &{ena, uio_in, 1'b0};

endmodule

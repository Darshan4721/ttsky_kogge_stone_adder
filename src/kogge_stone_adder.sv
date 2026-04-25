`default_nettype none

module kogge_stone_adder #(
    parameter width = 8
) (
    input  logic [width-1:0] a, b,
    input  logic             cin,
    output logic [width-1:0] sum,
    output logic             cout
);

    localparam final_stage = $clog2(width);

    logic [width - 1:0] propagate [final_stage:0];
    logic [width - 1:0] gen       [final_stage:0];

    // stage - 1 
    assign propagate [0] = a ^ b;                                                
    assign gen [0][0] = (a[0] & b[0]) | (propagate[0][0] & cin);               
    // FIX: Changed index from [width-1:0] to [width-1:1] to prevent multiple drivers on bit 0
    assign gen [0][width-1:1] = a[width-1:1] & b[width-1:1];          

    // stage - 2
    genvar current_stage, bit_position;

    generate
        for (current_stage = 1; current_stage <= final_stage; current_stage++) begin : stage_loop
            localparam int jump = 1 << (current_stage - 1);
            for (bit_position = 0; bit_position < width; bit_position++) begin : calculation_loop 
                if (bit_position >= jump) begin       
                    assign gen [current_stage][bit_position] = gen [current_stage - 1][bit_position] | (propagate [current_stage - 1][bit_position] & gen [current_stage - 1][bit_position - jump]);
                    assign propagate [current_stage][bit_position] = propagate [current_stage - 1][bit_position] & propagate [current_stage - 1][bit_position - jump];
                end 
                else begin    
                    assign gen [current_stage][bit_position] = gen [current_stage - 1][bit_position];
                    assign propagate [current_stage][bit_position] = propagate [current_stage - 1][bit_position];
                end
            end
        end
    endgenerate

    // stage - 3
    assign sum [0]             = propagate [0][0] ^ cin;
    assign sum [width - 1 : 1] = propagate [0][width - 1:1] ^ gen [final_stage][width - 2:0];
    assign cout                = gen[final_stage][width - 1];

endmodule

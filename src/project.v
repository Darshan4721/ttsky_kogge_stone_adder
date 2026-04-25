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
        else if (start && !busy) begin
            result <= sum;
            busy <= 1;
            count <= 0;
        end

        // Shift only AFTER start (important fix)
        else if (busy) begin
            result <= {1'b0, result[7:1]};
            count <= count + 1;

            if (count == 7)
                busy <= 0;
        end
    end
end

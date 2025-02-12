module ShiftLatchChain #(
    parameter int VCAM_DEPTH = 64,
    parameter int VCAM_WIDTH = 9
)(
    input   var logic                           vcam_rd_clock_odd,
    input   var logic                           vcam_rd_clock_even,
    input   var logic                           reset,
    output  var logic   [VCAM_WIDTH - 1 : 0]    vcam_mask
);

    // Internal signals
    logic [VCAM_WIDTH : 0]    shift_chain;

    // Generate shift chain using latches
    always_comb begin
        if (reset) begin
            shift_chain = 10'b0;
        end else begin
            shift_chain[9] = (vcam_rd_clock_odd) ? 1'b1 : shift_chain[9];
            shift_chain[7] = (vcam_rd_clock_odd) ? shift_chain[8] : shift_chain[7];
            shift_chain[5] = (vcam_rd_clock_odd) ? shift_chain[6] : shift_chain[5];
            shift_chain[3] = (vcam_rd_clock_odd) ? shift_chain[4] : shift_chain[3];
            shift_chain[1] = (vcam_rd_clock_odd) ? shift_chain[2] : shift_chain[1];

            shift_chain[8] = (vcam_rd_clock_even) ? shift_chain[9] : shift_chain[8];
            shift_chain[6] = (vcam_rd_clock_even) ? shift_chain[7] : shift_chain[6];
            shift_chain[4] = (vcam_rd_clock_even) ? shift_chain[5] : shift_chain[4];
            shift_chain[2] = (vcam_rd_clock_even) ? shift_chain[3] : shift_chain[2];
            shift_chain[0] = (vcam_rd_clock_even) ? shift_chain[1] : shift_chain[0];
        end
    end

    // Generate mask by XORing adjacent bits of shift_chain
    always_comb begin
        for (int i = 0; i < VCAM_WIDTH; i++) begin
            vcam_mask[i] = ~shift_chain[i] & shift_chain[i+1];
        end
    end

endmodule

module CimDecoder #(
    parameter DEPTH = 64
)(
    input CK,
    input [5:0] ADDR, // Since DEPTH=64, we need 6 address bits.
    output [DEPTH-1:0] WRWL
);

    wire [DEPTH-1:0] WL;
    wire [3:0] a01, a23;
    wire [3:0] a45; // Additional wires for handling higher bits.

    assign a01 = {
        ADDR[1] & ADDR[0],
        ADDR[1] & (~ADDR[0]),
        (~ADDR[1]) & ADDR[0],
        (~ADDR[1]) & (~ADDR[0])
    };

    assign a23 = {
        ADDR[3] & ADDR[2],
        ADDR[3] & (~ADDR[2]),
        (~ADDR[3]) & ADDR[2],
        (~ADDR[3]) & (~ADDR[2])
    };

    assign a45 = {
        ADDR[5] & ADDR[4],
        ADDR[5] & (~ADDR[4]),
        (~ADDR[5]) & ADDR[4],
        (~ADDR[5]) & (~ADDR[4])
    };

    genvar i, j, k;
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            for (k = 0; k < 4; k = k + 1) begin
                assign WL[16*i + 4*j + k] = a45[i] & a23[j] & a01[k];
            end
        end
    end

    assign WRWL = CK ? WL : 0;

endmodule

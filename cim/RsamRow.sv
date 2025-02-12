module RsamRow #(
    parameter   int RSAM_DEPTH = 64,
    parameter   int RSAM_WIDTH = 8
)(
    input   var logic [RSAM_WIDTH - 1 : 0] BL, BLN, SL, SLN, SM,
    input   var logic                      WL,
    output  var logic                      MLL
);

    wire [RSAM_WIDTH : 0] ML;
    assign ML[0] = 1'b0;
    for (genvar i = 0; i < RSAM_WIDTH; i += 1) begin: RSAMROW
        RSAM uRSAM(.SL(SL[i]), .SLN(SLN[i]), .SM(SM[i]), .WL(WL), .BLN(BLN[i]), .BL(BL[i]), .MLL(ML[i+1]), .MLR(ML[i]));
    end
    assign MLL = ML[RSAM_WIDTH];
endmodule

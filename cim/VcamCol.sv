module VcamCol #(
    parameter   int VCAM_DEPTH = 64,
    parameter   int VCAM_WIDTH = 9
)(
    input   var logic                       reset,
    input   var logic [VCAM_WIDTH - 1 : 0]  BL, BLN,
    input   var logic                       WL, CKR, ACT, CKRO, CKRE,
    output  var logic                       HOT
);

    logic   [VCAM_WIDTH - 1 : 0]    MASK;   
    wire                            ML;

    ShiftLatchChain#(
            .VCAM_DEPTH(VCAM_DEPTH), 
            .VCAM_WIDTH(VCAM_WIDTH)
        ) uShiftLatchChain(
            .vcam_rd_clock_odd(CKRO),                  
            .vcam_rd_clock_even(CKRE),             
            .reset(reset),              
            .vcam_mask(MASK)                          
        );

    for (genvar i = 0; i < VCAM_WIDTH; i += 1) begin: VCAMCOL
        VCAM uVCAM(.MASK(MASK[i]), .CKR(~CKR), .WL(WL), .BLN(BLN[i]), .BL(BL[i]), .ML(ML));
    end

    RA5T uRA5T(.ML(ML), .CKR(~CKR), .ACT(1'b1), .HOT(HOT));

endmodule

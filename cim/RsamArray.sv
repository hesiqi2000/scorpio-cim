module RsamArray #(
    parameter int RSAM_DEPTH = 64,
    parameter int RSAM_WIDTH = 8,
    parameter int ADDR_WIDTH = $clog2(RSAM_DEPTH)
)(
    input  var logic                                                rsam_wr_clock,
    input  var logic    [RSAM_WIDTH - 1 : 0]                        rsam_sm, rsam_sl, rsam_sln,

    input  var logic    [ADDR_WIDTH - 1 : 0]                        rsam_waddr,
    input  var logic    [RSAM_WIDTH - 1 : 0]                        rsam_wdata,

    output var logic    [RSAM_DEPTH - 1 : 0]                        rsam_out
);

    logic [RSAM_WIDTH - 1 : 0]  DIN, DINB;
    logic [RSAM_WIDTH - 1 : 0]  BL, BLN;
    assign DIN  =  rsam_wdata;
    assign DINB = ~rsam_wdata;

    logic [RSAM_DEPTH - 1 : 0]  BUFFWL;
    logic [RSAM_DEPTH - 1 : 0]  WL;
    
    CimDecoder wr_decoder(.CK(rsam_wr_clock), .ADDR(rsam_waddr), .WRWL(WL));
    CimDecoderBuffer w_buffer(.WRWL(WL),.BUFFWRWL(BUFFWL));

    generate
        for(genvar i = 0; i < RSAM_WIDTH; i += 1) begin:RSAMWRITE
            WD7T uWD7T(.DIN(DIN[i]), .DINB(DINB[i]), .CKW(rsam_wr_clock), .BL(BL[i]), .BLN(BLN[i]));    
        end        
    endgenerate

    generate
        for(genvar i = 0; i < RSAM_DEPTH; i += 1) begin:EXPMEM
            RsamRow uRsamRow(.BL(BL), .BLN(BLN), .SL(rsam_sl), .SLN(rsam_sln), .SM(rsam_sm), .WL(BUFFWL[i]), .MLL(rsam_out[i]));    
        end        
    endgenerate

endmodule: RsamArray





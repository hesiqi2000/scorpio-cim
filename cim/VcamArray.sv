module VcamArray #(
    parameter int VCAM_DEPTH = 64,
    parameter int VCAM_WIDTH = 9,
    parameter int ADDR_WIDTH = $clog2(VCAM_DEPTH)
)(
    input  var logic                                                reset,
    input  var logic                                                vcam_wr_clock,
    input  var logic                                                vcam_rd_clock,
    input  var logic                                                vcam_rd_clock_delay,

    input  var logic    [VCAM_DEPTH - 1 : 0]                        vcam_rd_clock_odd,
    input  var logic    [VCAM_DEPTH - 1 : 0]                        vcam_rd_clock_even,

    input  var logic    [ADDR_WIDTH - 1 : 0]                        vcam_waddr,
    input  var logic    [VCAM_WIDTH - 1 : 0]                        vcam_wdata,

    output var logic    [VCAM_DEPTH - 1 : 0]                        a_out
);

    logic [VCAM_WIDTH - 1 : 0]  DIN, DINB;
    logic [VCAM_WIDTH - 1 : 0]  BL, BLN;
    assign DIN  =  vcam_wdata;
    assign DINB = ~vcam_wdata;

    logic [VCAM_DEPTH - 1 : 0]  BUFFWL;
    logic [VCAM_DEPTH - 1 : 0]  WL;
    
    CimDecoder wr_decoder(.CK(vcam_wr_clock), .ADDR(vcam_waddr), .WRWL(WL));
    CimDecoderBuffer w_buffer(.WRWL(WL),.BUFFWRWL(BUFFWL));

    generate
        for(genvar i = 0; i < VCAM_WIDTH; i += 1) begin:VCAMWRITE
            WD7T uWD7T(.DIN(DIN[i]), .DINB(DINB[i]), .CKW(vcam_wr_clock), .BL(BL[i]), .BLN(BLN[i]));    
        end        
    endgenerate

    logic [VCAM_DEPTH - 1 : 0]  HOT;    

    generate
        for(genvar i = 0; i < VCAM_DEPTH; i += 1) begin:MANMEM
            VcamCol uVcamCol(.reset(reset), .BL(BL), .BLN(BLN), .CKR(vcam_rd_clock), .CKRO(vcam_rd_clock_odd[i]), .CKRE(vcam_rd_clock_even[i]), .ACT(1'b1), .WL(BUFFWL[i]), .HOT(HOT[i]));    
        end        
    endgenerate

    always_comb begin
        if (vcam_rd_clock_delay) begin
            a_out = HOT;
        end
    end

endmodule: VcamArray





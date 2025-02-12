module SramWrapperSp128bx128d(
    input  var logic           clock,

    input  var logic           rw_enable,
    input  var logic [6:0]     rw_addr,
    input  var logic           rw_write,
    input  var logic [127:0]   rw_dataIn,
    output var logic [127:0]   rw_dataOut,

    input  var logic [1:0]     config_rtsel,
    input  var logic [1:0]     config_wtsel,
    input  var logic [127:0]   config_bweb
);

`ifdef FLOW_ASIC
    logic           mem_rw_clock ;
    logic           mem_rw_enable;
    logic           mem_rw_write ;
    logic [6:0]     mem_rw_addr  ;
    logic [127:0]   mem_rw_dataIn;

    assign  mem_rw_clock = clock;
    assign  mem_rw_enable = rw_enable;
    assign  mem_rw_write  = rw_write;
    assign  mem_rw_addr   = rw_addr;
    assign  mem_rw_dataIn = rw_dataIn;

    TS1N12FFCLLSBSVTC128X128M4SW uSramMacro (
        .Q      (rw_dataOut),
        .CLK    (mem_rw_clock),
        .CEB    (!mem_rw_enable),
        .WEB    (!mem_rw_write),
        .A      (mem_rw_addr),
        .D      (mem_rw_dataIn),
        .BWEB   (config_bweb),
        .RTSEL  (config_rtsel),
        .WTSEL  (config_wtsel)
    );

`else
    SramFpga #(
        .DEPTH      (128),
        .ADDR_WIDTH (7),
        .DATA_WIDTH (128)
    ) uSramMacro (
        .clock  (clock),
        .rw_enable (rw_enable),
        .rw_write  (rw_write),
        .rw_addr   (rw_addr),
        .rw_dataIn (rw_dataIn),
        .rw_dataOut(rw_dataOut)
    );
`endif

endmodule : SramWrapperSp128bx128d


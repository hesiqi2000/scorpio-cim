module MantissaMacro #(
    parameter int VCAM_DEPTH = 64,
    parameter int VCAM_WIDTH = 9,
    parameter int ADDR_WIDTH = $clog2(VCAM_DEPTH)
)(
    input   var logic                           clock,
    input   var logic                           reset,

    input   var logic                           vcam_ren,
    input   var logic                           vcam_reset,
    input   var logic   [VCAM_DEPTH - 1 : 0]    rsam_out,
    
    input   var logic   [ADDR_WIDTH - 1 : 0]    vcam_waddr,
    input   var logic   [VCAM_WIDTH - 1 : 0]    vcam_wdata,
    input   var logic                           vcam_wen,

    output  var logic   [VCAM_DEPTH - 1 : 0]    vcam_out
);

    logic                                                vcam_rd_clock;
    logic                                                vcam_rd_clock_delay;
    logic    [VCAM_DEPTH - 1 : 0]                        vcam_rd_clock_odd;
    logic    [VCAM_DEPTH - 1 : 0]                        vcam_rd_clock_even;

    logic    [ADDR_WIDTH - 1 : 0]                        delayed_vcam_waddr;
    logic    [VCAM_WIDTH - 1 : 0]                        delayed_vcam_wdata;

    logic                           delayed_vcam_ren, delayed_vcam_reset;

    // Delayed cim_ren
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            delayed_vcam_ren <= 1'b0;
            delayed_vcam_reset <= 1'b0;
        end else begin
            delayed_vcam_ren <= vcam_ren;
            delayed_vcam_reset <= vcam_reset;
        end 
    end

    ClockGate VCAMWRCLK(
        .inClock(clock),
        .outClock(vcam_wr_clock),
        .enable0(vcam_wen),
        .enable1(1'b0)
    ); 

    VcamReg #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .VCAM_WIDTH(VCAM_WIDTH)
    ) uVcamReg(
        .clock(clock),
        .reset(reset),
        .vcam_waddr(vcam_waddr),
        .vcam_wdata(vcam_wdata),
        .delayed_vcam_waddr(delayed_vcam_waddr),
        .delayed_vcam_wdata(delayed_vcam_wdata)
    );

    VcamClockGenerator #(
        .VCAM_DEPTH(VCAM_DEPTH), 
        .VCAM_WIDTH(VCAM_WIDTH)
    ) uVcamClockGenerator(
        .clock(clock),
        .reset(reset),
        .vcam_ren(delayed_vcam_ren),
        .vcam_reset(vcam_reset),
        .rsam_out(rsam_out),
        .vcam_rd_clock(vcam_rd_clock),
        .vcam_rd_clock_delay(vcam_rd_clock_delay),
        .vcam_rd_clock_odd(vcam_rd_clock_odd),
        .vcam_rd_clock_even(vcam_rd_clock_even)
    );

    VcamArray #(
        .VCAM_DEPTH(VCAM_DEPTH), 
        .VCAM_WIDTH(VCAM_WIDTH)
    ) uVcamArray(
        .reset(reset|delayed_vcam_reset),
        .vcam_wr_clock(vcam_wr_clock),
        .vcam_rd_clock(vcam_rd_clock),
        .vcam_rd_clock_delay(vcam_rd_clock_delay),
        .vcam_rd_clock_odd(vcam_rd_clock_odd),
        .vcam_rd_clock_even(vcam_rd_clock_even),
        .vcam_waddr(delayed_vcam_waddr),
        .vcam_wdata(delayed_vcam_wdata),
        .a_out(vcam_out)
    );

endmodule: MantissaMacro

module VcamReg #(
    parameter int VCAM_DEPTH = 64,
    parameter int VCAM_WIDTH = 9,
    parameter int ADDR_WIDTH = $clog2(VCAM_DEPTH)
)(
    input   var logic                           clock,
    input   var logic                           reset,
    input   var logic   [ADDR_WIDTH - 1 : 0]    vcam_waddr,
    input   var logic   [VCAM_WIDTH - 1 : 0]    vcam_wdata,

    output  var logic   [ADDR_WIDTH - 1 : 0]    delayed_vcam_waddr,
    output  var logic   [VCAM_WIDTH - 1 : 0]    delayed_vcam_wdata
);

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            delayed_vcam_waddr <= '0;
            delayed_vcam_wdata <= '0;
        end else begin
            delayed_vcam_waddr <= vcam_waddr;
            delayed_vcam_wdata <= vcam_wdata;
        end
    end

endmodule: VcamReg

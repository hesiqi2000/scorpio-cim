module ExponentMacro #(
    parameter int RSAM_DEPTH = 64,
    parameter int RSAM_WIDTH = 8,
    parameter int ADDR_WIDTH = $clog2(RSAM_DEPTH)
)(
    input   var logic                           clock,
    input   var logic                           reset,

    input   var logic                           rsam_ren,
    input   var logic   [RSAM_WIDTH - 1 : 0]    rsam_sl,
    input   var logic   [RSAM_WIDTH - 1 : 0]    rsam_sm,
    input   var logic   [RSAM_WIDTH - 1 : 0]    rsam_sln,
    
    input   var logic   [ADDR_WIDTH - 1 : 0]    rsam_waddr,
    input   var logic   [RSAM_WIDTH - 1 : 0]    rsam_wdata,
    input   var logic                           rsam_wen,

    input   var logic                           vcam_reset,

    output  var logic   [RSAM_DEPTH - 1 : 0]    rsam_out,
    output  var logic   [RSAM_DEPTH - 1 : 0]    rsam_flip
);

    logic   delayed_rsam_ren, delayed_rsam_wen;
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            delayed_rsam_ren <= '0;
            delayed_rsam_wen <= '0;
        end else begin
            delayed_rsam_ren <= rsam_ren;
            delayed_rsam_wen <= rsam_wen;
        end
    end

    logic    rsam_rd_clock, rsam_wr_clock;

    ClockGate RSAMWRCLK(
        .inClock(clock),
        .outClock(rsam_wr_clock),
        .enable0(rsam_wen),
        .enable1(1'b0)
    ); 

    ClockGate RSAMRDCLK(
        .inClock(clock),
        .outClock(rsam_rd_clock),
        .enable0(rsam_ren),
        .enable1(1'b0)
    ); 

    logic   [ADDR_WIDTH - 1 : 0]    delayed_rsam_waddr;
    logic   [RSAM_WIDTH - 1 : 0]    delayed_rsam_wdata;

    RsamReg #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .RSAM_WIDTH(RSAM_WIDTH)
    ) uRsamReg(
        .clock(clock),
        .reset(reset),
        .rsam_waddr(rsam_waddr),
        .rsam_wdata(rsam_wdata),
        .delayed_rsam_waddr(delayed_rsam_waddr),
        .delayed_rsam_wdata(delayed_rsam_wdata)
    );

    logic   [RSAM_DEPTH - 1 : 0]   rsam_out_temp;

    RsamArray #(
        .RSAM_DEPTH(RSAM_DEPTH), 
        .RSAM_WIDTH(RSAM_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uRsamArray(
        .rsam_wr_clock(rsam_wr_clock),
        .rsam_sm(rsam_sm),
        .rsam_sl(rsam_sl),
        .rsam_sln(rsam_sln),
        .rsam_waddr(delayed_rsam_waddr),
        .rsam_wdata(delayed_rsam_wdata),
        .rsam_out(rsam_out_temp)
    );

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            rsam_out <= '0;
        end else if (rsam_ren) begin
            rsam_out <= rsam_out_temp;
        end
    end

    logic   [RSAM_DEPTH - 1 : 0]    rsam_flip_temp, delay_rsam_flip;

    for (genvar i = 0; i < RSAM_DEPTH; i++) begin
        always_ff @(posedge clock or posedge reset) begin
            if (reset) begin
                rsam_flip_temp[i] <= '0;
            end else if (vcam_reset) begin
                rsam_flip_temp[i] <= '0;
            end else if (delayed_rsam_ren & ~rsam_out[i]) begin
                rsam_flip_temp[i] <= '1;
            end
        end        
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            rsam_flip <= '0;
            delay_rsam_flip <= '0;
        end else begin
            rsam_flip <= delay_rsam_flip;
            delay_rsam_flip <= rsam_flip_temp;
        end
    end   

endmodule: ExponentMacro

module RsamReg #(
    parameter int RSAM_DEPTH = 64,
    parameter int RSAM_WIDTH = 8,
    parameter int ADDR_WIDTH = $clog2(RSAM_DEPTH)
)(
    input   var logic                           clock,
    input   var logic                           reset,
    input   var logic   [ADDR_WIDTH - 1 : 0]    rsam_waddr,
    input   var logic   [RSAM_WIDTH - 1 : 0]    rsam_wdata,

    output  var logic   [ADDR_WIDTH - 1 : 0]    delayed_rsam_waddr,
    output  var logic   [RSAM_WIDTH - 1 : 0]    delayed_rsam_wdata
);

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            delayed_rsam_waddr <= '0;
            delayed_rsam_wdata <= '0;
        end else begin
            delayed_rsam_waddr <= rsam_waddr;
            delayed_rsam_wdata <= rsam_wdata;
        end
    end

endmodule: RsamReg

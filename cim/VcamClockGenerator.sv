module VcamClockGenerator #(
    parameter int VCAM_DEPTH = 64,
    parameter int VCAM_WIDTH = 9
)(
    input   var logic                           clock,
    input   var logic                           reset,
    input   var logic                           vcam_ren,
    input   var logic                           vcam_reset,
    input   var logic   [VCAM_DEPTH - 1 : 0]    rsam_out,

    output  var logic                           vcam_rd_clock,
    output  var logic                           vcam_rd_clock_delay,
    output  var logic   [VCAM_DEPTH - 1 : 0]    vcam_rd_clock_odd,
    output  var logic   [VCAM_DEPTH - 1 : 0]    vcam_rd_clock_even
);

    // Internal signals
    logic   [VCAM_DEPTH - 1 : 0]    toggle;

    // Alternating clocks
    generate
        for(genvar i = 0; i < VCAM_DEPTH; i += 1) begin:TOGGLE
            always_ff @(posedge clock or posedge reset) begin
                if (reset) begin
                    toggle[i] <= 1'b0;
                end else if (vcam_reset) begin 
                    toggle[i] <= 1'b0;
                end
                else if (~rsam_out[i] & vcam_ren) begin
                    toggle[i] <= ~toggle[i];
                end else begin
                    toggle[i] <= 1'b0;
                end
            end
        end
    endgenerate

    ClockGate VCAMRDCLOCK(
        .inClock(clock),
        .outClock(vcam_rd_clock),
        .enable0(vcam_ren),
        .enable1(1'b0)
    ); 

    logic   vcam_ren_delay;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            vcam_ren_delay <= 1'b0;
        end else begin
            vcam_ren_delay <= vcam_ren;
        end
    end

    ClockGate VCAMRDCLOCKDELAY(
        .inClock(clock),
        .outClock(vcam_rd_clock_delay),
        .enable0(vcam_ren_delay),
        .enable1(1'b0)
    ); 

    for(genvar i = 0; i < VCAM_DEPTH; i += 1) begin:CLOCKEVEN
        ClockGate uEVENCLOCK(
            .inClock(clock),
            .outClock(vcam_rd_clock_even[i]),
            .enable0(~vcam_reset&vcam_ren&toggle[i]&~rsam_out[i]),
            .enable1(1'b0)
        );  
    end

    for(genvar i = 0; i < VCAM_DEPTH; i += 1) begin:CLOCKODD
        ClockGate uODDCLOCK(
            .inClock(clock),
            .outClock(vcam_rd_clock_odd[i]),
            .enable0(~vcam_reset&vcam_ren&~toggle[i]&~rsam_out[i]),
            .enable1(1'b0)
        );  
    end

endmodule

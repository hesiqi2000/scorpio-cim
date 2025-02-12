module ClockGate (
    input  wire  inClock,
    output wire  outClock,
    input  wire  enable0,
    input  wire  enable1
);
`ifdef ASIC_CLOCK_GATING
   CKLNQD16BWP6T20P96CPD clock_gate_latch (
       .CP (inClock),
       .Q  (outClock),
       .E  (enable0),
       .TE (enable1)
   );
`else
   reg en_latch;
   always @(*) begin
        if(!inClock) begin
            en_latch = enable0;
        end
   end

   assign outClock = inClock & en_latch;
`endif
endmodule // ClockGate

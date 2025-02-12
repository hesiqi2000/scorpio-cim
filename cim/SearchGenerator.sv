module SearchGenerator #(
    parameter   int RSAM_DEPTH = 64,
    parameter   int RSAM_WIDTH = 8,
    parameter   int ADDR_WIDTH = $clog2(RSAM_DEPTH)
)(
    input   var logic                           clock,
    input   var logic                           reset,

    input   var logic   [RSAM_WIDTH - 1 : 0]    rsam_wdata,
    input   var logic   [ADDR_WIDTH - 1 : 0]    rsam_waddr,
    input   var logic                           rsam_wen,

    input   var logic                           rsam_ren,
    input   var logic                           rsam_reset,

    output  var logic   [RSAM_WIDTH - 1 : 0]    rsam_sm, rsam_sl, rsam_sln,
    output  var logic   [RSAM_WIDTH - 1 : 0]    emax
);

    logic [RSAM_WIDTH - 1 : 0] emax_reg, sl_reg;

    assign  rsam_sm = sl_reg;
    assign  rsam_sl = sl_reg;
    assign  rsam_sln = ~rsam_sl;

    assign rsam_emax = emax_reg;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            emax_reg <= '0;
        end else if (rsam_wen) begin
            if (rsam_waddr == '0) begin
                emax_reg <= rsam_wdata;
            end else if (rsam_wdata > emax_reg) begin
                emax_reg <= rsam_wdata;
            end
        end
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            sl_reg <= '0;
        end else if (rsam_reset & rsam_ren) begin
            sl_reg <= emax_reg;
        end else if (~rsam_reset & rsam_ren) begin
            sl_reg <= sl_reg - 1;
        end
    end

    assign emax = emax_reg;

endmodule
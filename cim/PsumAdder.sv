module PsumAdder (
    input   var logic                   clock,
    input   var logic                   reset,

    input   var logic   [13 : 0]        psum,
    input   var logic                   psum_ren,
    input   var logic                   psum_start,
    input   var logic                   vcam_reset,

    output  var logic   [21 : 0]        sum,
    output  var logic                   cim_odata_valid
);
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            sum <= '0;
        end else if (psum_start & psum_ren) begin
            sum <= $signed(psum);
        end else if (~psum_start & psum_ren & ~cim_odata_valid) begin
            sum <= ($signed(sum) << 1) + $signed(psum);
        end else begin
            sum <= '0;
        end
    end

    logic   delay_vcam_reset;
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            delay_vcam_reset <= '0;
        end else begin
            delay_vcam_reset <= vcam_reset;
        end
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            cim_odata_valid <= 0;
        end else if (delay_vcam_reset) begin
            cim_odata_valid <= 1;
        end else begin
            cim_odata_valid <= 0;
        end
    end

endmodule: PsumAdder
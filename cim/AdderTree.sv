module AdderTree #(
    parameter int VCAM_DEPTH = 64,
    parameter int RSAM_DEPTH = 64,
    parameter int DATA_WIDTH = 512
)(
    input   var logic           [VCAM_DEPTH - 1 : 0]    vcam_out,
    input   var logic           [RSAM_DEPTH - 1 : 0]    rsam_flip,
    input   var logic           [DATA_WIDTH - 1 : 0]    cim_idata,
    output  var logic   signed  [13 : 0]                psum
);

    logic   signed  [VCAM_DEPTH - 1 : 0] [7 : 0]    psum_temp;
    always_comb begin
        for (int i = 0; i < VCAM_DEPTH; i = i + 1) begin
            psum_temp[i] = cim_idata[8*i +: 8] & {8{vcam_out[i]}};
        end
    end

    logic   signed  [VCAM_DEPTH - 1 : 0] [7 : 0]    signed_psum_temp;
    always_comb begin
        for (int i = 0; i < VCAM_DEPTH; i = i + 1) begin
            signed_psum_temp[i] = (~rsam_flip[i] & vcam_out[i]) ? -$signed(psum_temp[i]) : $signed(psum_temp[i]);
        end
    end

    always_comb begin
        psum = '0;
        for (int i = 0; i < VCAM_DEPTH; i = i + 1) begin
            psum += $signed(signed_psum_temp[i]);
        end
    end    

endmodule: AdderTree

module CimDecoderBuffer  #(
    parameter DEPTH = 64
)(
    input   [DEPTH - 1 : 0]    WRWL,
    output  [DEPTH - 1 : 0]    BUFFWRWL
);

    genvar i;
    for (i = 0;i < DEPTH;i = i + 1) begin:BUFF
        BUFFD8BWP6T20P96CPD BUFF(.I(WRWL[i]), .Z(BUFFWRWL[i]));
    end

endmodule
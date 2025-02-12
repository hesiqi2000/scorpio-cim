module SramFpga#(
    parameter DATA_WIDTH = 128,
    parameter ADDR_WIDTH = 9,
    parameter DEPTH = 512
)(
    input wire clock,
    input wire rw_enable,
    input wire rw_write,
    input wire [ADDR_WIDTH-1:0] rw_addr,
    input wire [DATA_WIDTH-1:0] rw_dataIn,
    output wire [DATA_WIDTH-1:0] rw_dataOut
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] rdDataReg;
    always @(posedge clock) begin
        if (rw_enable) begin
            if (rw_write) mem[rw_addr] <= rw_dataIn;
            else rdDataReg <= mem[rw_addr];
        end
    end
    assign rw_dataOut = rdDataReg;

endmodule  // SinglePortSram

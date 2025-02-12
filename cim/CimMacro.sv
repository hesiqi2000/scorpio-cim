module CimMacro  #(
    parameter int CIM_WIDTH = 17,
    parameter int CIM_DEPTH = 64,
    parameter int DATA_WIDTH = 512,
    parameter int RSAM_WIDTH = 8,
    parameter int ADDR_WIDTH = $clog2(CIM_DEPTH)
)(
    input  var logic                            clock,
    input  var logic                            reset,

    input  var logic    [DATA_WIDTH - 1: 0]     cim_idata,
    input  var logic    [7 : 0]                 cim_idata_exp,
    input  var logic                            cim_ren,

    input  var logic                            cim_wen,
    input  var logic    [ADDR_WIDTH - 1 : 0]    cim_waddr,
    input  var logic    [CIM_WIDTH - 1 : 0]     cim_wdata,

    output var logic    [15 : 0]                cim_odata,
    output var logic                            cim_odata_valid  
);

    parameter int VCAM_DEPTH = 64;
    parameter int RSAM_DEPTH = 64;
    parameter int VCAM_WIDTH = 9;
    
    logic   [VCAM_WIDTH - 1 : 0]    vcam_wdata;
    logic   [RSAM_WIDTH - 1 : 0]    rsam_wdata;

    assign vcam_wdata = cim_wdata[VCAM_WIDTH - 1 : 0];
    assign rsam_wdata = cim_wdata[CIM_WIDTH - 1 : VCAM_WIDTH];

    logic   [DATA_WIDTH - 1 : 0]    delayed_cim_idata;
    logic   [7 : 0]                 delayed_cim_idata_exp;

    CimReg #(
        .DATA_WIDTH(DATA_WIDTH)
    ) uCimReg(
        .clock(clock),
        .reset(reset),
        .cim_idata(cim_idata),
        .cim_idata_exp(cim_idata_exp),
        .delayed_cim_idata(delayed_cim_idata),
        .delayed_cim_idata_exp(delayed_cim_idata_exp)
    );

    logic   rsam_reset, vcam_reset, psum_start;

    ClockCounter uClockCounter(
        .clock(clock),
        .reset(reset),
        .cim_ren(cim_ren),
        .rsam_reset(rsam_reset),
        .vcam_reset(vcam_reset),
        .psum_start(psum_start)
    ); 

    logic   [RSAM_WIDTH - 1 : 0]    rsam_sm, rsam_sl, rsam_sln, emax;

    logic [4:0] cim_ren_d;

    always_ff @(posedge clock or negedge reset) begin
        if (reset) begin
            cim_ren_d <= 5'b0;  
        end else begin
            cim_ren_d <= {cim_ren_d[3:0], cim_ren}; 
        end
    end

    logic  psum_ren;
    assign psum_ren = cim_ren_d[4];  // 取第 5 拍的值

    SearchGenerator  #(
        .RSAM_DEPTH(RSAM_DEPTH),     
        .RSAM_WIDTH(RSAM_WIDTH),      
        .ADDR_WIDTH(ADDR_WIDTH) 
    ) uSearchGenerator (
        .clock(clock),
        .reset(reset),
        .rsam_wdata(rsam_wdata),
        .rsam_waddr(cim_waddr),
        .rsam_wen(cim_wen),
        .rsam_ren(cim_ren_d[0]),
        .rsam_reset(rsam_reset),
        .rsam_sm(rsam_sm),
        .rsam_sl(rsam_sl),
        .rsam_sln(rsam_sln),
        .emax(emax)
    );

    logic   [RSAM_DEPTH - 1 : 0]    rsam_out;
    logic   [VCAM_DEPTH - 1 : 0]    vcam_out;
    logic   [RSAM_DEPTH - 1 : 0]    rsam_flip;

    ExponentMacro #(
        .RSAM_DEPTH(RSAM_DEPTH),     
        .RSAM_WIDTH(RSAM_WIDTH),      
        .ADDR_WIDTH(ADDR_WIDTH) 
    ) uExponentMacro (
        .clock(clock),
        .reset(reset),
        .rsam_ren(cim_ren_d[1]),
        .rsam_sm(rsam_sm),
        .rsam_sl(rsam_sl),
        .rsam_sln(rsam_sln),
        .rsam_waddr(cim_waddr),
        .rsam_wdata(rsam_wdata),
        .rsam_wen(cim_wen),
        .vcam_reset(vcam_reset),
        .rsam_out(rsam_out),
        .rsam_flip(rsam_flip)
    );

    MantissaMacro #(
        .VCAM_DEPTH(VCAM_DEPTH), 
        .VCAM_WIDTH(VCAM_WIDTH),  
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uMantissaMacro (
        .clock(clock),
        .reset(reset),
        .vcam_ren(cim_ren_d[1]),
        .vcam_reset(vcam_reset),
        .rsam_out(rsam_out),      
        .vcam_waddr(cim_waddr),
        .vcam_wdata(vcam_wdata),     
        .vcam_wen(cim_wen),
        .vcam_out(vcam_out)       
    );

    logic   [13 : 0]  psum;
    AdderTree #(
        .VCAM_DEPTH(VCAM_DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uAdderTree(
        .vcam_out(vcam_out),
        .rsam_flip(rsam_flip),
        .cim_idata(delayed_cim_idata),
        .psum(psum)
    );

    logic   [21 : 0]    sum;
    logic               cim_odata_valid_temp;
    logic   [15 : 0]    cim_odata_temp;

    PsumAdder uPsumAdder(
        .clock(clock),
        .reset(reset),        
        .psum_start(psum_start),
        .psum_ren(psum_ren),
        .psum(psum),
        .vcam_reset(vcam_reset),
        .sum(sum),
        .cim_odata_valid(cim_odata_valid_temp)
    );

    Normal uNormal(
        .sum(sum),
        .emax(emax),
        .cim_idata_exp(delayed_cim_idata_exp),
        .cim_odata(cim_odata_temp)
    );

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            cim_odata <= '0;
        end
        else if (cim_odata_valid_temp) begin
            cim_odata <= cim_odata_temp;
        end
    end

    always_ff @(posedge clock, posedge reset) begin
        if (reset) begin
            cim_odata_valid <= '0;
        end
        else begin
            cim_odata_valid <= cim_odata_valid_temp;
        end
    end

endmodule

module CimReg #(
    parameter int DATA_WIDTH = 512
)(
    input   var logic                           clock,
    input   var logic                           reset,
    input   var logic   [DATA_WIDTH - 1 : 0]    cim_idata,
    input   var logic   [7 : 0]                 cim_idata_exp,

    output  var logic   [DATA_WIDTH - 1 : 0]    delayed_cim_idata,
    output  var logic   [7 : 0]                 delayed_cim_idata_exp
);

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            delayed_cim_idata <= '0;
            delayed_cim_idata_exp <= '0;
        end else begin
            delayed_cim_idata <= cim_idata;
            delayed_cim_idata_exp <= cim_idata_exp;
        end
    end

endmodule: CimReg

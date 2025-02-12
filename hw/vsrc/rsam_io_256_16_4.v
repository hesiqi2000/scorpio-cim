`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: rsam_io_256_16_4
// Project Name: 
// Description: 例化RSAM，封装统一的接口
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module rsam_io_256_16_4
#(
    parameter DATA_WIDTH = 16, // 数据位宽
    parameter ADDR_WIDTH = 8,  // 地址位宽
    parameter BANK_NUM   = 4   // 
)(
    input wire clk, // 时钟信号

    // signal from bus: axi/spi
    input wire [ADDR_WIDTH-1:0]          rsam_bus_addr,
    input wire [DATA_WIDTH*BANK_NUM-1:0] rsam_bus_wdata, // 数据信号16*4=64b
    input wire                           rsam_bus_wen,
    input wire                           rsam_bus_ena,

    // signal from fsm 
    input wire [ADDR_WIDTH-1:0]          rsam_fsm_addr,
    input wire [DATA_WIDTH*BANK_NUM-1:0] rsam_fsm_wdata, // 数据信号16*4=64b
    input wire                           rsam_fsm_wen,
    input wire                           rsam_fsm_ena,

    input wire [DATA_WIDTH*BANK_NUM-1:0] rsam_fsm_sl,
    input wire [DATA_WIDTH*BANK_NUM-1:0] rsam_fsm_sm,
    input wire                           rsam_fsm_sen,


    output wire [DATA_WIDTH*BANK_NUM-1:0]  rsam_rdata,   // 读取数据信号, 16*3=64b
    output wire [(2**ADDR_WIDTH)-1:0]      rsam_sdata
);

wire [ADDR_WIDTH-1:0]           addr;
wire [DATA_WIDTH*BANK_NUM-1:0]  wdata;
wire                            wen;
wire                            ena;
reg [DATA_WIDTH*BANK_NUM-1:0]   sl;         // reg 型，16*4=64b，需要在下降沿对rsam_fsm_sl进行采样，确保有足够的保持时间
reg [DATA_WIDTH*BANK_NUM-1:0]   sm;         // reg 型，16*4=64b，需要在下降沿对rsam_fsm_sm进行采样，确保有足够的保持时间
wire                            sen;

assign addr = rsam_bus_ena ? rsam_bus_addr : rsam_fsm_addr;
assign wdata = rsam_bus_ena ? rsam_bus_wdata : rsam_fsm_wdata;
assign ena = rsam_bus_ena | rsam_fsm_ena;
assign wen = rsam_bus_ena ? rsam_bus_wen : rsam_fsm_wen;

always @(negedge clk) begin     // 下降沿触发
    sl <= rsam_fsm_sl;
    sm <= rsam_fsm_sm;
end
assign sen = rsam_fsm_sen;


// 例化BANK_NUM个rsam
wire [(2**ADDR_WIDTH)-1:0] sdata_t [BANK_NUM-1:0];
genvar i;
generate
    for (i=0; i<BANK_NUM; i=i+1) begin: gen_rsam
        rsam #(
            .DATA_WIDTH (DATA_WIDTH),
            .ADDR_WIDTH (ADDR_WIDTH)
        ) u_rsam (
            .clk    (clk),
            .addr   (addr),
            .wdata  (wdata[DATA_WIDTH*i +: DATA_WIDTH]),
            .wen    (wen),
            .ena    (ena),
            .sl     (sl[DATA_WIDTH*i +: DATA_WIDTH]),
            .sm     (sm[DATA_WIDTH*i +: DATA_WIDTH]),
            .sen    (sen),
            .rdata  (rsam_rdata[DATA_WIDTH*i +: DATA_WIDTH]),
            .sdata  (sdata_t[i])
        );
    end
endgenerate

// 4个sdata_t合并成一个sdata
// 最后的输出，匹配上为1，不匹配为0
assign rsam_sdata = ~(sdata_t[3] | sdata_t[2] | sdata_t[1] | sdata_t[0]);


endmodule
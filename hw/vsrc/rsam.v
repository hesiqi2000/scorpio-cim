`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: rsam
// Project Name: 
// Description: RSAM的整个阵列的行为级模块
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module rsam 
#(
    parameter DATA_WIDTH = 16, // 数据位宽
    parameter ADDR_WIDTH = 8  // 地址位宽
)(
    input wire clk, // 时钟信号

    input wire [ADDR_WIDTH-1:0]  addr, // 地址信号, 8位地址, 256个地址
    input wire [DATA_WIDTH-1:0]  wdata, // 数据信号
    input wire                   wen,
    input wire                   ena,

    input wire [DATA_WIDTH-1:0]  sl,
    input wire [DATA_WIDTH-1:0]  sm,
    input wire                   sen,

    output reg [DATA_WIDTH-1:0]      rdata, // 读取数据信号
    output reg [(2**ADDR_WIDTH)-1:0] sdata  // 读取数据信号
);

    // core memory 
    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0]; // 256个地址, 每个地址16位数据

    // 正常的sram读写功能
    always @(posedge clk) begin
        if (ena) begin
            if (wen) begin
                mem[addr] <= wdata;
            end
            else begin
                rdata <= mem[addr];
            end
        end
    end

    // Search功能
    integer                i;

    wire in_greater_than_mode;
    assign in_greater_than_mode = sm[0] == sl[0]; //sm和sl相同时，在进行查大的操作；

    always @(posedge clk) begin
        if (sen) begin
            for (i=0; i<(2**ADDR_WIDTH); i=i+1) begin
                if (mem[i] == sl) begin
                    sdata[i] <= 1'b0;
                end
                else if (mem[i] > sl) begin
                    sdata[i] <= ~in_greater_than_mode;
                end
                else begin
                    sdata[i] <= in_greater_than_mode;
                end
            end
        end
    end

endmodule
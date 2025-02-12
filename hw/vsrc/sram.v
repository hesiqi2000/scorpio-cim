`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: sram
// Project Name: 
// Description: sram的整个阵列的行为级模块
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module sram
 #(
    parameter   ADDR_WIDTH      =  8, 
    parameter   DATA_WIDTH      =  64
) (
    input wire clk, // 时钟信号

    input wire [ADDR_WIDTH-1:0]  addr, // 地址信号, 8位地址, 256个地址
    input wire [DATA_WIDTH-1:0]  wdata, // 数据信号
    input wire                   wen,
    input wire                   ena,

    output reg [DATA_WIDTH-1:0]  rdata // 读取数据信号
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
endmodule
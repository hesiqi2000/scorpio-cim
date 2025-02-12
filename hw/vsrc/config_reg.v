`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: config_reg
// Project Name: 
// Description: 
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module config_reg(
    input wire clk, // 时钟信号
    input wire rst_n, // 复位信号

    input wire [63:0]           config_bus_wdata, 
    input wire                  config_bus_wen,
    input wire                  config_bus_ena,

    input wire [63:0]           config_fsm_wdata,
    input wire                  config_fsm_wen,
    input wire                  config_fsm_ena,

    output reg [63:0]           mode_config_reg
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode_config_reg <= 64'b0;
        end 
        else if (config_fsm_ena && config_fsm_wen) begin
            mode_config_reg <= config_fsm_wdata;
        end
        else if (config_bus_ena && config_bus_wen) begin
            mode_config_reg <= config_bus_wdata;
        end 
    end



endmodule

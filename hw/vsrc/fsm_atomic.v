`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: fsm_atomic
// Project Name: 
// Description: 主要功能的原子操作：从IB的指定地址（范围）读取数据用于RSAM搜索，然后将搜索结果写回IB的指定地址（范围）
//      配置寄存器 从IB的指定地址（范围，使用第0块）读取数据用于RSAM搜索，然后将搜索结果写回IB的指定地址（范围，使用第1、2块）
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module fsm_atomic(
    input wire clk, // 时钟信号
    input wire rst_n, // 复位信号

    input  wire [63:0]           mode_config_reg, // 模式配置
    output wire [63:0]           atomic_mode_config_reg_wb, // 模式配置写回
    output wire                  atomic_mode_config_reg_wb_en, // 模式配置写回使能

    // signal to rsam 
    output wire [7:0]            atomic_rsam_fsm_addr,
    output wire [63:0]           atomic_rsam_fsm_wdata, // 数据信号16*4=64b
    output wire                  atomic_rsam_fsm_wen,
    output wire                  atomic_rsam_fsm_ena,
    output wire [63:0]           atomic_rsam_fsm_sl,
    output wire [63:0]           atomic_rsam_fsm_sm,
    output wire                  atomic_rsam_fsm_sen,
    input wire [63:0]            rsam_rdata,   // 读取数据信号, 16*3=64b
    input wire [255:0]           rsam_sdata,

    // signal to inputbuffer
    output wire [6:0]            atomic_ib_0_fsm_addr,
    output wire [127:0]          atomic_ib_0_fsm_wdata,
    output wire                  atomic_ib_0_fsm_wen,
    output wire                  atomic_ib_0_fsm_ena,
    output wire [6:0]            atomic_ib_1_fsm_addr,
    output wire [127:0]          atomic_ib_1_fsm_wdata, 
    output wire                  atomic_ib_1_fsm_wen,
    output wire                  atomic_ib_1_fsm_ena,
    output wire [6:0]            atomic_ib_2_fsm_addr,
    output wire [127:0]          atomic_ib_2_fsm_wdata, 
    output wire                  atomic_ib_2_fsm_wen,
    output wire                  atomic_ib_2_fsm_ena,
    output wire [6:0]            atomic_ib_3_fsm_addr,
    output wire [127:0]          atomic_ib_3_fsm_wdata, 
    output wire                  atomic_ib_3_fsm_wen,
    output wire                  atomic_ib_3_fsm_ena,
    input wire [127:0]           ib_0_rdata,
    input wire [127:0]           ib_1_rdata,
    input wire [127:0]           ib_2_rdata,
    input wire [127:0]           ib_3_rdata
);


// 配置寄存器译码
wire soft_rst, atomic_fsm_en;           // 1b: fsm_done，用于写回
assign soft_rst = mode_config_reg[0];
assign atomic_fsm_en = mode_config_reg[5];

// 配置寄存器 从IB的指定地址（范围，使用第0块）读取数据用于RSAM搜索，然后将搜索结果写回IB的指定地址（范围，使用第1、2块）
wire [6:0] rd_sram_start_addr;  // 用于读取搜索pattern
wire [6:0] rd_sram_end_addr;    // 包含start和end地址的数据
wire [6:0] wr_sram_start_addr;  // 用于写回结果，逐次加一

assign rd_sram_start_addr = mode_config_reg[14:8];
assign rd_sram_end_addr = mode_config_reg[21:15];
assign wr_sram_start_addr = mode_config_reg[28:22];



// 三段式状态机
    wire search_finish;

    reg [2:0] state;
    reg [2:0] next_state;

    localparam      IDLE = 3'b000, 
                    INIT = 3'b001,
                    READ = 3'b010,
                    DONE = 3'b011;
    
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
        end 
        else begin
            if (soft_rst) begin
                state <= IDLE;
            end
            else begin
                state <= next_state;
            end
        end
    end

    // state transition logic
    always @(*) begin 
        case(state)
            IDLE: begin
                if (atomic_fsm_en) begin
                    next_state = INIT;
                end
                else begin
                    next_state = IDLE;
                end
            end
            INIT: begin
                next_state = READ;
            end
            READ: begin
                if (search_finish) begin
                    next_state = DONE;
                end
                else begin
                    next_state = READ;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // state action, output logic
    reg [6:0]            rd_ib_fsm_addr;
    reg                  rd_ib_fsm_wen;
    reg                  rd_ib_fsm_ena;

    wire [63:0]          search_rsam_sl;  // 搜索数据来自于IB的输出 [63:0]
    wire [63:0]          search_rsam_sm;  // 搜索数据来自于IB的输出 [127:64]
    reg                  search_rsam_sen;

    reg  [6:0]           wr_ib_fsm_addr;
    wire [255:0]         wr_ib_fsm_wdata;  // 搜索数据来自于RSAM的输出 [255:0]
    reg                  wr_ib_fsm_wen;
    reg                  wr_ib_fsm_ena;


    //! 1. 读取Ibuffer的数据
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_ib_fsm_addr <= 7'b0;
            rd_ib_fsm_wen <= 1'b0;
            rd_ib_fsm_ena <= 1'b0;
        end
        else begin
            case(next_state)
                IDLE: begin
                    rd_ib_fsm_addr <= 7'b0;
                    rd_ib_fsm_wen <= 1'b0;
                    rd_ib_fsm_ena <= 1'b0;
                end
                INIT: begin
                    rd_ib_fsm_addr <= rd_sram_start_addr - 1'b1;
                    rd_ib_fsm_wen <= 1'b0;
                    rd_ib_fsm_ena <= 1'b0;
                end
                READ: begin
                    rd_ib_fsm_addr <= rd_ib_fsm_addr + 1'b1;
                    rd_ib_fsm_wen <= 1'b0;
                    rd_ib_fsm_ena <= 1'b1;
                end
                DONE: begin
                    rd_ib_fsm_addr <= 7'b0;
                    rd_ib_fsm_wen <= 1'b0;
                    rd_ib_fsm_ena <= 1'b0;
                end
                default: begin
                    rd_ib_fsm_addr <= 7'b0;
                    rd_ib_fsm_wen <= 1'b0;
                    rd_ib_fsm_ena <= 1'b0;
                end
            endcase
        end
    end

    //! 2. 根据Ibuffer的数据，搜索RSAM
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            search_rsam_sen <= 1'b0;
        end
        else begin
            if (rd_ib_fsm_ena) begin
                search_rsam_sen <= 1'b1;
            end
            else begin
                search_rsam_sen <= 1'b0;
            end
        end
    end
    // 读取的Ibuffer的数据
    assign search_rsam_sl = ib_0_rdata[63:0];
    assign search_rsam_sm = ib_0_rdata[127:64];

    //! 3. 将搜索结果写回Ibuffer
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_ib_fsm_addr <= 7'b0;
            wr_ib_fsm_wen <= 1'b0;
            wr_ib_fsm_ena <= 1'b0;
        end
        else begin
            if (next_state == INIT) begin
                wr_ib_fsm_addr <= wr_sram_start_addr - 1'b1;
                wr_ib_fsm_wen <= 1'b0;
                wr_ib_fsm_ena <= 1'b0;
            end
            else if (search_rsam_sen) begin
                wr_ib_fsm_addr <= wr_ib_fsm_addr + 1'b1;
                wr_ib_fsm_wen <= 1'b1;
                wr_ib_fsm_ena <= 1'b1;
            end
            else begin
                wr_ib_fsm_wen <= 1'b0;
                wr_ib_fsm_ena <= 1'b0;
            end
        end
    end

    assign wr_ib_fsm_wdata = rsam_sdata;

    //! 4. 结束条件
    assign search_finish = (rd_ib_fsm_addr == rd_sram_end_addr);

    //! 5. 接口信号整合输出
    wire done;
    assign done = (state == DONE);

    // 写回配置寄存器，第1位（done）写1、第5位（en）写0
    assign atomic_mode_config_reg_wb = {mode_config_reg[63:6], 1'b0, mode_config_reg[4:2], 1'b1, mode_config_reg[0]};
    assign atomic_mode_config_reg_wb_en = done;

    assign atomic_rsam_fsm_addr = 8'b0;
    assign atomic_rsam_fsm_wdata = 64'b0;
    assign atomic_rsam_fsm_wen = 1'b0;
    assign atomic_rsam_fsm_ena = 1'b0;
    assign atomic_rsam_fsm_sl = search_rsam_sl;
    assign atomic_rsam_fsm_sm = search_rsam_sm;
    assign atomic_rsam_fsm_sen = search_rsam_sen;

    assign atomic_ib_0_fsm_addr = rd_ib_fsm_addr;
    assign atomic_ib_0_fsm_wdata = 128'b0;
    assign atomic_ib_0_fsm_wen = rd_ib_fsm_wen;
    assign atomic_ib_0_fsm_ena = rd_ib_fsm_ena;

    assign atomic_ib_1_fsm_addr = wr_ib_fsm_addr;
    assign atomic_ib_1_fsm_wdata = wr_ib_fsm_wdata[127:0];
    assign atomic_ib_1_fsm_wen = wr_ib_fsm_wen;
    assign atomic_ib_1_fsm_ena = wr_ib_fsm_ena;

    assign atomic_ib_2_fsm_addr = wr_ib_fsm_addr;
    assign atomic_ib_2_fsm_wdata = wr_ib_fsm_wdata[255:128];
    assign atomic_ib_2_fsm_wen = wr_ib_fsm_wen;
    assign atomic_ib_2_fsm_ena = wr_ib_fsm_ena;

    assign atomic_ib_3_fsm_addr = 7'b0;
    assign atomic_ib_3_fsm_wdata = 128'b0;
    assign atomic_ib_3_fsm_wen = 1'b0;
    assign atomic_ib_3_fsm_ena = 1'b0;


endmodule
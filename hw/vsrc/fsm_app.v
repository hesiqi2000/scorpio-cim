`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: fsm_app
// Project Name: 
// Description: 主要功能的实际连续点云模式的操作：读取RSAM数据，生成搜索pattern，用于RSAM搜索，然后将搜索结果写回IB的指定地址(0,1组成一块 2,3组成一块)
//      
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module fsm_app(
    input wire clk, // 时钟信号
    input wire rst_n, // 复位信号

    input  wire [63:0]           mode_config_reg, // 模式配置
    output wire [63:0]           app_mode_config_reg_wb, // 模式配置写回
    output wire                  app_mode_config_reg_wb_en, // 模式配置写回使能

    // signal to rsam 
    output wire [7:0]            app_rsam_fsm_addr,
    output wire [63:0]           app_rsam_fsm_wdata, // 数据信号16*4=64b
    output wire                  app_rsam_fsm_wen,
    output wire                  app_rsam_fsm_ena,
    output wire [63:0]           app_rsam_fsm_sl,
    output wire [63:0]           app_rsam_fsm_sm,
    output wire                  app_rsam_fsm_sen,
    input wire [63:0]            rsam_rdata,   // 读取数据信号, 16*3=64b
    input wire [255:0]           rsam_sdata,

    // signal to inputbuffer
    output wire [6:0]            app_ib_0_fsm_addr,
    output wire [127:0]          app_ib_0_fsm_wdata,
    output wire                  app_ib_0_fsm_wen,
    output wire                  app_ib_0_fsm_ena,
    output wire [6:0]            app_ib_1_fsm_addr,
    output wire [127:0]          app_ib_1_fsm_wdata, 
    output wire                  app_ib_1_fsm_wen,
    output wire                  app_ib_1_fsm_ena,
    output wire [6:0]            app_ib_2_fsm_addr,
    output wire [127:0]          app_ib_2_fsm_wdata, 
    output wire                  app_ib_2_fsm_wen,
    output wire                  app_ib_2_fsm_ena,
    output wire [6:0]            app_ib_3_fsm_addr,
    output wire [127:0]          app_ib_3_fsm_wdata, 
    output wire                  app_ib_3_fsm_wen,
    output wire                  app_ib_3_fsm_ena,
    input wire [127:0]           ib_0_rdata,
    input wire [127:0]           ib_1_rdata,
    input wire [127:0]           ib_2_rdata,
    input wire [127:0]           ib_3_rdata
);


// 配置寄存器译码
wire soft_rst, app_fsm_en;           // 1b: fsm_done，用于写回
assign soft_rst = mode_config_reg[0];
assign app_fsm_en = mode_config_reg[6];

// 配置寄存器 
wire [15:0] radius;  // 用于搜索半径
assign radius = mode_config_reg[47:32];

// 三段式状态机
    wire search_finish;

    reg [2:0] state;
    reg [2:0] next_state;

    localparam      IDLE = 3'b000, 
                    INIT = 3'b001,
                    READ = 3'b010,
                    SEARCH_L = 3'b011,
                    SEARCH_H = 3'b100,
                    DONE = 3'b110;
    
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
                if (app_fsm_en) begin
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
                next_state = SEARCH_L;
            end
            SEARCH_L: begin
                next_state = SEARCH_H;
            end
            SEARCH_H: begin
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
    reg [7:0]       app_rsam_addr;
    reg             app_rsam_wen;
    reg             app_rsam_ena;

    wire [63:0]     app_rsam_sl_l;
    wire [63:0]     app_rsam_sm_l;
    reg             app_rsam_sen_l;
    wire [63:0]     app_rsam_sl_h;
    wire [63:0]     app_rsam_sm_h;
    reg             app_rsam_sen_h;

    reg [255:0]     app_rsam_sdata_l;

    reg [7:0]       app_ib_addr;
    wire [255:0]    app_ib_wdata;
    reg             app_ib_wen;
    reg             app_ib_ena;

    //! 1. 读取RSAM数据
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            app_rsam_addr <= 8'b0;
            app_rsam_wen <= 1'b0;
            app_rsam_ena <= 1'b0;
        end
        else begin
            case(state)
                IDLE: begin
                    app_rsam_addr <= 8'b0;
                    app_rsam_wen <= 1'b0;
                    app_rsam_ena <= 1'b0;
                end
                INIT: begin
                    app_rsam_addr <= 8'b0 - 1'b1;
                    app_rsam_wen <= 1'b0;
                    app_rsam_ena <= 1'b0;
                end
                READ: begin
                    app_rsam_addr <= app_rsam_addr + 1'b1;
                    app_rsam_wen <= 1'b0;
                    app_rsam_ena <= 1'b1;
                end
                SEARCH_L: begin
                    app_rsam_addr <= app_rsam_addr;
                    app_rsam_wen <= 1'b0;
                    app_rsam_ena <= 1'b0;
                end
                SEARCH_H: begin
                    app_rsam_addr <= app_rsam_addr;
                    app_rsam_wen <= 1'b0;
                    app_rsam_ena <= 1'b0;
                end
                DONE: begin
                    app_rsam_addr <= app_rsam_addr;
                    app_rsam_wen <= 1'b0;
                    app_rsam_ena <= 1'b0;
                end
                default: begin
                    app_rsam_addr <= 8'b0;
                    app_rsam_wen <= 1'b0;
                    app_rsam_ena <= 1'b0;
                end
            endcase
        end
    end

    //! 2. 生成搜索pattern >= L
    wire [16:0] xl,yl,zl;
    wire [15:0] trunc_xl,trunc_yl,trunc_zl;
    assign xl = rsam_rdata[15:0] - radius;
    assign yl = rsam_rdata[31:16] - radius;
    assign zl = rsam_rdata[47:32] - radius;
    assign trunc_xl = (xl[16]) ? 16'b0 : xl[15:0];
    assign trunc_yl = (yl[16]) ? 16'b0 : yl[15:0];
    assign trunc_zl = (zl[16]) ? 16'b0 : zl[15:0];

    assign app_rsam_sl_l = {16'b0,trunc_zl,trunc_yl,trunc_xl};
    assign app_rsam_sm_l = {16'b0,trunc_zl,trunc_yl,trunc_xl};
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            app_rsam_sen_l <= 1'b0;
        end
        else begin
            if (app_rsam_ena) begin
                app_rsam_sen_l <= 1'b1;
            end
            else begin
                app_rsam_sen_l <= 1'b0;
            end
        end
    end

    //! 3. 生成搜索pattern <= H，同时缓存上一次的搜索结果
    wire [16:0] xh,yh,zh;
    wire [15:0] trunc_xh,trunc_yh,trunc_zh;
    assign xh = rsam_rdata[15:0] + radius;
    assign yh = rsam_rdata[31:16] + radius;
    assign zh = rsam_rdata[47:32] + radius;
    assign trunc_xh = (xh[16]) ? 16'hffff : xh[15:0];
    assign trunc_yh = (yh[16]) ? 16'hffff : yh[15:0];
    assign trunc_zh = (zh[16]) ? 16'hffff : zh[15:0];

    assign app_rsam_sl_h = {16'hffff,trunc_zh,trunc_yh,trunc_xh};
    assign app_rsam_sm_h = ~app_rsam_sl_h;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            app_rsam_sen_h <= 1'b0;
        end
        else begin
            if (app_rsam_sen_l) begin
                app_rsam_sen_h <= 1'b1;
            end
            else begin
                app_rsam_sen_h <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            app_rsam_sdata_l <= 256'h0;
        end
        else begin
            if (app_rsam_sen_h) begin
                app_rsam_sdata_l <= rsam_sdata;
            end
        end
    end

    //! 4. 将搜索结果写回Ibuffer
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            app_ib_addr <= 7'b0;
            app_ib_wen <= 1'b0;
            app_ib_ena <= 1'b0;
        end
        else begin
            if (next_state == INIT) begin
                app_ib_addr <= 7'b0 - 1'b1;
                app_ib_wen <= 1'b0;
                app_ib_ena <= 1'b0;
            end
            else if (app_rsam_sen_h) begin
                app_ib_addr <= app_ib_addr + 1'b1;
                app_ib_wen <= 1'b1;
                app_ib_ena <= 1'b1;
            end
            else begin
                app_ib_wen <= 1'b0;
                app_ib_ena <= 1'b0;
            end
        end
    end
    assign app_ib_wdata = rsam_sdata & app_rsam_sdata_l;

    //! 5. 结束条件
    assign search_finish = (app_rsam_addr == 8'hff);

    //! 5. 接口信号整合输出
    wire done;
    assign done = (state == DONE);

    // 写回配置寄存器，第1位（done）写1、第6位（en）写0
    assign app_mode_config_reg_wb = {mode_config_reg[63:7], 1'b0, mode_config_reg[5:2], 1'b1, mode_config_reg[0]};
    assign app_mode_config_reg_wb_en = done;

    assign app_rsam_fsm_addr = app_rsam_addr;
    assign app_rsam_fsm_wdata = 64'b0;
    assign app_rsam_fsm_wen = app_rsam_wen;
    assign app_rsam_fsm_ena = app_rsam_ena;
    assign app_rsam_fsm_sl = app_rsam_sen_l ? app_rsam_sl_l : app_rsam_sl_h;
    assign app_rsam_fsm_sm = app_rsam_sen_l ? app_rsam_sm_l : app_rsam_sm_h;
    assign app_rsam_fsm_sen = app_rsam_sen_l | app_rsam_sen_h;

    assign app_ib_0_fsm_addr = app_ib_addr[6:0];
    assign app_ib_0_fsm_wdata = app_ib_wdata[127:0];
    assign app_ib_0_fsm_wen = app_ib_wen;
    assign app_ib_0_fsm_ena = app_ib_ena & (app_ib_addr[7] == 1'b0);

    assign app_ib_1_fsm_addr = app_ib_addr[6:0];
    assign app_ib_1_fsm_wdata = app_ib_wdata[255:128];
    assign app_ib_1_fsm_wen = app_ib_wen;
    assign app_ib_1_fsm_ena = app_ib_ena & (app_ib_addr[7] == 1'b0);

    assign app_ib_2_fsm_addr = app_ib_addr[6:0];
    assign app_ib_2_fsm_wdata = app_ib_wdata[127:0];
    assign app_ib_2_fsm_wen = app_ib_wen;
    assign app_ib_2_fsm_ena = app_ib_ena & (app_ib_addr[7] == 1'b1);

    assign app_ib_3_fsm_addr = app_ib_addr[6:0];
    assign app_ib_3_fsm_wdata = app_ib_wdata[255:128];
    assign app_ib_3_fsm_wen = app_ib_wen;
    assign app_ib_3_fsm_ena = app_ib_ena & (app_ib_addr[7] == 1'b1);


endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: fsm_power
// Project Name: 
// Description: 用于进行功耗测试的状态机。功耗测试：一直读RSAM、一直写RSAM（数据来源于IB）、一直搜索RSAM（数据来源于IB）
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module fsm_power(
    input wire clk, // 时钟信号
    input wire rst_n, // 复位信号

    input  wire [63:0]           mode_config_reg, // 模式配置
    output wire [63:0]           power_mode_config_reg_wb, // 模式配置写回
    output wire                  power_mode_config_reg_wb_en, // 模式配置写回使能

    // signal to rsam 
    output wire [7:0]            power_rsam_fsm_addr,
    output wire [63:0]           power_rsam_fsm_wdata, // 数据信号16*4=64b
    output wire                  power_rsam_fsm_wen,
    output wire                  power_rsam_fsm_ena,
    output wire [63:0]           power_rsam_fsm_sl,
    output wire [63:0]           power_rsam_fsm_sm,
    output wire                  power_rsam_fsm_sen,
    input wire [63:0]            rsam_rdata,   // 读取数据信号, 16*3=64b
    input wire [255:0]           rsam_sdata,

    // signal to inputbuffer
    output wire [6:0]            power_ib_0_fsm_addr,
    output wire [127:0]          power_ib_0_fsm_wdata, 
    output wire                  power_ib_0_fsm_wen,
    output wire                  power_ib_0_fsm_ena,
    output wire [6:0]            power_ib_1_fsm_addr,
    output wire [127:0]          power_ib_1_fsm_wdata, 
    output wire                  power_ib_1_fsm_wen,
    output wire                  power_ib_1_fsm_ena,
    output wire [6:0]            power_ib_2_fsm_addr,
    output wire [127:0]          power_ib_2_fsm_wdata, 
    output wire                  power_ib_2_fsm_wen,
    output wire                  power_ib_2_fsm_ena,
    output wire [6:0]            power_ib_3_fsm_addr,
    output wire [127:0]          power_ib_3_fsm_wdata, 
    output wire                  power_ib_3_fsm_wen,
    output wire                  power_ib_3_fsm_ena,
    input wire [127:0]           ib_0_rdata,
    input wire [127:0]           ib_1_rdata,
    input wire [127:0]           ib_2_rdata,
    input wire [127:0]           ib_3_rdata
);

// 配置寄存器译码
wire soft_rst, power_rd_fsm_en, power_wr_fsm_en, power_search_fsm_en;

assign soft_rst = mode_config_reg[0];
assign power_rd_fsm_en = mode_config_reg[2];
assign power_wr_fsm_en = mode_config_reg[3];
assign power_search_fsm_en = mode_config_reg[4];

// 读取模式配置寄存器
wire [7:0] rd_rsam_start_addr;
wire [7:0] rd_rsam_addr_step;
assign rd_rsam_start_addr = mode_config_reg[15:8];
assign rd_rsam_addr_step = mode_config_reg[23:16];

// 写入模式配置寄存器
wire [7:0] wr_rsam_start_addr;
wire [7:0] wr_rsam_addr_step;
assign wr_rsam_start_addr = mode_config_reg[15:8];
assign wr_rsam_addr_step = mode_config_reg[23:16];


//! 1. 读取RSAM
    reg [7:0]             rd_fsm_addr;
    reg                   rd_fsm_wen;
    reg                   rd_fsm_ena;

    // 三段式状态机
    reg [2:0] rd_state;
    reg [2:0] rd_next_state;

    localparam  RD_IDLE = 3'b000,
                RD_READ_RSAM = 3'b001;

    // core logic 
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_state <= RD_IDLE;
        end
        else begin
            if (soft_rst) begin
                rd_state <= RD_IDLE;
            end
            else begin
                rd_state <= rd_next_state;
            end
        end
    end

    // state transition logic
    always @(*) begin
        case(rd_state)
            RD_IDLE: begin
                if (power_rd_fsm_en) begin
                    rd_next_state = RD_READ_RSAM;
                end
                else begin
                    rd_next_state = RD_IDLE;
                end
            end
            RD_READ_RSAM: begin
                if (soft_rst) begin
                    rd_next_state = RD_IDLE;
                end
                else begin
                    rd_next_state = RD_READ_RSAM;
                end
            end
            default: begin
                rd_next_state = RD_IDLE;
            end
        endcase
    end

    // state action, output logic
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rd_fsm_addr <= 8'b0;
            rd_fsm_wen <= 1'b0;
            rd_fsm_ena <= 1'b0;
        end
        else begin
            if (soft_rst) begin
                rd_fsm_addr <= 8'b0;
                rd_fsm_wen <= 1'b0;
                rd_fsm_ena <= 1'b0;
            end
            else begin
                case(rd_state)
                    RD_IDLE: begin
                        rd_fsm_addr <= rd_rsam_start_addr - rd_rsam_addr_step;
                        rd_fsm_wen <= 1'b0;
                        rd_fsm_ena <= 1'b0;
                    end
                    RD_READ_RSAM: begin
                        rd_fsm_addr <= rd_fsm_addr + rd_rsam_addr_step;      // 地址自增，连续读取
                        rd_fsm_wen <= 1'b0;
                        rd_fsm_ena <= 1'b1;
                    end
                    default: begin
                        rd_fsm_addr <= 8'b0;
                        rd_fsm_wen <= 1'b0;
                        rd_fsm_ena <= 1'b0;
                    end
                endcase
            end
        end
    end

//! 2. 读取Ibuffer，并将读取的数据写入RSAM

    // RSAM的大小是 256D*64W，简单起见，使用两块128D*128W的SRAM座位数据来源（第0块和第1块），只使用低64位
    reg [7:0]              wr_ib_addr; // 读取Ibuffer的地址，用第7位表示读取的是哪个Ibuffer
    reg                    wr_ib_wen;
    reg                    wr_ib_ena;
    reg [7:0]              wr_rsam_addr; // 写入RSAM的地址
    reg                    wr_rsam_wen;
    reg                    wr_rsam_ena;
    wire [63:0]            wr_rsam_wdata; // 写入RSAM的数据 读取的Ibuffer数据的低64位

    // 三段式状态机
    reg [2:0] wr_state;
    reg [2:0] wr_next_state;

    localparam  WR_IDLE = 3'b000,
                WR_READ_IB = 3'b001;    // 一个周期后WR_WRITE_RSAM
    
    // core logic
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_state <= WR_IDLE;
        end
        else begin
            if (soft_rst) begin
                wr_state <= WR_IDLE;
            end
            else begin
                wr_state <= wr_next_state;
            end
        end
    end

    // state transition logic
    always @(*) begin
        case(wr_state)
            WR_IDLE: begin
                if (power_wr_fsm_en) begin
                    wr_next_state = WR_READ_IB;
                end
                else begin
                    wr_next_state = WR_IDLE;
                end
            end
            WR_READ_IB: begin
                if (soft_rst) begin
                    wr_next_state = WR_IDLE;
                end
                else begin
                    wr_next_state = WR_READ_IB;
                end
            end
            default: begin
                wr_next_state = WR_IDLE;
            end
        endcase
    end

    // state action, output logic
    // 读取Ibuffer
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_ib_addr <= 8'b0;
            wr_ib_wen <= 1'b0;
            wr_ib_ena <= 1'b0;
        end
        else begin
            if (soft_rst) begin
                wr_ib_addr <= 8'b0;
                wr_ib_wen <= 1'b0;
                wr_ib_ena <= 1'b0;
            end
            else begin
                case(wr_state)
                    WR_IDLE: begin
                        wr_ib_addr <= 8'b0 - 8'b1;
                        wr_ib_wen <= 1'b0;
                        wr_ib_ena <= 1'b0;
                    end
                    WR_READ_IB: begin
                        wr_ib_addr <= wr_ib_addr + 1'b1;
                        wr_ib_wen <= 1'b0;
                        wr_ib_ena <= 1'b1;
                    end
                    default: begin
                        wr_ib_addr <= 8'b0;
                        wr_ib_wen <= 1'b0;
                        wr_ib_ena <= 1'b0;
                    end
                endcase
            end
        end
    end

    // 写入RSAM
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_rsam_addr <= 8'b0;
            wr_rsam_wen <= 1'b0;
            wr_rsam_ena <= 1'b0;
        end
        else begin
            if (wr_ib_ena) begin
                wr_rsam_addr <= wr_rsam_addr + wr_rsam_addr_step;
                wr_rsam_wen <= 1'b1;
                wr_rsam_ena <= 1'b1;
            end
            else begin
                wr_rsam_addr <= wr_rsam_start_addr - wr_rsam_addr_step;
                wr_rsam_wen <= 1'b0;
                wr_rsam_ena <= 1'b0;
            end
        end
    end

    // 读取的Ibuffer的数据
    reg wr_ce_reg;
    always @(posedge clk) begin
        wr_ce_reg <= wr_ib_addr[7];
    end
    assign wr_rsam_wdata = wr_ce_reg ? ib_1_rdata[63:0] : ib_0_rdata[63:0];

//! 3. 读取Ibuffer，并将读取的数据用来进行RSAM搜索
    
    // RSAM的大小是 256D*64W，简单起见，使用一块128D*128W的SRAM座位数据来源（第2块）
    reg [6:0]              search_ib_addr; // 读取Ibuffer的地址，用第7位表示读取的是哪个Ibuffer
    reg                    search_ib_wen;
    reg                    search_ib_ena;
    wire [63:0]            search_rsam_sl;  // 搜索数据来自于IB的输出 [63:0]
    wire [63:0]            search_rsam_sm;  // 搜索数据来自于IB的输出 [127:64]
    reg                    search_rsam_sen;

    // 三段式状态机
    reg [2:0] search_state;
    reg [2:0] search_next_state;

    localparam  SEARCH_IDLE = 3'b000,
                SEARCH_READ_IB = 3'b001;    // 一个周期后SEARCH_WRITE_RSAM
    
    // core logic
    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            search_state <= SEARCH_IDLE;
        end
        else begin
            if (soft_rst) begin
                search_state <= SEARCH_IDLE;
            end
            else begin
                search_state <= search_next_state;
            end
        end
    end

    // state transition logic
    always @(*) begin
        case(search_state)
            SEARCH_IDLE: begin
                if (power_search_fsm_en) begin
                    search_next_state = SEARCH_READ_IB;
                end
                else begin
                    search_next_state = SEARCH_IDLE;
                end
            end
            SEARCH_READ_IB: begin
                if (soft_rst) begin
                    search_next_state = SEARCH_IDLE;
                end
                else begin
                    search_next_state = SEARCH_READ_IB;
                end
            end
            default: begin
                search_next_state = SEARCH_IDLE;
            end
        endcase
    end

    // state action, output logic
    // 读取Ibuffer
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            search_ib_addr <= 7'b0;
            search_ib_wen <= 1'b0;
            search_ib_ena <= 1'b0;
        end
        else begin
            if (soft_rst) begin
                search_ib_addr <= 7'b0;
                search_ib_wen <= 1'b0;
                search_ib_ena <= 1'b0;
            end
            else begin
                case(search_state)
                    SEARCH_IDLE: begin
                        search_ib_addr <= 7'b0 - 7'b1;
                        search_ib_wen <= 1'b0;
                        search_ib_ena <= 1'b0;
                    end
                    SEARCH_READ_IB: begin
                        search_ib_addr <= search_ib_addr + 1'b1;
                        search_ib_wen <= 1'b0;
                        search_ib_ena <= 1'b1;
                    end
                    default: begin
                        search_ib_addr <= 7'b0;
                        search_ib_wen <= 1'b0;
                        search_ib_ena <= 1'b0;
                    end
                endcase
            end
        end
    end

    // 对RSAM进行搜索
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            search_rsam_sen <= 1'b0;
        end
        else begin
            if (search_ib_ena) begin
                search_rsam_sen <= 1'b1;
            end
            else begin
                search_rsam_sen <= 1'b0;
            end
        end
    end

    // 读取的Ibuffer的数据
    assign search_rsam_sl = ib_2_rdata[63:0];
    assign search_rsam_sm = ib_2_rdata[127:64];

//! 4. 接口信号整合输出

    assign power_mode_config_reg_wb = mode_config_reg;
    assign power_mode_config_reg_wb_en = 1'b0;
    
    assign power_rsam_fsm_ena = rd_fsm_ena | wr_rsam_ena;
    assign power_rsam_fsm_wen = wr_rsam_ena ? wr_rsam_wen : rd_fsm_wen;
    assign power_rsam_fsm_addr = wr_rsam_ena ? wr_rsam_addr : rd_fsm_addr;
    assign power_rsam_fsm_wdata = wr_rsam_wdata;
    assign power_rsam_fsm_sl = search_rsam_sl;
    assign power_rsam_fsm_sm = search_rsam_sm;
    assign power_rsam_fsm_sen = search_rsam_sen;

    assign power_ib_0_fsm_addr = wr_ib_addr[6:0];
    assign power_ib_0_fsm_wdata = 128'b0;
    assign power_ib_0_fsm_wen = wr_ib_wen;
    assign power_ib_0_fsm_ena = wr_ib_ena & (wr_ib_addr[7] == 1'b0);

    assign power_ib_1_fsm_addr = wr_ib_addr[6:0];
    assign power_ib_1_fsm_wdata = 128'b0;
    assign power_ib_1_fsm_wen = wr_ib_wen;
    assign power_ib_1_fsm_ena = wr_ib_ena & (wr_ib_addr[7] == 1'b1);

    assign power_ib_2_fsm_addr = search_ib_addr;
    assign power_ib_2_fsm_wdata = 128'b0;
    assign power_ib_2_fsm_wen = search_ib_wen;
    assign power_ib_2_fsm_ena = search_ib_ena;

    assign power_ib_3_fsm_addr = 7'b0;
    assign power_ib_3_fsm_wdata = 128'b0;
    assign power_ib_3_fsm_wen = 1'b0;
    assign power_ib_3_fsm_ena = 1'b0;




endmodule
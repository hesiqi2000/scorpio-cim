`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: fsm_total
// Project Name: 
// Description: 所有fsm的包装模块
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module fsm_total(
    input wire clk, // 时钟信号
    input wire rst_n, // 复位信号

    input  wire [63:0]           mode_config_reg, // 模式配置
    output wire [63:0]           mode_config_reg_wb, // 模式配置写回
    output wire                  mode_config_reg_wb_en, // 模式配置写回使能

    // signal to rsam 
    output wire [8-1:0]          rsam_fsm_addr,
    output wire [16*4-1:0]       rsam_fsm_wdata, // 数据信号16*4=64b
    output wire                  rsam_fsm_wen,
    output wire                  rsam_fsm_ena,
    output wire [16*4-1:0]       rsam_fsm_sl,
    output wire [16*4-1:0]       rsam_fsm_sm,
    output wire                  rsam_fsm_sen,
    input wire [63:0]            rsam_rdata,   // 读取数据信号, 16*3=64b
    input wire [255:0]           rsam_sdata,

    // signal to inputbuffer
    output wire [6:0]            ib_0_fsm_addr,
    output wire [127:0]          ib_0_fsm_wdata, 
    output wire                  ib_0_fsm_wen,
    output wire                  ib_0_fsm_ena,
    output wire [6:0]            ib_1_fsm_addr,
    output wire [127:0]          ib_1_fsm_wdata, 
    output wire                  ib_1_fsm_wen,
    output wire                  ib_1_fsm_ena,
    output wire [6:0]            ib_2_fsm_addr,
    output wire [127:0]          ib_2_fsm_wdata, 
    output wire                  ib_2_fsm_wen,
    output wire                  ib_2_fsm_ena,
    output wire [6:0]            ib_3_fsm_addr,
    output wire [127:0]          ib_3_fsm_wdata, 
    output wire                  ib_3_fsm_wen,
    output wire                  ib_3_fsm_ena,
    input wire [127:0]           ib_0_rdata,
    input wire [127:0]           ib_1_rdata,
    input wire [127:0]           ib_2_rdata,
    input wire [127:0]           ib_3_rdata
);

// 需要包含的功能包括：
// 1. 功耗测试：一直读RSAM、一直写RSAM（数据来源于IB）、一直搜索RSAM（数据来源于IB）
// 2. 原子操作：从IB的指定地址（范围）读取数据用于RSAM搜索，然后将搜索结果写回IB的指定地址（范围）
// 3. 实际应用：从RSAM读取点云信息（范围），按照配置信息进行处理，然后进行搜索，将搜索结果写回IB的指定地址（范围）
// 划分为三个FSM：fsm_power、fsm_atomic、fsm_app

// mode_config_reg的配置信息
// 0b: soft_rst 
// 1b: fsm_done
// 2b: power_rd_fsm_en       // 使用soft_rst来控制结束
// 3b: power_wr_fsm_en       // 使用soft_rst来控制结束
// 4b: power_search_fsm_en   // 使用soft_rst来控制结束
// 5b: atomic_fsm_en
// 6b: app_fsm_en

// 剩下的bit根据不同的FSM来进行译码
    // 读取功耗
        // rd_rsam_start_addr = mode_config_reg[15:8];
        // rd_rsam_addr_step = mode_config_reg[23:16];
    // 写入功耗
        // wr_rsam_start_addr = mode_config_reg[15:8];
        // wr_rsam_addr_step = mode_config_reg[23:16];
        // 其中，数据来源于IB，地址从0开始逐次加一 0~255
    // atomic 
        // rd_sram_start_addr = mode_config_reg[14:8];
        // rd_sram_end_addr = mode_config_reg[21:15];
        // wr_sram_start_addr = mode_config_reg[28:22];
    // app
        // radius = mode_config_reg[47:32];


// output wire
    wire [63:0]  	power_mode_config_reg_wb;
    wire         	power_mode_config_reg_wb_en;
    wire [7:0]   	power_rsam_fsm_addr;
    wire [63:0]  	power_rsam_fsm_wdata;
    wire         	power_rsam_fsm_wen;
    wire         	power_rsam_fsm_ena;
    wire [63:0]  	power_rsam_fsm_sl;
    wire [63:0]  	power_rsam_fsm_sm;
    wire         	power_rsam_fsm_sen;
    wire [6:0]   	power_ib_0_fsm_addr;
    wire [127:0] 	power_ib_0_fsm_wdata;
    wire         	power_ib_0_fsm_wen;
    wire         	power_ib_0_fsm_ena;
    wire [6:0]   	power_ib_1_fsm_addr;
    wire [127:0] 	power_ib_1_fsm_wdata;
    wire         	power_ib_1_fsm_wen;
    wire         	power_ib_1_fsm_ena;
    wire [6:0]   	power_ib_2_fsm_addr;
    wire [127:0] 	power_ib_2_fsm_wdata;
    wire         	power_ib_2_fsm_wen;
    wire         	power_ib_2_fsm_ena;
    wire [6:0]   	power_ib_3_fsm_addr;
    wire [127:0] 	power_ib_3_fsm_wdata;
    wire         	power_ib_3_fsm_wen;
    wire         	power_ib_3_fsm_ena;

    wire [63:0]  	atomic_mode_config_reg_wb;
    wire         	atomic_mode_config_reg_wb_en;
    wire [7:0]   	atomic_rsam_fsm_addr;
    wire [63:0]  	atomic_rsam_fsm_wdata;
    wire         	atomic_rsam_fsm_wen;
    wire         	atomic_rsam_fsm_ena;
    wire [63:0]  	atomic_rsam_fsm_sl;
    wire [63:0]  	atomic_rsam_fsm_sm;
    wire         	atomic_rsam_fsm_sen;
    wire [6:0]   	atomic_ib_0_fsm_addr;
    wire [127:0] 	atomic_ib_0_fsm_wdata;
    wire         	atomic_ib_0_fsm_wen;
    wire         	atomic_ib_0_fsm_ena;
    wire [6:0]   	atomic_ib_1_fsm_addr;
    wire [127:0] 	atomic_ib_1_fsm_wdata;
    wire         	atomic_ib_1_fsm_wen;
    wire         	atomic_ib_1_fsm_ena;
    wire [6:0]   	atomic_ib_2_fsm_addr;
    wire [127:0] 	atomic_ib_2_fsm_wdata;
    wire         	atomic_ib_2_fsm_wen;
    wire         	atomic_ib_2_fsm_ena;
    wire [6:0]   	atomic_ib_3_fsm_addr;
    wire [127:0] 	atomic_ib_3_fsm_wdata;
    wire         	atomic_ib_3_fsm_wen;
    wire         	atomic_ib_3_fsm_ena;

    wire [63:0]  	app_mode_config_reg_wb;
    wire         	app_mode_config_reg_wb_en;
    wire [7:0]   	app_rsam_fsm_addr;
    wire [63:0]  	app_rsam_fsm_wdata;
    wire         	app_rsam_fsm_wen;
    wire         	app_rsam_fsm_ena;
    wire [63:0]  	app_rsam_fsm_sl;
    wire [63:0]  	app_rsam_fsm_sm;
    wire         	app_rsam_fsm_sen;
    wire [6:0]   	app_ib_0_fsm_addr;
    wire [127:0] 	app_ib_0_fsm_wdata;
    wire         	app_ib_0_fsm_wen;
    wire         	app_ib_0_fsm_ena;
    wire [6:0]   	app_ib_1_fsm_addr;
    wire [127:0] 	app_ib_1_fsm_wdata;
    wire         	app_ib_1_fsm_wen;
    wire         	app_ib_1_fsm_ena;
    wire [6:0]   	app_ib_2_fsm_addr;
    wire [127:0] 	app_ib_2_fsm_wdata;
    wire         	app_ib_2_fsm_wen;
    wire         	app_ib_2_fsm_ena;
    wire [6:0]   	app_ib_3_fsm_addr;
    wire [127:0] 	app_ib_3_fsm_wdata;
    wire         	app_ib_3_fsm_wen;
    wire         	app_ib_3_fsm_ena;

// 接口信号整合输出
    assign mode_config_reg_wb = power_mode_config_reg_wb_en ? power_mode_config_reg_wb : 
                                atomic_mode_config_reg_wb_en ? atomic_mode_config_reg_wb : app_mode_config_reg_wb;
    assign mode_config_reg_wb_en = power_mode_config_reg_wb_en | atomic_mode_config_reg_wb_en | app_mode_config_reg_wb_en;

    assign rsam_fsm_addr = power_rsam_fsm_ena ? power_rsam_fsm_addr : 
                           atomic_rsam_fsm_ena ? atomic_rsam_fsm_addr : app_rsam_fsm_addr;
    assign rsam_fsm_wdata = power_rsam_fsm_ena ? power_rsam_fsm_wdata : 
                            atomic_rsam_fsm_ena ? atomic_rsam_fsm_wdata : app_rsam_fsm_wdata;
    assign rsam_fsm_wen = power_rsam_fsm_ena ? power_rsam_fsm_wen : 
                          atomic_rsam_fsm_ena ? atomic_rsam_fsm_wen : app_rsam_fsm_wen;
    assign rsam_fsm_ena = power_rsam_fsm_ena | atomic_rsam_fsm_ena | app_rsam_fsm_ena;

    assign rsam_fsm_sl = power_rsam_fsm_sen ? power_rsam_fsm_sl : 
                         atomic_rsam_fsm_sen ? atomic_rsam_fsm_sl : app_rsam_fsm_sl;
    assign rsam_fsm_sm = power_rsam_fsm_sen ? power_rsam_fsm_sm : 
                         atomic_rsam_fsm_sen ? atomic_rsam_fsm_sm : app_rsam_fsm_sm;
    assign rsam_fsm_sen = power_rsam_fsm_sen | atomic_rsam_fsm_sen | app_rsam_fsm_sen;


    assign ib_0_fsm_addr = power_ib_0_fsm_ena ? power_ib_0_fsm_addr : 
                           atomic_ib_0_fsm_ena ? atomic_ib_0_fsm_addr : app_ib_0_fsm_addr;
    assign ib_0_fsm_wdata = power_ib_0_fsm_ena ? power_ib_0_fsm_wdata : 
                            atomic_ib_0_fsm_ena ? atomic_ib_0_fsm_wdata : app_ib_0_fsm_wdata;
    assign ib_0_fsm_wen = power_ib_0_fsm_ena ? power_ib_0_fsm_wen : 
                          atomic_ib_0_fsm_ena ? atomic_ib_0_fsm_wen : app_ib_0_fsm_wen;
    assign ib_0_fsm_ena = power_ib_0_fsm_ena | atomic_ib_0_fsm_ena | app_ib_0_fsm_ena;

    assign ib_1_fsm_addr = power_ib_1_fsm_ena ? power_ib_1_fsm_addr : 
                           atomic_ib_1_fsm_ena ? atomic_ib_1_fsm_addr : app_ib_1_fsm_addr;
    assign ib_1_fsm_wdata = power_ib_1_fsm_ena ? power_ib_1_fsm_wdata : 
                            atomic_ib_1_fsm_ena ? atomic_ib_1_fsm_wdata : app_ib_1_fsm_wdata;
    assign ib_1_fsm_wen = power_ib_1_fsm_ena ? power_ib_1_fsm_wen : 
                          atomic_ib_1_fsm_ena ? atomic_ib_1_fsm_wen : app_ib_1_fsm_wen;
    assign ib_1_fsm_ena = power_ib_1_fsm_ena | atomic_ib_1_fsm_ena | app_ib_1_fsm_ena;

    assign ib_2_fsm_addr = power_ib_2_fsm_ena ? power_ib_2_fsm_addr : 
                           atomic_ib_2_fsm_ena ? atomic_ib_2_fsm_addr : app_ib_2_fsm_addr;
    assign ib_2_fsm_wdata = power_ib_2_fsm_ena ? power_ib_2_fsm_wdata : 
                            atomic_ib_2_fsm_ena ? atomic_ib_2_fsm_wdata : app_ib_2_fsm_wdata;
    assign ib_2_fsm_wen = power_ib_2_fsm_ena ? power_ib_2_fsm_wen : 
                          atomic_ib_2_fsm_ena ? atomic_ib_2_fsm_wen : app_ib_2_fsm_wen;
    assign ib_2_fsm_ena = power_ib_2_fsm_ena | atomic_ib_2_fsm_ena | app_ib_2_fsm_ena;

    assign ib_3_fsm_addr = power_ib_3_fsm_ena ? power_ib_3_fsm_addr : 
                           atomic_ib_3_fsm_ena ? atomic_ib_3_fsm_addr : app_ib_3_fsm_addr;
    assign ib_3_fsm_wdata = power_ib_3_fsm_ena ? power_ib_3_fsm_wdata : 
                            atomic_ib_3_fsm_ena ? atomic_ib_3_fsm_wdata : app_ib_3_fsm_wdata;
    assign ib_3_fsm_wen = power_ib_3_fsm_ena ? power_ib_3_fsm_wen : 
                          atomic_ib_3_fsm_ena ? atomic_ib_3_fsm_wen : app_ib_3_fsm_wen;
    assign ib_3_fsm_ena = power_ib_3_fsm_ena | atomic_ib_3_fsm_ena | app_ib_3_fsm_ena;

// 例化fsm_power
fsm_power u_fsm_power(
	.clk                         	( clk                          ),
	.rst_n                       	( rst_n                        ),
	.mode_config_reg             	( mode_config_reg              ),
	.power_mode_config_reg_wb    	( power_mode_config_reg_wb     ),
	.power_mode_config_reg_wb_en 	( power_mode_config_reg_wb_en  ),
	.power_rsam_fsm_addr         	( power_rsam_fsm_addr          ),
	.power_rsam_fsm_wdata        	( power_rsam_fsm_wdata         ),
	.power_rsam_fsm_wen          	( power_rsam_fsm_wen           ),
	.power_rsam_fsm_ena          	( power_rsam_fsm_ena           ),
	.power_rsam_fsm_sl           	( power_rsam_fsm_sl            ),
	.power_rsam_fsm_sm           	( power_rsam_fsm_sm            ),
	.power_rsam_fsm_sen          	( power_rsam_fsm_sen           ),
	.rsam_rdata                  	( rsam_rdata                   ),
	.rsam_sdata                  	( rsam_sdata                   ),
	.power_ib_0_fsm_addr         	( power_ib_0_fsm_addr          ),
	.power_ib_0_fsm_wdata        	( power_ib_0_fsm_wdata         ),
	.power_ib_0_fsm_wen          	( power_ib_0_fsm_wen           ),
	.power_ib_0_fsm_ena          	( power_ib_0_fsm_ena           ),
	.power_ib_1_fsm_addr         	( power_ib_1_fsm_addr          ),
	.power_ib_1_fsm_wdata        	( power_ib_1_fsm_wdata         ),
	.power_ib_1_fsm_wen          	( power_ib_1_fsm_wen           ),
	.power_ib_1_fsm_ena          	( power_ib_1_fsm_ena           ),
	.power_ib_2_fsm_addr         	( power_ib_2_fsm_addr          ),
	.power_ib_2_fsm_wdata        	( power_ib_2_fsm_wdata         ),
	.power_ib_2_fsm_wen          	( power_ib_2_fsm_wen           ),
	.power_ib_2_fsm_ena          	( power_ib_2_fsm_ena           ),
	.power_ib_3_fsm_addr         	( power_ib_3_fsm_addr          ),
	.power_ib_3_fsm_wdata        	( power_ib_3_fsm_wdata         ),
	.power_ib_3_fsm_wen          	( power_ib_3_fsm_wen           ),
	.power_ib_3_fsm_ena          	( power_ib_3_fsm_ena           ),
	.ib_0_rdata                  	( ib_0_rdata                   ),
	.ib_1_rdata                  	( ib_1_rdata                   ),
	.ib_2_rdata                  	( ib_2_rdata                   ),
	.ib_3_rdata                  	( ib_3_rdata                   )
);

// 例化fsm_atomic
fsm_atomic u_fsm_atomic(
	.clk                          	( clk                           ),
	.rst_n                        	( rst_n                         ),
	.mode_config_reg              	( mode_config_reg               ),
	.atomic_mode_config_reg_wb    	( atomic_mode_config_reg_wb     ),
	.atomic_mode_config_reg_wb_en 	( atomic_mode_config_reg_wb_en  ),
	.atomic_rsam_fsm_addr         	( atomic_rsam_fsm_addr          ),
	.atomic_rsam_fsm_wdata        	( atomic_rsam_fsm_wdata         ),
	.atomic_rsam_fsm_wen          	( atomic_rsam_fsm_wen           ),
	.atomic_rsam_fsm_ena          	( atomic_rsam_fsm_ena           ),
	.atomic_rsam_fsm_sl           	( atomic_rsam_fsm_sl            ),
	.atomic_rsam_fsm_sm           	( atomic_rsam_fsm_sm            ),
	.atomic_rsam_fsm_sen          	( atomic_rsam_fsm_sen           ),
	.rsam_rdata                   	( rsam_rdata                    ),
	.rsam_sdata                   	( rsam_sdata                    ),
	.atomic_ib_0_fsm_addr         	( atomic_ib_0_fsm_addr          ),
	.atomic_ib_0_fsm_wdata        	( atomic_ib_0_fsm_wdata         ),
	.atomic_ib_0_fsm_wen          	( atomic_ib_0_fsm_wen           ),
	.atomic_ib_0_fsm_ena          	( atomic_ib_0_fsm_ena           ),
	.atomic_ib_1_fsm_addr         	( atomic_ib_1_fsm_addr          ),
	.atomic_ib_1_fsm_wdata        	( atomic_ib_1_fsm_wdata         ),
	.atomic_ib_1_fsm_wen          	( atomic_ib_1_fsm_wen           ),
	.atomic_ib_1_fsm_ena          	( atomic_ib_1_fsm_ena           ),
	.atomic_ib_2_fsm_addr         	( atomic_ib_2_fsm_addr          ),
	.atomic_ib_2_fsm_wdata        	( atomic_ib_2_fsm_wdata         ),
	.atomic_ib_2_fsm_wen          	( atomic_ib_2_fsm_wen           ),
	.atomic_ib_2_fsm_ena          	( atomic_ib_2_fsm_ena           ),
	.atomic_ib_3_fsm_addr         	( atomic_ib_3_fsm_addr          ),
	.atomic_ib_3_fsm_wdata        	( atomic_ib_3_fsm_wdata         ),
	.atomic_ib_3_fsm_wen          	( atomic_ib_3_fsm_wen           ),
	.atomic_ib_3_fsm_ena          	( atomic_ib_3_fsm_ena           ),
	.ib_0_rdata                   	( ib_0_rdata                    ),
	.ib_1_rdata                   	( ib_1_rdata                    ),
	.ib_2_rdata                   	( ib_2_rdata                    ),
	.ib_3_rdata                   	( ib_3_rdata                    )
);

// 例化fsm_app
fsm_app u_fsm_app(
	.clk                       	( clk                        ),
	.rst_n                     	( rst_n                      ),
	.mode_config_reg           	( mode_config_reg            ),
	.app_mode_config_reg_wb    	( app_mode_config_reg_wb     ),
	.app_mode_config_reg_wb_en 	( app_mode_config_reg_wb_en  ),
	.app_rsam_fsm_addr         	( app_rsam_fsm_addr          ),
	.app_rsam_fsm_wdata        	( app_rsam_fsm_wdata         ),
	.app_rsam_fsm_wen          	( app_rsam_fsm_wen           ),
	.app_rsam_fsm_ena          	( app_rsam_fsm_ena           ),
	.app_rsam_fsm_sl           	( app_rsam_fsm_sl            ),
	.app_rsam_fsm_sm           	( app_rsam_fsm_sm            ),
	.app_rsam_fsm_sen          	( app_rsam_fsm_sen           ),
	.rsam_rdata                	( rsam_rdata                 ),
	.rsam_sdata                	( rsam_sdata                 ),
	.app_ib_0_fsm_addr         	( app_ib_0_fsm_addr          ),
	.app_ib_0_fsm_wdata        	( app_ib_0_fsm_wdata         ),
	.app_ib_0_fsm_wen          	( app_ib_0_fsm_wen           ),
	.app_ib_0_fsm_ena          	( app_ib_0_fsm_ena           ),
	.app_ib_1_fsm_addr         	( app_ib_1_fsm_addr          ),
	.app_ib_1_fsm_wdata        	( app_ib_1_fsm_wdata         ),
	.app_ib_1_fsm_wen          	( app_ib_1_fsm_wen           ),
	.app_ib_1_fsm_ena          	( app_ib_1_fsm_ena           ),
	.app_ib_2_fsm_addr         	( app_ib_2_fsm_addr          ),
	.app_ib_2_fsm_wdata        	( app_ib_2_fsm_wdata         ),
	.app_ib_2_fsm_wen          	( app_ib_2_fsm_wen           ),
	.app_ib_2_fsm_ena          	( app_ib_2_fsm_ena           ),
	.app_ib_3_fsm_addr         	( app_ib_3_fsm_addr          ),
	.app_ib_3_fsm_wdata        	( app_ib_3_fsm_wdata         ),
	.app_ib_3_fsm_wen          	( app_ib_3_fsm_wen           ),
	.app_ib_3_fsm_ena          	( app_ib_3_fsm_ena           ),
	.ib_0_rdata                	( ib_0_rdata                 ),
	.ib_1_rdata                	( ib_1_rdata                 ),
	.ib_2_rdata                	( ib_2_rdata                 ),
	.ib_3_rdata                	( ib_3_rdata                 )
);




endmodule
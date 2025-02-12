`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: pixi_top
// Project Name: 
// Description: 包括fsm、memory、config_reg等模块，以及暂时用的axi2mem模块
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module pixi_top(
    input wire          clk, // 时钟信号
    input wire          rst_n, // 复位信号
    input wire        	bus_en,
    input wire          bus_we,
    input wire [20:0] 	bus_addr,
    input wire [127:0] 	bus_wrdata,
    output wire [127:0] bus_rddata
);


// outports wire
    wire [63:0]     	mode_config_reg_wb;
    wire            	mode_config_reg_wb_en;
    wire [8-1:0]    	rsam_fsm_addr;
    wire [16*4-1:0] 	rsam_fsm_wdata;
    wire            	rsam_fsm_wen;
    wire            	rsam_fsm_ena;
    wire [16*4-1:0] 	rsam_fsm_sl;
    wire [16*4-1:0] 	rsam_fsm_sm;
    wire            	rsam_fsm_sen;
    wire [6:0]      	ib_0_fsm_addr;
    wire [127:0]    	ib_0_fsm_wdata;
    wire            	ib_0_fsm_wen;
    wire            	ib_0_fsm_ena;
    wire [6:0]      	ib_1_fsm_addr;
    wire [127:0]    	ib_1_fsm_wdata;
    wire            	ib_1_fsm_wen;
    wire            	ib_1_fsm_ena;
    wire [6:0]      	ib_2_fsm_addr;
    wire [127:0]    	ib_2_fsm_wdata;
    wire            	ib_2_fsm_wen;
    wire            	ib_2_fsm_ena;
    wire [6:0]      	ib_3_fsm_addr;
    wire [127:0]    	ib_3_fsm_wdata;
    wire            	ib_3_fsm_wen;
    wire            	ib_3_fsm_ena;
// outports wire
    wire [63:0] 	    mode_config_reg;
// outports wire
    wire [63:0] 	    rsam_rdata;
    wire [255:0]     	rsam_sdata;
// outports wire
    wire [127:0] 	    ib_rdata;
    wire [127:0] 	    ib_0_rdata;
    wire [127:0] 	    ib_1_rdata;
    wire [127:0] 	    ib_2_rdata;
    wire [127:0] 	    ib_3_rdata;


    wire [63:0]     	config_fsm_wdata;
    wire            	config_fsm_wen;
    wire            	config_fsm_ena;
    assign config_fsm_wdata = mode_config_reg_wb;
    assign config_fsm_wen = mode_config_reg_wb_en;
    assign config_fsm_ena = mode_config_reg_wb_en;


// bus inports wire
    wire [63:0]     	config_bus_wdata;
    wire            	config_bus_wen;
    wire            	config_bus_ena;
    wire [7:0]          rsam_bus_addr;
    wire [63:0]         rsam_bus_wdata;
    wire                rsam_bus_wen;
    wire                rsam_bus_ena;
    wire [8:0]          ib_bus_addr;
    wire [127:0]        ib_bus_wdata;
    wire                ib_bus_wen;
    wire                ib_bus_ena;


// 地址空间分配，输入的addr一个地址控制8b，我们按照128b一次写入进行控制，每次地址需要+0x10
    // config reg：0x0000-0x000F  （1*64b，扩到1*128b）
    // rsam：0x1000-0x1FFF        （256*64b，扩到256*128b）
    // sram：0x2000-0x3FFF        （512*128b）

    // 根据地址分配，生成每个模块的地址信号和使能信号和数据信号
    assign config_bus_ena = bus_en & (bus_addr >= 20'h0 ) & (bus_addr < 20'h10 );
    assign config_bus_wdata = bus_wrdata[63:0];
    assign config_bus_wen = bus_we;

    assign rsam_bus_ena = bus_en & (bus_addr >= 20'h1000 ) & (bus_addr < 20'h2000 );
    assign rsam_bus_addr = bus_addr[11:4];
    assign rsam_bus_wdata = bus_wrdata;
    assign rsam_bus_wen = bus_we;

    assign ib_bus_ena = bus_en & (bus_addr >= 20'h2000 ) & (bus_addr < 20'h4000 );
    assign ib_bus_addr = bus_addr[11:4];
    assign ib_bus_wdata = bus_wrdata;
    assign ib_bus_wen = bus_we;

    // 生成总线读取数据信号
    reg [20:0] addr_reg;
    always @(posedge clk) begin
        if (bus_en & ~bus_we) begin
            addr_reg <= bus_addr;
        end
    end
    assign bus_rddata = (addr_reg >= 20'h2000) ? ib_rdata : 
                        (addr_reg >= 20'h1000) ? {64'd0,rsam_rdata} : {64'd0,mode_config_reg};
                        



// 模块例化
    // 状态机核心控制模块
        fsm_total u_fsm_total(
            .clk                   	( clk                    ),
            .rst_n                 	( rst_n                  ),
            .mode_config_reg       	( mode_config_reg        ),
            .mode_config_reg_wb    	( mode_config_reg_wb     ),
            .mode_config_reg_wb_en 	( mode_config_reg_wb_en  ),
            .rsam_fsm_addr         	( rsam_fsm_addr          ),
            .rsam_fsm_wdata        	( rsam_fsm_wdata         ),
            .rsam_fsm_wen          	( rsam_fsm_wen           ),
            .rsam_fsm_ena          	( rsam_fsm_ena           ),
            .rsam_fsm_sl           	( rsam_fsm_sl            ),
            .rsam_fsm_sm           	( rsam_fsm_sm            ),
            .rsam_fsm_sen          	( rsam_fsm_sen           ),
            .rsam_rdata            	( rsam_rdata             ),
            .rsam_sdata            	( rsam_sdata             ),
            .ib_0_fsm_addr         	( ib_0_fsm_addr          ),
            .ib_0_fsm_wdata        	( ib_0_fsm_wdata         ),
            .ib_0_fsm_wen          	( ib_0_fsm_wen           ),
            .ib_0_fsm_ena          	( ib_0_fsm_ena           ),
            .ib_1_fsm_addr         	( ib_1_fsm_addr          ),
            .ib_1_fsm_wdata        	( ib_1_fsm_wdata         ),
            .ib_1_fsm_wen          	( ib_1_fsm_wen           ),
            .ib_1_fsm_ena          	( ib_1_fsm_ena           ),
            .ib_2_fsm_addr         	( ib_2_fsm_addr          ),
            .ib_2_fsm_wdata        	( ib_2_fsm_wdata         ),
            .ib_2_fsm_wen          	( ib_2_fsm_wen           ),
            .ib_2_fsm_ena          	( ib_2_fsm_ena           ),
            .ib_3_fsm_addr         	( ib_3_fsm_addr          ),
            .ib_3_fsm_wdata        	( ib_3_fsm_wdata         ),
            .ib_3_fsm_wen          	( ib_3_fsm_wen           ),
            .ib_3_fsm_ena          	( ib_3_fsm_ena           ),
            .ib_0_rdata            	( ib_0_rdata             ),
            .ib_1_rdata            	( ib_1_rdata             ),
            .ib_2_rdata            	( ib_2_rdata             ),
            .ib_3_rdata            	( ib_3_rdata             )
        );

    // config reg 模块
        config_reg u_config_reg(
            .clk              	( clk               ),
            .rst_n            	( rst_n             ),
            .config_bus_wdata 	( config_bus_wdata  ),
            .config_bus_wen   	( config_bus_wen    ),
            .config_bus_ena   	( config_bus_ena    ),
            .config_fsm_wdata 	( config_fsm_wdata  ),
            .config_fsm_wen   	( config_fsm_wen    ),
            .config_fsm_ena   	( config_fsm_ena    ),
            .mode_config_reg  	( mode_config_reg   )
        );

    // rsam模块 
        rsam_io_256_16_4 #(
            .DATA_WIDTH 	( 16  ),
            .ADDR_WIDTH 	( 8   ),
            .BANK_NUM   	( 4   ))
        u_rsam_io_256_16_4(
            .clk            	( clk             ),
            .rsam_bus_addr  	( rsam_bus_addr   ),
            .rsam_bus_wdata 	( rsam_bus_wdata  ),
            .rsam_bus_wen   	( rsam_bus_wen    ),
            .rsam_bus_ena   	( rsam_bus_ena    ),
            .rsam_fsm_addr  	( rsam_fsm_addr   ),
            .rsam_fsm_wdata 	( rsam_fsm_wdata  ),
            .rsam_fsm_wen   	( rsam_fsm_wen    ),
            .rsam_fsm_ena   	( rsam_fsm_ena    ),
            .rsam_fsm_sl    	( rsam_fsm_sl     ),
            .rsam_fsm_sm    	( rsam_fsm_sm     ),
            .rsam_fsm_sen   	( rsam_fsm_sen    ),
            .rsam_rdata     	( rsam_rdata      ),
            .rsam_sdata     	( rsam_sdata      )
        );

    // sram 模块
        inputbuffer_128_128_4 u_inputbuffer_128_128_4(
            .clk            	( clk             ),
            .ib_bus_addr    	( ib_bus_addr     ),
            .ib_bus_wdata   	( ib_bus_wdata    ),
            .ib_bus_wen     	( ib_bus_wen      ),
            .ib_bus_ena     	( ib_bus_ena      ),
            .ib_0_fsm_addr  	( ib_0_fsm_addr   ),
            .ib_0_fsm_wdata 	( ib_0_fsm_wdata  ),
            .ib_0_fsm_wen   	( ib_0_fsm_wen    ),
            .ib_0_fsm_ena   	( ib_0_fsm_ena    ),
            .ib_1_fsm_addr  	( ib_1_fsm_addr   ),
            .ib_1_fsm_wdata 	( ib_1_fsm_wdata  ),
            .ib_1_fsm_wen   	( ib_1_fsm_wen    ),
            .ib_1_fsm_ena   	( ib_1_fsm_ena    ),
            .ib_2_fsm_addr  	( ib_2_fsm_addr   ),
            .ib_2_fsm_wdata 	( ib_2_fsm_wdata  ),
            .ib_2_fsm_wen   	( ib_2_fsm_wen    ),
            .ib_2_fsm_ena   	( ib_2_fsm_ena    ),
            .ib_3_fsm_addr  	( ib_3_fsm_addr   ),
            .ib_3_fsm_wdata 	( ib_3_fsm_wdata  ),
            .ib_3_fsm_wen   	( ib_3_fsm_wen    ),
            .ib_3_fsm_ena   	( ib_3_fsm_ena    ),
            .ib_rdata       	( ib_rdata        ),
            .ib_0_rdata     	( ib_0_rdata      ),
            .ib_1_rdata     	( ib_1_rdata      ),
            .ib_2_rdata     	( ib_2_rdata      ),
            .ib_3_rdata     	( ib_3_rdata      )
        );



endmodule

    
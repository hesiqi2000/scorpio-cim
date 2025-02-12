`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: 
// Module Name: inputbuffer_128_128_4
// Project Name: 
// Description: sram的例化模块，128*128*4
// Dependencies: 
// 
//////////////////////////////////////////////////////////////////////////////////

module inputbuffer_128_128_4(
    input wire clk, // 时钟信号

    input wire [8:0]            ib_bus_addr,    // 7b = 128  9b = 512
    input wire [127:0]          ib_bus_wdata, 
    input wire                  ib_bus_wen,
    input wire                  ib_bus_ena,

    input wire [6:0]            ib_0_fsm_addr,
    input wire [127:0]          ib_0_fsm_wdata, 
    input wire                  ib_0_fsm_wen,
    input wire                  ib_0_fsm_ena,
    input wire [6:0]            ib_1_fsm_addr,
    input wire [127:0]          ib_1_fsm_wdata, 
    input wire                  ib_1_fsm_wen,
    input wire                  ib_1_fsm_ena,
    input wire [6:0]            ib_2_fsm_addr,
    input wire [127:0]          ib_2_fsm_wdata, 
    input wire                  ib_2_fsm_wen,
    input wire                  ib_2_fsm_ena,
    input wire [6:0]            ib_3_fsm_addr,
    input wire [127:0]          ib_3_fsm_wdata, 
    input wire                  ib_3_fsm_wen,
    input wire                  ib_3_fsm_ena,

    output wire [127:0]         ib_rdata,
    output wire [127:0]         ib_0_rdata,
    output wire [127:0]         ib_1_rdata,
    output wire [127:0]         ib_2_rdata,
    output wire [127:0]         ib_3_rdata
);


wire [6:0]      addr [0:3];
wire [127:0]    wdata [0:3];
wire            wen [0:3];
wire            ena [0:3];
wire [127:0]    rdata [0:3];

wire            bus_ce [0:3];
assign bus_ce[0] = ib_bus_ena & (ib_bus_addr[8:7] == 2'b00);
assign bus_ce[1] = ib_bus_ena & (ib_bus_addr[8:7] == 2'b01);
assign bus_ce[2] = ib_bus_ena & (ib_bus_addr[8:7] == 2'b10);
assign bus_ce[3] = ib_bus_ena & (ib_bus_addr[8:7] == 2'b11);

assign addr[0] = ib_0_fsm_ena ? ib_0_fsm_addr : ib_bus_addr[6:0];
assign wdata[0] = ib_0_fsm_ena ? ib_0_fsm_wdata : ib_bus_wdata;
assign ena[0] = ib_0_fsm_ena | bus_ce[0];
assign wen[0] = ib_0_fsm_ena ? ib_0_fsm_wen : ib_bus_wen;

assign addr[1] = ib_1_fsm_ena ? ib_1_fsm_addr : ib_bus_addr[6:0];
assign wdata[1] = ib_1_fsm_ena ? ib_1_fsm_wdata : ib_bus_wdata;
assign ena[1] = ib_1_fsm_ena | bus_ce[1];
assign wen[1] = ib_1_fsm_ena ? ib_1_fsm_wen : ib_bus_wen;

assign addr[2] = ib_2_fsm_ena ? ib_2_fsm_addr : ib_bus_addr[6:0];
assign wdata[2] = ib_2_fsm_ena ? ib_2_fsm_wdata : ib_bus_wdata;
assign ena[2] = ib_2_fsm_ena | bus_ce[2];
assign wen[2] = ib_2_fsm_ena ? ib_2_fsm_wen : ib_bus_wen;

assign addr[3] = ib_3_fsm_ena ? ib_3_fsm_addr : ib_bus_addr[6:0];
assign wdata[3] = ib_3_fsm_ena ? ib_3_fsm_wdata : ib_bus_wdata;
assign ena[3] = ib_3_fsm_ena | bus_ce[3];
assign wen[3] = ib_3_fsm_ena ? ib_3_fsm_wen : ib_bus_wen;

// output 
reg [1:0] ce_reg;
always @(posedge clk) begin
    if (ib_bus_ena & ~ib_bus_wen) 
        ce_reg <= ib_bus_addr[8:7];
end

assign ib_rdata = (ce_reg == 2'b00) ? rdata[0] : 
                 (ce_reg == 2'b01) ? rdata[1] : 
                 (ce_reg == 2'b10) ? rdata[2] : rdata[3];
assign ib_0_rdata = rdata[0];
assign ib_1_rdata = rdata[1];
assign ib_2_rdata = rdata[2];
assign ib_3_rdata = rdata[3];


// 例化4个sram
genvar i;
generate
    for (i=0; i<4; i=i+1) begin: gen_sram
        sram #(
            .DATA_WIDTH (7),
            .ADDR_WIDTH (128)
        ) u_sram (
            .clk    (clk),
            .addr   (addr[i]),
            .wdata  (wdata[i]),
            .wen    (wen[i]),
            .ena    (ena[i]),
            .rdata  (rdata[i])
        );
    end
endgenerate

// 完成此部分代码


endmodule
module RsamWrapper64bx256d#(
    parameter DATA_WIDTH = 16, // 数据位宽
    parameter ADDR_WIDTH = 8,  // 地址位宽
    parameter BANK_NUM   = 4   // 
)(
    input  var logic           clock,

    input  var logic           rw_enable,
    input  var logic [7:0]     rw_addr,
    input  var logic           rw_write,
    input  var logic [63:0]    rw_dataIn,
    output var logic [63:0]    rw_dataOut,

    input  var logic [63:0]    search_sl,
    input  var logic [63:0]    search_sm,
    input  var logic           search_sen,
    output var logic [255:0]   search_sdataOut
);

    rsam_io_256_16_4 u_rsam_io_256_16_4(
        .clk            	( clock           ),
        .rsam_bus_addr  	( '0              ),
        .rsam_bus_wdata 	( '0              ),
        .rsam_bus_wen   	( '0              ),
        .rsam_bus_ena   	( '0              ),
        .rsam_fsm_addr  	( rw_addr         ), 
        .rsam_fsm_wdata 	( rw_dataIn       ),
        .rsam_fsm_wen   	( rw_write        ),
        .rsam_fsm_ena   	( rw_enable       ),
        .rsam_fsm_sl    	( search_sl       ),
        .rsam_fsm_sm    	( search_sm       ),
        .rsam_fsm_sen   	( search_sen      ),
        .rsam_rdata     	( rw_dataOut      ),
        .rsam_sdata     	( search_sdataOut )
    );

endmodule : RsamWrapper64bx256d


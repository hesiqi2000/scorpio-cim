`timescale 1ns/10ps
`celldefine
module RSAM (MLL, MLR, SM, SL, SLN, BL, BLN, WL);
	output MLL;
	input MLR, SM, SL, SLN, BL, BLN, WL;

	// Function
	wire M1, M2, M3, M4, M5, M6, M7, M8, M9, M10;

	and(M1, WL, BL);
	not(M2, WL);
	and(M3, M2, store);   
	assign #0.01  store=  (BL!=BLN)?(M3|M1):store;
	//or(store, M3, M1);
	not(M4, store);
        and(M5, store, SL);
        and(M6, M4, SLN);
        or(M7, M5, M6);
        not(M8, M7);
	and(M9, M7, MLR);
        and(M10, SM, M8);
	or(MLL, M9, M10);

endmodule
`endcelldefine

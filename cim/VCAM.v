`timescale 1ns/10ps
`celldefine
module VCAM (ML, MASK, CKR, BL, BLN, WL);
	output ML;
	input MASK, BL, BLN, WL, CKR;

	// Function
	wire M1, M2, M3, M4, M5;

	and(M1, WL, BL);
	not(M2, WL);
	and(M3, M2, store);   
	assign #0.01  store=  (BL!=BLN)?(M3|M1):store;
	//or(store, M3, M1);
    and(M5, CKR, MASK);
	not(M4, store);
	bufif1(ML, M4, M5);

	// Timing
	specify
		(negedge BLN => (ML:0)) = 0;
		ifnone (posedge CKR => (ML-:1'b0)) = 0;
		(negedge CKR => (ML:0)) = 0;
		ifnone (posedge MASK => (ML-:1'b0)) = 0;
		(negedge MASK => (ML:0)) = 0;
		ifnone (posedge WL => (ML-:1'b0)) = 0;
		if ((BL & ~BLN & CKR & MASK))
			(posedge WL => (ML:0)) = 0;
		if ((~BL & ~BLN & CKR & MASK))
			(posedge WL => (ML:0)) = 0;
	endspecify
endmodule
`endcelldefine

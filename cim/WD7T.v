`timescale 1ns/10ps
`celldefine
module WD7T (BL, BLN, CKW, DIN, DINB);
	output BL, BLN;
	input CKW, DIN, DINB;
	reg notifier;
	wire M1, M2, M3, M4, M5;

	// Function
	not(M1, DIN);
	not(M2, DINB);
	not(M3, CKW);
	and(M4, CKW, M1);
	and(M5, CKW, M2);
	or(BL, M3, M5);
	or(BLN, M3, M4);

	// Timing
	specify
		if ((~DIN & DINB))
			(posedge CKW => (BL-:1'b0)) = 0;
		if ((DIN & ~DINB))
			(posedge CKW => (BLN-:1'b0)) = 0;
	endspecify
endmodule
`endcelldefine

// `timescale 1ns/10ps
// `celldefine
// module RA5T (HOT, ACT, CKR, ML);
// 	output HOT;
// 	input ACT, CKR, ML;
// 	reg notifier;

// 	// Function
// 	wire int_fwire_d, ML__bar;
// 	not (ML__bar, ML);
// 	and (int_fwire_d, ACT, ML__bar);
// 	altos_latch (HOT, notifier, CKR, int_fwire_d);

// 	// Timing
// 	specify
// 		(posedge ACT => (HOT:ACT)) = 0;
// 		(posedge CKR => (HOT-:CKR)) = 0;
// 		(ML => HOT) = 0;
// 	endspecify
// endmodule
// `endcelldefine

// primitive altos_latch (q, v, clk, d);
// 	output q;
// 	reg q;
// 	input v, clk, d;

// 	table
// 		* ? ? : ? : x;
// 		? 1 0 : ? : 0;
// 		? 1 1 : ? : 1;
// 		? x 0 : 0 : -;
// 		? x 1 : 1 : -;
// 		? 0 ? : ? : -;
// 	endtable
// endprimitive

module RA5T (HOT, ACT, CKR, ML);
	output HOT;
	input ACT, CKR, ML;
	reg notifier;

	// Function
	wire int_fwire_d;
	reg ML_bar;

    always @(*) begin
        case ({CKR, ML}) 
            2'b1z: ML_bar = 1'b0;  
            default: ML_bar = ~ML; 
        endcase
    end

	and (int_fwire_d, ACT, ML_bar);
	altos_latch (HOT, notifier, CKR, int_fwire_d);

endmodule

primitive altos_latch (q, v, clk, d);
	output q;
	reg q;
	input v, clk, d;

	table
		* ? ? : ? : x;
		? 1 0 : ? : 0;
		? 1 1 : ? : 1;
		? x 0 : 0 : -;
		? x 1 : 1 : -;
		? 0 ? : ? : -;
	endtable
endprimitive
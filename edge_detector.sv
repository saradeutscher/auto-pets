// edge_detector is a helper module that takes a 1-bit signal and outputs
// a signal equivalent to the posedge of the input signal. 

// Inputs:
// in: signal we want to output posedge of for one clock cycle
// clock: clock currently being used

// Outputs:
// out: outputs when the in signal is true for one clock cycle
module edge_detector (
	input logic in, clk, reset, 
	output logic out
);

	//define states
  typedef enum {S_0, S_1, S_2} state_t; 
  state_t ps; 
  
  
  always_ff @(posedge clk) begin 
  
	if (reset) ps <= S_0;
		
	else 
	
		case (ps)
		
			S_0: if (in)  ps <= S_1;
			
			S_1: if (in)  ps <= S_2;
				  else     ps <= S_0;
				  
			S_2: if (~in) ps <= S_0; 
			
		endcase
					
   end 
	

	//output of logic
	assign out = (ps == S_1);
	

endmodule // edge_detector

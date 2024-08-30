/* counter is a helper module for stats. It allows for either incrementing
 * or decrementing a stored value. 
 *
 * Parameter:
 *   W				- width of the value stored in the counter
 *   I				- initial value of the counter
 *
 * Inputs:
 *   a			 	- value to increase/decrease stored value by
 *   count			- indicates when to update value stored in counter
 *   down			- indicates whether to increment or decrement stored value (1 = decrement)
 *   clk 			- clock being used by the overall system
 *	  reset			- resets the counter to its initial values
 *
 * Outputs:
 *   x	 			- current value stored in the counter
 */
module counter #(parameter W=8, I=0) // W = width, I = initial (reset) value

	(
	input  logic [W-1:0] a,
	input  logic			count, down, clk, reset,
	output logic [W-1:0] x
	);
	
	always_ff @(posedge clk)
	
		if (reset)				x <= I;
		
		else if (count)
			if (down)	
				if (x - a > x)	x <= 0;
				else				x <= x - a;
			else
				if (x + a < x)	x <= (1 << W) - 1;
				else				x <= x + a;
	
endmodule // counter
/* stabilize is a module that takes input signal and outputs a slightly
 * delayed version of that signal
 *
 * Inputs:
 *   clk 			- clock being used by the overall system
 *	  x				- input signal
 *
 * Outputs:
 *   out 			- delayed signal
 */
module stabilize (
	input logic clk, x,
	output logic out
);
	//define x1
	logic x1;
	
	always_ff @(posedge clk) begin 
			x1 <= x;
			out <= x1;
	end 

endmodule // stabilize

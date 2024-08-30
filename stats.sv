/* Stats is a module that keeps track of the players coins, 
 * remaining lives, and current round number. Updates these
 * values according to the outcome of battle rounds.
 *
 * Inputs:
 *   battleDone 	- Indicates that a battle has finished to increment the round 
 *   decr_lives	- Indicates that player lost round, need to decrement remaining lives
 *   clk 			- clock being used by the overall system
 *	  reset			- resets the stats to their initial values
 *
 * Outputs:
 *   lives 			- Number of lives remaining
 *   round 			- Round number 
 *   coins 			- How many coins the play has, can be used to level up pets
 */
module stats

	(
	input  logic		 battleDone, decr_lives, clk, reset,
	input  logic [9:0] cost, revenue, // profit (cost/revenue) is always being added to your coin count. Make sure it shows each value for precisely one clock cycle!
	output logic [1:0] lives,
	output logic [7:0] round,	// surely no one survives more than 255 rounds in a row
	output logic [9:0] coins	// extreme richness is BANNED
	);
	
	logic [9:0] profit;
	
	assign profit = (cost > revenue) ? cost - revenue : revenue - cost;
	
	// instantiate counters for each stat
	counter #(.W(2), .I(3) )  lifeCoutner(.x(lives), .a(1'b1),   .count(decr_lives), .down(1'b1),           .*);
	counter #(.W(8), .I(1) ) roundCoutner(.x(round), .a(1'b1),   .count(battleDone),	.down(1'b0),           .*);
	counter #(.W(10),.I(10))  coinCoutner(.x(coins), .a(profit), .count(1'b1),       .down(cost > revenue), .*);
	
endmodule // stats
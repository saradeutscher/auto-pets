/* datapath is the module that deals with the logic of updating and keeping
 * track of values important to game play. It instantiates the stats, sixteen_bit_LFSR,
 * and pet modules to help with this. It also contains the logic for allowing the player
 * to select their pets using SW0-3.
 
 * Inputs:
 *   load_regs 	- signal to load inital values
 *   decr_lives	- signal to decrement remaining lives
 *   rewards 		- signal to update rewards won by player in battle round
 *   ns				- next state from the control module
 *   key1-3			- stabilized user input keys from top level module
 *	  sw0-3			- switches from user input that coorespond to pet selections
 *   clk 			- clock being used by the overall system
 *   clkBE			- clk_battle_posedge (clkBE) is used for the attack timing in battle phase
 *	  reset			- resets to the start state
 *
 * Outputs:
 *   start		 	- signal indicating player has decided to start the game (key0 in top level module)
 *   chosenDelay2	- signal indicating that the player has selected their team and indicated they are ready to move on 
 *   actionFight	- signal indicating player has decided to move to the battle stage
 *   battleDone	- signal indicating the battle has ended (either both of the players or opponents pets died)
 *   battleWin		- indicates that the player won the battle
 *   alive 			- indicates that the player still has remaining lives
 *   lives 			- Number of lives remaining
 *   round 			- Round number 
 *   coins 			- How many coins the play has, can be used to level up pets
 *   opp1			- number indicating the pet chosen for opponent 1
 *   opp2 			- number indicating the pet chosen for opponent 1
 *   pet1 			- number indicating the pet chosen by user for pet1
 *   pet2 			- number indicating the pet chosen by user for pet2
 *   pet1_status  - number indicating the status of pet1 (indicates whether it is dead or not)
 *   pet2_status  - number indicating the status of pet2 (indicates whether it is dead or not)
 */
module datapath

	// port definitions
	
	(
	input  logic clk, clkBE, key0, key1, key2, key3, sw0, sw1, sw2, sw3, // from top level
	input  logic load_regs, decr_lives, rewards, // from control
	input  logic [2:0] ns, // from control
	output logic start, chosenDelay2, actionFight, battleDone, battleWin, alive, // to control
	output logic [1:0] lives,
	output logic [7:0] round,
	output logic [9:0] coins,
	output logic [2:0] opp1, opp2, pet1, pet2, pet1_status, pet2_status
	);
	
	
	// additional signals
	
	logic [15:0] rng;
	logic [9:0]  cost, revenue;
	logic [1:0][7:0] id;
	
	logic chosen, chosenDelay1; // gets delayed a few cycles just to make sure the correct ids get used
	
	
	// instances
	
	stats 							stat 	(.reset(load_regs), .*); // handles lives, round, and coins
	sixteen_bit_LFSR	#(.S(0))	lfsr	(.reset(load_regs), .*); // handles rng
	pet								pets	(.CALLheal(actionFight), .CALLnew(chosenDelay2), .id, .*); // temp signals
	
	
   // datapath logic
	
	always_ff @(posedge clk) begin
	
		chosenDelay1 <= chosen;
		chosenDelay2 <= chosenDelay1;
		
		
		if (rewards) begin
			revenue <= 10 + 2 * (round - 1);
			// round is already incremented elsewhere
		end
		
		else begin
			revenue <= 0;
		end
		
		
		if (ns == 1) begin
			if      (sw0) id[0] <= 3;
			else if (sw1) id[0] <= 2;
			else if (sw2) id[0] <= 1;
			else			  id[0] <= 4;
			
			if      (sw3) 						id[1] <= 0;
			else if (sw2 & (sw1 | sw0)) 	id[1] <= 1;
			else if (sw1 & (sw0)) 			id[1] <= 2;
			else          						id[1] <= 4;
		end
		
	end  // always_ff
	
	
	assign start			= key0;
	assign chosen			= (ns == 3'd1) & (pet1 != 4) & (pet2 != 4) & key1;
	assign actionFight	= /*(ns == 3'd2) &*/ key2;
	assign alive         = lives > 1; // because of asmd timing, you will die if your lives are at when you lose a battle 1.
	
endmodule // datapath
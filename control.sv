/* control is the module that deals with the state logic of the ASMD chart for the
 * gameplay. It deals with switching between game states/screens. This includes
 * the start screen, team selection setup screen, planning screen, battle screen,
 * and game over screen. It receives signals from the datapath module on when
 * to update states.
 *
 * Inputs:
 *   start		 	- signal indicating player has decided to start the game (key0 in top level module)
 *   chosenDelay2	- signal indicating that the player has selected their team and indicated they are ready to move on 
 *   actionFight	- signal indicating player has decided to move to the battle stage
 *   battleDone	- signal indicating the battle has ended (either both of the players or opponents pets died)
 *   battleWin		- indicates that the player won the battle
 *   alive 			- player still has remaining lives
 *   clk 			- clock being used by the overall system
 *	  reset			- resets to the start state
 *
 * Outputs:
 *   load_regs 	- signal to datapath to load inital values
 *   decr_lives	- signal to datapath to decrement remaining lives
 *   rewards 		- signal to datapath to update rewards won by player in battle round
 *   ns				- next state 
 *   read_off		- the offset used by the rom module to draw the correct game screen
 */
module control
	
	
	// port definitions
	
	(
	input  logic clk, reset, // from top level
	input  logic start, chosenDelay2, actionFight, battleDone, battleWin, alive, // from datapath
	output logic load_regs, decr_lives, rewards, // to datapath
	output logic [2:0] ns, // to datapath
	output logic [11:0] read_off // to top level, for drawing game screens
	);
	
		
	logic [2:0] ps; // ns is defined above

	
	// controller logic w/ synchronous reset
	
	always_ff @(posedge clk)
		if (reset)
			ps <= 0;
		else
			ps <= ns;
			
			
	// next state logic
	
	always_comb
		case (ps)
		
			0: begin // start
				ns = start			? 1 : 0;
				read_off = 480 * 0;
			end
				
			1: begin // setup						
				ns = chosenDelay2	? 2 : 1;
				read_off = 480 * 1;
			end
			
			2: begin // plan
				ns = actionFight	? 3 : 2;
				read_off = 480 * 3;
			end
			
			3: begin // battle
				if (battleDone) ns = (battleWin | alive) ? 2 : 4;
				else 			    ns = 3;
				read_off = 480 * 4;
			end
			
			default: begin
				ns = ps; // this is for sDead = 4
				read_off = 480 * 2;
			end
			
		endcase
		
		
	// output assignments
	
	assign load_regs	= (ps == 0) & start;
	assign decr_lives	= (ps == 3) & battleDone & ~battleWin;
	assign rewards 	=  battleDone & (battleWin | alive);	
	
endmodule // control
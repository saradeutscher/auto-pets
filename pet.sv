/* pet is the module that contains the base stats, current stats, and actions used
 * during the battle phase. This module allows for level up of pets using coins,
 * generating randomized opponent teams with randomized levels, and healing pets after 
 * battle. During battle phase, deals with logic of pets battling and determining
 * who wins the round.
 
 * Inputs:
 *   ns				- next state from the control module
 *   key0-2			- stabilized user input keys from top level module
 *   clk 			- clock being used by the overall system
 *   clkBE			- clk_battle_posedge (clkBE) is used for the attack timing in battle phase
 *	  reset			- resets to the start state
 *   coins 			- How many coins the play has, can be used to level up pets
 *   CALLnew		- indicates that initial values need to be loaded
 *   CALLheal     - signal to reset health stats and update level stats before next battle
 *   id				- unique pet type identifier (0 - pig, 1 - cat, 2 - goat, 3 - fish, 4 - dead)
 *   rng				- RNG generated from the sixteen_bit_LFSR module
 *   round 			- Round number 
 *
 * Outputs:
 *   battleDone	- signal indicating the battle has ended (either both of the players or opponents pets died)
 *   battleWin		- indicates that the player won the battle
 *   opp1			- number indicating the pet chosen for opponent 1
 *   opp2 			- number indicating the pet chosen for opponent 1
 *   pet1 			- number indicating the pet chosen by user for pet1
 *   pet2 			- number indicating the pet chosen by user for pet2
 *   pet1_status  - number indicating the status of pet1 (indicates whether it is dead or not)
 *   pet2_status  - number indicating the status of pet2 (indicates whether it is dead or not)
 */
module pet

	(
	input  logic clk, clkBE, key0, key1, key2, CALLnew, CALLheal,
	input  logic [2:0] ns,
	input  logic [1:0][7:0] id, // unique (user) pet type identifier, 0-indexed
	input  logic [9:0]  coins,
	input  logic [15:0] rng,
	input  logic [7:0]  round,
	output logic [9:0]  cost,
	output logic battleWin, battleDone,
	output logic [2:0] opp1, opp2, pet1, pet2, pet1_status, pet2_status
	);

	logic [3:0][7:0] hps			= {8'd20, 	8'd5,		8'd9, 	8'd6,		8'd0};   // array of base max health values based on pet id
	logic [3:0][7:0] atks 		= {8'd1, 	8'd3, 	8'd2, 	8'd2, 	8'd0};   // array of base damage values based on pet id
	logic [3:0][7:0] tiers		= {8'd0, 	8'd0, 	8'd0, 	8'd0, 	8'd0};   // array of tiers based on pet id
	logic [3:0][7:0] evasions	= {8'd20,	8'd100,	8'd50,	8'd150,	8'd0}; // array of evasion values based on pet id, max of 255

	logic [3:0][7:0] lvl;  		// level of the pet - starts at 1 and can be increased
	logic [3:0][7:0] hp;   		// current health of the pet
	logic [3:0][7:0] atk;  		// damage the pet does per hi
	logic [3:0][7:0] tier; 		// fixed - tier of the pet type
	logic [3:0][7:0] evasion;  // fixed - evade rate of the pet, calculated by P(dodge) = evasion / 256 
	
	logic battleIndexP, battleIndexO;
	
	logic [1:0][7:0] idOpp;
	
	/* additional features that may be added:
	logic [7:0] dbf   // a debuff id, may decrease atk, hit, or other. 0 is no debuff
	logic [7:0] buf   // a buff id, similar to above
	*/
	
	
	assign pet1 = id[0];
	assign pet2 = id[1];
	
	assign pet1_status = (hp[0] == 0) ? 4 : id[0];
	assign pet2_status = (hp[1] == 0) ? 4 : id[1];
	
	assign opp1 = (hp[3] == 0) ? 4 : idOpp[1];
	assign opp2 = (hp[2] == 0) ? 4 : idOpp[0];
	
	
	always_ff @(posedge clk) begin
		
		// [sSelect -> sPrep] load all initial values
		if (CALLnew) begin
		
			battleDone <= 0;
			battleWin  <= 0;
		
			lvl[0] <= 1;
			lvl[1] <= 1;
			lvl[2] <= 1;
			lvl[3] <= 1;
			
			hp[0]  <= hps[id[0]];
			hp[1]  <= hps[id[1]];
			hp[2]  <= hps[rng[7:0]  % 4];
			hp[3]  <= hps[rng[15:8] % 4];
			
			atk[0] <= atks[id[0]];
			atk[1] <= atks[id[1]];
			atk[2] <= atks[rng[7:0]  % 4];
			atk[3] <= atks[rng[15:8] % 4];
			
			tier[0] <= tiers[id[0]];
			tier[1] <= tiers[id[1]];
			tier[2] <= tiers[rng[7:0]  % 4];
			tier[3] <= tiers[rng[15:8] % 4];
			
			evasion[0] <= evasions[id[0]];
			evasion[1] <= evasions[id[1]];
			evasion[2] <= evasions[rng[7:0]  % 4];
			evasion[3] <= evasions[rng[15:8] % 4];
			
			idOpp[0] <= rng[7:0]  % 4;
			idOpp[1] <= rng[15:8] % 4;
			
		end
		
		// [sBattle -> sPrep] create a new opponent team after each battle
		else if (battleDone) begin
		
			battleDone <= 0;
			battleWin  <= 0;
		
			lvl[2] <= 1 + ((((3 * round + 1) >> 2) * (8 + rng[14:13])) >> 3);
			lvl[3] <= 1 + ((((3 * round)     >> 2) * (8 + rng[6:5]))   >> 3);
			
			tier[2] <= tiers[rng[7:0]  % 4];
			tier[3] <= tiers[rng[15:8] % 4];
			
			evasion[2] <= evasions[rng[7:0]  % 4];
			evasion[3] <= evasions[rng[15:8] % 4];
			
			hp[2]  <= hps[rng[7:0]  % 4]  + ((((((3 * round + 1) >> 2) * (8 + rng[14:13])) >> 3) *  hps[rng[7:0]  % 4]) >> 2);
			hp[3]  <= hps[rng[15:8] % 4]  + ((((((3 * round)     >> 2) * (8 + rng[6:5]))   >> 3) *  hps[rng[15:8] % 4]) >> 2);
			
			atk[2] <= atks[rng[7:0]  % 4] + ((((((3 * round + 1) >> 2) * (8 + rng[14:13])) >> 3) * atks[rng[7:0]  % 4]) >> 2);
			atk[3] <= atks[rng[15:8] % 4] + ((((((3 * round)     >> 2) * (8 + rng[6:5]))   >> 3) * atks[rng[15:8] % 4]) >> 2);
		
			idOpp[0] <= rng[7:0]  % 4;
			idOpp[1] <= rng[15:8] % 4;
		
		end
		
		
		 // [sPrep -> sBattle] heal and update leveled stats before each battle
		else if (CALLheal) begin
			
			hp[0]  <= hps[id[0]]  + (((lvl[0] - 1) *  hps[id[0]]) >> 2);
			hp[1]  <= hps[id[1]]  + (((lvl[1] - 1) *  hps[id[1]]) >> 2);
			
			atk[0] <= atks[id[0]] + (((lvl[0] - 1) * atks[id[0]]) >> 2);
			atk[1] <= atks[id[1]] + (((lvl[1] - 1) * atks[id[0]]) >> 2);
			
		end
		
		
		// [sPrep] you attempted to upgrade a pet, so we will see if you can afford the upgrade, and if so, charge the correct number of coins for it and apply the upgrade
		else if ((key0 | key1) & ~key2 & (ns == 2)) begin // upgrade
		
			if (key0 & lvl[0] < 10) begin
				if (coins >= (4 + 2 * (lvl[0] - 1)) * (2 ** tier)) begin
					cost <= (4 + 2 * (lvl[0] - 1)) * (2 ** tier);
					lvl[0] <= lvl[0] + 1;
				end
			end
			
			else if (key1 & lvl[1] < 10) begin
				if (coins >= (4 + 2 * (lvl[1] - 1)) * (2 ** tier)) begin
					cost <= (4 + 2 * (lvl[1] - 1)) * (2 ** tier);
					lvl[1] <= lvl[1] + 1;
				end
			end
			
			
				hp  =  hps[id] + (((lvl - 1) *  hps[id]) >> 2);
				atk = atks[id] + (((lvl - 1) * atks[id]) >> 2);
		
		end
		
		
		// sBattle actions, can only happen on posedge of clk_battle and while in sBattle
		else if (clkBE & (ns == 3)) begin
		
			// [sBattle] someone fainted, go to the next pet
			if ((hp[0 + battleIndexP] == 0) | (hp[3 - battleIndexO] == 0)) begin
				
				if (hp[0 + battleIndexP] == 0) begin
				
					if (battleIndexP == 1) begin
						battleDone <= 1;
					end
					
					else begin 
						battleIndexP <= battleIndexP + 1;
					end
					
				end
				
				if (hp[3 - battleIndexO] == 0) begin
				
					if (battleIndexO == 1) begin 
						battleDone <= 1;
						battleWin  <= 1;
					end
					
					else begin
						battleIndexO <= battleIndexO + 1;
					end
					
				end
				
			end
			
			
			// [sBattle] no one has fainted, so the pets will attack
			else begin
			
				// You and your opponent attack at the same time. We check check if each attack missed, and then if so, if the attack was fatal.
				hp[0 + battleIndexP] <= (rng[15:8] < evasion[0 + battleIndexP]) ? hp[0 + battleIndexP] : ((hp[0 + battleIndexP] <= atk[3 - battleIndexO]) ? 0 : hp[0 + battleIndexP] - atk[3 - battleIndexO]);
				hp[3 - battleIndexO] <= (rng[7:0]  < evasion[3 - battleIndexO]) ? hp[3 - battleIndexO] : ((hp[3 - battleIndexO] <= atk[0 + battleIndexP]) ? 0 : hp[3 - battleIndexO] - atk[0 + battleIndexP]);
			
			end
			
		end
		
		
		// you are not currently upgrading a pet, so we will reset the continuously referenced "cost" variable
		if (~((key0 | key1) & ~key2 & (ns == 2))) begin
			cost <= 0;
		end
		
	end
	
	
	// add buff / debuff functions if those get added to the game
	
endmodule // pet
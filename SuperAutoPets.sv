/* Top level module of the SuperAutoPets game. A single player
 * game where the user can select pets to battle against a 
 * randomly generated opponent. 
 * Instantiates all helper modules that deal with the game logic. 
 * Also uses the video_driver module to draw game screens and
 * object onto the VGA display. 
 *
 * Inputs:
 *   KEY 			- On board keys of the FPGA
 *   SW 				- On board switches of the FPGA
 *   CLOCK_50 		- On board 50 MHz clock of the FPGA
 *
 * Outputs:
 *   HEX 			- On board 7 segment displays of the FPGA
 *   VGA_R 			- Red data of the VGA connection
 *   VGA_G 			- Green data of the VGA connection
 *   VGA_B 			- Blue data of the VGA connection
 *   VGA_BLANK_N 	- Blanking interval of the VGA connection
 *   VGA_CLK 		- VGA's clock signal
 *   VGA_HS 		- Horizontal Sync of the VGA connection
 *   VGA_SYNC_N 	- Enable signal for the sync of the VGA connection
 *   VGA_VS 		- Vertical Sync of the VGA connection
 */
module SuperAutoPets

	// inputs and outputs
	(
	input  logic [3:0] KEY,
	input  logic [9:0] SW,
	input  logic       CLOCK_50,
	output logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,

	output logic [7:0] VGA_R,
	output logic [7:0] VGA_G,
	output logic [7:0] VGA_B,
	output logic VGA_BLANK_N,
	output logic VGA_CLK,
	output logic VGA_HS,
	output logic VGA_SYNC_N,
	output logic VGA_VS
	);
	
		
	// -> main
	logic				clk, clkB, clkBE; // clk_battle_posedge (clkBE) is used for the attack timing in battle phase
	logic	[31:0]	clocks;
	logic				reset;
	logic				sw0, sw1, sw2, sw3, KEY0, KEY1, KEY2, KEY3, key0, key1, key2, key3;
	
	// -> stats
	logic	[1:0]		lives;
	logic	[7:0]		round;
	logic	[9:0]		coins;
	
	// -> RNG
	logic	[15:0] 	rng;
	
	// -> ASMD
	logic start, chosenDelay2, actionFight, battleDone, battleWin, alive; // datapath -> control
	logic load_regs, decr_lives, rewards; // control -> datapath
	logic [2:0] ns; // control -> datapath
	
	// -> display
	logic [9:0] x;
	logic [8:0] y;
	logic [7:0] r, g, b;
	logic [11:0] read_off, row;
	
	// -> pet selection
	logic [2:0] pet1, pet2; // user selected pets
	logic [2:0] opp1, opp2; // randomly generated opponents
	logic [2:0] pet1_status, pet2_status; // updated status of pets from the battle stage
	
	
	// instances
	
	clock_divider 		cdiv 	(.clock(CLOCK_50), .divided_clocks(clocks));
	
	control				ctrl	(.*);
	datapath				path	(.*);
	
	stabilize			stS0	(.out(sw0), .x(SW[0]), .*);
	stabilize			stS1	(.out(sw1), .x(SW[1]), .*);
	stabilize			stS2	(.out(sw2), .x(SW[2]), .*);
	stabilize			stS3	(.out(sw3), .x(SW[3]), .*);
	
	stabilize			stK0	(.out(KEY0), .x(~KEY[0]), .*);
	stabilize			stK1	(.out(KEY1), .x(~KEY[1]), .*);
	stabilize			stK2	(.out(key2), .x(~KEY[2]), .*);
	stabilize			stK3	(.out(KEY3), .x(~KEY[3]), .*);
	
	edge_detector		edK0	(.out(key0), .in(KEY0), .*);
	edge_detector		edK1	(.out(key1), .in(KEY1), .*);
	edge_detector		edK3	(.out(key3), .in(KEY3), .*);
	
	edge_detector		edCB	(.out(clkBE), .in(clkB), .*);
	
	
	// instantiates a 640x480 pixel VGA display
	video_driver #(.WIDTH(640), .HEIGHT(480))
		v1 (.CLOCK_50, .reset, .x, .y, .r, .g, .b,
			 .VGA_R, .VGA_G, .VGA_B, .VGA_BLANK_N,
			 .VGA_CLK, .VGA_HS, .VGA_SYNC_N, .VGA_VS);
			 
	// show your stats on the 7-seg displays
	seg7 coins_display (.hex(coins), .leds(HEX5));
	seg7 lives_display (.hex(lives), .leds(HEX3));
	seg7 wins_display  (.hex(round), .leds(HEX1));
		
	
	// assignments
	assign reset = key3;
	assign clk   = CLOCK_50;
	assign clkB  = clocks[26];
	
	// turn off unused 7-seg displays
	assign HEX0 = '1;
	assign HEX2 = '1;
	assign HEX4 = '1;
	
	
	// all additional visual related code (mixed types)
	
	// instantiate rom module that holds all the game screens
	logic	[639:0]  x_array;
	rom640x3360 screens (.address(row), .clock(CLOCK_50), .q(x_array));
	
	// instantiate rom module that holds pet images
	logic [99:0] x_arr_pet1, x_arr_pet2, x_arr_opp1, x_arr_opp2;
	logic [8:0] pet_addr1, pet_addr2, opp_addr1, opp_addr2, pet_mod, mod;
	rom100x500 pets (.address_a(pet_addr1), .address_b(pet_addr2), .clock(CLOCK_50), .q_a(x_arr_pet1), .q_b(x_arr_pet2));
	rom100x500 opp (.address_a(opp_addr1), .address_b(opp_addr2), .clock(CLOCK_50), .q_a(x_arr_opp1), .q_b(x_arr_opp2));

	
	logic [2:0] pet_off1, pet_off2;
	// pick what row to start reading game screen from rom at
	// pick what row to start reading the pets from 
	always_comb begin
		row = read_off + y;
		pet_off1 = (ns == 3) ? pet1_status : pet1; // if in battle stage, want to display updated pets
		pet_off2 = (ns == 3) ? pet2_status : pet2;
		mod = ((ns == 1) | (ns == 2)) ? 150 : 220;
		pet_mod = (ns == 2) ? 345 : mod;
		pet_addr1 = (100 * pet_off1) + (y % pet_mod);
		pet_addr2 = (100 * pet_off2) + (y % pet_mod);
		opp_addr1 = (100 * opp1) + (y % mod);
		opp_addr2 = (100 * opp2) + (y % mod);	

	end
	
	// draw screen
	always_ff @(posedge CLOCK_50) begin
		if ((ns == 1)) begin // setup stage where player's team is being selected
			if ((y >= 150) & (y < 250) & (x >= 100) & (x < 200)) begin
				// if in square for pet1 on the vga display, draw pixel from pet1 address from rom
				if ((pet1 != 4) & x_arr_pet1[x - 100] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			else if ((y >= 150) & (y < 250) & (x >= 300) & (x < 400)) begin
				// if in square for pet2 on vga display, draw pixel from pet2 address from rom
				if ((pet2 != 4) & x_arr_pet2[x - 300] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			// otherewise draw pixel from the current game screen 
			else if (x_array[x] == 1) begin
				r <= 8'b11111111;
				g <= 8'b11111111;
				b <= 8'b11111111;
			end
			else begin
				r <= 8'b0;
				g <= 8'b0;
				b <= 8'b0;
			end
		end
		else if ((ns == 2)) begin  // planning stage where opponents team and players team are displayed
			if ((y >= 150) & (y < 250) & (x >= 100) & (x < 200)) begin
				// draw opponent 1
				if (x_arr_opp1[x - 100] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			else if ((y >= 150) & (y < 250) & (x >= 300) & (x < 400)) begin
				// draw opponent 2
				if (x_arr_opp2[x - 300] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			else if ((y >= 345) & (y < 445) & (x >= 60) & (x < 160)) begin
				// draw pet 1
				if (x_arr_pet1[x - 60] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			else if ((y >= 345) & (y < 445) & (x >= 200) & (x < 300)) begin
				// draw pet 2
				if (x_arr_pet2[x - 200] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			// otherwise draw game screen
			else if (x_array[x] == 1) begin
				r <= 8'b11111111;
				g <= 8'b11111111;
				b <= 8'b11111111;
			end
			else begin
				r <= 8'b0;
				g <= 8'b0;
				b <= 8'b0;
			end
		end
		else if ((ns == 3)) begin // battle screen
			if ((y >= 220) & (y < 320) & (x >= 40) & (x < 140)) begin
				// draw pet 1
				if (x_arr_pet1[x - 40] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			else if ((y >= 220) & (y < 320) & (x >= 165) & (x < 265)) begin
				// draw pet 2
				if (x_arr_pet2[x - 165] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			else if ((y >= 220) & (y < 320) & (x >= 355) & (x < 455)) begin
				// draw opponent 1
				if (x_arr_opp1[x - 355] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			else if ((y >= 220) & (y < 320) & (x >= 485) & (x < 585)) begin
				// draw opponent 2
				if (x_arr_opp2[x - 485] == 1) begin
					r <= 8'b11111111;
					g <= 8'b11111111;
					b <= 8'b11111111;
				end
				else begin
					r <= 8'b0;
					g <= 8'b0;
					b <= 8'b0;
				end
			end
			// otherwise draw game screen
			else if (x_array[x] == 1) begin
				r <= 8'b11111111;
				g <= 8'b11111111;
				b <= 8'b11111111;
			end
			else begin
				r <= 8'b0;
				g <= 8'b0;
				b <= 8'b0;
			end
		end
		else if (x_array[x] == 1) begin
			r <= 8'b11111111;
			g <= 8'b11111111;
			b <= 8'b11111111;
		end
		else begin
			r <= 8'b0;
			g <= 8'b0;
			b <= 8'b0;
		end
	end
	
endmodule // SuperAutoPets
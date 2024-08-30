// Testbench for the control module
module control_testbench();
	// define module port connections
	logic clk, reset;
	logic start, chosenDelay2, actionFight, battleDone, battleWin, alive;
	
	logic load_regs, decr_lives, rewards;
	logic [2:0] ns;
	logic [11:0] read_off;
	
	// instantiate module
   control dut (.*);
	
	// create simulated clock
	parameter T = 20;
	initial begin
		clk <= 0;
		forever #(T/2) clk <= ~clk;
	end  // clock initial
	
   integer i;
	initial begin
	
		reset <= 1; start <= 0; chosenDelay2 <= 0; actionFight <= 0; battleDone <= 0; battleWin <= 0; alive <= 1;			@(posedge clk);
		reset <= 0; start <= 1;											@(posedge clk); @(posedge clk); // goes to setup state
						start <= 0;											@(posedge clk); @(posedge clk);	
																				@(posedge clk);
						chosenDelay2 <= 1;								@(posedge clk); 					  // goes to planning state
						chosenDelay2 <= 0;								@(posedge clk); @(posedge clk);																
						chosenDelay2 <= 1;								@(posedge clk); 					  // should have no effect, stay in planning state
						chosenDelay2 <= 0;								@(posedge clk); 
																				@(posedge clk);
						actionFight <= 1;									@(posedge clk);
						actionFight	<= 0;									@(posedge clk);
																				@(posedge clk);	
						battleDone <= 1; battleWin <= 1;				@(posedge clk); 					// should go back to planning state
						battleDone <= 0; battleWin <= 0;				@(posedge clk); 
																				@(posedge clk);
						actionFight <= 1;									@(posedge clk);
						actionFight	<= 0;									@(posedge clk);
																				@(posedge clk);
						battleDone <= 1; battleWin <= 0; alive <= 0;	@(posedge clk); 					// should go back to dead state
						battleDone <= 0; battleWin <= 0;				@(posedge clk); 
																				@(posedge clk);
		$stop;
	end  // initial

endmodule // control_testbench
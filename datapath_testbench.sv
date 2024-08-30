// Testbench for datapath module
module datapath_testbench();
	// define module port connections
	logic clk, clkBE, key0, key1, key2, key3, sw0, sw1, sw2, sw3; // from top level
   logic load_regs, decr_lives, rewards; // from control
	logic [2:0] ns; // from control
	
	logic start, chosenDelay2, actionFight, battleDone, battleWin, alive; // to control
	logic [1:0] lives;
	logic [7:0] round;
	logic [9:0] coins;
	logic [2:0] opp1, opp2, pet1, pet2, pet1_status, pet2_status;

	// instantiate module
   datapath dut (.*);
	
	// create simulated clock
	parameter T = 20;
	initial begin
		clk <= 0;
		forever #(T/2) clk <= ~clk;
	end  // clock initial
	
   integer i;
	initial begin
	
		clkBE <= 0; key0 <= 0; key1 <= 0; key2 <= 0; key3 <= 0; sw0 <= 0; sw1 <= 0; sw2 <= 0; sw3 <= 0;
						load_regs <= 0; decr_lives <= 0; rewards <= 0; 													@(posedge clk);
		key0 <= 1; ns <= 1; load_regs <= 1;											@(posedge clk);
		key0 <= 0; load_regs <= 0;														@(posedge clk);
																												@(posedge clk);
		sw0 <= 1; sw1 <= 1;																@(posedge clk);
		sw0 <= 0; sw2 <= 1;																@(posedge clk);
		sw2 <= 0; sw1 <= 0;																@(posedge clk);
		sw3 <= 1; sw0 <= 1;	key1 <= 1;												@(posedge clk);
									key1 <= 0;												@(posedge clk);
		ns <= 2;																				@(posedge clk);
																												@(posedge clk);
		key2 <= 1;																			@(posedge clk);
		key2 <= 0; ns <= 3;																@(posedge clk);
																												@(posedge clk);	
																												@(posedge clk);
		$stop;
	end  // initial
endmodule // datapath_testbench
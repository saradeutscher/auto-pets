/* sixteen_bit_LFSR is a Linear Feedback Sheet Register used
 * for randomness in different areas of the game. It is used
 * to generate random opponents, hitrates, and levels. 
 *
 * Parameter:
 *   S				- seed value
 *
 * Inputs:
 *   clk 			- clock being used by the overall system
 *	  reset			- resets to initial seed value
 *
 * Outputs:
 *   rng	 			- random value generated
 */
module sixteen_bit_LFSR #(parameter S=0) // S = seed

  (
  input  logic        clk, reset,
  output logic [15:0] rng
  );
  
  always_ff @(posedge clk)
  if (reset)
    rng <= S;
  else
    begin
      rng[0]  <= ~(rng[15] ^ rng[14] ^ rng[12] ^ rng[3]);
	   rng[1]  <= rng[0];
	   rng[2]  <= rng[1];
	   rng[3]  <= rng[2];
	   rng[4]  <= rng[3];
	   rng[5]  <= rng[4];
	   rng[6]  <= rng[5];
	   rng[7]  <= rng[6];
	   rng[8]  <= rng[7];
		rng[9]  <= rng[8];
		rng[10] <= rng[9];
		rng[11] <= rng[10];
		rng[12] <= rng[11];
		rng[13] <= rng[12];
		rng[14] <= rng[13];
		rng[15] <= rng[14];
    end
	 
endmodule // sixteen_bit_LFSR
  
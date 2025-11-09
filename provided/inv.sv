// This module implements a INV gate
module inv
  (input [0:0] a_i
  ,output [0:0] b_o);

   assign b_o = ~a_i;

endmodule
	   

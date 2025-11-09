// This module implements a NMOS transistor
module nmosfet
  (input [0:0] gate_i
  ,input [0:0] drain_i
  ,output [0:0] source_o);

   assign source_o = gate_i ? drain_i : 1'bz;

endmodule
	   

module xor2
  (input [0:0] a_i
  ,input [0:0] b_i
  ,output [0:0] c_o);

   // For Lab 1, do not use assign statements!
   // Your code here:
  `define FET // comment out this line to flash lfsr top correctly
  `ifdef FET

  wire [0:0] inva_w;
  wire [0:0] invb_w;
  wire [0:0] p1_w;
  wire [0:0] p2_w;
  wire [0:0] n1_w;
  wire [0:0] n2_w;
  
  // a inverter
  pmosfet 
    #()
  pmosfet_inva_inst
  (.gate_i(a_i),
   .source_i(1'b1),
   .drain_o(inva_w)
  ); 

  nmosfet 
    #()
  nmosfet_inva_inst 
  (.gate_i(a_i),
   .drain_i(1'b0),
   .source_o(inva_w)
  );

  // b inverter
  pmosfet 
    #()
  pmosfet_invb_inst
  (.gate_i(b_i),
   .source_i(1'b1),
   .drain_o(invb_w)
  ); 

  nmosfet 
    #()
  nmosfet_invb_inst 
  (.gate_i(b_i),
   .drain_i(1'b0),
   .source_o(invb_w)
  );

  // ~a & b
  pmosfet 
    #()
  pmosfet_first_inst
  (.gate_i(inva_w),
   .source_i(1'b1),
   .drain_o(p1_w)
  ); 

  pmosfet 
    #()
  pmosfet_second_inst
  (.gate_i(b_i),
   .source_i(p1_w),
   .drain_o(c_o)
  ); 

  // a & ~b
  pmosfet 
    #()
  pmosfet_third_inst
  (.gate_i(a_i),
   .source_i(1'b1),
   .drain_o(p2_w)
  ); 

  pmosfet 
    #()
  pmosfet_fourth_inst
  (.gate_i(invb_w),
   .source_i(p2_w),
   .drain_o(c_o)
  ); 

  // a & b
  nmosfet 
    #()
  nmosfet_first_inst 
  (.gate_i(a_i),
   .drain_i(1'b0),
   .source_o(n1_w)
  );

  nmosfet 
    #()
  nmosfet_second_inst 
  (.gate_i(b_i),
   .drain_i(n1_w),
   .source_o(c_o)
  );

  // ~a & ~b
  nmosfet 
    #()
  nmosfet_third_inst 
  (.gate_i(inva_w),
   .drain_i(1'b0),
   .source_o(n2_w)
  );

  nmosfet 
    #()
  nmosfet_fourth_inst 
  (.gate_i(invb_w),
   .drain_i(n2_w),
   .source_o(c_o)
  );

`else

  wire [0:0] c_first_w;
  wire [0:0] c_second_w;
  wire [0:0] c_third_w;

  nand2 
    #()
  nand2_first_inst
    (.a_i(a_i),        // 0,0,1,1
     .b_i(b_i),        // 0,1,0,1
     .c_o(c_first_w)   // 1,1,1,0
    );

  nand2 
    #()
  nand2_second_inst
    (.a_i(a_i),        // 0,0,1,1
     .b_i(c_first_w),  // 1,1,1,0
     .c_o(c_second_w)  // 1,1,0,1
    );

  nand2 
    #()
  nand2_third_inst
    (.a_i(c_first_w),  // 1,1,1,0
     .b_i(b_i),        // 0,1,0,1
     .c_o(c_third_w)   // 1,0,1,1
    );
  
  nand2
    #()
  nand2_fourth_inst
    (.a_i(c_second_w), // 1,1,0,1
     .b_i(c_third_w),  // 1,0,1,1
     .c_o(c_o)         // 0,1,1,0
    );

`endif

endmodule

module xnor2
  (input [0:0] a_i
  ,input [0:0] b_i
  ,output [0:0] c_o);

   // For Lab 1, do not use assign statements!
   // Your code here:

  wire [0:0] c_first_w;
  wire [0:0] c_second_w;
  wire [0:0] c_third_w;
  wire [0:0] c_fourth_w;

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
     .c_o(c_fourth_w)  // 0,1,1,0
    );

  nand2
    #()
  nand2_fifth_inst
    (.a_i(c_fourth_w), // 0,1,1,0
     .b_i(c_fourth_w), // 0,1,1,0
     .c_o(c_o)         // 1,0,0,1
    );


endmodule

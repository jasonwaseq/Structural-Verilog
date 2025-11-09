module mux2
  (input [0:0] a_i
  ,input [0:0] b_i
  ,input [0:0] select_i
  ,output [0:0] c_o);

   // For Lab 1, do not use assign statements!
   // Your code here:

  // mux2 = (a_i & ~select_i) + (b_i & select_i) 

  wire [0:0] select_w;
  wire [0:0] c_first_w;
  wire [0:0] c_second_w;

  nand2 
    #()
  nand2_invselect_inst
    (.a_i(select_i),        
     .b_i(select_i),       
     .c_o(select_w)   // select_w = ~select_i
    );

  nand2 
    #()
  nand2_first_inst
    (.a_i(a_i),        // 0,0
     .b_i(select_w),   // 0,1
     .c_o(c_first_w)   // 1,1
    );

  nand2 
    #()
  nand2_second_inst
    (.a_i(b_i),        // 1,1
     .b_i(select_i),   // 1,0     
     .c_o(c_second_w)  // 0,1
    );
  
  nand2
    #()
  nand2_third_inst
    (.a_i(c_first_w),  // 1,1
     .b_i(c_second_w), // 0,1 
     .c_o(c_o)         // 1,0
    );

 
endmodule

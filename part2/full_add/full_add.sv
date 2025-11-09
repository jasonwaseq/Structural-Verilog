module full_add
  (input [0:0] a_i
  ,input [0:0] b_i
  ,input [0:0] carry_i
  ,output [0:0] carry_o
  ,output [0:0] sum_o);

   // For Lab 1, do not use assign statements!
   // Your code here:

  // full_add = (sum = a ^ b ^ cin) (cout = (a * b) + (b * cin) + (a * cin))

  wire [0:0] c_first_w;
  wire [0:0] s_first_w;
  wire [0:0] c_second_w;
  wire [0:0] c_third_w;
  wire [0:0] c_fourth_w;

  // first half adder
  half_add
    #()
  half_add_first_inst
  (.a_i(a_i),
   .b_i(b_i),
   .carry_o(c_first_w),
   .sum_o(s_first_w)
  );

  // second half adder
  half_add
    #()
  half_add_second_inst
  (.a_i(carry_i),
   .b_i(s_first_w),
   .carry_o(c_second_w),
   .sum_o(sum_o)
  );

  nand2
    #()
  nand2_first_inst
    (.a_i(c_first_w),   // 0,0,1,1
     .b_i(c_first_w),   // 0,0,1,1 
     .c_o(c_third_w)    // 1,1,0,0
    );

  nand2
    #()
  nand2_second_inst
    (.a_i(c_second_w),  // 0,1,0,1
     .b_i(c_second_w),  // 0,1,0,1  
     .c_o(c_fourth_w)   // 1,0,1,0
    );

  nand2
    #()
  nand2_third_inst
    (.a_i(c_third_w),   // 1,1,0,0
     .b_i(c_fourth_w),  // 1,0,1,0  
     .c_o(carry_o)      // 0,1,1,1
    );

endmodule

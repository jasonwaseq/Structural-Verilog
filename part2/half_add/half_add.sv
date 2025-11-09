module half_add
  (input a_i
  ,input b_i
  ,output carry_o
  ,output sum_o);

   // For Lab 1, do not use assign statements!
   // Your code here:

  // half_add = (sum = a_i ^ b_i) (carry_o = a_i & b_i)

  // sum
  xor2
    #()
  xor2_sum_inst
    (.a_i(a_i), 
     .b_i(b_i), 
     .c_o(sum_o)       
    );

  // carry out
  wire [0:0] c_w;

  nand2
    #()
  nand2_first_inst
    (.a_i(a_i),     // 0,0,1,1
     .b_i(b_i),     // 0,1,0,1
     .c_o(c_w)      // 1,1,1,0
    );

  nand2
    #()
  nand2_second_inst
    (.a_i(c_w),     // 1,1,1,0
     .b_i(c_w),     // 1,1,1,0
     .c_o(carry_o)  // 0,0,0,1     
    );

endmodule

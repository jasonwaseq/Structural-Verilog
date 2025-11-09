module lfsr
   (input [0:0] clk_i
   ,input [0:0] reset_i
   ,input [0:0] en_i
   ,output [10:0] data_o);

   wire feedback_w;
   wire bit_1;
   wire bit_10;

   shift
     #(.depth_p(11), .reset_val_p(11'b00000000001))
   shift_inst (
      .clk_i(clk_i),
      .reset_i(reset_i),
      .data_i(feedback_w),
      .enable_i(en_i),
      .data_o(data_o)
   );

   assign bit_1 = data_o[1];
   assign bit_10 = data_o[10];

   wire [0:0] xor2_w;

   xor2
      #()
   xor2_inst (
      .a_i(bit_1),
      .b_i(bit_10),
      .c_o(xor2_w)
   );

   assign feedback_w = xor2_w;

endmodule

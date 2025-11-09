module adder
  #(parameter width_p = 5)
  // You must fill in the bit widths of a_i, b_i and sum_o. a_i and
  // b_i must be width_p bits.
  (input [width_p-1:0] a_i
  ,input [width_p-1:0] b_i
  ,output [width_p:0] sum_o
  ,output c_o
  );

   // Your code here

  wire [width_p:0] c_w;
  assign c_w[0] = 1'b0;

  genvar i;
  generate
    for (i=0; i < width_p; i++) begin : adding
      full_add full_add_inst (
        .a_i(a_i[i]),
        .b_i(b_i[i]),
        .carry_i(c_w[i]),
        .sum_o(sum_o[i]),
        .carry_o(c_w[i+1])
      );
    end
  endgenerate

    assign sum_o[width_p] = c_w[width_p];
    assign c_o = c_w[width_p];

endmodule

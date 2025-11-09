module counter
  #(parameter width_p = 4)
   (input [0:0] clk_i
   ,input [0:0] reset_i
   ,input [0:0] up_i
   ,input [0:0] down_i
   ,output [width_p-1:0] count_o);

  wire [width_p:0] up_sum_w;
  wire [width_p:0] down_sum_w;
  wire [width_p-1:0] next_count_w;

  // dummy wires to satisfy linter
  wire [0:0] unused_up_bit;
  assign unused_up_bit = up_sum_w[width_p];
  wire [0:0] unused_down_bit;
  assign unused_down_bit = down_sum_w[width_p];
  wire [0:0] unused_carry_up; 
  wire [0:0] unused_carry_down;

  // enable logic
  wire [0:0] not_up_w;
  wire [0:0] not_down_w;
  wire [0:0] nand_w;
  wire [0:0] en_w;

  xnor2 
    #()
  xnor2_up_inst (
    .a_i(up_i), 
    .b_i(1'b0), 
    .c_o(not_up_w)
  ); 
  
  xnor2
    #()
  xnor2_down_inst (
    .a_i(down_i), 
    .b_i(1'b0), 
    .c_o(not_down_w)
  ); 

  xnor2
    #()
  xnor2_up_or_down_inst (
    .a_i(not_up_w), 
    .b_i(not_down_w), 
    .c_o(nand_w)
  ); 

  xnor2
    #()
  xnor2_en_inst (
    .a_i(nand_w), 
    .b_i(1'b0), 
    .c_o(en_w)
  ); 

  // adder up
  adder 
    #(.width_p(width_p)) 
  adder_up_inst (
    .a_i(count_o),
    .b_i({{width_p-1{1'b0}}, 1'b1}), 
    .sum_o(up_sum_w),
    .c_o(unused_carry_up)
  );

  // adder down
  adder 
    #(.width_p(width_p)) 
  adder_down_inst (
    .a_i(count_o),
    .b_i({{width_p-1{1'b1}}, 1'b1}), 
    .sum_o(down_sum_w),
    .c_o(unused_carry_down)
  );

  // mux
  genvar i;
  generate
    for (i = 0; i < width_p; i++) begin : mux_stage
      wire [0:0] hold_w;
      mux2 
        #()
      mux2_hold_inst (
        .a_i(count_o[i]),    
        .b_i(down_sum_w[i]), 
        .select_i(down_i),
        .c_o(hold_w)
      );

      mux2 
        #()
      mux2_out_inst (
        .a_i(hold_w),
        .b_i(up_sum_w[i]),
        .select_i(up_i),
        .c_o(next_count_w[i])
      );
    end
  endgenerate

  // dff storage
  generate
    for (i = 0; i < width_p; i++) begin : dff_storage
      dff 
        #(.reset_val_p(1'b0)) 
      dff_inst (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .d_i(next_count_w[i]),
        .en_i(en_w),
        .q_o(count_o[i])
      );
    end
  endgenerate
   
endmodule

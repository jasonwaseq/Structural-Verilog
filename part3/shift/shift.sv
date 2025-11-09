module shift
  #(parameter depth_p = 5
    /* verilator lint_off WIDTHTRUNC */
   ,parameter [depth_p-1:0] reset_val_p = '0)
   /* verilator lint_on WIDTHTRUNC */   
   (input [0:0] clk_i
   ,input [0:0] reset_i
   ,input [0:0] data_i
   ,input [0:0] enable_i
   ,output [depth_p-1:0] data_o);

  wire [depth_p-1:0] d_w;
  wire [depth_p-1:0] q_w;

  assign d_w[0] = data_i;

  genvar i;
   generate
    for (i = 1; i < depth_p; i++) begin : shifter
      assign d_w[i] = q_w[i-1];
    end
  endgenerate

  generate
    for (i = 0; i < depth_p; i++) begin: dff_inst
      dff 
      #(.reset_val_p(reset_val_p[i])) 
      dff_inst (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .d_i(d_w[i]),
        .en_i(enable_i),
        .q_o(q_w[i])
      );
    end
  endgenerate

  assign data_o = q_w;

endmodule

module top
  (input [0:0] clk_12mhz_i
  ,input [0:0] reset_n_async_unsafe_i
   // n: Negative Polarity (0 when pressed, 1 otherwise)
   // async: Not synchronized to clock
   // unsafe: Not De-Bounced
  ,input [3:1] button_async_unsafe_i
   // async: Not synchronized to clock
   // unsafe: Not De-Bounced
  ,output [7:0] ssd_o
  ,output [5:1] led_o);

   // For this demonstration, instantiate your Counter modules to
   // drive the output wires of ssd_o. You may only use structural
   // verilog, the modules in provided_modules, and your lfsr module,
   // and your counter.
   // 
   // Hint: A 12 MHz clock is _very fast_ for human consumption. You
   // should use your counter to slow down your LFSR by generating a
   // new clock. In our solution, about 22 bits is sufficent.

   // These two D Flip Flops form what is known as a Synchronizer. We
   // will learn about these in Week 5, but you can see more here:
   // https://inst.eecs.berkeley.edu/~cs150/sp12/agenda/lec/lec16-synch.pdf
   wire [0:0] reset_n_sync_r;
   wire [0:0] reset_sync_r;
   wire [0:0] reset_r; // Use this as your reset_signal
   dff
     #()
   sync_a
     (.clk_i(clk_12mhz_i)
     ,.reset_i(1'b0)
     ,.en_i(1'b1)
     ,.d_i(reset_n_async_unsafe_i)
     ,.q_o(reset_n_sync_r));

   inv
     #()
   inv
     (.a_i(reset_n_sync_r)
     ,.b_o(reset_sync_r));

   dff
     #()
   sync_b
     (.clk_i(clk_12mhz_i)
     ,.reset_i(1'b0)
     ,.en_i(1'b1)
     ,.d_i(reset_sync_r)
     ,.q_o(reset_r));
       
  // Your code goes here

  wire [21:0] time_count_w;

  counter
    #(.width_p(22))
  counter_time_inst (
    .clk_i(clk_12mhz_i),
    .reset_i(reset_r),
    .up_i(1'b1),
    .down_i(1'b0),
    .count_o(time_count_w)
  );

  wire [0:0] time_d;

  dff 
    #() 
  dff_time_inst (
    .clk_i(clk_12mhz_i),
    .reset_i(reset_r),
    .d_i(time_count_w[21]),
    .en_i(1'b1),
    .q_o(time_d)
  );

  wire [0:0] time_w;

  dff 
    #() 
  dff_time_d_inst (
    .clk_i(clk_12mhz_i),
    .reset_i(reset_r),
    .d_i(time_d),
    .en_i(1'b1),
    .q_o(time_w)
  );

  wire [0:0] inv_time_w;

  inv 
    #() 
  inv_inst (
    .a_i(time_w),
    .b_o(inv_time_w)
  );

  wire [0:0] edge_w;

  nand2 
    #() 
  nand2_inst (
    .a_i(time_d),
    .b_i(inv_time_w),
    .c_o(edge_w)
  );

  wire [0:0] invedge_w;

  inv 
    #() 
  inv_edge (
    .a_i(edge_w),
    .b_o(invedge_w)
  );

  wire [0:0] en_w;
  assign en_w = invedge_w;

  wire [10:0] data_w;

  lfsr
    #()
  lfsr_inst (
    .clk_i(clk_12mhz_i),
    .reset_i(reset_r),
    .en_i(en_w),
    .data_o(data_w)
  );

  wire [7:0] top8_w;
  assign top8_w = data_w[10:3];
  wire [3:0] tophex_w;
  assign tophex_w = top8_w[7:4];
  wire [3:0] bottomhex_w;
  assign bottomhex_w = top8_w[3:0];

  wire [6:0] topssd_w;
  wire [6:0] bottomssd_w;

  hex2ssd
    #()
  hex2ssd_top_inst (
    .hex_i(tophex_w),
    .ssd_o(topssd_w)
  );

  hex2ssd
    #()
  hex2ssd_bottom_inst (
    .hex_i(bottomhex_w),
    .ssd_o(bottomssd_w)
  );

  wire [13:0] digit_count_w;

  counter
    #(.width_p(14))
  counter_digit_inst (
    .clk_i(clk_12mhz_i),
    .reset_i(reset_r),
    .up_i(1'b1),
    .down_i(1'b0),
    .count_o(digit_count_w)
  );

  wire [0:0] digit_w;
  assign digit_w = digit_count_w[13];

  wire [6:0] ssd_w;

  genvar i;
  generate
    for (i = 0; i < 7; i++) begin : mux
      mux2 
        #()
      mux2_inst (
        .a_i(bottomssd_w[i]),   
        .b_i(topssd_w[i]),      
        .select_i(digit_w),         
        .c_o(ssd_w[i])         
      );
    end
  endgenerate

  assign ssd_o = {digit_w, ssd_w}; 

  assign led_o = {time_count_w[21], edge_w, digit_count_w[13], en_w, reset_r};

endmodule

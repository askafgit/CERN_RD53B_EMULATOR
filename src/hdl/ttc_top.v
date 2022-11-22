`timescale 1ps/1ps
// TTC input decoder
// Timing and Trigger Control
// Takes the TTC line as an input and parses it.
// As this emulator is built expecting the DAQ clock to be forwarded,
// no clock recovery is done on the TTC line. Instead, we simply
// search for the sync pattern and lock to that bit position.

// testing: ttc_tb.v, ttc.do

module ttc_top 
(
    input         clk             , 
    input         reset           , //Global external rest
    input         datain          , //TTC Serial Stream
    output        valid_o         , //Data word valid signal
    output [15:0] dataout           //16-bit word out, in same domain as clkin
    
);

    wire [255:0] data_concat         ;
    wire [ 15:0] dataint_array [0:15];
    wire [ 15:0] validint            ;
    wire   [3:0] shift_count [15:0]  ;
    

    //---------------------------------------------------------
    //Shift Register Channels
    //---------------------------------------------------------
    SR16 #(.channel(4'hf)) ch00(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 0]), .dataout(dataint_array[ 0]), .shift_count_o(shift_count[15]));
    SR16 #(.channel(4'he)) ch01(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 1]), .dataout(dataint_array[ 1]), .shift_count_o(shift_count[14]));
    SR16 #(.channel(4'hd)) ch02(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 2]), .dataout(dataint_array[ 2]), .shift_count_o(shift_count[13]));
    SR16 #(.channel(4'hc)) ch03(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 3]), .dataout(dataint_array[ 3]), .shift_count_o(shift_count[12]));
    SR16 #(.channel(4'hb)) ch04(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 4]), .dataout(dataint_array[ 4]), .shift_count_o(shift_count[11]));
    SR16 #(.channel(4'ha)) ch05(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 5]), .dataout(dataint_array[ 5]), .shift_count_o(shift_count[10]));
    SR16 #(.channel(4'h9)) ch06(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 6]), .dataout(dataint_array[ 6]), .shift_count_o(shift_count[9]));
    SR16 #(.channel(4'h8)) ch07(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 7]), .dataout(dataint_array[ 7]), .shift_count_o(shift_count[8]));
    SR16 #(.channel(4'h7)) ch08(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 8]), .dataout(dataint_array[ 8]), .shift_count_o(shift_count[7]));
    SR16 #(.channel(4'h6)) ch09(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[ 9]), .dataout(dataint_array[ 9]), .shift_count_o(shift_count[6]));
    SR16 #(.channel(4'h5)) ch10(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[10]), .dataout(dataint_array[10]), .shift_count_o(shift_count[5]));
    SR16 #(.channel(4'h4)) ch11(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[11]), .dataout(dataint_array[11]), .shift_count_o(shift_count[4]));
    SR16 #(.channel(4'h3)) ch12(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[12]), .dataout(dataint_array[12]), .shift_count_o(shift_count[3]));
    SR16 #(.channel(4'h2)) ch13(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[13]), .dataout(dataint_array[13]), .shift_count_o(shift_count[2]));
    SR16 #(.channel(4'h1)) ch14(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[14]), .dataout(dataint_array[14]), .shift_count_o(shift_count[1]));
    SR16 #(.channel(4'h0)) ch15(.clk(clk), .reset(reset), .datain(datain), .valid_o(validint[15]), .dataout(dataint_array[15]), .shift_count_o(shift_count[0]));
  
    // TODO: What does this variable represent
    assign data_concat = {
        dataint_array[15], dataint_array[14], dataint_array[13], dataint_array[12],
        dataint_array[11], dataint_array[10], dataint_array[ 9], dataint_array[ 8],
        dataint_array[ 7], dataint_array[ 6], dataint_array[ 5], dataint_array[ 4],
        dataint_array[ 3], dataint_array[ 2], dataint_array[ 1], dataint_array[ 0]
    };
    
    //---------------------------------------
    //Choose the channel to align to
    //---------------------------------------
    shift_align         u_shift_align
    (
        .clk            (clk            ), 
        .reset          (reset          ), 
        .valid_in       (validint       ), 
        .datain         (data_concat    ), 
        .valid_o        (valid_o        ), 
        .dataout        (dataout        )
    );
    
    /*
    //------------------------------------------
    // Debug ILA
    //------------------------------------------
    ila_ttc     u_ila_ttc
    (
        .clk    (clk      ),
        .probe0 (datain   ),
        .probe1 (validint ),
        .probe2 (valid    ),
        .probe3 (data     )
    ); 
    */
endmodule
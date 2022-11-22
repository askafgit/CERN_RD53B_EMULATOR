//----------------------------------------------------------------------
// RD53_top
// Top level module to the RD53 chip emulator
//----------------------------------------------------------------------
`timescale 1ps/1ps

module RD53_top 
(
    input              reset            ,

    input              clk_tx           ,       // Serial transmit clock (Output bitrate/2)
    input              clk              ,       // Logic clock

    input              uart_rxd         ,       // Debug connection to hit maker
    output             uart_txd         ,
    
    input              ser_ttc_data     ,       // Was 'ttc_data'.  Serial input from differential pad

    input   [3:0]      chip_id          ,       // Constant
    
    output  [3:0]      cmd_out_p        ,       // Serial differential output frame data
    output  [3:0]      cmd_out_n        ,

    output             trig_out         ,       // used for debug LED
    output  [ 2:0]     debug                    // LEDs debug port -> wrreg,rdreg,trigger_r 
);

logic        ttc_dataout_valid;     // Was word_valid 
logic [15:0] ttc_dataout;           // Was data_locked

logic [63:0] cpo_frames_dout[0:3];      // Was frame_out
logic [ 0:3] cpo_frames_dout_service;   // Was service_frame 
logic [ 1:0] cpo_syncs [0:3]   ;        // Was sync
logic [ 3:0] atx_data_next     ;        // Was data_next


    //------------------------------------------------
    // Parses incoming TTC stream, locks to a channel
    //------------------------------------------------
    ttc_top             u_ttc_top
    (
        .clk            (clk                ),      // input
        .reset          (reset              ),      // input

        .datain         (ser_ttc_data       ),      // input  serial data

        .valid_o        (ttc_dataout_valid  ),      // output was  word_valid      
        .dataout        (ttc_dataout        )       // output [15:0] was data_locked
    );


    //----------------------------------------------
    // Prepare data from RD53 to be sent out
    // 'cpo'
    //----------------------------------------------
    chip_output             u_chip_output
    (
        .reset              (reset                  ),
        .clk                (clk                    ),

        .uart_rxd           (uart_rxd               ),  // input   logic
        .uart_txd           (uart_txd               ),  // output  logic

        .ttc_data_valid     (ttc_dataout_valid      ),
        .ttc_data           (ttc_dataout            ),
        .chip_id            (chip_id                ),  // Constant 
        .data_next          (|atx_data_next         ),  // All four lines should always present same value 

        .frames_dout        (cpo_frames_dout        ),  // output. net was frame_out
        .frames_dout_service(cpo_frames_dout_service),  // output. net was service_frame
        .trig_out           (trig_out               ),  // Can be used for debug LED
        .debug              (debug                  )   // Can be used for debug LED
    );


    // Convert service frame bit to 2-bit sync symbol
    assign cpo_syncs[0] = cpo_frames_dout_service[0] ? 2'b10 : 2'b01;
    assign cpo_syncs[1] = cpo_frames_dout_service[1] ? 2'b10 : 2'b01;
    assign cpo_syncs[2] = cpo_frames_dout_service[2] ? 2'b10 : 2'b01;
    assign cpo_syncs[3] = cpo_frames_dout_service[3] ? 2'b10 : 2'b01;


    //----------------------------------------------
    // Four lanes of Aurora differential output
    // from four parallel input frames
    // 'atx' (Aurora TX)
    //----------------------------------------------
    aurora_tx_four_lane     u_aurora_tx_four_lane
    (
        .reset              (reset          ), // input          
        .clk                (clk            ), // input            Logic clock 

        .data_next          (atx_data_next  ), // output  [3:0]    Block requests next data frames 

        .data_in            (cpo_frames_dout), // input   [63:0][0:3]
        .sync               (cpo_syncs      ), // input   [ 1:0][0:3] 

        // Differential pad output
        .clk_tx             (clk_tx         ), // input            Transmit clock (Output Mbps/2)
        .data_out_p         (cmd_out_p      ), // output  [3:0]   
        .data_out_n         (cmd_out_n      )  // output  [3:0]  
    );

/*
    //----------------------------------------------
    // Debug ILAs
    //----------------------------------------------

    ila_command_received    u_ila_cmd_rcv
    (
       .clk                 (clk            ),
       .probe0              (reset          ),
       .probe1              (4'h0           ),
       .probe2              (ser_ttc_data   ),  // Was just 'ttc_data'
       .probe3              (ttc_dataout    ),  // Was 'command', same as data_locked
       .probe4              (ttc_dataout    ),  // Was 'data_locked'
       .probe5              (4'h0           ),
       .probe6              (ttc_dataout_valid)
    );

    ila_output_data_top_level   u_ila_output_data_top_level
    (
       .clk                 (clk                ),
       .probe0              (cpo_frames_dout[0] ),
       .probe1              (cpo_frames_dout[1] ),
       .probe2              (cpo_frames_dout[2] ),
       .probe3              (cpo_frames_dout[3] ),
       .probe4              (trig_out           ),
       .probe5              (4'h0               ),
       .probe6              (1'b0               )
    ); 
*/

endmodule

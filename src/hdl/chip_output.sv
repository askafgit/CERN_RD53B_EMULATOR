//------------------------------------------------------------------------
// Takes received messages from TTC_top after formatting to 16 bit words.
//
// The data is passed into the trigger FSM, which detects if the word is a
// trigger. If it is, the trigger pattern is shifted out. If it is not, the
// word is passed to the command FSM, which processes it. 
// If the command results in generated data, the data is then passed to command_out.

//------------------------------------------------------------------------
`timescale 1ps/1ps
module chip_output
(
    input           reset               ,
    input           clk                 ,

    input           uart_rxd            ,
    output          uart_txd            ,

    input           ttc_data_valid      ,
    input    [15:0] ttc_data            ,
    input    [ 3:0] chip_id             ,
    input           data_next           ,

    output  [63:0]  frames_dout[0:3]    ,   // To Aurora serial output
    output  [ 0:3]  frames_dout_service ,   // Was service_frame
    output          trig_out            ,   // debug 
    output  [ 2:0]  debug 
);
//------------------------------------------------------------------------

    reg         cmd_detect      ;
    reg         trig_detect     ;
    reg  [3:0]  trig_data       ;
    reg  [3:0]  trig_word       ;      // 4-bit trigger pattern e.g. T0T0 or 000T
    reg  [7:0]  trig_tagbase    ;
    reg         trig_word_dv    ;
    reg         cmd_word_dv     ;
    reg  [7:0]  cmd_word        ; 
    reg         rd_fifo_ttc     ; 
    wire        trig_busy       ; 

    // Hit Maker signals
    wire [63:0] htm_data_out        ;
    logic       htm_hitdata_empty   ;
    logic       htm_fifo_trig_full  ;     // ILA
    logic       htm_fifo_trig_empty ;    // ILA

    // command processor register read data and address output
    wire              cpr_rdreg_dv  ;
    wire [15:0]       cpr_rdreg_data;
    wire  [8:0]       cpr_rdreg_addr;
    logic [7:0][25:0] cpr_auto_read ;

    wire  [7:0] fifo_ttc_dout       ;
    logic       fifo_ttc_full       ; 
    logic       fifo_ttc_empty      ;
    wire        fifo_ttc_valid      ;

    // Command_out outputs
    wire        cmo_next_hit        ;
    wire [63:0] cmo_data_out        ;
    wire        cmo_data_out_valid  ;
    wire        cmo_data_out_service;

    // State machine states.
    localparam  S_IDLE  = 1'b0, S_WAIT_TAG = 1'b1;
    logic       state_trig;

//------------------------------------------------------------------------


    //------------------------------------------------------------------------
    // Input width is 16, output width is 8, Depth 16
    // TODO : This IP should be re-named to fifo_ttc_data instead of fifo_generator_0
    //------------------------------------------------------------------------
    fifo_generator_0    u_fifo_ttc_data
    (
       .rst             (reset              ),

       .wr_clk          (clk                ),
       .wr_en           (ttc_data_valid     ),
       .din             (ttc_data           ),

       .rd_clk          (clk                ),
       .rd_en           (rd_fifo_ttc        ),      // was rd_word
       .dout            (fifo_ttc_dout      ),      // Was fifo_data
       .valid           (fifo_ttc_valid     ),      // Was 'fifo_data_valid'

       .full            (fifo_ttc_full      ),      // not used
       .empty           (fifo_ttc_empty     )       // not used
    );


    //------------------------------------------------------------------------
    // Look at TTC data output and check for trigger commands
    // Decode and decide if trigger or command detected
    //------------------------------------------------------------------------
    always @(posedge clk or posedge reset) 
    begin
        if (reset) begin

            trig_data   = 4'b0000;
            cmd_detect  = 1'b0;
            trig_detect = 1'b0;

        end
        else begin

            trig_detect = 1'b0; // TODO: Set to 1'b1 and remove each second line in case statements
            cmd_detect  = 1'b0;

            case (fifo_ttc_dout)

                8'h2B: begin    // 000T
                    trig_data   = 4'b0001;
                    trig_detect = 1'b1;
                end
                8'h2D: begin    // 00T0
                    trig_data   = 4'b0010;
                    trig_detect = 1'b1;
                end
                8'h2E: begin    // 00TT
                    trig_data   = 4'b0011;
                    trig_detect = 1'b1;
                end
                8'h33: begin    // 0T00
                    trig_data   = 4'b0100;
                    trig_detect = 1'b1;
                end
                8'h35: begin    // 0T0T
                    trig_data   = 4'b0101;
                    trig_detect = 1'b1;
                end
                8'h36: begin    // 0TT0
                    trig_data   = 4'b0110;
                    trig_detect = 1'b1;
                end
                8'h39: begin    // 0TTT
                    trig_data   = 4'b0111;
                    trig_detect = 1'b1;
                end
                8'h3A: begin    // T000
                    trig_data   = 4'b1000;
                    trig_detect = 1'b1;
                end
                8'h3C: begin    // T00T
                    trig_data   = 4'b1001;
                    trig_detect = 1'b1;
                end
                8'h4B: begin    // T0T0
                    trig_data   = 4'b1010;
                    trig_detect = 1'b1;
                end
                8'h4D: begin    // T0TT
                    trig_data   = 4'b1011;
                    trig_detect = 1'b1;
                end
                8'h4E: begin    // TT00
                    trig_data   = 4'b1100;
                    trig_detect = 1'b1;
                end
                8'h53: begin    // TT0T
                    trig_data   = 4'b1101;
                    trig_detect = 1'b1;
                end
                8'h55: begin    // TTT0
                    trig_data   = 4'b1110;
                    trig_detect = 1'b1;
                end
                8'h56: begin    // TTTT
                    trig_data   = 4'b1111;
                    trig_detect = 1'b1;
                end
                default: begin  // No trigger pattern, FIFO output is part of a command, or a trigger tag
                    trig_data   = 4'b0000;
                    cmd_detect  = 1'b1;
                    trig_detect = 1'b0;
                end
            endcase
        end
    end
   
   
    //------------------------------------------------------------------------
    // State machine to write trigger data from ttc FIFO to the hitmaker
    // and command (all non-trigger) data from the ttc FIFO to the command_process block.
    //------------------------------------------------------------------------
    // A trigger pattern is always followed by a trigger tag word.
    // Both are written to the hitmaker at the same time.
    // Operation :
    // 1.  Wait for TTC fifo_data (fifo_ttc_valid = 1)
    // 2.  If a trigger pattern word (trig_detect=1) then wait for next word (tag)
    //     then write trigger pattern (trig_word) and trigger tag to hitmaker 
    // 3.  If a non-trigger pattern then write to command_process.
    //------------------------------------------------------------------------
    always @(posedge clk or posedge reset) 
    begin
        if (reset) begin

            cmd_word        <= 4'h0;
            cmd_word_dv     <= 1'b0;
            trig_word       <= 4'h0;
            trig_tagbase    <= 8'b00000000;
            trig_word_dv    <= 1'b0;
            rd_fifo_ttc     <= 1'b0;
            state_trig      <= S_IDLE;

        end
        else begin

            cmd_word_dv     <= 1'b0;    // Defaults
            trig_word_dv    <= 1'b0;

            case (state_trig)

                S_IDLE : begin

                    // Write command word to command_process and read the FIFO
                    if (cmd_detect && fifo_ttc_valid) begin
                        cmd_word        <= fifo_ttc_dout;
                        cmd_word_dv     <= 1'b1;
                        rd_fifo_ttc     <= 1'b1;
                    end

                    // If a trigger pattern is seen, hold it and wait for trigger tag in next FIFO word
                    else if (trig_detect && fifo_ttc_valid) begin
                        state_trig      <= S_WAIT_TAG;
                        trig_word       <= trig_data;
                        rd_fifo_ttc     <= 1'b1;
                    end

                end

                // When next ttc word arrives, generate a write for the trig_word and the current ttc data (tag)
                S_WAIT_TAG : begin

                    if (fifo_ttc_valid) begin
                        state_trig      <= S_IDLE;
                        trig_tagbase    <= fifo_ttc_dout;
                        trig_word_dv    <= 1'b1;
                        rd_fifo_ttc     <= 1'b1;
                    end
                end

                default:  begin
                    state_trig      <= S_IDLE;
                    trig_word       <= 4'h0;
                end
            endcase
        end
    end


    //------------------------------------------------------------------------
    // Converts a 4-bit trigger data word into serial triggers.
    // The 'trig_out' is a serialized trigger pattern exported to an FPGA pin. 
    // Not used anywhere else.
    // The 'trig_done' output is used to produce a single-cycle pulse once the 
    // trigger pattern has been serialized. Used to read next data from the TTC fifo.
    //------------------------------------------------------------------------
    trigger_timing              u_trigger_timing
    (
        .reset                  (reset              ),
        .clk                    (clk                ),
        .datain                 (trig_word          ),
        .datain_dv              (trig_word_dv       ),
        .trig_out               (trig_out           ), 
        .busy                   (trig_busy          )   
    );


    //------------------------------------------------------------------------
    // Command processor 
    // Takes commands from ttc, (not trigger data), and parses it for commands.
    // Contains all the chip configuration registers.
    // If command is a register-write then the register is updated. 
    // If command is a register-read  then the register and its address are output. 
    //------------------------------------------------------------------------
    command_process             u_command_process 
    (
        .reset                  (reset              ),  // input
        .clk                    (clk                ),  // input 

        .chip_id                (chip_id            ),  // input  [3:0]  Static pin setting

        // Data from TTC
        .data_in_valid          (cmd_word_dv        ),  // input
        .data_in                (cmd_word           ),  // input  [7:0]  
        // Decoded commands
        .cmd_clear              (                   ),  // output (Not used)
        .cmd_pulse              (                   ),  // output (Not used)
        .cmd_cal                (                   ),  // output (Not used)
        .cmd_wrreg              (debug[0]           ),  // output (Not used) Drives LED
        .cmd_rdreg              (debug[1]           ),  // output (Not used) Drives LED
        .cmd_sync               (                   ),  // output (Not used)

        // Results of read-reg command. Sent to command_out block
        .rdreg_valid            (cpr_rdreg_dv       ),  // output 
        .rdreg_data             (cpr_rdreg_data     ),  // output  [15:0]
        .rdreg_addr             (cpr_rdreg_addr     ),  // output  [ 8:0]
        // Auto read data, send to command_out block
        .auto_read_o            (cpr_auto_read      ),  // output  [ 7:0][25:0] 

        // Unused outputs. Reserved for future use?
        .cal_edge               (                   ),  // output 
        .cal_aux                (                   )   // output (Not used)
    );

    
    //------------------------------------------------------------------------
    // hitMaker generates 64-bit output data and writes it to an internal FIFO
    // which is read on 'hitData' using 'cmo_next_hit'
    //------------------------------------------------------------------------
    hitMaker3               u_hitmaker3
    (
        .reset              (reset                  ),
       
        .clk                (clk                    ),  // (dClk) 160MHz Clk only used to read the hit data FIFO

        .uart_rxd           (uart_rxd               ),  // input   logic
        .uart_txd           (uart_txd               ),  // output  logic     


        .reset_trigger      (reset                  ),  // Clears trigger FIFOs TODO: get rid of since it uses same reset as above
        .trigger_valid      (trig_word_dv           ),  // Was 'writeT & extraData'  
        .trigger_data       (trig_word              ),  // 4-bit trigger pattern
        .trigger_tagbase    (trig_tagbase           ),  // Trigger tag base. In RD53B tag is not encoded. Tag base field is 8 bits but value is only 6-bit  

        .next_hit           (cmo_next_hit           ),  // Request next output data word

        .hit_dout           (htm_data_out           ),  // Output data word
        .fifo_trig_full     (htm_fifo_trig_full     ),  // ILA
        .fifo_trig_empty    (htm_fifo_trig_empty    ),  // ILA
        .fifo_hitdata_empty (htm_hitdata_empty      ),

        .debug              (debug[2]               )
    );

    
    //------------------------------------------------------------------------
    // Command Out
    //------------------------------------------------------------------------
    command_out             u_command_out
    (
        .reset              (reset                  ),
        .clk                (clk                    ),

        // Interface from command_process
        .auto_read          (cpr_auto_read          ),
        .rdreg_dv           (cpr_rdreg_dv           ),
        .rdreg_data         (cpr_rdreg_data         ),
        .rdreg_addr         (cpr_rdreg_addr         ),

        // Interface with hit maker
        .hitdata_empty      (htm_hitdata_empty      ),
        .hitdata_in         (htm_data_out           ),

        // Interface to frame_buffer 
        .next_hit           (cmo_next_hit           ),      // To hitmaker to request next data
        .data_out           (cmo_data_out           ),
        .data_out_valid     (cmo_data_out_valid     ),
        .data_out_service   (cmo_data_out_service   )
    );
    
    
    //------------------------------------------------------------------------
    // Buffer holds and aligns frames before output
    // TODO: Consider getting rid of clk_rd/wr for a single clk
    //------------------------------------------------------------------------
    frame_buffer_four_lane  u_frame_buffer 
    (
        .reset              (reset                  ), 
        .present_frame      (data_next              ), 
        .clk_wr             (clk                    ),

        // Input from command_out (cmo)
        .frame_din          (cmo_data_out           ), 
        .frame_din_valid    (cmo_data_out_valid     ), 
        .frame_din_service  (cmo_data_out_service   ), 

        .clk_rd             (clk                    ), 
        .frames_dout        (frames_dout            ), 
        .frames_dout_service(frames_dout_service    ) 
    );
    

    //----------------------------------------------
    // Debug ILA
    //----------------------------------------------
/*
    ila_chip_out        u_ila_chip_out
    (
        .clk            (clk),
        .probe0         (data_in),
        .probe1         (trig_out),
        .probe2         (processed_hit),
        .probe3         (cmo_next_hit),
        .probe4         (data_out_valid),
        .probe5         (word_valid),
        .probe6         (rd_fifo_ttc),
        .probe7         (fifo_ttc_valid),
        .probe8         (fifo_ttc_full),
        .probe9         (fifo_ttc_dout),
        .probe10        (htm_fifo_trig_full),
        .probe11        (htm_fifo_trig_empty),
        .probe12        (trig_data),
        .probe13        (trig_detect)
        .probe14        (trig_busy),
        .probe15        (data_out),
        .probe16        (frame_dout[0]),
        .probe17        (frame_dout[1]),
        .probe18        (frame_dout[2]),
        .probe19        (frame_dout[3])
    );
*/

endmodule

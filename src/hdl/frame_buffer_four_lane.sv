//----------------------------------------------------------------------------
// Module: Frame Buffer Four Lane
//----------------------------------------------------------------------------
// Description: assembles individual frames of 64-bit data 
// into sets of 4 frames to be sent to four channels of Aurora TX. 
// Takes input directly from command_out. 
// Additional logic in place to guarantee strict alignment 
// (All output channels contain the same type of data (hit, service or idle) 
//----------------------------------------------------------------------------
`timescale 1ps/1ps

module frame_buffer_four_lane
(
    input         reset                 ,

    input         present_frame         ,   // Downstream block requests a frame

    // Input data and input data clock
    input         clk_wr                ,   // Used to write into FIFOs
    input  [63:0] frame_din             ,
    input         frame_din_valid       ,
    input         frame_din_service     ,   // Set for service frames

    // Output data and output data clock
    input         clk_rd                ,   // Used for state machine logic and FIFO reading
    output [63:0] frames_dout [0:3]     ,
    output [ 0:3] frames_dout_service    
);

//----------------------------------------------------------------------------
// Pattern to output when there is no hit data or service data ready
//----------------------------------------------------------------------------
localparam      IDLE = 64'h1E00000000000000;  

logic       hit_available; 
logic       srv_available; 

// Controls to FIFOs, and output from FIFOs
logic       wr_fifo_hit;
logic       rd_fifo_hit;
logic       fifo_hit_full;
logic       fifo_hit_empty;
logic [7:0] fifo_hit_level;         // Number of words in output side of hit data FIFO. (Prefer 'level' to 'count')
logic [0:3][64:0] fifo_hit_dout; 


logic       wr_fifo_srv;
logic       rd_fifo_srv;
logic       fifo_srv_full;
logic       fifo_srv_empty;
logic [7:0] fifo_srv_level;         // Number of words in output side of service FIFO
logic [0:3][64:0] fifo_srv_dout; 

logic [64:0] frame_selected[0:3];   // State machine selected frame from hit FIFO, service FIFO or IDLE pattern

logic       rden_fifo_hit;          // Enable read from hit data FIFO
logic       rden_fifo_srv;          // Enable read from service frame FIFO

logic       present_frame_d1;       // present_frame delayed by one clock cycle 
logic       present_frame_pulse;    // Pulse of present_frame that shares the same posedge 


//------------------------------------------------------------
// Rising edge edge detect for 'present_frame'
//------------------------------------------------------------
always_ff @(posedge clk_rd or posedge reset) 
begin
    if (reset)
        present_frame_d1    <= 0; 
    else 
        present_frame_d1    <= present_frame; 
end  

assign present_frame_pulse  = (!present_frame_d1 && present_frame);     // Rising edge detect for present_frame

assign wr_fifo_hit  = frame_din_valid && !frame_din_service;            // Write hit data frame words into the hit FIFO
assign rd_fifo_hit  = rden_fifo_hit && present_frame_pulse;


//------------------------------------------------------------
// FIFO for Hit Data Frames and frame type (service)
// 'fifo_one_to_four' should be renamed to
// something like fifo_frame_buffer, or fifo_fb or fifo_fb_65to260
//------------------------------------------------------------
fifo_one_to_four    u_fb_fifo_hit   
(
    .rst            (reset                          ),

    .wr_clk         (clk_wr                         ),
    .din            ({frame_din_service, frame_din} ),
    .wr_en          (wr_fifo_hit                    ),

    .rd_clk         (clk_rd                         ),
    .rd_en          (rd_fifo_hit                    ),
    .dout           (fifo_hit_dout                  ),

    .full           (fifo_hit_full                  ),
    .empty          (fifo_hit_empty                 ),
    .rd_data_count  (fifo_hit_level                 ),

    .wr_rst_busy    (                               ),
    .rd_rst_busy    (                               )
);

assign  hit_available   = !fifo_hit_empty;

assign  wr_fifo_srv     = frame_din_valid && frame_din_service;     // Write service frames
assign  rd_fifo_srv     = rden_fifo_srv && present_frame_pulse; // Read service frames

//------------------------------------------------------------
// FIFO for Service Frame data
//------------------------------------------------------------
fifo_one_to_four u_fb_fifo_srv 
(
    .rst           (reset                           ),

    .wr_clk         (clk_wr                         ),
    .din            ({frame_din_service, frame_din} ),
    .wr_en          (wr_fifo_srv                    ),

    .rd_clk         (clk_rd                         ),
    .rd_en          (rd_fifo_srv                    ),
    .dout           (fifo_srv_dout                  ),

    .full           (fifo_srv_full                  ),
    .empty          (fifo_srv_empty                 ),
    .rd_data_count  (fifo_srv_level                 ),

    .wr_rst_busy    (                               ),
    .rd_rst_busy    (                               )
);
 
assign srv_available    = !fifo_srv_empty;


//------------------------------------------------------------
// Enumerated type for output State Machine 
//------------------------------------------------------------
enum {S_IDLE = 0,  S_DATA = 1,  S_SER} state, state_next; 


//------------------------------------------------------------
// Update state when a FIFO is read
//------------------------------------------------------------
always_ff @(posedge clk_rd or posedge reset) begin

    if (reset) begin 
        state <= S_IDLE; 
    end else if (present_frame_pulse) begin 
        state <= state_next; 
    end  

end 


//------------------------------------------------------------
// Generate next state which selects data either from a FIFO
// or selects the IDLE pattern
//------------------------------------------------------------
always_comb begin

    case (state)

        //----------------------------------------------------
        // Output IDLE
        //----------------------------------------------------
        S_IDLE : begin 

            if      (srv_available) // Output service frame if available. Priority over data
                state_next = S_SER;
            else if (hit_available) 
                state_next = S_DATA; 
            else 
                state_next = S_IDLE; 
        end

        //----------------------------------------------------
        // Hitdata is available to send out but service takes priority
        //----------------------------------------------------
        S_DATA : begin
            if      (srv_available)         // Output service frame if available. Priority over data
                state_next = S_SER;
            else if (fifo_hit_level >= 2)   // Otherwise data frame if available 
                state_next = S_DATA; 
            else 
                state_next = S_IDLE; 
        end

        //----------------------------------------------------
        // Service frame data to send out 
        //----------------------------------------------------
        S_SER : begin 
            if (fifo_srv_level >= 2)        // Output service frame if available
                state_next = S_SER; 
            else if (hit_available)         // Output data is that is available
                state_next = S_DATA; 
            else 
                state_next = S_IDLE; 
        end 

    endcase

end 


//------------------------------------------------------------
// State based logic selecting between outputs from service 
// or hit data FIFOs or using IDLE    
//------------------------------------------------------------
always_comb begin 
    int i; 

    for (i=0 ; i<4 ; i=i+1) 
    begin 
        if      (state == S_IDLE)
            frame_selected[i] = {1'b1, IDLE};
        else if (state == S_DATA) 
            frame_selected[i] = fifo_hit_dout[i]; 
        else
            frame_selected[i] = fifo_srv_dout[i];
    end

    // Read from one of the two FIFOs 
    if (state == S_DATA) begin 
        rden_fifo_hit   <= 1'b1; 
        rden_fifo_srv   <= 1'b0; 
    end else if (state == S_SER) begin 
        rden_fifo_hit   <= 1'b0; 
        rden_fifo_srv   <= 1'b1; 
    end else begin 
        rden_fifo_hit   <= 1'b0;
        rden_fifo_srv   <= 1'b0; 
    end     

end 


//------------------------------------------------------------
// Assign selected frame data to the four output channels
//------------------------------------------------------------
genvar j; 
for (j = 0; j < 4; j = j+1) 
begin 
    assign frames_dout[j]           = frame_selected[j][63:0];
    assign frames_dout_service[j]   = frame_selected[j][64]; 
end 

//------------------------------------------------------------
// Logic Analyzer for internal signals
//------------------------------------------------------------
/*
ilaFourBuff     u_ilaFourBuff 
(
    .clk(clk_wr)                    ,
    .probe0(frame_din)              ,
    .probe1(frame_din_valid)        ,
    .probe2(present_frame)          ,
    .probe3(fifo_hit_dout[0])       ,
    .probe4(fifo_hit_dout[1])       ,
    .probe5(fifo_hit_dout[2])       ,
    .probe6(fifo_hit_dout[3])       ,
    .probe7(fifo_srv_dout[0])       ,
    .probe8(fifo_srv_dout[1])       ,
    .probe9(fifo_srv_dout[2])       ,
    .probe10(fifo_srv_dout[3])      ,
    .probe11()              ,
    .probe12(frame_din_service)     ,
    .probe13(srv_available)         ,
    .probe14(hit_available)         ,
    .probe15(state)                 ,
    .probe16(frame_selected[0])     ,
    .probe17(frame_selected[1])     ,
    .probe18(frame_selected[2])     ,
    .probe19(frame_selected[3])     ,
    .probe20(rd_fifo_srv)           ,
    .probe21(rd_fifo_hit)
);
*/

endmodule


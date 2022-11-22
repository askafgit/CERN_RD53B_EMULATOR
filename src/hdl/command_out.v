//---------------------------------------------------------------------
// command_out 
//---------------------------------------------------------------------
// Creates 64-bit output data frames.
// Merges hit datai frames (or idle patterns) with channel bonding frames and 
// register read data frames 
// 
// TODO : What is maximum output data rate?
// Looks like 64-bit data on alternate 160 MHz clock cycles 
// 64-bit x 160/2 MHz = 5.12 Gb/sec = 4 channels at 1.28 Gb/sec
//
// TODO : Looks like a maximum of two reg-read data/address pairs can be 
// output in each burst of four service frames. Other 3 service frames will 
// always be autoread data.
//---------------------------------------------------------------------
`timescale 1ps/1ps

module command_out(
    input            reset              ,
    input            clk                ,   // Used for all internal logic and output signals

    // Command processor interface
    // Auto read address and data. Each consists of a 10-bit register address and 16-bit register value
    input [7:0][25:0] auto_read         ,
    // Data and address from commanded register reads
    input            rdreg_dv           ,
    input    [15:0]  rdreg_data         ,
    input    [ 8:0]  rdreg_addr         ,


    // Hit generator interface
    input            hitdata_empty      ,   // High when no data available
    output           next_hit           ,
    input    [63:0]  hitdata_in         ,   // FIFO data read at 160 MHz

    // Output frames
    output  reg [63:0]  data_out           ,
    output  reg         data_out_valid     ,
    output              data_out_service   // was service_frame,
);


// The interval between service frames
localparam DATA_FRAMES  = 193;  // (Rename to SERVICE_INTERVAL ?)
//localparam DATA_FRAMES  = 80;  // (Rename to SERVICE_INTERVAL ?)
//localparam SERVICE_INTERVAL  = 193; 

// AURORA protocol IDLE frame
localparam IDLE         = 64'h1E00_0000_0000_0000;

// The interval between channel bonding frames (?)
localparam CB_WAIT      = 42;   // (Rename to INTERVAL_CH_BOND ?)

localparam sync_pattern = 16'b1000_0001_0111_1110;  // 0x817E

reg [ 8:0]  cnt_frames;         // Count output frames. 
reg [ 9:0]  fifo_adx_hold;      // Hold address FIFO output 
reg [15:0]  fifo_cmd_hold;      // Hold reg-read FIFO output 
reg [ 1:0]  data_available;
reg [11:0] cnt_cb_wait;        // Channel bonding wait count   (Rename cnt_ch_bond ?)

wire [63:0] hitdata_muxed;
wire [15:0] fifo_cmd_dout;
wire  [8:0] fifo_adx_dout;
wire        fifo_cmd_empty;     // was cmd_valid;
wire        fifo_adx_empty;     // was adx_valid;
wire        fifo_cmd_full;      // status. Was adx_full output port but was only used in level above to gate FIFFO writes. Now used internally
wire        fifo_adx_full;      // status. Was adx_full output port but was only used in level above to gate FIFFO writes. Now used internally

wire        wr_fifo_cmd;        // was gated externally;
wire        wr_fifo_adx;        // was gated externally;
wire        rd_fifo_cmd;        // was rd_cmd;
wire        rd_fifo_adx;        // was_rd_adx;


//--------------------------------------------
// If there is no hit data, send idle frame
//--------------------------------------------
assign      hitdata_muxed = (hitdata_empty) ? IDLE : hitdata_in;


assign      wr_fifo_cmd = rdreg_dv & !fifo_cmd_full;
assign      wr_fifo_adx = rdreg_dv & !fifo_adx_full;

// These two FIFOs actually have the same read signal.
// TODO : Replace u_fifo_cmd (data and u_fifo_adx with one 26-bit fifo_rdreg
//--------------------------------------------
// Command FIFO (Data from read-register commands)
// Input width 16, output width 16, Depth 32
//--------------------------------------------
fifo_generator_1    u_fifo_cmd
(
   .rst             (reset              ),

   .wr_clk          (clk                ),
   .din             (rdreg_data         ),
   .wr_en           (wr_fifo_cmd        ),

   .rd_clk          (clk                ),
   .rd_en           (rd_fifo_cmd        ),
   .dout            (fifo_cmd_dout      ),

   .full            (fifo_cmd_full      ),
   .empty           (fifo_cmd_empty     ),
   .wr_rst_busy     (                   ),
   .rd_rst_busy     (                   )
);


//--------------------------------------------
// Register read address FIFO
// Input width 9, output width 9, Depth 32
//--------------------------------------------
fifo_generator_2    u_fifo_adx
(
    .rst            (reset              ),

    .wr_clk         (clk                ),
    .din            (rdreg_addr         ),
    .wr_en          (wr_fifo_adx        ),

    .rd_clk         (clk                ),
    .rd_en          (rd_fifo_adx        ),
    .dout           (fifo_adx_dout      ),

    .full           (fifo_adx_full      ),
    .empty          (fifo_adx_empty     ),  // Was adx_valid
    .wr_rst_busy    (                   ),
    .rd_rst_busy    (                   )
);


//--------------------------------------------------------------------
// Logic that pulls data from hitmaker block
//--------------------------------------------------------------------
assign next_hit =
    // Every other cycle of frame counter
    (cnt_frames[0] &&
    // Sending service frames. Hitdata frames are not being sent out
    !((cnt_frames >= DATA_FRAMES * 2 - 3) && (cnt_frames <= DATA_FRAMES * 2 + 3)) &&
    // hitdata is available
    !(hitdata_empty)) &&
    // Sending channel bonding frames. Hitdata frames are not being sent out
    !(cnt_cb_wait == CB_WAIT && (cnt_frames >= DATA_FRAMES * 2 + 5) && (cnt_frames <= DATA_FRAMES * 2 + 11));


//--------------------------------------------------------------------
// A pulse alongside data_out_valid while a service frame 
// or channel bonding frame is being sent out
//--------------------------------------------------------------------
assign data_out_service =
    // If service frames (register-read or autoread values) are being sent 
    ((((cnt_frames >= DATA_FRAMES * 2 - 2) && (cnt_frames <= DATA_FRAMES * 2 + 4)) ||
    // or if channel bonding frames are being sent and
    ((cnt_cb_wait == CB_WAIT) && (cnt_frames >= DATA_FRAMES * 2 + 5))) &&
    // when data_out is valid
    data_out_valid);


// fifo_cmd_empty and fifo_adx_empty should be the same since 'command' and 'address' data are always written together.
assign rd_fifo_cmd  = ~fifo_cmd_empty 
                      && ((cnt_frames == DATA_FRAMES * 2 - 6) || (cnt_frames == DATA_FRAMES * 2 - 4));

assign rd_fifo_adx  = ~fifo_adx_empty 
                      && ((cnt_frames == DATA_FRAMES * 2 - 6) || (cnt_frames == DATA_FRAMES * 2 - 4));


// These are identical signals since both FIFOs are written and read at the same time
reg adx_valid;
reg cmd_valid;


//--------------------------------------------------------------------
// Register inverted FIFO empty signal to use as 'data/adx' available'
//--------------------------------------------------------------------
always @ (posedge clk or posedge reset) begin
    if (reset) begin
        adx_valid   <= 0;
        cmd_valid   <= 0;
    end else begin
        adx_valid   <= ~fifo_adx_empty;
        cmd_valid   <= ~fifo_cmd_empty;
    end
end


//--------------------------------------------------------------------
// Main state machine to count output frames to decide when to insert 
// Channel Bonding frames or auto-read or reg-read data frames
//--------------------------------------------------------------------
always @ (posedge clk or posedge reset) begin

    if (reset) begin
        cnt_frames          <= 9'b111111111;
        data_out            <= 64'b0;
        data_out_valid      <= 1'b0;
        fifo_adx_hold       <= 9'b0;
        fifo_cmd_hold       <= 16'b0;
        cnt_cb_wait         <= 12'b0;
    end 

    // Used when input was 80 MHz
    //else if (sync_flag == 1'b0) begin
    //
    //if (high)
    //    cnt_frames <= cnt_frames + 1;
    //
    //sync_flag <= 1'b1;
    //end 

    else begin

        //--------------------------------------------------------------------
        // Update service counter every cycle
        //--------------------------------------------------------------------
        cnt_frames  <= cnt_frames + 1;

        //--------------------------------------------------------------------
        // Get first data chunk
        //--------------------------------------------------------------------
        if (cnt_frames == DATA_FRAMES * 2 - 6) begin

            if (cmd_valid && adx_valid) begin
                data_available <= 2'b01;
            end
            else if (!cmd_valid && !adx_valid) begin
                data_available <= 2'b00;
            end
            else begin
                $display("Invalid FIFO configuration at %d", $time);
            end

        end

        // Save first set of FIFO data
        else if (cnt_frames == DATA_FRAMES * 2 - 5) begin
            if (data_available) begin
                fifo_adx_hold <= {1'b0, fifo_adx_dout};     // Pad address to 10 bits
                fifo_cmd_hold <= fifo_cmd_dout;
            end
            data_out    <= hitdata_muxed;                   // Output hit data or 'idle' pattern
        end

        // Get second set of FIFO data
        else if (cnt_frames == DATA_FRAMES * 2 - 4) begin
            if (cmd_valid && adx_valid) begin
                data_available  <= 2'b10;
            end
            else if (!cmd_valid && !adx_valid) begin
                data_available  <= data_available;
            end
            else begin
                $display("Invalid FIFO configuration at %d", $time);
            end
        end

        //--------------------------------------------------------------------
        // Commanded reg-read data is only returned on lane 0
        //--------------------------------------------------------------------
        // Concatenate the two register-read FIFO reads or autoread data into an output frame.
        else if (cnt_frames == DATA_FRAMES * 2 - 3) begin

            if (data_available == 2'b10) begin          // Both regs from read commands
                data_out    <= {8'hD2, 4'b0000, fifo_adx_hold, fifo_cmd_hold, 1'b0, fifo_adx_dout, fifo_cmd_dout};
            end
            else if (data_available == 2'b01) begin     // First reg from read cmd, Second from autoread
                data_out    <= {8'h99, 4'b0000, fifo_adx_hold, fifo_cmd_hold, auto_read[0]};
            end
            else begin  // If reg-read data is not available, send 2 auto-read registers
                data_out[63:52]     <= 12'hB40;
                data_out[51:26]     <= auto_read[0];        // 10-bit address, 16-bit data
                data_out[25:0]      <= auto_read[1];        // 10-bit address, 16-bit data
            end  
            data_available <= 2'b0;
        end

        // Reiterate(?) register/service frame
        else if ((cnt_frames == DATA_FRAMES * 2 - 2)) begin
            data_out        <= data_out;
        end

        // Concatenate autoread data into an output frame.
        else if ((cnt_frames == DATA_FRAMES * 2 - 1) || (cnt_frames == DATA_FRAMES * 2)) begin
            data_out[63:52]     <= 12'hB40;
            data_out[51:26]     <= auto_read[2];        // 10-bit address, 16-bit data
            data_out[25:0]      <= auto_read[3];        // 10-bit address, 16-bit data
        end

        // Concatenate autoread data into an output frame.
        else if ((cnt_frames == DATA_FRAMES * 2 + 1) || (cnt_frames == DATA_FRAMES * 2 + 2)) begin
            data_out[63:52]     <= 12'hB40;             // Both regs are 'autoread'
            data_out[51:26]     <= auto_read[4];        // 10-bit address, 16-bit data
            data_out[25:0]      <= auto_read[5];        // 10-bit address, 16-bit data
        end

        // Concatenate autoread data into an output frame.
        else if ((cnt_frames == DATA_FRAMES * 2 + 3)  || (cnt_frames == DATA_FRAMES * 2 + 4)) begin
            data_out[63:52]     <= 12'hB40;             // Both regs 'autoread', chip_id and status = '00'
            data_out[51:26]     <= auto_read[6];        // 10-bit address, 16-bit data
            data_out[25:0]      <= auto_read[7];        // 10-bit address, 16-bit data
        end

        // Reset loop (?) if not due for a CB bundle
        else if ((cnt_frames >= DATA_FRAMES * 2 + 5) && (cnt_frames <= DATA_FRAMES * 2 + 11)) begin

            if (cnt_cb_wait == CB_WAIT)
                data_out    <= {8'h78, 4'b0100, 52'b0};     // AURORA code word. Channel Bonding

            else begin // reset loop
                cnt_cb_wait         <= cnt_cb_wait + 1;
                data_out            <= hitdata_muxed;
                cnt_frames          <= 9'b000000000;
            end

        end

        // Reset loop (?) after a forced CB bundle
        else if ((cnt_frames >= DATA_FRAMES * 2 + 11) && cnt_cb_wait == CB_WAIT) begin
            cnt_cb_wait         <= 0;
            data_out            <= hitdata_muxed;
            cnt_frames          <= 7;
        end

        // Data frame (not service frame)
        else if (cnt_frames[0]) begin
            data_out            <= hitdata_muxed;
        end


        //--------------------------------------------------------------------
        // Data_out_valid logic
        //--------------------------------------------------------------------
        if (  ((cnt_frames >= DATA_FRAMES * 2 - 3) && (cnt_frames <= DATA_FRAMES * 2 + 4)) 
           || ((cnt_cb_wait == CB_WAIT)            && (cnt_frames >= DATA_FRAMES * 2 + 5))
        )
            data_out_valid <= cnt_frames[0];

        else if (!hitdata_empty)
            data_out_valid <= cnt_frames[0];
        else
            data_out_valid <= 1'b0;
    end

end


/*
ilaOut u_ila_CmdOut
(
    .clk   (clk   )          ,
    .probe0(data_out)        ,
    .probe1(cnt_frames) ,
    .probe2(hitdata_empty)   ,
    .probe3(hitin)           ,
    .probe4(data_out_service),
    .probe5(rdreg_data)      ,
    .probe6(rdreg_dv)        ,
    .probe7(rdreg_addr)      ,
    .probe8(1'b0)            ,
    .probe9(data_out_valid)  ,
    .probe10(rd_fifo_cmd)    ,
    .probe11(fifo_cmd_dout)  ,
    .probe12(cmd_full)       ,
    .probe13(rd_fifo_adx)    ,
    .probe14(fifo_adx_dout)  ,
    .probe15(fifo_adx_full)
);
*/

endmodule

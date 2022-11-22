//----------------------------------------------------------------------------
// File : hitMaker3.sv
//----------------------------------------------------------------------------
// When the input next_hit is raised, the next hit data word is output 
//
// Contains three FIFOs :
// Two for Trigger patterns and Trigger tag information. (Written with tClk (clk80), read with hClk (clk40))
// One for output data buffering. (fifo_hit_data : Written with hClk (clk40), read with dClk (clk))
//----------------------------------------------------------------------------
`timescale 1ps/1ps

// TODO: Get rid of all reset_trigger and replace with reset

//module hit_maker      // Preferred name
module hitMaker3
(
    input           reset               ,
    input           clk                 ,   // (dClk) 160MHz Clock only used to read the hit data FIFO

    input           uart_rxd            ,   // Reserved signals for hit_generator debug
    output          uart_txd            ,

    input           reset_trigger       ,   // Resets trigger_data and trigger_tagbase FIFOs. Was 'emptyTT'

    input           trigger_valid       ,   // Set when trigger_data and trigger_tagbase are updated. Was 'writeT'
    input   [ 3:0]  trigger_data        ,   // 4-bit trigger pattern. Was 'triggerClump'
    input   [ 7:0]  trigger_tagbase     ,   // 6 lower bits used. Was 'triggerTag'
    input           next_hit            ,   // Request a new word from fifo_hit_data

    output  [63:0]  hit_dout            ,   // Output. Was 'hitData'
    output          fifo_trig_full      ,   // Was 'full'. Only used in ILA in upper level
    output          fifo_trig_empty     ,   // Was 'empty'. Only used in ILA in upper level
    output          fifo_hitdata_empty  ,   // Was 'hitData_empty'

    output          debug                   // Debug port
);

//------------------------------------------------------------------------

    wire            fifo_trig_dout;     // Was 'step'
    logic           fifo_trig_dout_dv;  // Was 'valid_step'

    wire    [63:0]  hitgen_dataout;     // Was 'maskedData'
    wire    [63:0]  fifo_hitdata_dout;  // New
    wire            fifo_hitdata_full;  // Was 'holdDataFull'
    
    wire            wr_fifos_trig;      // Write to both trigger FIFOs. Was 'doWriteT'
    logic           rd_fifo_trig;       // Read trigger data FIFO. Was 'first_rd_en'
    reg             rd_fifo_tag;        // Read trigger tag FIFO. Was 'doRead'
    reg             hitgen_done;        // High when hit_generator is waiting for a trigger. Low when it is outputting data.
    logic           trigger;            // To hit_generator to start data generation
    logic   [ 1:0]  bit_order_tag;      // Specified which of the 4 bits in a trigger word are associated with this hit data
    reg             wr_fifo_hitdata;    // Was ~hitgen_done. Now a registered signal
    logic   [63:0]  hitgen_data_tagged; // Data with tag (info) merged into first word
    logic   [ 1:0]  wait_period;        // Creates delay between triggers to hit_generator

    wire    [ 5:0]  fifo_tagbase_dout;  // Was 'tagInfoOut';
    reg     [ 2:0]  cnt_tag;            // Was 'tagCounter';
    logic   [ 7:0]  trigger_info;
    reg             empty_r;



    // Write new trigger data to both FIFOs if fifo_trig_data has room
    assign wr_fifos_trig = trigger_valid & (~fifo_trig_full);
    
    //------------------------------------------------------------------------
    // Reverse the order of the trigger so the single-bit FIFO output is in 
    // the correct order
    //------------------------------------------------------------------------
    wire    [3:0]   fifo_trig_din;      // Was 'iTriggerClump';
    assign fifo_trig_din[0] = trigger_data[3];
    assign fifo_trig_din[1] = trigger_data[2];
    assign fifo_trig_din[2] = trigger_data[1];
    assign fifo_trig_din[3] = trigger_data[0];


    //------------------------------------------------------------------------
    // FIFO for triggers 32x4 -> 128x1   (Actual 31x4 -> 124x1
    // Write 4-bit trigger patterns. Read 1-bit triggers 
    //------------------------------------------------------------------------
    triggerFifo         u_fifo_trig 
    (
        .rst            ( reset_trigger     ),

        .wr_clk         ( clk               ),
        .wr_en          ( wr_fifos_trig     ),
        .din            ( fifo_trig_din     ),

        .rd_clk         ( clk               ),
        .rd_en          ( rd_fifo_trig      ),
        .dout           ( fifo_trig_dout    ),

        .full           ( fifo_trig_full    ),
        .empty          ( fifo_trig_empty   )
    );

    //------------------------------------------------------------------------
    // FIFO for trigger tags
    // Read and write signals are same as for triggerFifO
    //------------------------------------------------------------------------
    triggerTagFifo      u_fifo_tagbase 
    (
        .rst            ( reset_trigger         ), 

        .wr_clk         ( clk                   ),
        .wr_en          ( wr_fifos_trig         ), 
        .din            ( trigger_tagbase[5:0]  ),

        .rd_clk         ( clk                   ), 
        .rd_en          ( rd_fifo_tag           ), 
        .dout           ( fifo_tagbase_dout     ),

        .full           (                       ),  
        .empty          (                       ),
        .wr_rst_busy    (                       ),
        .rd_rst_busy    (                       )
    );


    //------------------------------------------------------------------------
    // Read new trigger values from FIFO
    // Read FIFO every 4 clock cycles or wait until hit generator is done
    //------------------------------------------------------------------------
    always_ff @(posedge clk) 
    begin
        if (reset) begin
            rd_fifo_trig        <= 0;
            wait_period         <= 0;
            fifo_trig_dout_dv   <= 0;

        // If trigger data FIFO is empty or not hitgen_done, don't read new trigger value from FIFO
        end else if (fifo_trig_empty | ~hitgen_done) begin
            rd_fifo_trig        <= 0;
            wait_period         <= 0;
            fifo_trig_dout_dv   <= 0;

        // Get a new value from trigger FIFO 
        end else if (wait_period == 0 & ~fifo_trig_empty) begin
            rd_fifo_trig        <= 1;
            wait_period         <= 1;
            fifo_trig_dout_dv   <= 0;

        end else if (wait_period == 1) begin
            rd_fifo_trig        <= 0;
            wait_period         <= 2;
            fifo_trig_dout_dv   <= 1;

        end else if (wait_period == 2) begin
            rd_fifo_trig        <= 0;
            wait_period         <= 3;
            fifo_trig_dout_dv   <= 0;

        end else if (wait_period == 3 & ~fifo_trig_empty) begin

            // If trigger value is '0' keep reading
            if (fifo_trig_dout == 0) begin
                rd_fifo_trig        <= 1;
                wait_period         <= 1;       // Set wait_period back to 1
                fifo_trig_dout_dv   <= 0;

            // If trigger value is '1' cause a cycle delay
            end else begin
                rd_fifo_trig        <= 0;
                wait_period         <= 0;       // Set wait_period back to 0
                fifo_trig_dout_dv   <= 0;
            end

        end else begin
            rd_fifo_trig        <= 0;
            wait_period         <= 0;
            fifo_trig_dout_dv   <= 0;
        end
    end


    //------------------------------------------------------------------------
    // Counter that manages when next tag should be read from its fifo.
    // The trigger data FIFO has 4 bits written at the same time as the tag FIFO
    // but they are read out serially (1-bit at a time)
    // Tag changes only when all 4 trigger bits are read from trigger data FIFO.
    // Tag counter is incremented for each trigger with the same tag.
    //------------------------------------------------------------------------
    always_ff @(posedge clk)
    begin
        if (reset) begin
            cnt_tag         <= 0;
            rd_fifo_tag     <= 0;
        end else if (fifo_trig_empty) begin
            cnt_tag         <= 0;
            rd_fifo_tag     <= 0;
        end else if (cnt_tag == 4 & rd_fifo_trig) begin
            cnt_tag         <= 1;
            rd_fifo_tag     <= 1;
        end else if (cnt_tag == 0 & rd_fifo_trig) begin
            cnt_tag         <= cnt_tag + 1;
            rd_fifo_tag     <= 1;
        end else if (rd_fifo_trig) begin
            cnt_tag         <= cnt_tag + 1;
            rd_fifo_tag     <= 0;
        end else begin
          //cnt_tag         <= cnt_tag;  // Useless line
            rd_fifo_tag     <= 0;
        end
    end


    //------------------------------------------------------------------------
    // 8-bit value to place in a field of the first output word of each hit.
    // 6-bit tagbase from FIFO and lower 2 bits from a counter.
    //------------------------------------------------------------------------
    assign bit_order_tag        = cnt_tag - 1;
    assign trigger_info[7:0]    = {fifo_tagbase_dout, bit_order_tag};


    //------------------------------------------------------------------------
    // Register trigger data FIFO empty
    //------------------------------------------------------------------------
    always_ff @(posedge clk) 
    begin
        if (reset)
            empty_r     <= 0;
        else
            empty_r     <= fifo_trig_empty;
    end


    //------------------------------------------------------------------------
    // Generate trigger to hit_generator
    // Was a separate 'assign' statement.
    //------------------------------------------------------------------------
    always_ff @(posedge clk) 
    begin
        if (reset)
            trigger     <= 0;
        else
            trigger     <= fifo_trig_dout & (~empty_r) & fifo_trig_dout_dv;
    end


    //------------------------------------------------------------------------
    // Output stream data from a memory table when triggered 
    //------------------------------------------------------------------------
    hit_generator3      u_hit_generator3    // This hit_generator uses a ROM pre-loaded with hit data from a COE file
    (
        .reset          ( reset             ),
        .clk            ( clk               ), 

        .uart_rxd       ( uart_rxd          ),  // input   logic
        .uart_txd       ( uart_txd          ),  // output  logic     

        .trigger        ( trigger           ),  // input

        .hitgen_dataout ( hitgen_dataout    ),  // output [63:0] Output data stream. Net was 'MaskedData' (?)
        .hitgen_done    ( hitgen_done       )   // output        Low when data is being output. Port was 'done_o', net was 'done'
    );
    
    // Debug port possibly used to drive one of the LEDs
    assign debug = trigger;


    //------------------------------------------------------------------------
    // Make merged hitdata for output FIFO. The first word of each hit contains
    // a tag, an 8-bit trigger_info field.
    // This was a combinational process with the FIFO write using ~hitgen_done.
    // Now wr_fifo_hitdata and 64-bit hitgen_data_tagged are registered.
    //------------------------------------------------------------------------
    always_ff @(posedge clk)
    begin
        if (~hitgen_done && hitgen_dataout[63]) begin
            hitgen_data_tagged  <= {hitgen_dataout[63], trigger_info[7:0], hitgen_dataout[54:0]};
            wr_fifo_hitdata     <= 1'b1;
        end
        else if (~hitgen_done) begin
            hitgen_data_tagged  <= hitgen_dataout;
            wr_fifo_hitdata     <= 1'b1;
        end
        else begin
            hitgen_data_tagged  <= 64'b0;
            wr_fifo_hitdata     <= 1'b0;
        end
    end


    //------------------------------------------------------------------------
    // FIFO to store output data from the hit_generator block
    //------------------------------------------------------------------------
    hitDataFIFO         u_fifo_hitdata 
    (
        .rst          ( reset             ),
        .wr_clk         ( clk               ),
        .wr_en          ( wr_fifo_hitdata   ),  // Was ~hitgen_done
        .din            ( hitgen_data_tagged),

        .rd_clk         ( clk               ),
        .rd_en          ( next_hit          ),
        .dout           ( fifo_hitdata_dout ),
        .full           ( fifo_hitdata_full ),
        .empty          ( fifo_hitdata_empty)
    );

    // Output port
    assign hit_dout = fifo_hitdata_dout;


    //------------------------------------------------------------------------
    // Debug ILA
    //------------------------------------------------------------------------
    /*
    ila_hitgen_fifo ila_6
    (
        .clk   (clk                ),
        .probe0(hitgen_data_tagged ),
        .probe1(fifo_hitdata_dout  ),
        .probe2(next_hit           ),
        .probe3(fifo_hitdata_empty )
    );
    */

endmodule


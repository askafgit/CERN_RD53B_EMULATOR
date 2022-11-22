//----------------------------------------------------------------------
// RD53B Top Level FPGA for SLAC Readout board with 156.25 MHz clock
// on SMA inputs from YARR board
//----------------------------------------------------------------------
//
// This module is the top level module for the on-chip electronics.
// That includes the RD53 emulator and the required PLLs.
// PLLs were separated from the emulators so that we could maximize
// the number of emulators stampable in the FPGA, rather than
// be limited by the number of PLLs.

// The clocks and TTC must be forwarded from the DAQ, but they are
// shared by all the emulators, so only one of each must be present
// for the system to work.
// Emulator outputs 4 differential lanes of data.
//----------------------------------------------------------------------
`timescale 1ps/1ps


module on_chip_top
(
    input           USER_SMA_CLOCK_P                ,
    input           USER_SMA_CLOCK_N                ,

    input           p_uart_rxd                      ,
    output          p_uart_txd                      ,

    input           ttc_data_p                      ,
    input           ttc_data_n                      ,
    
    output  [3:0]   cmd_out_p                       ,
    output  [3:0]   cmd_out_n                       ,

    output  [3:0]   led                             ,
    output [29:0]   p_debug
);

logic reset;
logic trig_out;

assign reset = 1'b0;

// Clocks
logic clk_tx    ;     // Serial output data clock (Output data rate/2)
logic clk160    ;

logic ttc_data  ;                       // Single-ended TTC input data signal
logic uart_rxd      ;                   // Debug
logic uart_txd      ;                   // Debug
logic mmcm_locked   ;                   // MMCM locked signal
logic rst_lock_halt ;                   // High during reset or when MMCM not locked

logic   [2:0]   rd53_debug ;
logic   [3:0]   chip_id;                //
assign  chip_id = 4'b0011;

// wait for the PLL to lock before releasing submodules from reset
assign rst_lock_halt = reset | !mmcm_locked;


    //----------------------------------------------------
    // Internal clocks generated from incoming clk sent over SMA or VHDCI
    //----------------------------------------------------
    clk_wiz_SLAC u_clk_wiz_SLAC
    (
        .reset      (reset        ),

        .clk_in1_p  (USER_SMA_CLOCK_P   ),
        .clk_in1_n  (USER_SMA_CLOCK_N   ),

        .clk_out1   (           ),  // 160 MHz  
        .clk_out2   (clk160     ),  // 160 MHz  Logic clock
        .clk_out3   (clk_tx     ),  //  80 MHz  Serial output clock (80MHz gives 160Mbps output rate)
        .clk_out4   (           ),  //  40 MHz
        .clk_out5   (           ),  //  40 MHz  
        .clk_out6   (           ),  //  20 MHz
        .clk_out7   (           ),  // 320 MHz   // Need 640 MHz clock for clk_tx 1.280Gpbs output rate

        .locked     (mmcm_locked)
    );


    //----------------------------------------------------
    // Turn differential TTC signal into single-ended
    //----------------------------------------------------
    IBUFDS          u_IBUFDS_ttc
    (
        .I          (ttc_data_p  ),
        .IB         (ttc_data_n  ),
        .O          (ttc_data    )
    );


    //----------------------------------------------------
    // One emulator instance
    //----------------------------------------------------
    RD53_top            u_RD53_top 
    (
        .reset          (rst_lock_halt  ),
        .clk_tx         (clk_tx         ),
        .clk            (clk160         ),

        .uart_rxd       (uart_rxd       ),
        .uart_txd       (uart_txd       ),

        .ser_ttc_data   (ttc_data       ),
        
        .chip_id        (chip_id        ),

        .cmd_out_p      (cmd_out_p      ),
        .cmd_out_n      (cmd_out_n      ),

        .trig_out       (trig_out       ),

		.debug          (rd53_debug     )   //LEDs debug port -> wrreg,rdreg,trigger_r 

    );

    // Connections to FPGA UART pins to RD53 UART ports
    assign  p_uart_txd      = uart_rxd;
    assign  uart_rxd        = p_uart_rxd;


    logic           flash      ;
    logic           tick_sec   ;
    logic           tick_msec  ;
    logic           tick_usec  ;
    logic   [2:0]   pulse      ;
    logic   [2:0]   stretched  ;


    //----------------------------------------------------
    // Misc logic for timing pulses and LED signals
    //----------------------------------------------------
    blink u_blink
    (
        .reset          (reset      ),  // in   std_logic;
        .clk            (clk160     ),  // in   std_logic;
        .flash          (flash      ),  // out  std_logic;
        .tick_sec       (tick_sec   ),  // out  std_logic;    // Output tick every 1 sec
        .tick_msec      (tick_msec  ),  // out  std_logic;    // Output tick every 1 msec
        .tick_usec      (tick_usec  ),  // out  std_logic;    // Output tick every 1 usec
        .pulse          (pulse      ),  // in   std_logic_vector(2 downto 0);
        .stretched      (stretched  )   // out  std_logic_vector(2 downto 0)
    );

    assign pulse[0] = rd53_debug[0];
    assign pulse[1] = rd53_debug[1];
    assign pulse[2] = rd53_debug[2];

    // Drive LEDs labelled DS1-4 on SLAC board
    assign led[0]   = flash;                // DS1
    assign led[1]   = mmcm_locked;          // DS2
    assign led[2]   = stretched[0];         // DS3
    assign led[3]   = stretched[1];         // DS4

    assign p_debug[0]       = tick_msec;
    assign p_debug[1]       = mmcm_locked;
    assign p_debug[2]       = ttc_data;
    assign p_debug[3]       = trig_out;
    assign p_debug[29:4]    = 26'b0;


endmodule

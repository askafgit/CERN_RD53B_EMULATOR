//----------------------------------------------------------------------------
// Generate hit data.
// Data is written into a dual port RAM by a CPU using a 32-bit data bus and
// is then read out over a 64-bit port when 'trigger_i' goes high.
// CPU controls number of words sent.
//----------------------------------------------------------------------------
// tclk: "clk80",
// hclk: "clk40",
// dclk: "clk160";
// using hclk, fifo reads at dclk
//----------------------------------------------------------------------------
module hit_generator4
(
    input   logic           rst_i           , // Active high reset
    input   logic           clk             , // Clock

    input   logic           uart_rxd        , //
    output  logic           uart_txd        , //

    input   logic   [15:0]  config_reg_i    , // Unused. Used in RD53A
    input   logic           trigger_i       , // Start data output
    input   logic   [31:0]  trigger_info_i  , // Unused. In RD53A was passed through to the first 32-bit chunk sent out before the first hit data chunk

    output  logic   [63:0]  trigger_data_o  , // Output data
    output  logic           done_o            // Low while output of data is occurring
);


//----------------------------------------------------------------------------
// Module contins CPU and Dual-port RAM for 128x64bit hit data
//----------------------------------------------------------------------------

    reg             busy;
    wire            reset_n;

    // Inputs/outputs to/from dual-port hit RAM
    wire            cpu_wea;
    wire    [ 7:0]  cpu_addra;
    wire    [31:0]  cpu_dina;       // Data from CPU gpio1_out[31:0]
    wire    [31:0]  ram_douta;
    reg     [ 6:0]  cnt_addrb;
    wire    [63:0]  ram_doutb;

    // Inputs/Outputs to/from MCS CPU block
    wire    [31:0]  gpio1_in;
    wire    [31:0]  gpio1_out;
    wire    [31:0]  gpio2_in;
    wire    [31:0]  gpio2_out;
    wire    [ 4:0]  dip_sw;
    wire    [ 5:0]  push_buttons;
    wire            pit1_toggle;

    wire    [ 6:0]  cpu_addr_start;
    wire    [ 6:0]  cpu_hit_size;
    reg     [ 6:0]  cnt_hit_size;
    wire            cpu_trigger;

    // Signal assignments
    assign  reset_n         = ~rst_i;

    // First CPU output port used for data bus to hit RAM
    assign  cpu_dina        = gpio1_out;

    // Second CPU port used to set RAM address, RAM write enable and address counter parameters
    assign  cpu_addra       = gpio2_out[7:0];
    assign  cpu_wea         = gpio2_out[8];
    assign  cpu_trigger     = gpio2_out[12];       // CPU trigger instead of command trigger
    assign  cpu_addr_start  = gpio2_out[22:16];
    assign  cpu_hit_size    = gpio2_out[30:24];

    // Inputs to CPU
    assign  gpio1_in        = ram_douta;           // Readback from hit RAM
    assign  gpio2_in[0]     = busy;                // Readback of state machine 'busy'
    assign  dip_sw          = 4'b0;                //  
    assign  push_buttons    = 5'b0;                //  


    //------------------------------------------------------------------------
    // Microblaze CPU with access to the hit RAM.
    // CPU runs software contolled by UART commands.
    //------------------------------------------------------------------------
    ps1 u_ps1
    (
        .reset_n                    (reset_n        )   ,
        .clk                        (clk            )   ,

        .gpio1_tri_i                (gpio1_in       )   ,
        .gpio2_tri_i                (gpio2_in       )   ,

        .gpio1_tri_o                (gpio1_out      )   ,
        .gpio2_tri_o                (gpio2_out      )   ,

        .dip_switches_4bits_tri_i   (dip_sw         )   , // in STD_LOGIC_VECTOR ( 3 downto 0 );
        .push_buttons_5bits_tri_i   (push_buttons   )   , // in STD_LOGIC_VECTOR ( 4 downto 0 );
        .pit1_toggle                (pit1_toggle    )   ,

        .uart_rxd                   (uart_rxd       )   ,
        .uart_txd                   (uart_txd       )
    );


    //------------------------------------------------------------------------
    // ROM address counter. Started by input command trigger or CPU trigger.
    // Sets busy high and counts up from 'cpu_start_addr' for 'cpu_hit_words'+1
    //------------------------------------------------------------------------
    always_ff @(posedge clk)
    begin

        if (rst_i) begin
            busy            <= 1'b0;
            cnt_addrb       <= 0;
            cnt_hit_size    <= 0;

        end else if (!busy & (trigger_i | cpu_trigger)) begin
            busy            <= 1'b1;
            cnt_addrb       <= cnt_addrb + 1;
            cnt_hit_size    <= cnt_hit_size + 1;

        end else if (busy & (cnt_hit_size < cpu_hit_size)) begin
            busy            <= 1'b1;
            cnt_addrb       <= cnt_addrb + 1;
            cnt_hit_size    <= cnt_hit_size + 1;

        end else begin
            busy            <= 1'b0;
            cnt_addrb       <= cpu_addr_start;
            cnt_hit_size    <= 0;
        end

    end

    assign done_o = ~busy;


    //------------------------------------------------------------------------
    // CPU loads RAM with output stream data through 32-bit port A
    // Counter reads RAM through (read-only) 64-bit port B
    //------------------------------------------------------------------------
    dpram_hitdata_128x64bit     u_dpram_hitdata
    (
        .clka       ( clk        ),  // input  wire clka
        .wea        ( cpu_wea    ),  // input  wire [ 0 : 0] wea
        .addra      ( cpu_addra  ),  // input  wire [ 7 : 0] addra
        .dina       ( cpu_dina   ),  // input  wire [31 : 0] dina
        .douta      ( ram_douta  ),  // output wire [31 : 0] douta

        .clkb       ( clk        ),  // input  wire clkb
        .web        ( 1'b0       ),  // input  wire [ 0 : 0] web
        .addrb      ( cnt_addrb  ),  // input  wire [ 6 : 0] addrb
        .dinb       ( 64'b0      ),  // input  wire [63 : 0] dinb
        .doutb      ( ram_doutb  )   // output wire [63 : 0] doutb
    );
    assign trigger_data_o   = ram_doutb;


endmodule


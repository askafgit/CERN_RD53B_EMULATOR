//----------------------------------------------------------------------------
// Generate hit data.
// Data is pre-loaded into a RAM and read out when 'trigger' goes high.
//----------------------------------------------------------------------------
`timescale 1ps/1ps

module hit_generator3
(
    input   logic           reset           , // Active high reset
    input   logic           clk             , // Clock

    input                   uart_rxd        , // Debug (unused)
    output                  uart_txd        , // Debug (unused)

  //input   logic   [15:0]  config_reg_i    , // Unused. Used in RD53A
    input   logic           trigger         , // Start data output. Was 'trigger_i'
  //input   logic   [31:0]  trigger_info_i  , // Unused. In RD53A was passed through to the first 32-bit chunk sent out before the first hit data chunk

    output  logic   [63:0]  hitgen_dataout  , // Output data. Was 'trigger_data_o'
    output  logic           hitgen_done       // Low while output of data is occurring. Was 'done_o'
);
//----------------------------------------------------------------------------


    reg     [ 6:0]  rom_addr;
    reg     [63:0]  rom_dout;
    reg             busy;
    localparam      SIZE_STREAM = 20;

    assign  uart_txd    = 1'b1; // Unused output port


    //------------------------------------------------------------------------
    // ROM address counter. Started by trigger. Sets busy high and counts up
    // to SIZE_STREAM-1
    //------------------------------------------------------------------------
    always_ff @(posedge clk)
    begin

        if (reset) begin
            busy        <= 1'b0;
            rom_addr    <= 0;

        end else if (!busy & trigger) begin
            busy        <= 1'b1;
            rom_addr    <= rom_addr + 1;

        end else if (busy & (rom_addr < SIZE_STREAM)) begin
            busy        <= 1'b1;
            rom_addr    <= rom_addr + 1;

        end else begin
            busy        <= 1'b0;
            rom_addr    <= 0;
        end

    end


    assign hitgen_done      = ~busy;
    assign hitgen_dataout   = rom_dout;


    //------------------------------------------------------------------------
    // ROM pre-loaded with output stream data
    //------------------------------------------------------------------------
    rom_128x64bit u_rom_128x64bit  //NM => changed the module from 128 to 256
    (
        .clka   ( clk       )   ,   // in  std_logic;
        .addra  ( rom_addr  )   ,   // in  std_logic_vector( 6 downto 0);
        .douta  ( rom_dout  )       // out std_logic_vector(63 downto 0)
    );


endmodule

-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR
-- Engineer:       Queiroz Maic
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    01:24:12 07/03/2018
-- Design Name:
-- Module Name:    aurora_tx_lane128 - Behavioral
-- Project Name:   Pixel data-stream aggregator
-- Target Devices: Xilinx Kintex-7 KC705
-- Tool versions:  Xilinx Vivado v2017.4
-- Description:    Aurora TX Lane, map all the subcomponents
--
-- Block contains:
--                  64-bit data scrambler
--                  66-bit to 32-bit 'gearbox'
--                  32-bit to 8-bit serdes
--                  8-bit to 1-bit serdes
--
-- The G_RATIO generic sets the gearbox block output data rate divisor.
-- The divisor to use depends on the ratio between the logic clock and the serial clock.
-- One implementation used an 80 Mhz serial output clock and a 20 MHz logic clock. 
-- This means that the serial output was running at 160Mb/s.
-- That means that the 32-bit gearbox output data rate is 5 MHz. 
-- Since the logic clock was 20 MHz a ratio of 20/5 = 4 was required.
-- (32x20)/160 = 4
--
-- If the serial output bitrate remains at 160 MHz (80MHz clk_tx) but the logic clock is increased
-- to also be 160 MHz then the ratio required is 160/5 = 32
-- (32x160)/160 = 32
--
-- The actual ratio equation is : (32 x logic_clock_freq) / Output_bitrate_Mbps
--                           or : (32 x logic_clock_freq) / ( 2 x clk_tx freq)
-- 
-- G_RATIO = (32 x clk freq)/(2 x clk_tx freq)
--
-- For an output bitrate of 1280Mbps with a logic clock of 160MHz the ratio must be
-- 32x160/1280 = 4      The serial output clock must be running at 640 MHz.
-------------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

entity aurora_tx_lane128 is
port (
    reset              : in  std_logic;
    clk                : in  std_logic;     -- Clock for tx_data_in and internal logic

    -- TX data in
    request_tx_data    : out std_logic;
    tx_data_in         : in  std_logic_vector(65 downto 0);

    -- Serial data output
    clk_tx             : in  std_logic;     -- Clock for high speed serial links. Output is DDR i.e. 2x this clock
    dataout_p          : out std_logic;
    dataout_n          : out std_logic
);
end aurora_tx_lane128;


architecture struct of aurora_tx_lane128 is

--------------------------------------------------------
-- Data scrambler (no impact on the header)
--------------------------------------------------------
component scrambler     -- Width parameter set to 64. (Verilog)
port (
    clk             : in  std_logic;
    reset           : in  std_logic;
    enable          : in  std_logic;

    sync_info       : in  std_logic_vector(1 downto 0);
    data_in         : in  std_logic_vector(0 to 63);

    data_out        : out std_logic_vector(65 downto 0)
);
end component scrambler;


--------------------------------------------------------
-- Gearbox 66 bit to 32 bit
--------------------------------------------------------
component gearbox66to32
generic (
    G_RATIO         : integer := 4
);
port (
    reset           : in  std_logic;
    clk             : in  std_logic;

    data66_in       : in  std_logic_vector(65 downto 0);

    data32_out      : out std_logic_vector(31 downto 0);
    data32_out_valid: out std_logic;

    request_data    : out std_logic
);
end component;

  
--------------------------------------------------------
-- 32bit to 8 bit (required to have the right serdes input width)
--------------------------------------------------------
component serdes32to8
generic (
    G_RATEDIV       : integer := 8     -- Output data rate divisor. N outputs one byte every N clocks 
);
port (
    reset           : in  std_logic;
    clk             : in  std_logic;

    datain32        : in  std_logic_vector(31 downto 0);
    datain32_dv     : in  std_logic;

    dataout8        : out std_logic_vector(7 downto 0)
);
end component;


--------------------------------------------------------
-- Serdes 8 to 1
-- Receives 8-bit data with clk_i 
-- Outputs single-bit data with DDR clkhigh_i
--------------------------------------------------------
component serdes8to1
port (
    reset           : in  std_logic;
    clk             : in  std_logic;
    datain          : in  std_logic_vector(7 downto 0);

    clkhigh_i       : in  std_logic;
    dataout_p       : out std_logic;
    dataout_n       : out std_logic
);
end component;


signal scram_data_out       : std_logic_vector(65 downto 0);     -- 66 bit scrambler output
signal gbox_data32_out      : std_logic_vector(31 downto 0);     -- 32-bit gearbox output
signal gbox_data32_valid    : std_logic;                         -- 32-bit gearbox output valid
signal gbox_req_read        : std_logic;                         -- Read block and scramble flag
signal serdes32to8_dout     : std_logic_vector(7 downto 0);      -- SerDes32to8 8-bit output

-- Generics
-- G_GEARBOX_RATIO = (32 x clk freq)/(2 x clk_tx freq)
constant G_GEARBOX_RATIO    : integer := 32;                     -- (32 x 160MHz) / (2 x 80MHz)

-- G_SERDES32TO8_RATE  = (8 x clk freq)/(2 x clk_tx freq)
-- The generic sets the number of output clocks for each byte.
-- If the logic clock rate is 160MHz and the final output bitrate is 160Mbps then
-- 32 bits are transmitted in 32 clock cycles so one byte is transmitted in 8 clocks
-- so G_SERDES32TO8_RATE = 8
constant G_SERDES32TO8_RATE : integer := 8;                     -- (8 x 160MHz) / (2 x 80MHz)

-- Alternative calc method if gearbox data output width is 32 bits
--constant G_SERDES32TO8_RATE : integer := G_GEARBOX_RATIO/4;

begin

    -- Generics checking
    assert (G_GEARBOX_RATIO >= 4)
    report "aurora_tx_lane128, generic constant G_GEARBOX_RATIO error: ratio must be 4 minimum"
    severity failure;


    --------------------------------------------------------
    -- 
    --------------------------------------------------------
    u_scrambler : scrambler 
    port map (
        clk             => clk      ,                   -- input                        
        reset           => reset    ,                   -- input                        
  
        enable          => gbox_req_read            ,   -- input   from gearbox
        sync_info       => tx_data_in(65 downto 64) ,   -- input   [1:0]                
        data_in         => tx_data_in(63 downto 0)  ,   -- input   [0:(TX_DATA_WIDTH-1)]

        data_out        => scram_data_out               -- output  [(TX_DATA_WIDTH+1):0]
    );


    --------------------------------------------------------
    -- Turn 66-bit data into 32-bit data
    --------------------------------------------------------
    u_gearbox66to32 : gearbox66to32
    generic map (
        G_RATIO             => G_GEARBOX_RATIO
    )
    port map(
        reset               => reset            ,
        clk                 => clk              ,

        data66_in           => scram_data_out   ,

        data32_out          => gbox_data32_out  ,
        data32_out_valid    => gbox_data32_valid,

        request_data        => gbox_req_read 
    );
    -- Drive port
    request_tx_data     <= gbox_req_read;     -- Request more data from upstream blocks
      

    --------------------------------------------------------
    -- Convert 32-bit word into series of 8-bit data 
    --------------------------------------------------------
    u_serdes32to8 : serdes32to8
    generic map (
        G_RATEDIV       => G_SERDES32TO8_RATE   -- Set output rate
    )
    port map(
        reset           => reset            ,
        clk             => clk              ,

        datain32        => gbox_data32_out  ,
        datain32_dv     => gbox_data32_valid,

        dataout8        => serdes32to8_dout
    );
      
    --------------------------------------------------------
    -- 8-to-1 serdes receiving data8_s from 32-to-8 serdes
    --------------------------------------------------------
    u_serdes1to8 : serdes8to1
    port map(
        reset           => reset            ,
        clk             => clk              ,
        datain          => serdes32to8_dout ,

        clkhigh_i       => clk_tx           ,
        dataout_p       => dataout_p        ,
        dataout_n       => dataout_n
    );

  
end struct;


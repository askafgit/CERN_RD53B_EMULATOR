-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR 
-- Engineer:       Queiroz Maic, cleaned up by Gjones / UW Seattle
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    22:09:13 07/03/2018
-- Design Name:
-- Module Name:    serdes1to8
-- Project Name:   Pixel data-stream aggregator
-- Target Devices: Xilinx Kintex-7 KC705
-- Tool versions:  Xilinx Vivado v2017.4
-- Description:    The purpose of this VHDL component is to implement a 8 bit DDR
--                 serializer and to output data in differential.
--                 Note: Words are transmitted LSB first
--
-------------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;

entity serdes8to1 is
port (
    reset           : in  std_logic;
    clk             : in  std_logic;    -- Logic clock

    datain          : in  std_logic_vector(7 downto 0);

    clkhigh_i       : in  std_logic;
    dataout_p       : out std_logic;
    dataout_n       : out std_logic
);
end serdes8to1;

architecture struct of serdes8to1 is

signal tx_data_out    : std_logic;  -- OSERDESE2 output serial data

begin


    --------------------------------------------
    -- Serdes cell
    --------------------------------------------
    u_OSERDESE2 : OSERDESE2
    generic map(
        DATA_WIDTH      => 8,           -- SERDES input word width
        TRISTATE_WIDTH  => 1,
        DATA_RATE_OQ    => "DDR",       -- <SDR>, DDR
        DATA_RATE_TQ    => "SDR",       -- <SDR>, DDR
        SERDES_MODE     => "MASTER"     -- <DEFAULT>, MASTER, SLAVE
    )
    port map (
        OQ          => tx_data_out,
        OCE         => '1',
        CLK         => clkhigh_i,
        RST         => reset,
        CLKDIV      => clk,
        D8          => datain(0),
        D7          => datain(1),
        D6          => datain(2),
        D5          => datain(3),
        D4          => datain(4),
        D3          => datain(5),
        D2          => datain(6),
        D1          => datain(7),
        TQ          => open,
        T1          => '0',
        T2          => '0',
        T3          => '0',
        T4          => '0',
        TCE         => '0',
        TBYTEIN     => '0',
        TBYTEOUT    => open,
        OFB         => open,
        TFB         => open,
        SHIFTOUT1   => open,
        SHIFTOUT2   => open,
        SHIFTIN1    => '0',
        SHIFTIN2    => '0'
    );


    --------------------------------------------
    --  Differential output pad
    --------------------------------------------
    u_OBUFDS : OBUFDS 
    port map (
        I           => tx_data_out,
        O           => dataout_p,
        OB          => dataout_n
    );

end struct;


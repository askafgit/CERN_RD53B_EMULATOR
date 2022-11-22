-------------------------------------------------------------------------------------
-- Description:    The purpose of this VHDL component is to implement a 8 bit DDR
--                 serializer and to output data in differential.
--                 Note: Words are transmitted MSB first
--
-------------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;

entity serdes8to1 is
port (
    rst_i           : in  std_logic;
    clk_i           : in  std_logic;    -- Logic clock

    data8_i         : in  std_logic_vector(7 downto 0);

    clkhigh_i       : in  std_logic;
    dataout_p       : out std_logic;
    dataout_n       : out std_logic;
    TQ_o            : out std_logic     -- unused, but kept for port compatibility
);
end serdes8to1;

architecture no_synth of serdes8to1 is

signal buffer8              : std_logic_vector(7 downto 0);
signal tx_data_out          : std_logic;  -- output serial data

-- Debug signals if running OSERDES cell in parallel with RTL for comparison
signal debug_tx_data_out    : std_logic;  -- OSERDESE2 output serial data
signal debug_dataout_p      : std_logic;  -- 
signal debug_dataout_n      : std_logic;  -- 

signal clkhigh_d            : std_logic;  -- Delay for serial clock after buffer8 loaded by clk 

begin

    clkhigh_d   <= clkhigh_i after 10 ps;

     ----------------------------------------------------------------------------------
     -- Wait until clk rise then convert to a series of -bit outputs 
     -- to set output rate.
     ----------------------------------------------------------------------------------
     pr_dout : process
     variable v_cnt_bit : integer;
     begin
     
         wait until rising_edge(clk_i);
         buffer8        <= data8_i;

         wait until rising_edge(clkhigh_d);
         tx_data_out    <= buffer8(7);
         wait until falling_edge(clkhigh_d);
         tx_data_out    <= buffer8(6);
         wait until rising_edge(clkhigh_d);
         tx_data_out    <= buffer8(5);
         wait until falling_edge(clkhigh_d);
         tx_data_out    <= buffer8(4);
         wait until rising_edge(clkhigh_d);
         tx_data_out    <= buffer8(3);
         wait until falling_edge(clkhigh_d);
         tx_data_out    <= buffer8(2);
         wait until rising_edge(clkhigh_d);
         tx_data_out    <= buffer8(1);
         wait until falling_edge(clkhigh_d);
         tx_data_out    <= buffer8(0);
     
     end process;
     

    --------------------------------------------
    --  Differential output pad
    --------------------------------------------
    dataout_p   <= tx_data_out;
    dataout_n   <= not(tx_data_out);
    TQ_o        <= '0';


    --  --------------------------------------------
    --  -- Serdes cell for debug comparison
    --  --------------------------------------------
    --  u_OSERDESE2 : OSERDESE2
    --  generic map(
    --      DATA_WIDTH      => 8,           -- SERDES input word width
    --      TRISTATE_WIDTH  => 1,
    --      DATA_RATE_OQ    => "DDR",       -- <SDR>, DDR
    --      DATA_RATE_TQ    => "SDR",       -- <SDR>, DDR
    --      SERDES_MODE     => "MASTER"     -- <DEFAULT>, MASTER, SLAVE
    --  )
    --  port map (
    --      OQ          => debug_tx_data_out,
    --      OCE         => '1',
    --      CLK         => clkhigh_i,
    --      RST         => reset,
    --      CLKDIV      => clk,
    --      D8          => datain(0),
    --      D7          => datain(1),
    --      D6          => datain(2),
    --      D5          => datain(3),
    --      D4          => datain(4),
    --      D3          => datain(5),
    --      D2          => datain(6),
    --      D1          => datain(7),       -- First bit out
    --      TQ          => open,
    --      T1          => '0',
    --      T2          => '0',
    --      T3          => '0',
    --      T4          => '0',
    --      TCE         => '0',
    --      TBYTEIN     => '0',
    --      TBYTEOUT    => open,
    --      OFB         => open,
    --      TFB         => open,
    --      SHIFTOUT1   => open,
    --      SHIFTOUT2   => open,
    --      SHIFTIN1    => '0',
    --      SHIFTIN2    => '0'
    --  );
    --  
    --  
    --  --------------------------------------------
    --  --  Differential output pad
    --  --------------------------------------------
    --  u_OBUFDS : OBUFDS 
    --  port map (
    --      I           => debug_tx_data_out,
    --      O           => debug_dataout_p,
    --      OB          => debug_dataout_n
    --  );

end no_synth;

-------------------------------------------------------------------------------------
-- Module Name:    serdes32to8 - RTL
-- Description:    The purpose of this VHDL component is to implement a conversion
--                 from a 32 bit input to a 8 bit output, outputting 4 blocks
--                 of 8 bit data for each input.
--
-- The G_RATEDIV generic sets the number of output clocks for each byte.
-- If the logic clock rate is 160MHz and the final output bitrate is 160Mbps then
-- 32 bits are transmitted in 32 clock cycles so one byte is transmitted in 8 clocks
-- so G_RATEDIV = 8
-------------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
entity serdes32to8 is
generic (
    G_RATEDIV       : integer := 8     -- Output data rate divisor. N outputs one byte every N clocks 
);
port (
    reset           : in  std_logic;
    clk             : in  std_logic;

    -- Input data
    datain32        : in  std_logic_vector(31 downto 0);
    datain32_dv     : in  std_logic;

    -- Output data
    dataout8        : out std_logic_vector( 7 downto 0)
);
end serdes32to8;

-------------------------------------------------------------------------------------
-- Receive 32-bit input and convert to a series of 8-bit outputs using G_RATEDIV
-- to set output rate.
-- Upper 8 bits of 32-bit input are output first
-------------------------------------------------------------------------------------
architecture rtl of serdes32to8 is

signal   buffer32       : std_logic_vector(31 downto 0);        -- 32-bit data buffer
signal   cnt_dout       : integer range 0 to 3 ;                -- Counter to select output byte from buffer
signal   cnt_rate       : integer range 0 to G_RATEDIV-1 ;      -- Count clock cycles to set 8-bit output rate
signal   enable         : std_logic;

constant C_NUM_BYTES    : integer := 4;                         -- Number of output bytes per input word

begin

    ----------------------------------------------------------------------------------
    -- Receive 32-bit input and convert to a series of 8-bit outputs using G_RATEDIV
    -- to set output rate.
    ----------------------------------------------------------------------------------
    pr_serdes32to8 : process (reset, clk)
    begin

        if (reset = '1') then

            buffer32    <= (others=>'0');
            dataout8    <= (others=>'0');
            cnt_rate    <= 0;
            cnt_dout    <= 0;
            enable      <= '0';

        elsif rising_edge(clk) then

            -- Store input and output first byte
            if (datain32_dv = '1') then

                buffer32    <= datain32;
                cnt_rate    <= 0;
                cnt_dout    <= 1;
                dataout8    <= datain32(31 downto 24);
                enable      <= '1';

            -- Output next byte every 'G_RATEDIV' clock cycles
            elsif (cnt_rate = G_RATEDIV-1) then

                cnt_rate    <= 0;
                
                if (cnt_dout < C_NUM_BYTES-1) and (enable = '1') then
                    cnt_dout    <= cnt_dout + 1;
                else
                    cnt_dout    <= 0;
                    enable      <= '0';
                end if;

                if (enable = '1') then
                    case (cnt_dout) is
                        when 0      =>  dataout8    <= buffer32(31 downto 24);
                        when 1      =>  dataout8    <= buffer32(23 downto 16);
                        when 2      =>  dataout8    <= buffer32(15 downto  8);
                        when 3      =>  dataout8    <= buffer32( 7 downto  0);
                        when others =>  dataout8    <= buffer32( 7 downto  0);
                    end case;
                else
                    dataout8    <= X"00";
                end if;
                
            else
                cnt_rate    <= cnt_rate + 1;

            end if;

        end if;

    end process;

end rtl;


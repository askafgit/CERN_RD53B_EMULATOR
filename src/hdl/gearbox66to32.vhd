-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR
-- Engineer:       Queiroz Maic, re-written, re-naming by G.Jones
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    20:48:40 06/27/2018
-- Design Name:
-- Module Name:    gearbox66to32 
-- Description:    The purpose of this VHDL component is to implement a gearbox taking
--                 a 66 bit input and outputting 32bit.
-- The block requests new 66-bit input every 2 32-bit outputs but then must skip 
-- requesting new data once every 33 inputs because two bits (66 = 32+32+2) accumulate
-- for every 66-bit input
--
-- The G_RATIO generic sets the output data rate divisor.
-- The divisor to use depends on the ratio between the logic clock and the serial clock.
-- One implementation used an 80 Mhz serial output clock and a 20 MHz logic clock. 
-- This means that the serial output was running at 160Mb/s.
-- That means that the 32-bit gearbox output data rate is 5 MHz. 
-- Since the logic clock was 20 MHz a ratio of 20/5 = 4 was required.
-- (32x20)/160 = 4
--
-- If the serial output clock remains at 160 MHz but the logic clock is increased
-- to also be 160 MHz then the ratio required is 160/5 = 32
-- (32x160)/160 = 32
--
-- The actual ratio equation is (32 x logic_clock_freq) / Output_bitrate_Mbps
--
-- For an output bitrate of 1280Mbps with a logic clock of 160MHz the ratio must be
-- 32x160/1280 = 4      The serial output clock must be running at 640 MHz.
--
-------------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

entity gearbox66to32 is
generic (
    G_RATIO          : integer := 4     -- Output data rate divisor. 
);
port (
    reset            : in  std_logic;
    clk              : in  std_logic;

    data66_in        : in  std_logic_vector(65 downto 0);   -- Input data 

    data32_out       : out std_logic_vector(31 downto 0);   -- Output data
    data32_out_valid : out std_logic;

    request_data     : out std_logic
);
end gearbox66to32;

architecture rtl of gearbox66to32 is

constant C_GEARBOX_CNT    : integer := 32;                      -- Gearbox cycles counts max value
constant C_INPUT_SIZE     : integer := 66;                      -- Block size

signal   cnt_gearbox      : integer range 0 to C_GEARBOX_CNT;   -- Gearbox cycle counter
signal   cnt_rate         : integer range 0 to G_RATIO-1;       -- Rate counter
signal   buffer96         : std_logic_vector(95 downto 0);      -- Buffer for three sets of 32-bit output


begin

    ----------------------------------------------------------------------------------
    -- Generic checking
    ----------------------------------------------------------------------------------
    assert (G_RATIO >= 1)
        report "gearbox66to32, generic parameter G_RATIO error: ratio must be 1 minimum"
        severity failure;


    ----------------------------------------------------------------------------------
    -- Converts a series of 66-bit inputs into a series of 32-bit outputs.
    -- Each input produces 2 32-bit outputs with 2-bits left over.
    -- This means that after every 33rd input an additional output occurs.
    ----------------------------------------------------------------------------------
    pr_shift_proc : process (reset, clk)
    begin

        if (reset = '1') then
            buffer96        <= (others=>'0');
            cnt_gearbox     <= 0;
            cnt_rate        <= 0;
            request_data    <= '0';

        elsif rising_edge(clk) then

            -- Gearbox counter. Increment every G_RATIO clocks and wrap at max
            if (cnt_rate = G_RATIO-1) then

                if (cnt_gearbox = C_GEARBOX_CNT) then
                    cnt_gearbox     <= 0;
                else
                    cnt_gearbox     <= cnt_gearbox + 1;
                end if;

                cnt_rate        <= 0;

            else
                cnt_rate        <= cnt_rate + 1;
            end if;

      
            request_data    <= '0';


            -- Shift buffer and insert new block depending on the counter value
            if (cnt_rate = G_RATIO-1) then

                buffer96    <= (others=>'0');

                -- Special case
                if (cnt_gearbox = C_GEARBOX_CNT) then
                    buffer96(95 downto 30)  <= data66_in;   -- New data put into MSBs of buffer
                    request_data            <= '1';

                -- Even number or 31. Change output data. No new input data
                elsif (cnt_gearbox mod 2 = 0) or (cnt_gearbox = 31) then
                    buffer96(95 downto 32)  <= buffer96(63 downto 0);

                -- Remaining odd counter values
                else  
                    request_data            <= '1';

                    -- New input data
                    buffer96((95 - cnt_gearbox-1) downto (95 - cnt_gearbox - C_INPUT_SIZE)) <= data66_in; 

                    -- Shift buffer 
                    case cnt_gearbox is
                        when  1     => buffer96(95 downto 94)   <= buffer96(63 downto 62);  -- Shift 2 bits
                        when  3     => buffer96(95 downto 92)   <= buffer96(63 downto 60);  -- Shift 4 bits
                        when  5     => buffer96(95 downto 90)   <= buffer96(63 downto 58);  -- Shift 6 bits
                        when  7     => buffer96(95 downto 88)   <= buffer96(63 downto 56);
                        when  9     => buffer96(95 downto 86)   <= buffer96(63 downto 54);
                        when 11     => buffer96(95 downto 84)   <= buffer96(63 downto 52);
                        when 13     => buffer96(95 downto 82)   <= buffer96(63 downto 50);
                        when 15     => buffer96(95 downto 80)   <= buffer96(63 downto 48);
                        when 17     => buffer96(95 downto 78)   <= buffer96(63 downto 46);
                        when 19     => buffer96(95 downto 76)   <= buffer96(63 downto 44);
                        when 21     => buffer96(95 downto 74)   <= buffer96(63 downto 42);
                        when 23     => buffer96(95 downto 72)   <= buffer96(63 downto 40);
                        when 25     => buffer96(95 downto 70)   <= buffer96(63 downto 38);
                        when 27     => buffer96(95 downto 68)   <= buffer96(63 downto 36);
                        when 29     => buffer96(95 downto 66)   <= buffer96(63 downto 34);  -- Shift 32 bits
                        when others => buffer96                 <= (others=>'0');
                    end case;
                end if;
            end if;
        end if;
    end process pr_shift_proc;

    -- Output 
    data32_out          <= buffer96(95 downto 64);  -- Data output is from 32 MSBs of buffer
    data32_out_valid    <= '1' when cnt_rate = 0 else '0';

end rtl;


-------------------------------------------------------------------------------
-- File         : model_yarr_ttc.vhd
-- Description  : Testbench model of YARR that sends trigger and command data
--                to RD53B. It sends PLL_LOCK symbols when there is no data and
--                inserts periodic SYNC symbols.
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.rd53b_fpga_pkg.all;

entity model_yarr_ttc is
port(
    clk                 : in  std_logic;
    reset               : in  std_logic;
    sim_done            : in  boolean;

    tx_data             : in  std_logic_vector(15 downto 0);    -- Commands
    tx_data_dv          : in  std_logic;
    ready               : out std_logic;

    ttc_p               : out std_logic;
    ttc_n               : out std_logic
);
end entity;

-------------------------------------------------------------------------------
-- Generate TTC command stream.
-- At reset start sending PLL_LOCK frames. In the real chip these are used
-- for clock recovery.
-- Once the PLL has locked then SYNC frames are sent. 2x N_LOCK frames must be
-- sent to guarantee locking.
-- Then ready for commands.
-- Commands are put into a FIFO and output serially.
-- Insert SYNCs every 32 frames.
-- If there are no commands in the FIFO send PLL_LOCK frames (with occasional SYNCs)
-------------------------------------------------------------------------------
architecture rtl of model_yarr_ttc is

signal sreg_tx              : std_logic_vector(15 downto 0);

type   t_state_ttc is (
        S_TTC_START ,   -- Send PLL_LOCK commands until count is reached
        S_TTC_RUN       -- Send FIFO data or PLL_LOCKs with periodic SYNCs
);
signal state_tx             : t_state_ttc;

signal fifo_data_out        : std_logic_vector(15 downto 0);    -- Output data
signal fifo_empty           : std_logic;                        -- Set as '1' when the FIFO is empty
signal fifo_full            : std_logic;                        -- Set as '1' when the FIFO is full

signal sm_load_fifo_dout    : std_logic;
signal sm_load_pll_lock     : std_logic;
signal sm_load_sync         : std_logic;

signal cnt_bits_tx          : integer range 0 to 16;    -- Load new tx data every 16 clocks/bits
signal cnt_words            : integer range 0 to 32;    -- Count number of words sent before inserting a SYNC word. Also used to count PLL_LOCKs at startup.

constant N_BITS_IN_WORD     : integer   := 16;          -- Number of bits in each transmit word
constant N_WORDS_PLL_LOCK   : integer   :=  4;          -- Number of initial PLL_LOCK commands to send before beginning SYNC
constant N_SYNC_INTERVAL    : integer   :=  4;          -- Insert a SYNC pattern every N words

begin

    -------------------------------------------------------
    -- FIFO for TTC commands
    -------------------------------------------------------
    u_fifo : entity work.fifo
    generic map (G_DEPTH => 16)
    port map(
        clk         => clk              , --  in  std_logic;
        reset       => reset            , --  in  std_logic;
        wr          => tx_data_dv       , --  in  std_logic;                        -- Write
        data_in     => tx_data          , --  in  std_logic_vector(15 downto 0);    -- Input data

        rd          => sm_load_fifo_dout, --  in  std_logic;                        -- Read
        data_out    => fifo_data_out    , --  out std_logic_vector(15 downto 0);    -- Output data

        fifo_empty  => fifo_empty       , --  out std_logic;                        -- Set as '1' when the FIFO is empty
        fifo_full   => fifo_full          --  out std_logic                         -- Set as '1' when the FIFO is full
    );

    ready   <= not(fifo_full);


    -------------------------------------------------------
    -- State machine to select output data to send.
    -------------------------------------------------------
    pr_sm_tx : process (reset, clk)
    begin

        if (reset = '1') then

            state_tx            <= S_TTC_START;
            sm_load_fifo_dout   <= '0';
            sm_load_pll_lock    <= '0';
            sm_load_sync        <= '0';
            cnt_bits_tx         <= 0;
            cnt_words           <= 0;

        elsif rising_edge(clk) then

            -- Default signal levels
            sm_load_fifo_dout   <= '0';
            sm_load_pll_lock    <= '0';
            sm_load_sync        <= '0';

            case state_tx  is

                ---------------------------------------------------
                -- Send PLL_LOCK commands until count is reached
                ---------------------------------------------------
                when S_TTC_START    =>

                    if (cnt_bits_tx = N_BITS_IN_WORD-1) then

                        if (cnt_words = N_WORDS_PLL_LOCK-1) then

                            sm_load_sync        <= '1';
                            state_tx            <= S_TTC_RUN;
                            cnt_words           <= 0;

                        else
                            sm_load_pll_lock    <= '1';
                            cnt_words           <= cnt_words + 1;

                        end if;

                        cnt_bits_tx     <= 0;

                    else

                        cnt_bits_tx     <= cnt_bits_tx + 1;

                    end if;


                ---------------------------------------------------
                -- Send FIFO data or PLL_LOCKs with periodic SYNCs
                ---------------------------------------------------
                when S_TTC_RUN      =>

                    if (cnt_bits_tx = N_BITS_IN_WORD-1) then

                        if (cnt_words = N_SYNC_INTERVAL-1) then

                            sm_load_sync        <= '1';
                            cnt_words           <= 0;

                        -- Send data from FIFO
                        elsif (fifo_empty = '0') then
                            sm_load_fifo_dout   <= '1';
                            cnt_words           <= cnt_words + 1;

                        -- No data in FIFO, send a PLL_LOCK
                        else
                            sm_load_pll_lock    <= '1';
                            cnt_words           <= cnt_words + 1;

                        end if;

                        cnt_bits_tx     <= 0;

                    else

                        cnt_bits_tx     <= cnt_bits_tx + 1;

                    end if;



                when others =>
                    state_tx        <= S_TTC_START ;

            end case;

        end if;

    end process;


    -------------------------------------------------------
    -- Shift reg for output command.
    -- Loaded data is PLL_LOCK, SYNC or data from FIFO
    -------------------------------------------------------
    pr_sreg : process (reset, clk)
    begin

        if (reset = '1') then

            sreg_tx     <= (others=>'0');
            ttc_p       <= '0';
            ttc_n       <= '1';

        elsif rising_edge(clk) then

            if    (sm_load_fifo_dout = '1') then
                sreg_tx     <= fifo_data_out;

            elsif (sm_load_sync = '1') then
                sreg_tx     <= C_CMD_SYNC;

            elsif (sm_load_pll_lock = '1') then
                sreg_tx     <= C_CMD_PLL_LOCK;

            else
                sreg_tx     <= sreg_tx(14 downto 0) & '1';
            end if;

            ttc_p       <= sreg_tx(15);
            ttc_n       <= not(sreg_tx(15));

        end if;

    end process;


end rtl;


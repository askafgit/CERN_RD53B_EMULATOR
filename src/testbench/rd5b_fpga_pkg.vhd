----------------------------------------------------------------------------------------
-- Project       : RD53B Emulator
-- File          : rd53b_fpga_pkg.vhd
-- Description   : Package file for RD53B
-- Author        : gjones
----------------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

package rd53b_fpga_pkg is

-- Clock freq expressed in MHz
constant CLK_FREQ_160MHZ        : real      := 160.0;
constant CLK_FREQ_LOGIC         : real      := CLK_FREQ_160MHZ;


----------------------------------------------------------------------------------------
-- Nlock, Nunlock, and Nlost are parameters set in the CH_SYNC_CONF register.
----------------------------------------------------------------------------------------
-- Using the 160MHz recovered clock, the channel synchronizer will search for sync symbols
-- and count each valid appearance of this pattern in 16 separate channels (one channel for each
-- possible frame alignment). When the count for one of the channels, i, reaches a threshold Nlock,
-- sync lock is declared as acquired, channel i is adopted as the correct channel, and the count of the
-- remaining 15 channels is reset.
----------------------------------------------------------------------------------------
constant N_LOCK         : integer   := 10;

----------------------------------------------------------------------------------------
-- If the count for a channel that is not the lock channel ever reaches a second threshold
-- N_unlock, lock is declared lost, and a new sync lock is acquired on the first
-- channel that reaches the locking threshold N_lock
----------------------------------------------------------------------------------------
constant N_UNLOCK       : integer   := 5;

----------------------------------------------------------------------------------------
-- Additionally, if zero sync frames are received in the lock channel within Nlost frames
-- (regardless of other channels), lock will be declared lost and no further commands
-- will be decoded until a new lock is acquired
----------------------------------------------------------------------------------------
constant N_LOST         : integer   := 256;


--------------------------------------------------------------------------------
-- Command        |   Encoding              | (T)ag, (A)ddress or (D)ata 8-bit encoded 5-bit content
--------------------------------------------------------------------------------
-- Sync           |   1000_0001 0111_1110   |
-- PLLlock (noop) |   1010_1010 1010_1010   |
-- Trigger        |   tttt_tttt Tag[0..53]  |
-- Read_trigger   |   0110_1001 ID<4:0>     | 00, T<7:5> T<4:0>  |
-- Clear          |   0101_1010 ID<4:0>     |
-- Global Pulse   |   0101_1100 ID<4:0>     |
-- Cal            |   0110_0011 ID<4:0>     | D<19:15> D<14:10>  |    D< 9:5>  D< 4:0>
-- WrReg(0)       |   0110_0110 ID<4:0>     | 0, A<8:5> A<4:0>   |    D<15:11> D<10:6>  |  D<5:1> D<0>,0000
-- WrReg(1)       |   0110_0110 ID<4:0>     | 1, A<8:5> A<4:0>   |Nx (D< 9:5>  D< 4:0>)
-- RdReg          |   0110_0101 ID<4:0>     | 0, A<8:5> A<4:0>   |
--------------------------------------------------------------------------------
-- Commands with Chip_ID and Tag field set to zero
constant C_CMD_SYNC         : std_logic_vector(15 downto  0) := X"817E";
constant C_CMD_PLL_LOCK     : std_logic_vector(15 downto  0) := X"AAAA";
constant C_CMD_READ_TRIGGER : std_logic_vector(15 downto  0) := X"696A";    -- Chip_id[4:0] = "00000" encoded as X"6A"
constant C_CMD_CLEAR        : std_logic_vector(15 downto  0) := X"5500";
constant C_CMD_GLOBAL_PULSE : std_logic_vector(15 downto  0) := X"5C00";
constant C_CMD_CAL          : std_logic_vector(15 downto  0) := X"6300";
constant C_CMD_WRREG_0      : std_logic_vector(15 downto  0) := X"6600";    -- Must have '0' in MSB of address field
constant C_CMD_WRREG_1      : std_logic_vector(15 downto  0) := X"6600";    -- Must have '1' in MSB of address field
constant C_CMD_RDREG        : std_logic_vector(15 downto  0) := X"6500";

-- Trigger commands with Tag of 0
--constant C_CMD_TRIGGER_00   : std_logic_vector(15 downto  0) := X"0000";    -- "0000_0000"   0000   Trigger_00
constant C_CMD_TRIGGER_01   : std_logic_vector(15 downto  0) := X"2B00";    -- "0010_1011"   000T   Trigger_01
constant C_CMD_TRIGGER_02   : std_logic_vector(15 downto  0) := X"2D00";    -- "0010_1101"   00T0   Trigger_02
constant C_CMD_TRIGGER_03   : std_logic_vector(15 downto  0) := X"2E00";    -- "0010_1110"   00TT   Trigger_03
constant C_CMD_TRIGGER_04   : std_logic_vector(15 downto  0) := X"3300";    -- "0011_0011"   0T00   Trigger_04
constant C_CMD_TRIGGER_05   : std_logic_vector(15 downto  0) := X"3500";    -- "0011_0101"   0T0T   Trigger_05
constant C_CMD_TRIGGER_06   : std_logic_vector(15 downto  0) := X"3600";    -- "0011_0110"   0TT0   Trigger_06
constant C_CMD_TRIGGER_07   : std_logic_vector(15 downto  0) := X"3900";    -- "0011_1001"   0TTT   Trigger_07
constant C_CMD_TRIGGER_08   : std_logic_vector(15 downto  0) := X"3A00";    -- "0011_1010"   T000   Trigger_08
constant C_CMD_TRIGGER_09   : std_logic_vector(15 downto  0) := X"3C00";    -- "0011_1100"   T00T   Trigger_09
constant C_CMD_TRIGGER_10   : std_logic_vector(15 downto  0) := X"4B00";    -- "0100_1011"   T0T0   Trigger_10
constant C_CMD_TRIGGER_11   : std_logic_vector(15 downto  0) := X"4D00";    -- "0100_1101"   T0TT   Trigger_11
constant C_CMD_TRIGGER_12   : std_logic_vector(15 downto  0) := X"4E00";    -- "0100_1110"   TT00   Trigger_12
constant C_CMD_TRIGGER_13   : std_logic_vector(15 downto  0) := X"5300";    -- "0101_0011"   TT0T   Trigger_13
constant C_CMD_TRIGGER_14   : std_logic_vector(15 downto  0) := X"5500";    -- "0101_0101"   TTT0   Trigger_14
constant C_CMD_TRIGGER_15   : std_logic_vector(15 downto  0) := X"5600";    -- "0101_0110"   TTTT   Trigger_15

--------------------------------------------------------------------------------
-- Encoding for 4-bit trigger pattern into 8-bit trigger commands
-- with a tag
--------------------------------------------------------------------------------
type     t_arr_cmd_trig is array (0 to 15) of std_logic_vector( 7 downto 0);
constant C_ARR_CMD_TRIGGER   : t_arr_cmd_trig := (

--   Encoding         Trigger Pattern   Symbol Name
    "00000000",     --    0000          Trigger_00 (Invalid)
    "00101011",     --    000T          Trigger_01
    "00101101",     --    00T0          Trigger_02
    "00101110",     --    00TT          Trigger_03
    "00110011",     --    0T00          Trigger_04
    "00110101",     --    0T0T          Trigger_05
    "00110110",     --    0TT0          Trigger_06
    "00111001",     --    0TTT          Trigger_07
    "00111010",     --    T000          Trigger_08
    "00111100",     --    T00T          Trigger_09
    "01001011",     --    T0T0          Trigger_10
    "01001101",     --    T0TT          Trigger_11
    "01001110",     --    TT00          Trigger_12
    "01010011",     --    TT0T          Trigger_13
    "01010101",     --    TTT0          Trigger_14
    "01010110"      --    TTTT          Trigger_15
);


--------------------------------------------------------------------------------
-- Encoding for 5 bit data (chip_id, tags, data, address) into 8-bit data
-- e.g. a chip_id[4:0] of 3 would be encoded into "01110010" = X"72"
--------------------------------------------------------------------------------
type     t_enc_5bit_to_8bit is array (0 to 31) of std_logic_vector( 7 downto 0);
constant C_ENC_5BIT_TO_8BIT     : t_enc_5bit_to_8bit := (
    "01101010",     -- DATA_00  X"6A"
    "01101100",     -- DATA_01  X"6C"
    "01110001",     -- DATA_02  X"71"
    "01110010",     -- DATA_03  X"72"
    "01110100",     -- DATA_04  X"74"
    "10001011",     -- DATA_05  X"8B"
    "10001101",     -- DATA_06  X"8D"
    "10001110",     -- DATA_07  X"8E"
    "10010011",     -- DATA_08  X"93"
    "10010101",     -- DATA_09  X"95"
    "10010110",     -- DATA_10  X"96"
    "10011001",     -- DATA_11  X"99"
    "10011010",     -- DATA_12  X"9A"
    "10011100",     -- DATA_13  X"9C"
    "10100011",     -- DATA_14  X"A3"
    "10100101",     -- DATA_15  X"A5"
    "10100110",     -- DATA_16  X"A6"
    "10101001",     -- DATA_17  X"A9"
    "01011001",     -- DATA_18  X"59"
    "10101100",     -- DATA_19  X"AC"
    "10110001",     -- DATA_20  X"B1"
    "10110010",     -- DATA_21  X"B2"
    "10110100",     -- DATA_22  X"B4"
    "11000011",     -- DATA_23  X"C3"
    "11000101",     -- DATA_24  X"C5"
    "11000110",     -- DATA_25  X"C6"
    "11001001",     -- DATA_26  X"C9"
    "11001010",     -- DATA_27  X"CA"
    "11001100",     -- DATA_28  X"CC"
    "11010001",     -- DATA_29  X"D1"
    "11010010",     -- DATA_30  X"D2"
    "11010100"      -- DATA_31  X"D4"
);


--------------------------------------------------------------------------------
-- Register addresses
--------------------------------------------------------------------------------
constant ADR_REG_000    : std_logic_vector( 8 downto 0) := "000000000";
constant ADR_REG_001    : std_logic_vector( 8 downto 0) := "000000001";
constant ADR_REG_002    : std_logic_vector( 8 downto 0) := "000000010";
constant ADR_REG_003    : std_logic_vector( 8 downto 0) := "000000011";
constant ADR_REG_004    : std_logic_vector( 8 downto 0) := "000000100";
constant ADR_REG_005    : std_logic_vector( 8 downto 0) := "000000101";

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
constant C_DATA_00      : std_logic_vector( 7 downto 0) := X"6A";   -- "0110_1010"
constant C_DATA_01      : std_logic_vector( 7 downto 0) := X"6C";   -- "0110_1100"
constant C_DATA_02      : std_logic_vector( 7 downto 0) := X"71";   -- "0111_0001"
constant C_DATA_03      : std_logic_vector( 7 downto 0) := X"72";   -- "0111_0010"
constant C_DATA_04      : std_logic_vector( 7 downto 0) := X"74";   -- "0111_0100"
constant C_DATA_05      : std_logic_vector( 7 downto 0) := X"8B";   -- "1000_1011"
constant C_DATA_06      : std_logic_vector( 7 downto 0) := X"8D";   -- "1000_1101"
constant C_DATA_07      : std_logic_vector( 7 downto 0) := X"8E";   -- "1000_1110"
constant C_DATA_08      : std_logic_vector( 7 downto 0) := X"93";   -- "1001_0011"
constant C_DATA_09      : std_logic_vector( 7 downto 0) := X"95";   -- "1001_0101"
constant C_DATA_10      : std_logic_vector( 7 downto 0) := X"96";   -- "1001_0110"
constant C_DATA_11      : std_logic_vector( 7 downto 0) := X"99";   -- "1001_1001"
constant C_DATA_12      : std_logic_vector( 7 downto 0) := X"9A";   -- "1001_1010"
constant C_DATA_13      : std_logic_vector( 7 downto 0) := X"9C";   -- "1001_1100"
constant C_DATA_14      : std_logic_vector( 7 downto 0) := X"A3";   -- "1010_0011"
constant C_DATA_15      : std_logic_vector( 7 downto 0) := X"A5";   -- "1010_0101"
constant C_DATA_16      : std_logic_vector( 7 downto 0) := X"A6";   -- "1010_0110"
constant C_DATA_17      : std_logic_vector( 7 downto 0) := X"A9";   -- "1010_1001"
constant C_DATA_18      : std_logic_vector( 7 downto 0) := X"59";   -- "0101_1001"
constant C_DATA_19      : std_logic_vector( 7 downto 0) := X"AC";   -- "1010_1100"
constant C_DATA_20      : std_logic_vector( 7 downto 0) := X"B1";   -- "1011_0001"
constant C_DATA_21      : std_logic_vector( 7 downto 0) := X"B2";   -- "1011_0010"
constant C_DATA_22      : std_logic_vector( 7 downto 0) := X"B4";   -- "1011_0100"
constant C_DATA_23      : std_logic_vector( 7 downto 0) := X"C3";   -- "1100_0011"
constant C_DATA_24      : std_logic_vector( 7 downto 0) := X"C5";   -- "1100_0101"
constant C_DATA_25      : std_logic_vector( 7 downto 0) := X"C6";   -- "1100_0110"
constant C_DATA_26      : std_logic_vector( 7 downto 0) := X"C9";   -- "1100_1001"
constant C_DATA_27      : std_logic_vector( 7 downto 0) := X"CA";   -- "1100_1010"
constant C_DATA_28      : std_logic_vector( 7 downto 0) := X"CC";   -- "1100_1100"
constant C_DATA_29      : std_logic_vector( 7 downto 0) := X"D1";   -- "1101_0001"
constant C_DATA_30      : std_logic_vector( 7 downto 0) := X"D2";   -- "1101_0010"
constant C_DATA_31      : std_logic_vector( 7 downto 0) := X"D4";   -- "1101_0100"

end package rd53b_fpga_pkg;
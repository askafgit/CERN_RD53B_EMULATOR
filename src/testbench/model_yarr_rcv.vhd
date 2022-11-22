-------------------------------------------------------------------------------
-- File         : model_yarr_rcv.vhd
-- Description  : Testbench model of part of YARR that receives  4 lanes of serial data
--                Outputs 4 64-bit words of hit data on rx_hitdata[3:0] when rx_hitdata_dv = '1'.
--                Outputs 8 10-bit address/16-bit data pairs of autoread data on rx_autoread[7:0] when rx_autoread_dv = '1'.
--                Outputs 10-bit address/16-bit data pairs of reg-read data on rx_rd_reg[1:0] when rx_rdreg_dv[1:0] = '1'.
--
--                Each 64-bit serial data block is prefixed with a 2-bit sync header.
--
--                A sync header of 01 indicates that the 64-bit block is stream data i.e. hit data.
--
--                A sync header of 10 indicates that the 64-bit block is user data i.e. reg reads, or is an AURORA code block.
--                   AURORA code blocks start with 0x78 then the AURORA code.
--                   Reg read start with 0xB4, 0x55, 0x99, 0xD2 or 0xCC and contain two register read fields (exept for 0xCC)
--                       0xB4 indicates autoread reg data in both fields.
--                       0x55 indicates autoread reg data in first field, user commanded read in field2.
--                       0x99 indicates autoread reg data in second field, user commanded read in first field.
--                       0xD2 indicates user reg read data in both fields.
--                       0xCC indicates an error. Other fields are meaningless
--
--                Output signals :
--                Hit data is indicated by rx_data_dv = 1.
--                IDLE and service frames are indicated by rx_service = 1.
--                rx_locked = 1 when IDLE frames have been detected 3 times
--                NO DESCRAMBLE
-- 
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.rd53b_fpga_pkg.all;

entity model_yarr_rcv is
port(
    clk                 : in  std_logic;
    reset               : in  std_logic;
    sim_done            : in  boolean;

    clk_tx              : in  std_logic;
    rx_serial_p         : in  std_logic_vector( 3 downto 0);
    rx_serial_n         : in  std_logic_vector( 3 downto 0);

    rx_hitdata0         : out std_logic_vector(63 downto 0);    -- Received data
    rx_hitdata1         : out std_logic_vector(63 downto 0);    -- Received data
    rx_hitdata2         : out std_logic_vector(63 downto 0);    -- Received data
    rx_hitdata3         : out std_logic_vector(63 downto 0);    -- Received data
    rx_hitdata_dv       : out std_logic;                        -- Received data valid

    rx_autoread         : out t_arr_autoread;
    rx_autoread_dv      : out std_logic;

    rx_rdreg            : out trec_rdreg;
    rx_rdreg_dv         : out std_logic;

    rx_service          : out std_logic;                        -- Received idle and service data words
    rx_error            : out std_logic;                        -- Received error
    rx_locked           : out std_logic                         -- Received data lock indicator
);
end entity;

-------------------------------------------------------------------------------
-- Receive RD53 data stream.
-------------------------------------------------------------------------------
architecture rtl of model_yarr_rcv is

constant C_IDLE             : std_logic_vector(63 downto 0) := X"1E00000000000000";
signal cnt_idle             : unsigned(7 downto 0);             -- Number of IDLE patterns received

signal cnt_bitslip          : integer range 0 to 70;            -- Number of bitslips to do after reset
signal bitslip              : std_logic;
signal locked               : std_logic;
signal seen_idle            : std_logic;
signal rx_data_dv_i         : std_logic;
signal rx_service_i         : std_logic;
signal rx_service_d1        : std_logic;
signal rx_data0_i           : std_logic_vector(63 downto 0);    -- Received data
signal rx_data1_i           : std_logic_vector(63 downto 0);    -- Received data
signal rx_data2_i           : std_logic_vector(63 downto 0);    -- Received data
signal rx_data3_i           : std_logic_vector(63 downto 0);    -- Received data

alias  rx_rd0_type          : std_logic_vector( 7 downto 0) is rx_data0_i(63 downto 56);
alias  rx_rd1_type          : std_logic_vector( 7 downto 0) is rx_data1_i(63 downto 56);
alias  rx_rd2_type          : std_logic_vector( 7 downto 0) is rx_data2_i(63 downto 56);
alias  rx_rd3_type          : std_logic_vector( 7 downto 0) is rx_data3_i(63 downto 56);

signal sreg0                : std_logic_vector(65 downto 0);    -- Receive data shift register
signal sreg1                : std_logic_vector(65 downto 0);    -- Receive data shift register
signal sreg2                : std_logic_vector(65 downto 0);    -- Receive data shift register
signal sreg3                : std_logic_vector(65 downto 0);    -- Receive data shift register
signal idle                 : std_logic_vector( 3 downto 0);

constant N_INTERVAL         : integer := 3;                     -- Number of 66-bit data words between bitslips
constant N_LOCK_IDLES       : integer := 3;                     -- Number of consecutive IDLEs seen on all lanes before 'locked' is set
signal cnt_interval         : integer range 0 to N_INTERVAL;    --
signal cnt_sreg             : integer range 0 to 65;            -- Input bit counter.

-- Service data block types in data[63:56]
constant C_RD_AUTO_BOTH     : std_logic_vector( 7 downto 0) := X"B4";
constant C_RD_USER2         : std_logic_vector( 7 downto 0) := X"55";
constant C_RD_USER1         : std_logic_vector( 7 downto 0) := X"99";
constant C_RD_USER_BOTH     : std_logic_vector( 7 downto 0) := X"D2";
constant C_RD_ERROR         : std_logic_vector( 7 downto 0) := X"CC";
constant C_AURORA_CODE      : std_logic_vector( 7 downto 0) := X"78";   -- AURORA code is in data[55:48]

signal rx_rd_user           : std_logic_vector( 7 downto 0) := "00000000";
signal rx_rd_auto           : std_logic_vector( 7 downto 0) := "00000000";

signal rx_rd_error          : std_logic_vector( 3 downto 0) := "0000";  -- Lane error
signal rx_rd_aurora         : std_logic_vector( 3 downto 0) := "0000";
type   t_arr_rx_aurora_codes is array ( 3 downto 0) of std_logic_vector( 7 downto 0);
signal arr_rx_aurora_codes  : t_arr_rx_aurora_codes;
signal rx_rd_id0            : std_logic_vector( 1 downto 0) := (others=>'0');
signal rx_rd_status0        : std_logic_vector( 1 downto 0) := (others=>'0');
signal rx_rd_addr_a0        : std_logic_vector( 9 downto 0) := (others=>'0');
signal rx_rd_data_a0        : std_logic_vector(15 downto 0) := (others=>'0');
signal rx_rd_addr_b0        : std_logic_vector( 9 downto 0) := (others=>'0');
signal rx_rd_data_b0        : std_logic_vector(15 downto 0) := (others=>'0');
signal rx_rd_id1            : std_logic_vector( 1 downto 0) := (others=>'0');
signal rx_rd_status1        : std_logic_vector( 1 downto 0) := (others=>'0');
signal rx_rd_addr_a1        : std_logic_vector( 9 downto 0) := (others=>'0');
signal rx_rd_data_a1        : std_logic_vector(15 downto 0) := (others=>'0');
signal rx_rd_addr_b1        : std_logic_vector( 9 downto 0) := (others=>'0');
signal rx_rd_data_b1        : std_logic_vector(15 downto 0) := (others=>'0');
signal rx_rd_id2            : std_logic_vector( 1 downto 0) := (others=>'0');
signal rx_rd_status2        : std_logic_vector( 1 downto 0) := (others=>'0');
signal rx_rd_addr_a2        : std_logic_vector( 9 downto 0) := (others=>'0');
signal rx_rd_data_a2        : std_logic_vector(15 downto 0) := (others=>'0');
signal rx_rd_addr_b2        : std_logic_vector( 9 downto 0) := (others=>'0');
signal rx_rd_data_b2        : std_logic_vector(15 downto 0) := (others=>'0');
signal rx_rd_id3            : std_logic_vector( 1 downto 0) := (others=>'0');
signal rx_rd_status3        : std_logic_vector( 1 downto 0) := (others=>'0');
signal rx_rd_addr_a3        : std_logic_vector( 9 downto 0) := (others=>'0');
signal rx_rd_data_a3        : std_logic_vector(15 downto 0) := (others=>'0');
signal rx_rd_addr_b3        : std_logic_vector( 9 downto 0) := (others=>'0');
signal rx_rd_data_b3        : std_logic_vector(15 downto 0) := (others=>'0');

-- Storage for register read data
constant C_NUM_REGS         : integer := 256;
type   t_arr_rx_regs is array (C_NUM_REGS-1 downto 0) of std_logic_vector(15 downto 0);
signal arr_rx_regs          : t_arr_rx_regs;

signal sync0                : std_logic_vector( 1 downto 0);
signal sync1                : std_logic_vector( 1 downto 0);
signal sync2                : std_logic_vector( 1 downto 0);
signal sync3                : std_logic_vector( 1 downto 0);

begin

    -------------------------------------------------------
    -- 66-bit shift register.
    -- Single cycle high when sreg contains IDLE pattern
    -------------------------------------------------------
    pr_sreg : process (reset, clk)

    variable v_rx_sync0  : std_logic_vector(1 downto 0);
    variable v_rx_sync1  : std_logic_vector(1 downto 0);
    variable v_rx_sync2  : std_logic_vector(1 downto 0);
    variable v_rx_sync3  : std_logic_vector(1 downto 0);

    begin

        if (reset = '1') then
            idle        <= (others=>'0');
            sreg0       <= (others=>'0');
            sreg1       <= (others=>'0');
            sreg2       <= (others=>'0');
            sreg3       <= (others=>'0');
            rx_data0_i  <= (others=>'0');
            rx_data1_i  <= (others=>'0');
            rx_data2_i  <= (others=>'0');
            rx_data3_i  <= (others=>'0');
            cnt_sreg    <= 0;

        elsif rising_edge(clk) then

            sreg0   <= sreg0(64 downto 0) & rx_serial_p(0);
            sreg1   <= sreg1(64 downto 0) & rx_serial_p(1);
            sreg2   <= sreg2(64 downto 0) & rx_serial_p(2);
            sreg3   <= sreg3(64 downto 0) & rx_serial_p(3);

            -- Capture 64-bit data and 2-bit sync from the sreg every 66 clock cycles
            if (cnt_sreg = 65) then

                rx_data_dv_i    <= '1';

                if (bitslip = '1') then
                    cnt_sreg        <= 1;
                else
                    cnt_sreg        <= 0;
                end if;

                if (locked = '1') then  -- only drive data when locked
                    rx_data0_i      <= sreg0(62 downto  0) & rx_serial_p(0);
                    rx_data1_i      <= sreg1(62 downto  0) & rx_serial_p(1);
                    rx_data2_i      <= sreg2(62 downto  0) & rx_serial_p(2);
                    rx_data3_i      <= sreg3(62 downto  0) & rx_serial_p(3);
                end if;

                v_rx_sync0  := sreg0(64 downto 63);
                v_rx_sync1  := sreg1(64 downto 63);
                v_rx_sync2  := sreg2(64 downto 63);
                v_rx_sync3  := sreg3(64 downto 63);
                sync0       <= v_rx_sync0;
                sync1       <= v_rx_sync1;
                sync2       <= v_rx_sync2;
                sync3       <= v_rx_sync3;

                if (v_rx_sync0 = "10") and (v_rx_sync1 = "10") and (v_rx_sync2 = "10") and (v_rx_sync3 = "10") then
                    rx_service_i    <= '1';
                else
                    rx_service_i   <= '0';
                end if;

                -- Detect IDLE on each channel
                if ((sreg0(62 downto 0) & rx_serial_p(0)) = C_IDLE) then
                    idle(0)     <= '1';
                else
                    idle(0)     <= '0';
                end if;

                if ((sreg1(62 downto 0) & rx_serial_p(1)) = C_IDLE) then
                    idle(1)     <= '1';
                else
                    idle(1)     <= '0';
                end if;

                if ((sreg2(62 downto 0) & rx_serial_p(2)) = C_IDLE) then
                    idle(2)     <= '1';
                else
                    idle(2)     <= '0';
                end if;

                if ((sreg3(62 downto 0) & rx_serial_p(3)) = C_IDLE) then
                    idle(3)     <= '1';
                else
                    idle(3)     <= '0';
                end if;

            else
                idle            <= (others=>'0');
                rx_data_dv_i    <= '0';

                if (bitslip = '1') then
                    cnt_sreg        <= cnt_sreg + 2;
                else
                    cnt_sreg        <= cnt_sreg + 1;
                end if;

            end if;

        end if;

    end process;


    rx_error    <= rx_rd_error(0) or rx_rd_error(1) or rx_rd_error(2) or rx_rd_error(3);


    -------------------------------------------------------
    -- Capture register reads and error
    -------------------------------------------------------
    pr_decode : process (reset, clk)
    begin

        if (reset = '1') then

            arr_rx_aurora_codes(0)  <= (others=>'0');
            arr_rx_aurora_codes(1)  <= (others=>'0');
            arr_rx_aurora_codes(2)  <= (others=>'0');
            arr_rx_aurora_codes(3)  <= (others=>'0');

        elsif rising_edge(clk) then

            -- Default values each clock cycle
            rx_rd_user              <= (others=>'0');
            rx_rd_auto              <= (others=>'0');
            rx_rd_error             <= (others=>'0');
            rx_rd_aurora            <= (others=>'0');

            rx_rd_id0               <= (others=>'0');
            rx_rd_status0           <= (others=>'0');
            rx_rd_addr_a0           <= (others=>'0');
            rx_rd_data_a0           <= (others=>'0');
            rx_rd_addr_b0           <= (others=>'0');
            rx_rd_data_b0           <= (others=>'0');

            rx_rd_id1               <= (others=>'0');
            rx_rd_status1           <= (others=>'0');
            rx_rd_addr_a1           <= (others=>'0');
            rx_rd_data_a1           <= (others=>'0');
            rx_rd_addr_b1           <= (others=>'0');
            rx_rd_data_b1           <= (others=>'0');

            rx_rd_id2               <= (others=>'0');
            rx_rd_status2           <= (others=>'0');
            rx_rd_addr_a2           <= (others=>'0');
            rx_rd_data_a2           <= (others=>'0');
            rx_rd_addr_b2           <= (others=>'0');
            rx_rd_data_b2           <= (others=>'0');

            rx_rd_id3               <= (others=>'0');
            rx_rd_status3           <= (others=>'0');
            rx_rd_addr_a3           <= (others=>'0');
            rx_rd_data_a3           <= (others=>'0');
            rx_rd_addr_b3           <= (others=>'0');
            rx_rd_data_b3           <= (others=>'0');


            if (rx_service_i = '1' and idle = "0000") then

                --------------------------------------------------------------------
                -- Lane 0 : Capture register addresses and data
                --------------------------------------------------------------------
                if (  (rx_rd0_type = C_RD_AUTO_BOTH) or (rx_rd0_type = C_RD_USER1)
                   or (rx_rd0_type = C_RD_USER2)     or (rx_rd0_type = C_RD_USER_BOTH)
                ) then
                    rx_rd_id0               <= rx_data0_i(55 downto 54);    -- 2-bit Chip ID
                    rx_rd_status0           <= rx_data0_i(53 downto 52);    -- 2-bit Status

                    rx_rd_addr_a0           <= rx_data0_i(51 downto 42);    -- 10-bit address A0
                    rx_rd_data_a0           <= rx_data0_i(41 downto 26);    -- 16-bit data A0
                    rx_rd_addr_b0           <= rx_data0_i(25 downto 16);    -- 10-bit address B0
                    rx_rd_data_b0           <= rx_data0_i(15 downto  0);    -- 16-bit data B0

                    arr_rx_aurora_codes(0)  <= (others=>'0');       -- 8-bit AURORA code

                elsif (rx_rd0_type = C_RD_ERROR) then

                    rx_rd_error(0)          <= '1';

                elsif (rx_rd0_type = C_AURORA_CODE) then

                    rx_rd_aurora(0)         <= '1';
                    arr_rx_aurora_codes(0)  <= rx_data0_i(55 downto 48);    -- 8-bit AURORA code

                end if;

                --------------------------------------------------------------------
                -- Lane 1 : Capture register addresses and data
                --------------------------------------------------------------------
                if (  (rx_rd1_type = C_RD_AUTO_BOTH) or (rx_rd1_type = C_RD_USER1)
                   or (rx_rd1_type = C_RD_USER2)     or (rx_rd1_type = C_RD_USER_BOTH)
                ) then
                    rx_rd_id1               <= rx_data1_i(55 downto 54);    -- 2-bit Chip ID
                    rx_rd_status1           <= rx_data1_i(53 downto 52);    -- 2-bit Status

                    rx_rd_addr_a1           <= rx_data1_i(51 downto 42);    -- 10-bit address A0
                    rx_rd_data_a1           <= rx_data1_i(41 downto 26);    -- 16-bit data A0
                    rx_rd_addr_b1           <= rx_data1_i(25 downto 16);    -- 10-bit address B0
                    rx_rd_data_b1           <= rx_data1_i(15 downto  0);    -- 16-bit data B0

                    arr_rx_aurora_codes(1)  <= (others=>'0');       -- 8-bit AURORA code

                elsif (rx_rd1_type = C_RD_ERROR) then

                    rx_rd_error(1)          <= '1';

                elsif (rx_rd1_type = C_AURORA_CODE) then

                    rx_rd_aurora(1)         <= '1';
                    arr_rx_aurora_codes(1)  <= rx_data1_i(55 downto 48);    -- 8-bit AURORA code

                end if;


                --------------------------------------------------------------------
                -- Lane 2 : Capture register addresses and data
                --------------------------------------------------------------------
                if (  (rx_rd2_type = C_RD_AUTO_BOTH) or (rx_rd2_type = C_RD_USER1)
                   or (rx_rd2_type = C_RD_USER2)     or (rx_rd2_type = C_RD_USER_BOTH)
                ) then
                    rx_rd_id2               <= rx_data2_i(55 downto 54);    -- 2-bit Chip ID
                    rx_rd_status2           <= rx_data2_i(53 downto 52);    -- 2-bit Status

                    rx_rd_addr_a2           <= rx_data2_i(51 downto 42);    -- 10-bit address A0
                    rx_rd_data_a2           <= rx_data2_i(41 downto 26);    -- 16-bit data A0
                    rx_rd_addr_b2           <= rx_data2_i(25 downto 16);    -- 10-bit address B0
                    rx_rd_data_b2           <= rx_data2_i(15 downto  0);    -- 16-bit data B0

                    arr_rx_aurora_codes(2)  <= (others=>'0');       -- 8-bit AURORA code

                elsif (rx_rd2_type = C_RD_ERROR) then

                    rx_rd_error(2)          <= '1';

                elsif (rx_rd2_type = C_AURORA_CODE) then

                    rx_rd_aurora(2)         <= '1';
                    arr_rx_aurora_codes(2)  <= rx_data2_i(55 downto 48);    -- 8-bit AURORA code

                end if;


                --------------------------------------------------------------------
                -- Lane 3 : Capture register addresses and data
                --------------------------------------------------------------------
                if (  (rx_rd3_type = C_RD_AUTO_BOTH) or (rx_rd3_type = C_RD_USER1)
                   or (rx_rd3_type = C_RD_USER2)     or (rx_rd3_type = C_RD_USER_BOTH)
                ) then
                    rx_rd_id3               <= rx_data3_i(55 downto 54);    -- 2-bit Chip ID
                    rx_rd_status3           <= rx_data3_i(53 downto 52);    -- 2-bit Status

                    rx_rd_addr_a3           <= rx_data3_i(51 downto 42);    -- 10-bit address A0
                    rx_rd_data_a3           <= rx_data3_i(41 downto 26);    -- 16-bit data A0
                    rx_rd_addr_b3           <= rx_data3_i(25 downto 16);    -- 10-bit address B0
                    rx_rd_data_b3           <= rx_data3_i(15 downto  0);    -- 16-bit data B0

                    arr_rx_aurora_codes(3)  <= (others=>'0');       -- 8-bit AURORA code

                elsif (rx_rd3_type = C_RD_ERROR) then

                    rx_rd_error(3)          <= '1';

                elsif (rx_rd3_type = C_AURORA_CODE) then

                    rx_rd_aurora(3)         <= '1';
                    arr_rx_aurora_codes(3)  <= rx_data3_i(55 downto 48);    -- 8-bit AURORA code

                end if;


                --------------------------------------------------------------------
                --------------------------------------------------------------------

                --------------------------------------------------------------------
                -- Lane 0 : Set read type flags
                --------------------------------------------------------------------
                if    (rx_rd0_type = C_RD_AUTO_BOTH) then
                    rx_rd_auto(0)   <= '1';                         -- Type of read auto
                    rx_rd_auto(1)   <= '1';                         -- Type of read auto
                elsif (rx_rd0_type = C_RD_USER2    ) then
                    rx_rd_auto(0)   <= '1';                         -- Type of read auto
                    rx_rd_user(1)   <= '1';                         -- Type of read user_commanded
                elsif (rx_rd0_type = C_RD_USER1    ) then
                    rx_rd_user(0)   <= '1';                         -- Type of read user_commanded
                    rx_rd_auto(1)   <= '1';                         -- Type of read auto
                elsif (rx_rd0_type = C_RD_USER_BOTH) then
                    rx_rd_user(0)   <= '1';                         -- Type of read user_commanded
                    rx_rd_user(1)   <= '1';                         -- Type of read user_commanded
                end if;

                --------------------------------------------------------------------
                -- Lane 1 : Set read type flags
                --------------------------------------------------------------------
                if    (rx_rd1_type = C_RD_AUTO_BOTH) then
                    rx_rd_auto(2)   <= '1';                         -- Type of read auto
                    rx_rd_auto(3)   <= '1';                         -- Type of read auto
                elsif (rx_rd1_type = C_RD_USER2    ) then
                    rx_rd_auto(2)   <= '1';                         -- Type of read auto
                    rx_rd_user(3)   <= '1';                         -- Type of read user_commanded
                elsif (rx_rd1_type = C_RD_USER1    ) then
                    rx_rd_user(2)   <= '1';                         -- Type of read user_commanded
                    rx_rd_auto(3)   <= '1';                         -- Type of read auto
                elsif (rx_rd1_type = C_RD_USER_BOTH) then
                    rx_rd_user(2)   <= '1';                         -- Type of read user_commanded
                    rx_rd_user(3)   <= '1';                         -- Type of read user_commanded
                end if;

                --------------------------------------------------------------------
                -- Lane 2 : Set read type flags
                --------------------------------------------------------------------
                if    (rx_rd2_type = C_RD_AUTO_BOTH) then
                    rx_rd_auto(4)   <= '1';                         -- Type of read auto
                    rx_rd_auto(5)   <= '1';                         -- Type of read auto
                elsif (rx_rd2_type = C_RD_USER2    ) then
                    rx_rd_auto(4)   <= '1';                         -- Type of read auto
                    rx_rd_user(5)   <= '1';                         -- Type of read user_commanded
                elsif (rx_rd2_type = C_RD_USER1    ) then
                    rx_rd_user(4)   <= '1';                         -- Type of read user_commanded
                    rx_rd_auto(5)   <= '1';                         -- Type of read auto
                elsif (rx_rd2_type = C_RD_USER_BOTH) then
                    rx_rd_user(4)   <= '1';                         -- Type of read user_commanded
                    rx_rd_user(5)   <= '1';                         -- Type of read user_commanded
                end if;

                --------------------------------------------------------------------
                -- Lane 3 : Set read type flags
                --------------------------------------------------------------------
                if    (rx_rd3_type = C_RD_AUTO_BOTH) then
                    rx_rd_auto(6)   <= '1';                         -- Type of read auto
                    rx_rd_auto(7)   <= '1';                         -- Type of read auto
                elsif (rx_rd3_type = C_RD_USER2    ) then
                    rx_rd_auto(6)   <= '1';                         -- Type of read auto
                    rx_rd_user(7)   <= '1';                         -- Type of read user_commanded
                elsif (rx_rd3_type = C_RD_USER1    ) then
                    rx_rd_user(6)   <= '1';                         -- Type of read user_commanded
                    rx_rd_auto(7)   <= '1';                         -- Type of read auto
                elsif (rx_rd3_type = C_RD_USER_BOTH) then
                    rx_rd_user(6)   <= '1';                         -- Type of read user_commanded
                    rx_rd_user(7)   <= '1';                         -- Type of read user_commanded
                end if;

            end if;

            rx_service  <= rx_service_i;
            rx_service_d1   <= rx_service_i;

        end if;

    end process;


    -------------------------------------------------------
    -- Hit data output
    -------------------------------------------------------
    pr_op_hitdata : process (reset, clk)
    begin

        if (reset = '1') then

            rx_hitdata_dv   <= '0';
            rx_hitdata0        <= (others=>'0');
            rx_hitdata1        <= (others=>'0');
            rx_hitdata2        <= (others=>'0');
            rx_hitdata3        <= (others=>'0');

        elsif rising_edge(clk) then

            -- Output hit data
            if ((rx_data_dv_i and locked and not(rx_service_i)) = '1') then
                rx_hitdata_dv   <= '1';
                rx_hitdata0        <= rx_data0_i;
                rx_hitdata1        <= rx_data1_i;
                rx_hitdata2        <= rx_data2_i;
                rx_hitdata3        <= rx_data3_i;
            else
                rx_hitdata_dv   <= '0';
            end if;


        end if;

    end process;


    -------------------------------------------------------
    -- Autoread and address/data output
    -------------------------------------------------------
    pr_op_autoread : process (reset, clk)
    begin

        if (reset = '1') then

            for I in 0 to 7 loop
                rx_autoread(I).addr    <= (others=>'0');
                rx_autoread(I).data    <= (others=>'0');
                rx_autoread_dv         <= '0';

            end loop;

        elsif rising_edge(clk) then

            -- Output autoread data
            if ((rx_data_dv_i and locked and rx_service_d1) = '1') then
                if (  (rx_rd_auto(0) = '1') or (rx_rd_auto(1) = '1') or (rx_rd_auto(2) = '1') or (rx_rd_auto(3) = '1') ) then

                    rx_autoread_dv  <= '1';
    
                    -- Lane 0
                    if (rx_rd_auto(0) = '1') then
                        rx_autoread(0).addr  <= rx_rd_addr_a0;
                        rx_autoread(0).data  <= rx_rd_data_a0;
                    end if;

                    if (rx_rd_auto(1) = '1') then
                        rx_autoread(1).addr  <= rx_rd_addr_b0;
                        rx_autoread(1).data  <= rx_rd_data_b0;
                    end if;

                    -- Lane 1
                    if (rx_rd_auto(2) = '1') then
                        rx_autoread(2).addr  <= rx_rd_addr_a1;
                        rx_autoread(2).data  <= rx_rd_data_a1;
                    end if;

                    if (rx_rd_auto(3) = '1') then
                        rx_autoread(3).addr  <= rx_rd_addr_b1;
                        rx_autoread(3).data  <= rx_rd_data_b1;
                    end if;

                    -- Lane 2
                    if (rx_rd_auto(4) = '1') then
                        rx_autoread(4).addr  <= rx_rd_addr_a2;
                        rx_autoread(4).data  <= rx_rd_data_a2;
                    end if;

                    if (rx_rd_auto(5) = '1') then
                        rx_autoread(5).addr  <= rx_rd_addr_b2;
                        rx_autoread(5).data  <= rx_rd_data_b2;
                    end if;

                    -- Lane 3
                    if (rx_rd_auto(6) = '1') then
                        rx_autoread(6).addr  <= rx_rd_addr_a3;
                        rx_autoread(6).data  <= rx_rd_data_a3;
                    end if;

                    if (rx_rd_auto(7) = '1') then
                        rx_autoread(7).addr  <= rx_rd_addr_b3;
                        rx_autoread(7).data  <= rx_rd_data_b3;
                    end if;

                else
                    rx_autoread_dv   <= '0';
                end if;

            else
                rx_autoread_dv   <= '0';
            end if;


        end if;

    end process;


    -------------------------------------------------------
    -- Commanded reg-read address/data output from Lane 0.
    -- Only handles one commanded reg read at a time.
    -------------------------------------------------------
    pr_op_cmdread : process (reset, clk)
    begin

        if (reset = '1') then

            rx_rdreg.addr     <= (others=>'0');
            rx_rdreg.data     <= (others=>'0');
            rx_rdreg_dv       <= '0';

        elsif rising_edge(clk) then

            if ((rx_data_dv_i and locked and rx_service_d1) = '1') then
    
                -- Lane 0
                if (rx_rd_user(0) = '1') then
                    rx_rdreg_dv   <= '1';
                    rx_rdreg.addr <= rx_rd_addr_a0;
                    rx_rdreg.data <= rx_rd_data_a0;

                elsif (rx_rd_user(1) = '1') then
                    rx_rdreg_dv   <= '1';
                    rx_rdreg.addr <= rx_rd_addr_b0;
                    rx_rdreg.data <= rx_rd_data_b0;
                end if;

            else
                rx_rdreg_dv   <= '0';
            end if;

        end if;

    end process;


    -------------------------------------------------------
    -- Store the register values read over each lane.
    -- Autoread or commanded reg reads update the register table.
    -------------------------------------------------------
    pr_regs : process (reset, clk)
    begin

        if (reset = '1') then

            for I in 0 to C_NUM_REGS-1 loop
                arr_rx_regs(I)  <= (others=>'0');
            end loop;

        elsif rising_edge(clk) then

            if (rx_rd_auto(0) = '1' or rx_rd_user(0) = '1') then
                arr_rx_regs(to_integer(unsigned(rx_rd_addr_a0)))  <= rx_rd_data_a0;
                arr_rx_regs(to_integer(unsigned(rx_rd_addr_b0)))  <= rx_rd_data_b0;
            end if;

            if (rx_rd_auto(1) = '1' or rx_rd_user(1) = '1') then
                arr_rx_regs(to_integer(unsigned(rx_rd_addr_a1)))  <= rx_rd_data_a1;
                arr_rx_regs(to_integer(unsigned(rx_rd_addr_b1)))  <= rx_rd_data_b1;
            end if;

            if (rx_rd_auto(2) = '1' or rx_rd_user(2) = '1') then
                arr_rx_regs(to_integer(unsigned(rx_rd_addr_a2)))  <= rx_rd_data_a2;
                arr_rx_regs(to_integer(unsigned(rx_rd_addr_b2)))  <= rx_rd_data_b2;
            end if;

            if (rx_rd_auto(3) = '1' or rx_rd_user(3) = '1') then
                arr_rx_regs(to_integer(unsigned(rx_rd_addr_a3)))  <= rx_rd_data_a3;
                arr_rx_regs(to_integer(unsigned(rx_rd_addr_b3)))  <= rx_rd_data_b3;
            end if;

        end if;

    end process;



    -------------------------------------------------------
    -- State machine to do bitslips at intervals until IDLE
    -- pattern is received.
    -- Do a bitslip every 66*N_INTERVAL input data clock cycles.
    -------------------------------------------------------
    pr_bitslip : process (reset, clk)
    begin

        if (reset = '1') then

            bitslip         <= '0';
            cnt_bitslip     <= 0;
            cnt_idle        <= (others=>'0');
            seen_idle       <= '0';
            locked          <= '0';

        elsif rising_edge(clk) then

            -- If an IDLE has not been seen, do a bitslip every N_INTERVAL*66 input bits
            if (seen_idle = '0') then

                if (rx_data_dv_i = '1' and idle = "0000") then

                    if (cnt_interval = N_INTERVAL-1) then
                        bitslip         <= '1';
                        cnt_interval    <= 0;
                        cnt_bitslip     <= cnt_bitslip + 1;
                    else
                        cnt_interval    <= cnt_interval+ 1;
                    end if;

                else
                    bitslip         <= '0';

                end if;

                -- If IDLE is seen on all 4 channels then set 'seen_idle'
                if ((rx_data_dv_i = '1') and (idle = "1111")) then
                    seen_idle   <= '1';
                end if;

            -- If IDLE has been seen and occurs again then increment counter
            else
                if ((rx_data_dv_i = '1') and (idle = "1111")) then
                    if (cnt_idle < X"FF") then
                        cnt_idle    <= cnt_idle + 1;
                    end if;
                end if;

            end if;

            -- Set 'locked' after 3 sets of idles
            if (seen_idle = '1' and cnt_idle > N_LOCK_IDLES-1) then
                locked      <= '1';
            else
                locked      <= '0';
            end if;

        end if;

    end process;

    rx_locked   <= locked;

end rtl;


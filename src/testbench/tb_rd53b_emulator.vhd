-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Simple testbench for RD53B emulator on SLAC board
--
--

-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;

use     work.rd53b_fpga_pkg.all;
use     work.rd53b_regmap_pkg.all;
use     work.rom_128x64bit_pkg.all;     -- Array of expected output data. Same data is loaded into hitmaker3 ROM
use     work.rd53b_tb_pkg.all;          -- Procedures used by testbench for stimulus and testing

entity tb_rd53b_emulator is
end tb_rd53b_emulator;

architecture rtl of tb_rd53b_emulator is

-- Clock freq expressed in MHz
constant CLK_FREQ_250MHZ    : real      := 250.00;
constant CLK_FREQ_156MHZ    : real      := 156.25;

-- Clock periods
constant CLK_PER_250MHZ     : time      := integer(1.0E+6/(CLK_FREQ_250MHZ)) * 1 ps;
constant CLK_PER_156MHZ     : time      := integer(1.0E+6/(CLK_FREQ_156MHZ)) * 1 ps;


signal clk250               : std_logic := '0';     -- Clock from Yarr to SLAC
signal clk156               : std_logic := '0';
signal clk                  : std_logic := '0';		-- Same as clk156
signal sim_done             : boolean   := false;
signal reset                : std_logic := '1';

-- Procedure data driven to model of YARR ttc driver
signal tx_data              : std_logic_vector(15 downto 0);
signal tx_data_dv           : std_logic;

-- Outputs from YARR receiver model
signal yarr_rx_hitdata0     : std_logic_vector(63 downto 0);    -- Received data
signal yarr_rx_hitdata1     : std_logic_vector(63 downto 0);    -- Received data
signal yarr_rx_hitdata2     : std_logic_vector(63 downto 0);    -- Received data
signal yarr_rx_hitdata3     : std_logic_vector(63 downto 0);    -- Received data
signal yarr_rx_hitdata_dv   : std_logic;                        -- Received data valid
signal yarr_rx_locked       : std_logic;                        -- Received data lock indicator
signal yarr_rx_error        : std_logic;                        -- Received error indicator
signal yarr_rx_service      : std_logic;                        -- Received sync indicator

signal yarr_rx_autoread     : t_arr_autoread;
signal yarr_rx_autoread_dv  : std_logic;
signal yarr_rx_rdreg        : trec_rdreg;
signal yarr_rx_rdreg_dv     : std_logic;

signal enable_check_autoread: std_logic;

-- FPGA port signals
signal USER_SMA_CLOCK_P     : std_logic;    -- Differential input clock
signal USER_SMA_CLOCK_N     : std_logic;
signal p_uart_rxd           : std_logic;
signal p_uart_txd           : std_logic;
signal ttc_ready            : std_logic;
signal ttc_data_p           : std_logic;
signal ttc_data_n           : std_logic;
signal cmd_out_p            : std_logic_vector( 3 downto 0);
signal cmd_out_n            : std_logic_vector( 3 downto 0);
signal led                  : std_logic_vector( 3 downto 0);
signal p_debug              : std_logic_vector(29 downto 0);

-- Signals to check recieved hit data against expected values from ROM package file
signal check_hitdata_fails  : std_logic_vector( 3 downto 0);
signal rx_hit_error         : std_logic := '0';
signal cnt_rx_data          : integer := 0;

-- Set expected register readback address and data 
signal exp_rdreg            : trec_rdreg;
signal exp_rdreg_dv         : std_logic := '0';
signal err_rdreg_addr       : std_logic;
signal err_rdreg_data       : std_logic;

signal exp_autoread         : t_arr_autoread;
signal exp_autoread_dv      : std_logic := '0';
signal err_autoread_addr    : std_logic_vector( 7 downto 0);
signal err_autoread_data    : std_logic_vector( 7 downto 0);

signal chip_id              : integer := 3;

-- A mirror of the configuration and status registers in the FPGA, 138 addresses
signal arr_config_reg       : t_arr_config_reg;

-- Array 
type   t_ptr_autoreads      is array (0 to 7) of integer;



----------------------------------------------------------------------------------------------------------------------
begin

    USER_SMA_CLOCK_P    <= clk250;
    USER_SMA_CLOCK_N    <= not(clk250);

    p_uart_rxd          <= '1';


    -------------------------------------------------------------
    -- YARR TTC driver
    -------------------------------------------------------------
    u_model_yarr_ttc : entity work.model_yarr_ttc
    port map
    (
        clk                 => clk156               , -- in  std_logic;
        reset               => reset                , -- in  std_logic;
        sim_done            => sim_done             , -- in  boolean;
        tx_data             => tx_data              , -- in  std_logic_vector(15 downto 0);    -- Commands
        tx_data_dv          => tx_data_dv           , -- in  std_logic;
        ready               => ttc_ready            , -- out std_logic;
        ttc_p               => ttc_data_p           , -- out std_logic;
        ttc_n               => ttc_data_n             -- out std_logic
    );


    -------------------------------------------------------------
    -- FPGA
    -------------------------------------------------------------
    u_on_chip_top : entity work.on_chip_top
    port map
    (
           USER_SMA_CLOCK_P => USER_SMA_CLOCK_P     , -- in
           USER_SMA_CLOCK_N => USER_SMA_CLOCK_N     , -- in

           p_uart_rxd       => p_uart_rxd           , -- in
           p_uart_txd       => p_uart_txd           , -- out

           ttc_data_p       => ttc_data_p           , -- in
           ttc_data_n       => ttc_data_n           , -- in

           cmd_out_p        => cmd_out_p            , -- out  [3:0]
           cmd_out_n        => cmd_out_n            , -- out  [3:0]

           led              => led                  , -- out  [3:0]
           p_debug          => p_debug                -- out [29:0]
    );


    -------------------------------------------------------------
    -- YARR data receiver. Descramble, deserializer
    -- TODO : Have this block use 'clk_tx' at the receive bitrate
    -- shift data in, and use 'clk' for data outputs.
    -- Preently assumes data is received at 160.
    -------------------------------------------------------------
    u_model_yarr_rcv : entity work.model_yarr_rcv
    port map
    (
        clk                 => clk156               , -- in  std_logic;
        reset               => reset                , -- in  std_logic;
        sim_done            => sim_done             , -- in  boolean;

        clk_tx              => '0'                  , -- in  std_logic; ** NOT USED YET **
        rx_serial_p         => cmd_out_p            , -- in  std_logic_vector( 3 downto 0);
        rx_serial_n         => cmd_out_n            , -- in  std_logic_vector( 3 downto 0);

        rx_hitdata0         => yarr_rx_hitdata0     , -- out std_logic_vector(63 downto 0);    -- Received data
        rx_hitdata1         => yarr_rx_hitdata1     , -- out std_logic_vector(63 downto 0);    -- Received data
        rx_hitdata2         => yarr_rx_hitdata2     , -- out std_logic_vector(63 downto 0);    -- Received data
        rx_hitdata3         => yarr_rx_hitdata3     , -- out std_logic_vector(63 downto 0);    -- Received data
        rx_hitdata_dv       => yarr_rx_hitdata_dv   , -- out std_logic;                        -- Received data valid

        rx_autoread         => yarr_rx_autoread     , -- out t_arr_autoread;
        rx_autoread_dv      => yarr_rx_autoread_dv  , -- out std_logic;

        rx_rdreg            => yarr_rx_rdreg        , -- out trec_rdreg;
        rx_rdreg_dv         => yarr_rx_rdreg_dv     , -- out std_logic;

        rx_service          => yarr_rx_service      , -- out std_logic                         -- Received sync data word
        rx_error            => yarr_rx_error        , -- out std_logic                         -- Received sync data word
        rx_locked           => yarr_rx_locked         -- out std_logic                         -- Received data lock indicator
    );



    -------------------------------------------------------------
    -- Generate clocks
    -------------------------------------------------------------
    pr_clk250 : process
    begin
        clk250  <= '0';
        wait for (CLK_PER_250MHZ/2);
        clk250  <= '1';
        wait for (CLK_PER_250MHZ-CLK_PER_250MHZ/2);
        if (sim_done=true) then
            wait;
        end if;
    end process;

    pr_clk156 : process
    begin
        clk156  <= '0';
        clk     <= '0';
        wait for (CLK_PER_156MHZ/2);
        clk156  <= '1';
        clk     <= '1';
        wait for (CLK_PER_156MHZ-CLK_PER_156MHZ/2);
        if (sim_done=true) then
            wait;
        end if;
    end process;


    -------------------------------------------------------------
    -- Main test sequence. 
    -------------------------------------------------------------
    pr_main : process
    variable v_reg_data         : std_logic_vector(15 downto 0);
    variable v_ptr_autoreads    : t_ptr_autoreads;
    variable v_regs_test_all    : boolean := false;
    begin

        -- Reset and drive starting values on all input signals
        reset                   <= '1';     -- Board testbench reset
        tx_data                 <= (others=>'0');
        tx_data_dv              <= '0';

        -- Load the config reg array with the default contents
        init_config_regs(arr_config_reg);
        clk_delay(clk, 10);

        -------------------------------------------------------------
        -- Expected default autoread values. Content and address of registers pointed to by autoread
        -- registers, NOT address and data contents of the autoread control registers themselves
        -------------------------------------------------------------
        v_ptr_autoreads(0)      := to_integer(unsigned(DEF_REG_AUTOREAD0));    -- Get the content of the AUTOREAD0 control reg
        exp_autoread(0).addr    <= DEF_REG_AUTOREAD0( 9 downto 0);             -- The returned register address should be the pointer value.
        exp_autoread(0).data    <= arr_config_reg(v_ptr_autoreads(0));

        v_ptr_autoreads(1)      := to_integer(unsigned(DEF_REG_AUTOREAD1));
        exp_autoread(1).addr    <= DEF_REG_AUTOREAD1( 9 downto 0);
        exp_autoread(1).data    <= arr_config_reg(v_ptr_autoreads(1));

        v_ptr_autoreads(2)      := to_integer(unsigned(DEF_REG_AUTOREAD2));
        exp_autoread(2).addr    <= DEF_REG_AUTOREAD2( 9 downto 0);
        exp_autoread(2).data    <= arr_config_reg(v_ptr_autoreads(2));

        v_ptr_autoreads(3)      := to_integer(unsigned(DEF_REG_AUTOREAD3));
        exp_autoread(3).addr    <= DEF_REG_AUTOREAD3( 9 downto 0);
        exp_autoread(3).data    <= arr_config_reg(v_ptr_autoreads(3));

        v_ptr_autoreads(4)      := to_integer(unsigned(DEF_REG_AUTOREAD4));
        exp_autoread(4).addr    <= DEF_REG_AUTOREAD4( 9 downto 0);
        exp_autoread(4).data    <= arr_config_reg(v_ptr_autoreads(4));

        v_ptr_autoreads(5)      := to_integer(unsigned(DEF_REG_AUTOREAD5));
        exp_autoread(5).addr    <= DEF_REG_AUTOREAD5( 9 downto 0);
        exp_autoread(5).data    <= arr_config_reg(v_ptr_autoreads(5));

        v_ptr_autoreads(6)      := to_integer(unsigned(DEF_REG_AUTOREAD6));
        exp_autoread(6).addr    <= DEF_REG_AUTOREAD6( 9 downto 0);
        exp_autoread(6).data    <= arr_config_reg(v_ptr_autoreads(6));

        v_ptr_autoreads(7)      := to_integer(unsigned(DEF_REG_AUTOREAD7));
        exp_autoread(7).addr    <= DEF_REG_AUTOREAD7( 9 downto 0);
        exp_autoread(7).data    <= arr_config_reg(v_ptr_autoreads(7));

        enable_check_autoread   <= '1';

        clk_delay(clk, 10);
        reset                   <= '0';     -- Board testbench reset

        -- Wait until the YARR receiver model has seen enough correctly aligned IDLE frames to lock
        wait until yarr_rx_locked = '1';
        cpu_print_msg("  YARR RX LOCKED");
        wait for 5 us;

        enable_check_autoread   <= '0';

        ------------------------------------------------------------------------
        -- Send a read-register command for every register and compare the returned value against the register's default value
        ------------------------------------------------------------------------
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_PIX_PORTAL                , DEF_REG_PIX_PORTAL                  , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_REGION_COL                , DEF_REG_REGION_COL                  , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_REGION_ROW                , DEF_REG_REGION_ROW                  , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_PIX_MODE                  , DEF_REG_PIX_MODE                    , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_PIX_DEFAULT_CONFIG        , DEF_REG_PIX_DEFAULT_CONFIG          , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_PIX_DEFAULT_CONFIG_B      , DEF_REG_PIX_DEFAULT_CONFIG_B        , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_GCR_DEFAULT_CONFIG        , DEF_REG_GCR_DEFAULT_CONFIG          , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_GCR_DEFAULT_CONFIG_B      , DEF_REG_GCR_DEFAULT_CONFIG_B        , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_L_DIFF         , DEF_REG_DAC_PREAMP_L_DIFF           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_R_DIFF         , DEF_REG_DAC_PREAMP_R_DIFF           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);

        v_regs_test_all := false;   -- Set 'false' for shortened register test 
        if (v_regs_test_all = true) then
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_TL_DIFF        , DEF_REG_DAC_PREAMP_TL_DIFF          , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_TR_DIFF        , DEF_REG_DAC_PREAMP_TR_DIFF          , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_T_DIFF         , DEF_REG_DAC_PREAMP_T_DIFF           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_M_DIFF         , DEF_REG_DAC_PREAMP_M_DIFF           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PRECOMP_DIFF          , DEF_REG_DAC_PRECOMP_DIFF            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_COMP_DIFF             , DEF_REG_DAC_COMP_DIFF               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_VFF_DIFF              , DEF_REG_DAC_VFF_DIFF                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_TH1_L_DIFF            , DEF_REG_DAC_TH1_L_DIFF              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_TH1_R_DIFF            , DEF_REG_DAC_TH1_R_DIFF              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_TH1_M_DIFF            , DEF_REG_DAC_TH1_M_DIFF              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_TH2_DIFF              , DEF_REG_DAC_TH2_DIFF                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_LCC_DIFF              , DEF_REG_DAC_LCC_DIFF                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_L_LIN          , DEF_REG_DAC_PREAMP_L_LIN            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_R_LIN          , DEF_REG_DAC_PREAMP_R_LIN            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_TL_LIN         , DEF_REG_DAC_PREAMP_TL_LIN           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_TR_LIN         , DEF_REG_DAC_PREAMP_TR_LIN           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_T_LIN          , DEF_REG_DAC_PREAMP_T_LIN            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_PREAMP_M_LIN          , DEF_REG_DAC_PREAMP_M_LIN            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_FC_LIN                , DEF_REG_DAC_FC_LIN                  , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_KRUM_CURR_LIN         , DEF_REG_DAC_KRUM_CURR_LIN           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_REF_KRUM_LIN          , DEF_REG_DAC_REF_KRUM_LIN            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_COMP_LIN              , DEF_REG_DAC_COMP_LIN                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_COMP_TA_LIN           , DEF_REG_DAC_COMP_TA_LIN             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_GDAC_L_LIN            , DEF_REG_DAC_GDAC_L_LIN              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_GDAC_R_LIN            , DEF_REG_DAC_GDAC_R_LIN              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_GDAC_M_LIN            , DEF_REG_DAC_GDAC_M_LIN              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_LDAC_LIN              , DEF_REG_DAC_LDAC_LIN                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_LEAKAGE_FEEDBACK          , DEF_REG_LEAKAGE_FEEDBACK            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_VOLTAGE_TRIM              , DEF_REG_VOLTAGE_TRIM                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOL_3               , DEF_REG_ENCORECOL_3                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOL_2               , DEF_REG_ENCORECOL_2                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOL_1               , DEF_REG_ENCORECOL_1                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOL_0               , DEF_REG_ENCORECOL_0                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOLUMNRESET_3       , DEF_REG_ENCORECOLUMNRESET_3         , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOLUMNRESET_2       , DEF_REG_ENCORECOLUMNRESET_2         , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOLUMNRESET_1       , DEF_REG_ENCORECOLUMNRESET_1         , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOLUMNRESET_0       , DEF_REG_ENCORECOLUMNRESET_0         , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_TRIGGERCONFIG             , DEF_REG_TRIGGERCONFIG               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_SELFTRIGGERCONFIG_1       , DEF_REG_SELFTRIGGERCONFIG_1         , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_SELFTRIGGERCONFIG_0       , DEF_REG_SELFTRIGGERCONFIG_0         , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_HITORPATTERNLUT           , DEF_REG_HITORPATTERNLUT             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_READTRIGGERCONFIG         , DEF_REG_READTRIGGERCONFIG           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_TRUNCATIONTIMEOUTCONF     , DEF_REG_TRUNCATIONTIMEOUTCONF       , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_CALIBRATIONCONFIG         , DEF_REG_CALIBRATIONCONFIG           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_CLK_DATA_FINE_DELAY       , DEF_REG_CLK_DATA_FINE_DELAY         , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_VCAL_HIGH                 , DEF_REG_VCAL_HIGH                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_VCAL_MED                  , DEF_REG_VCAL_MED                    , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_MEAS_CAP                  , DEF_REG_MEAS_CAP                    , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_CDRCONF                   , DEF_REG_CDRCONF                     , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_CHSYNCCONF                , DEF_REG_CHSYNCCONF                  , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_GLOBALPULSECONF           , DEF_REG_GLOBALPULSECONF             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_GLOBALPULSEWIDTH          , DEF_REG_GLOBALPULSEWIDTH            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_SERVICEDATACONF           , DEF_REG_SERVICEDATACONF             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_TOTCONFIG                 , DEF_REG_TOTCONFIG                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_PRECISIONTOTENABLE_3      , DEF_REG_PRECISIONTOTENABLE_3        , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_PRECISIONTOTENABLE_2      , DEF_REG_PRECISIONTOTENABLE_2        , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_PRECISIONTOTENABLE_1      , DEF_REG_PRECISIONTOTENABLE_1        , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_PRECISIONTOTENABLE_0      , DEF_REG_PRECISIONTOTENABLE_0        , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DATAMERGING               , DEF_REG_DATAMERGING                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DATAMERGINGMUX            , DEF_REG_DATAMERGINGMUX              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOLUMNCALIBRATION_3 , DEF_REG_ENCORECOLUMNCALIBRATION_3   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOLUMNCALIBRATION_2 , DEF_REG_ENCORECOLUMNCALIBRATION_2   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOLUMNCALIBRATION_1 , DEF_REG_ENCORECOLUMNCALIBRATION_1   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ENCORECOLUMNCALIBRATION_0 , DEF_REG_ENCORECOLUMNCALIBRATION_0   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DATACONCENTRATORCONF      , DEF_REG_DATACONCENTRATORCONF        , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_CORECOLENCODERCONF        , DEF_REG_CORECOLENCODERCONF          , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_EVENMASK                  , DEF_REG_EVENMASK                    , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ODDMASK                   , DEF_REG_ODDMASK                     , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_EFUSESCONFIG              , DEF_REG_EFUSESCONFIG                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_EFUSESWRITEDATA1          , DEF_REG_EFUSESWRITEDATA1            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_EFUSESWRITEDATA0          , DEF_REG_EFUSESWRITEDATA0            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AURORACONFIG              , DEF_REG_AURORACONFIG                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AURORA_CB_CONFIG1         , DEF_REG_AURORA_CB_CONFIG1           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AURORA_CB_CONFIG0         , DEF_REG_AURORA_CB_CONFIG0           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AURORA_INIT_WAIT          , DEF_REG_AURORA_INIT_WAIT            , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_OUTPUT_PAD_CONFIG         , DEF_REG_OUTPUT_PAD_CONFIG           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_GP_CMOS_ROUTE             , DEF_REG_GP_CMOS_ROUTE               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_GP_LVDS_ROUTE_1           , DEF_REG_GP_LVDS_ROUTE_1             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_GP_LVDS_ROUTE_0           , DEF_REG_GP_LVDS_ROUTE_0             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_CP_CDR                , DEF_REG_DAC_CP_CDR                  , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_CP_FD_CDR             , DEF_REG_DAC_CP_FD_CDR               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_CP_BUFF_CDR           , DEF_REG_DAC_CP_BUFF_CDR             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_VCO_CDR               , DEF_REG_DAC_VCO_CDR                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_VCOBUFF_CDR           , DEF_REG_DAC_VCOBUFF_CDR             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_SER_SEL_OUT               , DEF_REG_SER_SEL_OUT                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_CML_CONFIG                , DEF_REG_CML_CONFIG                  , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_CML_BIAS_2            , DEF_REG_DAC_CML_BIAS_2              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_CML_BIAS_1            , DEF_REG_DAC_CML_BIAS_1              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_CML_BIAS_0            , DEF_REG_DAC_CML_BIAS_0              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_MONITORCONFIG             , DEF_REG_MONITORCONFIG               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_ERRWNGMASK                , DEF_REG_ERRWNGMASK                  , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_MON_SENS_SLDO             , DEF_REG_MON_SENS_SLDO               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_MON_SENS_ACB              , DEF_REG_MON_SENS_ACB                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_MON_ADC                   , DEF_REG_MON_ADC                     , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_DAC_NTC                   , DEF_REG_DAC_NTC                     , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_HITOR_MASK_3              , DEF_REG_HITOR_MASK_3                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_HITOR_MASK_2              , DEF_REG_HITOR_MASK_2                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_HITOR_MASK_1              , DEF_REG_HITOR_MASK_1                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_HITOR_MASK_0              , DEF_REG_HITOR_MASK_0                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AUTOREAD0                 , DEF_REG_AUTOREAD0                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AUTOREAD1                 , DEF_REG_AUTOREAD1                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AUTOREAD2                 , DEF_REG_AUTOREAD2                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AUTOREAD3                 , DEF_REG_AUTOREAD3                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AUTOREAD4                 , DEF_REG_AUTOREAD4                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AUTOREAD5                 , DEF_REG_AUTOREAD5                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AUTOREAD6                 , DEF_REG_AUTOREAD6                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AUTOREAD7                 , DEF_REG_AUTOREAD7                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_RINGOSCCONFIG             , DEF_REG_RINGOSCCONFIG               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_RINGOSCROUTE              , DEF_REG_RINGOSCROUTE                , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_RING_OSC_A_OUT            , DEF_REG_RING_OSC_A_OUT              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_RING_OSC_B_OUT            , DEF_REG_RING_OSC_B_OUT              , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_BCIDCNT                   , DEF_REG_BCIDCNT                     , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_TRIGCNT                   , DEF_REG_TRIGCNT                     , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_READTRIGCNT               , DEF_REG_READTRIGCNT                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_LOCKLOSSCNT               , DEF_REG_LOCKLOSSCNT                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_BITFLIPWNGCNT             , DEF_REG_BITFLIPWNGCNT               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_BITFLIPERRCNT             , DEF_REG_BITFLIPERRCNT               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_CMDERRCNT                 , DEF_REG_CMDERRCNT                   , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_RDWRFIFOERRORCOUNT        , DEF_REG_RDWRFIFOERRORCOUNT          , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_AI_REGION_ROW             , DEF_REG_AI_REGION_ROW               , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_HITOR_3_CNT               , DEF_REG_HITOR_3_CNT                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_HITOR_2_CNT               , DEF_REG_HITOR_2_CNT                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_HITOR_1_CNT               , DEF_REG_HITOR_1_CNT                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_HITOR_0_CNT               , DEF_REG_HITOR_0_CNT                 , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_SKIPPEDTRIGGERCNT         , DEF_REG_SKIPPEDTRIGGERCNT           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_EFUSESREADDATA1           , DEF_REG_EFUSESREADDATA1             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_EFUSESREADDATA0           , DEF_REG_EFUSESREADDATA0             , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
            cmd_rd_reg_test (clk,  chip_id, ADR_REG_MONITORINGDATAADC         , DEF_REG_MONITORINGDATAADC           , tx_data, tx_data_dv, yarr_rx_rdreg_dv, exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        end if;

        ------------------------------------------------------------------------
        -- Trigger command
        -- Trigger pattern 000T with tagbase 5 
        ------------------------------------------------------------------------
        cmd_trigger(clk, TRIG_TTTT , 5, tx_data, tx_data_dv);
        cmd_trigger(clk, TRIG_000T , 0, tx_data, tx_data_dv);
        wait for 5 us;
        cpu_print_msg("Command trigger done");


        ------------------------------------------------------------------------
        -- Set AUTOREAD0 reg in chip 3 to read TRIGGERCONFIG (address 47, 0x2F) value 0x1F4
        ------------------------------------------------------------------------
        v_reg_data := std_logic_vector(to_unsigned(ADR_REG_TRIGGERCONFIG,16));
        cmd_wr_reg      (clk,  chip_id, ADR_REG_AUTOREAD0, v_reg_data,  tx_data, tx_data_dv);   -- Set autoread0 to read trigger config reg
        arr_config_reg(ADR_REG_AUTOREAD0)   <=  v_reg_data;                                     -- Update mirror
        clk_delay(clk, 1);

        -- Update expected data from autoread0
        v_ptr_autoreads(0)      := to_integer(unsigned(arr_config_reg(ADR_REG_AUTOREAD0)));     -- New pointer content of the AUTOREAD0 control reg
        exp_autoread(0).addr    <= arr_config_reg(ADR_REG_AUTOREAD0)( 9 downto 0);              -- The returned register address should be the pointer value.
        exp_autoread(0).data    <= arr_config_reg(v_ptr_autoreads(0));
        clk_delay(clk, 1);

        -- Enable autoread checking for a few read cycles
        wait for 5 us;
        enable_check_autoread   <= '1';
        wait for 10 us;
        enable_check_autoread   <= '0';

        ------------------------------------------------------------------------
        -- Read register (reg should return default value of 0x01F4
        -- (Old method of sending a read command and setting the expected reply 
        -- data with two separate functions. Now done with cmd_rd_reg_test()
        ------------------------------------------------------------------------
        -- Send command
        --cmd_rd_reg      (clk,  chip_id, ADR_REG_TRIGGERCONFIG, tx_data, tx_data_dv);    -- Read trigger config register
        -- Set expected readback value
        --set_rd_reg_exp  (clk,  ADR_REG_TRIGGERCONFIG, X"01F4", exp_rdreg.addr, exp_rdreg.data, exp_rdreg_dv);
        --wait for 3 us;


        wait for 100 us;
        sim_done    <= true;
        cpu_print_msg(" ");
        cpu_print_msg("--------------------------------");
        cpu_print_msg("--      SIMULATION DONE       --");
        cpu_print_msg("--------------------------------");
        cpu_print_msg(" ");
        wait;

    end process;


    ------------------------------------------------------------------------
    -- Check output hit data against expected values from ROM package
    -- Four ROM values are used on every output. The ROM value address pointer
    -- wraps back to zero.
    ------------------------------------------------------------------------
    pr_check_hitdata : process (reset, clk)
    begin
        if (reset = '1') then
            rx_hit_error  <= '1';
            cnt_rx_data   <= 0;

        elsif falling_edge(clk) then

            if (yarr_rx_hitdata_dv = '1') then

                check_hitdata( clk, yarr_rx_hitdata_dv, yarr_rx_hitdata0, C_ARR_HITDATA_EXP(cnt_rx_data    ), check_hitdata_fails(0));
                check_hitdata( clk, yarr_rx_hitdata_dv, yarr_rx_hitdata1, C_ARR_HITDATA_EXP(cnt_rx_data + 1), check_hitdata_fails(1));
                check_hitdata( clk, yarr_rx_hitdata_dv, yarr_rx_hitdata2, C_ARR_HITDATA_EXP(cnt_rx_data + 2), check_hitdata_fails(2));
                check_hitdata( clk, yarr_rx_hitdata_dv, yarr_rx_hitdata3, C_ARR_HITDATA_EXP(cnt_rx_data + 3), check_hitdata_fails(3));

                if (cnt_rx_data < 124) then
                    cnt_rx_data     <= cnt_rx_data + 4;
                end if;

            end if;

            rx_hit_error    <=  check_hitdata_fails(0) or check_hitdata_fails(1) or check_hitdata_fails(2) or check_hitdata_fails(3);
        end if;

    end process;


    ------------------------------------------------------------------------
    -- Check commanded reg reads against expected values
    ------------------------------------------------------------------------
    pr_check_rdreg : process (reset, clk)
    begin
        if (reset = '1') then

            err_rdreg_data    <= '0';
            err_rdreg_addr    <= '0';

        elsif falling_edge(clk) then

            if (yarr_rx_rdreg_dv = '1') then

                if (yarr_rx_rdreg.addr /= exp_rdreg.addr) then
                    err_rdreg_addr    <= '1';
                    cpu_print_msg("FAIL ADDR RDREG        *****");
                else
                    err_rdreg_addr    <= '0';
                    cpu_print_msg("PASS RDREG ADDR");
                end if;

                if (yarr_rx_rdreg.data /= exp_rdreg.data) then
                    cpu_print_msg("FAIL DATA RDREG        *****");
                    err_rdreg_data    <= '1';
                else
                    err_rdreg_data    <= '0';
                    cpu_print_msg("PASS RDREG DATA");
                end if;

            end if;

        end if;

    end process;


    ------------------------------------------------------------------------
    -- Check autoread data and addresess against expected values
    ------------------------------------------------------------------------
    pr_check_autoread : process (reset, clk)
    begin
        if (reset = '1') then

            err_autoread_data  <= (others=>'0');
            err_autoread_addr  <= (others=>'0');

        elsif falling_edge(clk) then

            if (yarr_rx_autoread_dv = '1' and enable_check_autoread = '1') then

                for I in 0 to 7 loop

                    if (yarr_rx_autoread(I).addr /= exp_autoread(I).addr) then
                        err_autoread_addr(I) <= '1';
                        cpu_print_msg("FAIL ADDR AUTOREAD     *****");
                    else
                        err_autoread_addr(I) <= '0';
                        cpu_print_msg("PASS ADDR AUTOREAD");
                    end if;


                    if (yarr_rx_autoread(I).data /= exp_autoread(I).data) then
                        cpu_print_msg("FAIL DATA AUTOREAD     *****");
                        err_autoread_data(I) <= '1';
                    else
                        err_autoread_data(I) <= '0';
                        cpu_print_msg("PASS DATA AUTOREAD");
                    end if;
                end loop;

            end if;

        end if;

    end process;

end rtl;


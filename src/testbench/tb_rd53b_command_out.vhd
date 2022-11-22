-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Simple testbench for RD53B emulator sub-block
--
--
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;

entity tb_rd53b_command_out is
end tb_rd53b_command_out;

architecture rtl of tb_rd53b_command_out is

-- Clock freq expressed in MHz
constant CLK_FREQ_160MHZ    : real      := 160.00;
constant CLK_FREQ_80MHZ     : real      := 80.00;

-- Clock periods
constant CLK_PER_160MHZ     : time      := integer(1.0E+6/(CLK_FREQ_160MHZ)) * 1 ps;
constant CLK_PER_80MHZ      : time      := integer(1.0E+6/(CLK_FREQ_80MHZ)) * 1 ps;


signal clk160               : std_logic := '0';
signal clk80                : std_logic := '0';
signal sim_done             : boolean   := false;

type   t_state_hit is (
        S_IDLE  ,   -- Wait for trigger
        S_RUN       -- Send out burst data when 'next_hit' is high
);
signal state_hit            : t_state_hit;
signal trigger              : std_logic := '0';
signal cnt_burst            : unsigned(7 downto 0)  := (others=>0);
constant C_SIZE_BURST       : integer := 8;



-------------------------------------------------------------------------------
-- FPGA port signals
-------------------------------------------------------------------------------
signal reset                : std_logic := '1';
signal clk80                : std_logic := '0';            -- Used only to write adxin and cmdin to FIFOs
signal clk160               : std_logic := '0';            -- Used for all internal logic and output signals

-- Auto read address and data. Each consists of a 10-bit register address and 16-bit register value
type t_arr_auto_read is array (7 downto 0) of std_logic_vector(25 downto 0);
signal auto_read            : t_arr_autoread;

-- Hit generator interface
signal hitdata_empty        : std_logic := '0';                 -- High when no data available
signal next_hit             : std_logic;
signal hitdata_in           : std_logic_vector(63 downto 0) := (others=>'0');

-- Data from commanded register reads
signal cmdin_dv             : std_logic := '0';                 -- was wr_cmd,
signal cmdin                : std_logic_vector(15 downto 0) := (others=>'0');
signal cmd_full             : std_logic;                        -- FIFO status

-- Addresses of commanded register reads
signal adxin_dv             : std_logic := '0';                 -- Was wr_adx,
signal adxin                : std_logic_vector( 8 downto 0) := (others=>'0');
signal adx_full             : std_logic;                        -- FIFO status

-- Output frames
signal data_out             : std_logic_vector(63 downto 0);
signal data_out_valid       : std_logic;
signal data_out_service     : std_logic;                        -- Was service_frame,



-------------------------------------------------------------
-- Delay
-------------------------------------------------------------
procedure clk_delay(
    constant nclks  : in  integer
) is
begin
    for I in 0 to nclks loop
        wait until clk'event and clk ='0';
    end loop;
end;


----------------------------------------------------------------
-- Print a string with no time or instance path.
----------------------------------------------------------------
procedure cpu_print_msg(
    constant msg    : in    string
) is
variable line_out   : line;
begin
    write(line_out, msg);
    writeline(output, line_out);
end procedure cpu_print_msg;


-------------------------------------------------------------
-- Procedure to drive results of a register read command
-------------------------------------------------------------
procedure cmd_reg_read(

    signal   clk        : in  std_logic;

    -- Address and data of commanded register reads
    constant addr       : in  integer;
    constant data       : in  std_logic_vector(15 downto 0);

    signal   cmdin_dv   : in  std_logic := '0';
    signal   cmdin      : in  std_logic_vector(15 downto 0);

    signal   adxin_dv   : in  std_logic; 
    signal   adxin      : in  std_logic_vector( 8 downto 0)
) is
begin

    wait until clk'event and clk='0';
    cmdin       <= data;
    cmdin_dv    <= '1';
    adxin       <= std_logic_vector(to_unsigned(addr, 9));
    adxin_dv    <= '1';

    wait until clk'event and clk='0';
    cmdin       <= (others=>'0');
    cmdin_dv    <= '0';
    adxin       <= (others=>'0');
    adxin_dv    <= '0';

end;

-------------------------------------------------------------
-- Procedure to drive results of a register read command
-------------------------------------------------------------
procedure hit_trigger(

    signal   clk            : in  std_logic;
    constant burst_length   : in  integer;
    signal   trigger        : out std_logic
    signal   burst_size     : out unsigned(7 downto 0)
) is
begin

    wait until clk'event and clk='0';
    if (burst_length < 1) then
        burst_size  <= X"00";
        trigger     <= '1';
        cpu_print_msg("No trigger, burst length < 1");

    if (burst_length < 257) then
        burst_size  <= to_unsigned(burst_length-1, 8);
        trigger     <= '1';
        cpu_print_msg("Trigger");
    else
        burst_size  <= X"FF";
        cpu_print_msg("Trigger, burst length limited to 256");
    end if;

    wait until clk'event and clk='0';
    trigger     <= '0';

end;

begin



    -------------------------------------------------------------
    -- FPGA
    -------------------------------------------------------------
    u_command_out : entity work.command_out
    port map
    (
        rst                => rst               ,   -- in  std_logic;
        clk80              => clk80             ,   -- in  std_logic;            -- Used only to write adxin and cmdin to FIFOs
        clk160             => clk160            ,   -- in  std_logic;            -- Used for all internal logic and output signals

        -- Auto read address and data. Each consists of a 10-bit register address and 16-bit register value
        auto_read         => auto_read          ,   -- in  std_logic_vector[7:0][25:0]

        -- Hit generator interface
        hitdata_empty     => hitdata_empty      ,   -- in  std_logic;   -- High when no data available
        next_hit          => next_hit           ,   -- out std_logic;
        hitdata_in        => hitdata_in         ,   -- in  std_logic_vector(63 downto 0);   -- FIFO data read at 160 MHz

        -- Data from commanded register reads
        cmdin_dv          => cmdin_dv           ,   -- in std_logic;                 ,   -- was wr_cmd,
        cmdin             => cmdin              ,   -- in  std_logic_vector(15 downto 0);
        cmd_full          => cmd_full           ,   -- out std_logic;                 ,   -- FIFO status

        -- Addresses of commanded register reads
        adxin_dv          => adxin_dv           ,   -- in  std_logic;             -- Was wr_adx,
        adxin             => adxin              ,   -- in  std_logic_vector( 8 downto 0);
        adx_full          => adx_full           ,   -- out std_logic;             -- status

        -- Output frames
        data_out          => data_out           ,   -- out std_logic_vector(63 downto 0);
        data_out_valid    => data_out_valid     ,   -- out std_logic          ,
        data_out_service  => data_out_service       -- out std_logic              -- was service_frame,
    );


    -------------------------------------------------------------
    -- Generate clocks
    -------------------------------------------------------------
    pr_clk80 : process
    begin
        clk80   <= '0';
        wait for (CLK_PER_80MHZ/2);
        clk80  <= '1';
        wait for (CLK_PER_80MHZ-CLK_PER_80MHZ/2);
        if (sim_done=true) then
            wait;
        end if;
    end process;

    pr_clk160 : process
    begin
        clk160  <= '0';
        clk     <= '0';
        wait for (CLK_PER_160MHZ/2);
        clk160  <= '1';
        clk     <= '1';
        wait for (CLK_PER_160MHZ-CLK_PER_160MHZ/2);
        if (sim_done=true) then
            wait;
        end if;
    end process;


    -------------------------------------------------------------
    -- Process to generate  a burst of hit data
    -------------------------------------------------------------
    pr_hitdata : process (rst, clk160)
    begin
        if (rst = '1') then

            state_hit       <= S_IDLE;
            cnt_burst       <= (others=>'0');
            hitdata_empty   <= '1';
            hitdata_in      <= X"0000000000000000";

        elsif rising_edge(clk) then
            -- Default 
            hitdata_empty   <= '1';

            case state_tx  is

                ---------------------------------------------------
                -- Wait for trigger
                ---------------------------------------------------
                when S_IDLE     =>

                    if (trigger = '1') then
                        state_hit       <= S_RUN;
                        hitdata_empty   <= '0';
                    else
                        hitdata_empty   <= '1';
                    end if;

                    cnt_burst       <= (others=>'0');


                ---------------------------------------------------
                -- Send new data whenever next_data is high
                ---------------------------------------------------
                when S_RUN      =>

                    if (cnt_burst = burst_size) then
                        state_hit       <= S_IDLE;
                        cnt_burst       <= 0;
                        hitdata_empty   <= '1';

                    else

                        cnt_burst   <= cnt_burst + 1;
                        hitdata     <= X"BBEE55330022FF" & std_logic_vector(cnt_burst); 

                    end if;


                when others =>
                    state_hit   <= S_IDLE ;

            end case;


        end if;

    end process;


    -------------------------------------------------------------
    -- Main
    -------------------------------------------------------------
    pr_main : process
    begin

        -- Reset and drive starting values on all input signals
        rst                         <= '1';     -- Board testbench reset
        auto_read(0)                <= (others=>'0');
        auto_read(1)                <= (others=>'0');
        auto_read(2)                <= (others=>'0');
        auto_read(3)                <= (others=>'0');
        auto_read(4)                <= (others=>'0');
        auto_read(5)                <= (others=>'0');
        auto_read(6)                <= (others=>'0');
        auto_read(7)                <= (others=>'0');

        cmdin                       <= (others=>'0');
        cmdin_dv                    <= '0';

        adxin                       <= (others=>'0');
        adxin_dv                    <= '0';


        -- Set up autoread array      9-bit address, 16-bit data
        auto_read(0)                <= "011010001" & X"A001";   -- Address 0xD1, data 0xA0001
        auto_read(1)                <= "011010010" & X"A002";   -- Address 0xD2
        auto_read(2)                <= "011010011" & X"A003";   -- etc.
        auto_read(3)                <= "011010100" & X"A004";
        auto_read(4)                <= "011010101" & X"A005";
        auto_read(5)                <= "011010110" & X"A006";
        auto_read(6)                <= "011010111" & X"A007";
        auto_read(7)                <= "011011000" & X"A008";

        wait for 1 us;

        ------------------------------------------------------------------------
        -- Read 0x1234 from register address 1
        -- Read 0x5678 from register address 2
        ------------------------------------------------------------------------
        cmd_reg_read    (clk80,   1, X"1234", cmdin, cmdin_dv, adxin, adxin_dv);
        cmd_reg_read    (clk80,   2, X"5678", cmdin, cmdin_dv, adxin, adxin_dv);

        wait for 2 us;

        hit_trigger     (clk160,  8, trigger, burst_size);

        wait for 60 us;

        sim_done    <= true;
        wait;

    end process;


end rtl;


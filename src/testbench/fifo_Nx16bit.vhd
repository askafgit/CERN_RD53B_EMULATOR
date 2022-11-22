library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity fifo is
generic (G_DEPTH : integer := 16);  -- Depth of fifo
port (    
    reset       : in  std_logic;
    clk         : in  std_logic;

    wr          : in  std_logic;                        -- Write
    data_in     : in  std_logic_vector(15 downto 0);    -- Input data

    rd          : in  std_logic;                        -- Read
    data_out    : out std_logic_vector(15 downto 0);    -- Output data

    fifo_empty  : out std_logic;                        -- Set as '1' when the queue is empty
    fifo_full   : out std_logic                         -- Set as '1' when the queue is full
);
end fifo;

architecture behavioral of fifo is

type   t_memory is array (0 to G_DEPTH-1) of std_logic_vector(15 downto 0);
signal memory           : t_memory  := (others=>(others=>'0'));   -- FIFO data storage array

signal ptr_read         : integer   :=  0;      -- Read pointer.
signal ptr_write        : integer   :=  0;      -- Write pointer.
signal empty            : std_logic := '0';
signal full             : std_logic := '0';

begin

    fifo_empty  <= empty;
    fifo_full   <= full;

    -- First word fall-through
    data_out    <= memory(ptr_read);

    ------------------------------------------------------------------------
    -- All logic in one process
    ------------------------------------------------------------------------
    pr_fifo : process (reset, clk)

    variable v_num_elem : integer := 0;  -- Number of elements stored in fifo.  Used to decide whether the fifo is empty or full.

    begin

        if (reset = '1') then

            empty       <= '0';
            full        <= '0';
            ptr_read    <= 0;
            ptr_write   <= 0;
            v_num_elem  := 0;

        elsif (rising_edge(clk)) then

            -- Read
            if (rd = '1' and empty = '0') then
                if (ptr_read < G_DEPTH-1) then
                    ptr_read        <= ptr_read + 1;      
                else
                    ptr_read        <= 0;      
                end if;
                v_num_elem          := v_num_elem - 1;
            end if;

            -- Write
            if (wr ='1' and full = '0') then
                memory(ptr_write)   <= data_in;
                if (ptr_write < G_DEPTH-1) then
                    ptr_write       <= ptr_write + 1;  
                else
                    ptr_write       <= 0;      
                end if;
                v_num_elem          := v_num_elem + 1;
            end if;

            -- Set empty and full flags.
            if (v_num_elem = 0) then
                empty   <= '1';
            else
                empty   <= '0';
            end if;

            if (v_num_elem = G_DEPTH) then
                full    <= '1';
            else
                full    <= '0';
            end if;

        end if; 

    end process;

end behavioral;


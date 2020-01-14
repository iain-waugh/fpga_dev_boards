-------------------------------------------------------------------------------
--
-- Copyright (c) 2020 Iain Waugh
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : FPGA Dev Board Project
-- Author(s)     : Iain Waugh
-- File Name     : fifo_sync.vhd
--
-- First-Word Fall-Through (FWFT) synchronous FIFO with inferred RAM
-- Suitable for Xilinx, Altera/Intel or Lattice parts
--
-- If the 'empty' flag is low, data is immediately valid, unless the output is
-- registered, when it is ready on the next cycle.
-- 
-- If you read when the FIFO is 'empty', the you get a 'rd_error'.
-- If you write when the FIFO is 'full', the you get a 'wr_error' and the data
-- is lost.
--
-- If either 'wr_error" or 'rd_error' goes off, you need to reset the FIFO
-- because data will be corrupted.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity fifo_sync is
  generic(
    G_DATA_WIDTH : integer := 36;       -- Input / Output data width
    G_LOG2_DEPTH : integer := 9;        -- log2( Memory Depth )

    -- Leave this as "true" unless you have to have low latency
    G_REGISTER_OUT : boolean := true;

    -- RAM styles:
    -- Xilinx: "block", "distributed", "registers" or "uram"
    -- Altera: "logic", "M512", "M4K", "M9K", "M20K", "M144K", "MLAB", or "M-RAM"
    -- Lattice: "registers", "distributed" or "block_ram"
    G_RAM_STYLE : string := "block"
    );
  port(
    -- Clock and Reset signals
    clk : in std_logic;
    rst : in std_logic;

    -- Write ports
    i_data     : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    i_wr_en    : in  std_logic;
    o_full     : out std_logic;
    o_wr_error : out std_logic;

    -- Read ports
    o_empty    : out std_logic;
    i_rd_en    : in  std_logic;
    o_data     : out std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    o_dval     : out std_logic;
    o_rd_error : out std_logic
    );
end fifo_sync;

architecture fifo_sync_rtl of fifo_sync is

  type t_ram is array (natural range <>) of std_logic_vector(G_DATA_WIDTH-1 downto 0);
  signal ram : t_ram(0 to 2**G_LOG2_DEPTH - 1);

  -- Xilinx
  attribute ram_style        : string;
  attribute ram_style of ram : signal is G_RAM_STYLE;

  -- Altera, Lattice
  attribute syn_ramstyle        : string;
  attribute syn_ramstyle of ram : signal is G_RAM_STYLE;

  signal data_raw : std_logic_vector(G_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal data     : std_logic_vector(G_DATA_WIDTH - 1 downto 0) := (others => '0');

  signal wr_count : unsigned(G_LOG2_DEPTH - 1 downto 0) := (others => '0');
  signal rd_count : unsigned(G_LOG2_DEPTH - 1 downto 0) := (others => '0');

  -- Wrapped versions of signals
  signal rd_count_zero_extend : unsigned(G_LOG2_DEPTH downto 0) := (others => '0');
  signal wr_count_wrap        : unsigned(G_LOG2_DEPTH downto 0) := (others => '0');

  signal rd_wrapped : std_logic := '0';
  signal wr_wrapped : std_logic := '0';

  signal empty    : std_logic := '0';
  signal full     : std_logic := '0';
  signal rd_error : std_logic := '0';
  signal wr_error : std_logic := '0';

  signal rd_vld : std_logic := '0';
  signal dval   : std_logic := '0';

begin  -- fifo_sync_rtl

  ----------------------------------------------------------------------
  -- Infer the RAM; handle reads and writes
  u_ram_wr : process (clk)
  begin
    if (rising_edge(clk)) then
      if (i_wr_en = '1') then
        ram(to_integer(wr_count)) <= i_data;
      end if;
    end if;
  end process u_ram_wr;
  -- Use a "to_01" function to get rid of 'X'es when simulations start
  u_ram_rd : process (clk)
  begin
    if (rising_edge(clk)) then
      data_raw <= ram(to_integer(rd_count));
    end if;
  end process u_ram_rd;

  -- Create a read-valid signal
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        rd_vld <= '0';
      else
        rd_vld <= i_rd_en;
      end if;
    end if;
  end process;
  data <= to_01(data_raw);

  ----------------------------------------------------------------------
  -- Handle the counters
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        wr_count <= (others => '0');
        rd_count <= (others => '0');
      else
        if (i_rd_en = '1') then
          rd_count <= rd_count + 1;
        end if;
        if (i_wr_en = '1') then
          wr_count <= wr_count + 1;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------
  -- We need to know if the write pointer is ahead of the read pointer,
  -- even if it has wrapped around back to zero
  -- Assumption: Write and read will NEVER reach all ones at the same time
  wr_wrap_flag : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        rd_wrapped <= '0';
        wr_wrapped <= '0';
      else
        if (i_wr_en = '1' and wr_count = all_ones(wr_count)) then
          -- Write wrapped; it's still ahead of the read pointer
          rd_wrapped <= '0';
          wr_wrapped <= '1';
        elsif (i_rd_en = '1' and rd_count = all_ones(rd_count)) then
          -- Read wrapped, so read is a lower number than the write pointer
          rd_wrapped <= '1';
          wr_wrapped <= '0';
        end if;
      end if;
    end if;
  end process wr_wrap_flag;
  rd_count_zero_extend <= '0' & rd_count;
  wr_count_wrap        <= wr_wrapped & wr_count;

  -- Raise an error if my design assumption is wrong
  -- pragma synthesis_off
  assert not (rd_count = all_ones(rd_count) and wr_count = all_ones(wr_count))
    report "Error: The design assumes that 'rd_count' and 'wr_count' are never all 1's at the same time"
    severity error;
  -- pragma synthesis_on

  ----------------------------------------------------------------------
  -- Generate signal and error flags
  -- If rd_count = wr_count, the FIFO is empty
  -- If rd_count = wr_count + 1, the FIFO is full
  set_levels : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        empty    <= '1';
        full     <= '0';
        rd_error <= '0';
        wr_error <= '0';
      else
        -- The flags can only change if read/write are different
        if (i_rd_en /= i_wr_en) then
          -- Default values for signals
          full  <= '0';
          empty <= '0';

          if (i_rd_en = '1') then
            if (rd_count_zero_extend + 1 = wr_count_wrap) then
              empty <= '1';
            end if;
            if (rd_count_zero_extend = wr_count_wrap) then
              empty    <= '1';
              rd_error <= '1';
            end if;
          else
            -- i_rd_en /= i_wr_en, so i_wr_en must be '1'
            if (rd_count_zero_extend = wr_count + 3) then
              full <= '1';
            end if;
            if (rd_count_zero_extend = wr_count + 2) then
              full     <= '1';
              wr_error <= '1';
            end if;
          end if;
        end if;

      end if;
    end if;
  end process set_levels;

  ----------------------------------------------------------------------
  -- Either register the outputs or pass them straight through.
  -- Logic runs faster when registered, but there's a 1-cycle penalty.
  out_not_registered : if G_REGISTER_OUT = false generate
    o_data <= data;
    o_dval <= rd_vld;
  end generate out_not_registered;

  out_registered : if G_REGISTER_OUT = true generate
    u_reg_out : process (clk)
    begin
      if(rising_edge(clk)) then
        o_data <= data;
        o_dval <= rd_vld;
      end if;
    end process u_reg_out;
  end generate out_registered;

  -- Connect the signal flags to output pins
  o_full     <= full;
  o_wr_error <= wr_error;
  o_empty    <= empty;
  o_rd_error <= rd_error;

end fifo_sync_rtl;

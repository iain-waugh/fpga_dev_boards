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
-- First-Word Fall-Through (FWFT) synchronous FIFO with inferred RAM.
-- Suitable for Xilinx, Altera/Intel or Lattice parts.
--
-- Max fill depth is 2^G_LOG2_DEPTH - 1
--   So, if you've got a 16-deep FIFO, you can only store 15 entries.
--
-- If the 'empty' flag is low, data is immediately valid, unless the output is
--   registered, when it is ready on the next cycle.
-- 
-- If you read when the FIFO is 'empty', the you get a 'rd_error'.
-- If you write when the FIFO is 'full', the you get a 'wr_error' and the data
--   is lost.
--
-- If either 'wr_error" or 'rd_error' goes off, you need to reset the FIFO
--   before normal opertion can be guaranteed.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity fifo_sync is
  generic(
    G_DATA_WIDTH : integer := 16;       -- Input / Output data width
    G_LOG2_DEPTH : integer := 5;        -- log2( Memory Depth )

    -- Leave this as "true" unless you have to have low latency
    G_REGISTER_OUT : boolean := true;

    -- RAM styles:
    -- Xilinx: "block", "distributed", "registers" or "uram"
    -- Altera: "logic", "M512", "M4K", "M9K", "M20K", "M144K", "MLAB", or "M-RAM"
    -- Lattice: "registers", "distributed" or "block_ram"
    G_RAM_STYLE : string := "distributed"
    );
  port(
    -- Clock and Reset signals
    clk : in std_logic;
    rst : in std_logic;

    -- Write ports
    i_wr_en       : in  std_logic;
    i_data        : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    o_full        : out std_logic;
    o_almost_full : out std_logic;

    -- Read ports
    i_rd_en        : in  std_logic;
    o_data         : out std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    o_empty        : out std_logic;
    o_almost_empty : out std_logic;

    -- Error flags - stays high until reset
    o_wr_error : out std_logic;         -- High if you write when 'full' = '1'
    o_rd_error : out std_logic;         -- High if you read when 'empty' = '1'

    -- How far away from "full" or "empty"
    --   should the "almost full" and "almost empty" be?
    i_dist_from_full  : in unsigned(G_LOG2_DEPTH - 1 downto 0) := to_unsigned(1, G_LOG2_DEPTH);
    i_dist_from_empty : in unsigned(G_LOG2_DEPTH - 1 downto 0) := to_unsigned(1, G_LOG2_DEPTH);

    -- Optional simulation debug signal
    -- Setting this to '1' will report the max fill level to the console
    i_debug_dump : in std_logic := '0'
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

  signal data     : std_logic_vector(G_DATA_WIDTH - 1 downto 0) := (others => '0');

  signal wr_count   : unsigned(G_LOG2_DEPTH - 1 downto 0) := (others => '0');
  signal rd_count   : unsigned(G_LOG2_DEPTH - 1 downto 0) := (others => '0');
  signal fill_count : unsigned(G_LOG2_DEPTH - 1 downto 0) := (others => '0');

  constant C_MAX_FILL : unsigned(G_LOG2_DEPTH - 1 downto 0) := (others => '1');

  signal full         : std_logic := '0';
  signal empty        : std_logic := '0';
  signal almost_full  : std_logic := '0';
  signal almost_empty : std_logic := '0';

  signal rd_error : std_logic := '0';
  signal wr_error : std_logic := '0';

begin  -- fifo_sync_rtl

  ----------------------------------------------------------------------
  -- Infer the RAM; handle reads and writes
  u_ram_wr : process (clk)
  begin
    if rising_edge(clk) then
      if i_wr_en = '1' then
        ram(to_integer(wr_count)) <= i_data;
      end if;
    end if;
  end process u_ram_wr;
  u_ram_rd : process (clk)
  begin
    if rising_edge(clk) then
      data <= ram(to_integer(rd_count));
    end if;
  end process u_ram_rd;

  ----------------------------------------------------------------------
  -- Handle the counters
  rw_counters : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        wr_count <= (others => '0');
        rd_count <= (others => '0');
      else
        if i_rd_en = '1' then
          rd_count <= rd_count + 1;
        end if;
        if i_wr_en = '1' then
          wr_count <= wr_count + 1;
        end if;
      end if;
    end if;
  end process;

  -- Up/Down counter to tell how full the FIFO is
  fill_counter : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        fill_count <= (others => '0');
      elsif i_rd_en /= i_wr_en then
        if i_rd_en = '1' and empty = '0' then
          fill_count <= fill_count - 1;
        end if;
        if i_wr_en = '1' and full = '0' then
          fill_count <= fill_count + 1;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------------
  -- Generate signal and error flags
  set_flags : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        empty    <= '1';
        full     <= '0';
        rd_error <= '0';
        wr_error <= '0';
      elsif i_rd_en /= i_wr_en then
        -- The flags can only change if read/write are different
        full  <= '0';
        empty <= '0';

        if i_rd_en = '1' then
          if fill_count = 1 then
            empty <= '1';
          end if;
          if fill_count = 0 then
            empty    <= '1';
            rd_error <= '1';
          end if;
        else
          -- i_rd_en /= i_wr_en, so i_wr_en must be '1'
          if fill_count = to_unsigned(2**G_LOG2_DEPTH - 2, G_LOG2_DEPTH) then
            full <= '1';
          end if;
          if fill_count = to_unsigned(2**G_LOG2_DEPTH - 1, G_LOG2_DEPTH) then
            full     <= '1';
            wr_error <= '1';
          end if;
        end if;

      end if;
    end if;
  end process set_flags;

  ----------------------------------------------------------------------
  -- Generate signal and error flags
  -- Combinatorial because it needs to happen right away.
  -- It's either combinatorial, or it's a bunch of extra logic to precalculate,
  --   then check.
  set_almost_flags : process (fill_count, i_dist_from_empty, i_dist_from_full)
  begin
    -- The flags can only change if read/write are different
    if fill_count > i_dist_from_empty then
      almost_empty <= '0';
    else
      almost_empty <= '1';
    end if;

    if fill_count >= (C_MAX_FILL - i_dist_from_full) then
      almost_full <= '1';
    else
      almost_full <= '0';
    end if;
  end process set_almost_flags;
  o_almost_full  <= almost_full;
  o_almost_empty <= almost_empty;

  ----------------------------------------------------------------------
  -- Either register the outputs or pass them straight through.
  -- Logic runs faster when registered, but there's a 1-cycle penalty.
  out_not_registered : if G_REGISTER_OUT = false generate
    o_data <= data;
  end generate out_not_registered;

  out_registered : if G_REGISTER_OUT = true generate
    u_reg_out : process (clk)
    begin
      if rising_edge(clk) then
        o_data <= data;
      end if;
    end process u_reg_out;
  end generate out_registered;

  -- Connect the signal flags to output pins
  o_full     <= full;
  o_wr_error <= wr_error;
  o_empty    <= empty;
  o_rd_error <= rd_error;

  ----------------------------------------------------------------------
  -- Simulation-only debug code to print the max fill depth of the FIFO
  -- pragma translate_off
  ----------------------------------------------------------------------
  -- 
  process (clk)
    variable v_max_fill_count : unsigned(G_LOG2_DEPTH - 1 downto 0) := (others => '0');
  begin
    if rising_edge(clk) then
      if fill_count > v_max_fill_count then
        v_max_fill_count := fill_count;
      end if;

      if i_debug_dump = '1' then
        report "Max FIFO fill level was " & integer'image(to_integer(v_max_fill_count)) &
          " out of " & integer'image(2**G_LOG2_DEPTH - 1) severity note;
      end if;
    end if;
  end process;


  -- pragma translate_on

end fifo_sync_rtl;

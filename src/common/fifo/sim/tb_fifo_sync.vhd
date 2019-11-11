-------------------------------------------------------------------------------
--
-- Copyright (c) 2019 Iain Waugh
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : FPGA Dev Board Project
-- Author(s)     : Iain Waugh
-- File Name     : tb_fifo_sync.vhd
--
-- Testbench for a First-Word Fall-Through (FWFT) synchronous FIFO
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.clog2;

entity tb_fifo_sync is
end entity tb_fifo_sync;

architecture tb_fifo_sync_rtl of tb_fifo_sync is

  -- component generics
  constant G_DATA_WIDTH : integer := 8;
  constant G_LOG2_DEPTH : integer := 4;

  constant G_REGISTER_OUT : boolean := false;

  -- RAM styles:
  -- Xilinx: "block", "distributed", "registers" or "uram"
  -- Altera: "logic", "M512", "M4K", "M9K", "M20K", "M144K", "MLAB", or "M-RAM"
  -- Lattice: "registers", "distributed" or "block_ram"
  constant G_RAM_STYLE : string := "block";

  -- component ports
  -- Clock and Reset signals
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  -- Write ports
  signal i_data     : std_logic_vector(G_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal i_wr_en    : std_logic                                   := '0';
  signal o_full     : std_logic;
  signal o_wr_error : std_logic;

  -- Read ports
  signal o_empty    : std_logic;
  signal i_rd_en    : std_logic := '0';
  signal o_data     : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
  signal o_dval     : std_logic;
  signal o_rd_error : std_logic;

  signal fifo_rst : std_logic := '0';

  -- Stimulus counter
  constant C_COUNT_MAX : natural                                       := 126;
  signal count         : unsigned(clog2(C_COUNT_MAX - 1) - 1 downto 0) := (others => '0');
  signal data          : unsigned(clog2(C_COUNT_MAX - 1) - 1 downto 0) := (others => '0');

  -- Self-checking signals
  signal first_result : std_logic                           := '0';
  signal last_data    : unsigned(G_DATA_WIDTH - 1 downto 0) := (others => '0');

begin  -- architecture tb_fifo_sync_rtl

  -- component instantiation
  DUT : entity work.fifo_sync
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_LOG2_DEPTH => G_LOG2_DEPTH,

      G_REGISTER_OUT => G_REGISTER_OUT,

      -- RAM styles:
      -- Xilinx: "block" or "distributed"
      -- Altera: "logic", "M512", "M4K", "M9K", "M20K", "M144K", "MLAB", or "M-RAM"
      -- Lattice: "registers", "distributed" or "block_ram"
      G_RAM_STYLE => G_RAM_STYLE)
    port map (
      -- Clock and Reset signals
      clk => clk,
      rst => fifo_rst,

      -- Write ports
      i_data     => i_data,
      i_wr_en    => i_wr_en,
      o_full     => o_full,
      o_wr_error => o_wr_error,

      -- Read ports
      o_empty    => o_empty,
      i_rd_en    => i_rd_en,
      o_data     => o_data,
      o_dval     => o_dval,
      o_rd_error => o_rd_error);

  -------------------------------------------------------------------------------
  -- System clock generation
  clk_gen : process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process clk_gen;

  -----------------------------------------------------------------------------
  -- Reset generation
  rst_gen : process
  begin
    rst <= '1';
    wait for 30 ns;
    rst <= '0';
    wait;
  end process rst_gen;

  fifo_rst <= rst or o_wr_error or o_rd_error;

  ----------------------------------------------------------------------
  -- Counter
  --  constant C_COUNT_MAX : natural := 127;
  --  signal   count       : natural range 0 to C_COUNT_MAX;
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        count <= (others => '0');
      else
        if (count < C_COUNT_MAX) then
          count <= count + 1;
        else
          count <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        data <= (others => '0');
      else
        i_wr_en <= '0';
        if ((count(3) xor count(1)) = '1' and o_full = '0') then
          i_wr_en <= '1';
          if (data < C_COUNT_MAX) then
            data <= data + 1;
          else
            data <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        i_data <= (others => '1');
      else
        i_data <= std_logic_vector(resize(data, i_data'length));
      end if;
    end if;
  end process;
  i_rd_en <= (count(2) and not count(6)) when o_empty = '0'
             else '0';

  -- Check the results
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (fifo_rst = '1') then
        first_result <= '1';
      else
        if (i_rd_en = '1') then
          first_result <= '0';
          last_data    <= unsigned(o_data);
        end if;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (first_result = '0') then
        if (i_rd_en = '1') then
          if (last_data = C_COUNT_MAX) then
            assert unsigned(o_data) = 0
              report "Non-sequential data coming out" severity warning;
          else
            assert unsigned(o_data) = last_data + 1
              report "Non-sequential data coming out" severity warning;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture tb_fifo_sync_rtl;

-------------------------------------------------------------------------------

configuration tb_fifo_sync_rtl_cfg of tb_fifo_sync is
  for tb_fifo_sync_rtl
  end for;
end tb_fifo_sync_rtl_cfg;

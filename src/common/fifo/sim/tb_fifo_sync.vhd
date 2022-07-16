-------------------------------------------------------------------------------
--
-- Copyright (c) 2020 Iain Waugh
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : FPGA Dev Board Project
-- Author(s)     : Iain Waugh
-- File Name     : tb_fifo_sync.vhd
--
-- Self-checking testbench for a First-Word Fall-Through (FWFT) synchronous FIFO
--
-- Run it with "run -all".
-- It terminates by itself with a pass/fail message.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.num_bits;

entity tb_fifo_sync is
end entity tb_fifo_sync;

architecture tb_fifo_sync_rtl of tb_fifo_sync is

  -- component generics
  constant G_DATA_WIDTH : integer := 8;
  constant G_LOG2_DEPTH : integer := 3;

  constant G_REGISTER_OUT : boolean := false;

  -- RAM styles:
  -- Xilinx: "block", "distributed", "registers" or "uram"
  -- Altera: "logic", "M512", "M4K", "M9K", "M20K", "M144K", "MLAB", or "M-RAM"
  -- Lattice: "registers", "distributed" or "block_ram"
  constant G_RAM_STYLE : string := "distributed";

  -- component ports
  -- Clock and Reset signals
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  -- How far away from "full" or "empty"
  --   should the "almost full" and "almost empty" be?
  signal i_dist_from_full  : unsigned(G_LOG2_DEPTH - 1 downto 0);
  signal i_dist_from_empty : unsigned(G_LOG2_DEPTH - 1 downto 0);

  -- Write ports
  signal i_data        : std_logic_vector(G_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal i_wr_en       : std_logic                                   := '0';
  signal o_almost_full : std_logic;
  signal o_full        : std_logic;
  signal o_wr_error    : std_logic;

  -- Read ports
  signal o_almost_empty : std_logic;
  signal o_empty        : std_logic;
  signal i_rd_en        : std_logic := '0';
  signal o_data         : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
  signal o_rd_error     : std_logic;

  -- Self-checking signals
  signal first_result : std_logic                           := '0';
  signal last_data    : unsigned(G_DATA_WIDTH - 1 downto 0) := (others => '0');

  signal i_debug_dump : std_logic := '0';

  signal test_running : boolean := true;
  signal test_failed  : boolean := false;

begin  -- architecture tb_fifo_sync_rtl

  -- component instantiation
  DUT : entity work.fifo_sync
    generic map (
      G_DATA_WIDTH => G_DATA_WIDTH,
      G_LOG2_DEPTH => G_LOG2_DEPTH,

      -- Leave this as "true" unless you have to have low latency
      G_REGISTER_OUT => G_REGISTER_OUT,

      -- RAM styles:
      -- Xilinx: "block", "distributed", "registers" or "uram"
      -- Altera: "logic", "M512", "M4K", "M9K", "M20K", "M144K", "MLAB", or "M-RAM"
      -- Lattice: "registers", "distributed" or "block_ram"
      G_RAM_STYLE => G_RAM_STYLE)
    port map (
      -- Clock and Reset signals
      clk => clk,
      rst => rst,

      -- How far away from "full" or "empty"
      --   should the "almost full" and "almost empty" be?
      i_dist_from_full  => i_dist_from_full,
      i_dist_from_empty => i_dist_from_empty,

      -- Write ports
      i_data        => i_data,
      i_wr_en       => i_wr_en,
      o_almost_full => o_almost_full,
      o_full        => o_full,
      o_wr_error    => o_wr_error,

      -- Read ports
      o_almost_empty => o_almost_empty,
      o_empty        => o_empty,
      i_rd_en        => i_rd_en,
      o_data         => o_data,
      o_rd_error     => o_rd_error,

      i_debug_dump => i_debug_dump);

  -------------------------------------------------------------------------------
  -- System clock generation
  clk_gen : process
  begin
    if test_running then
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
    else
      wait;
    end if;
  end process clk_gen;

  u_test_sequence : process

    ----------------------------------------------------------------------
    -- Helper functions

    -- Procedute to wait for 'n' falling clock clock edges
    procedure wait_falling_clk(n : in natural := 1) is
    begin
      for i in 1 to n loop
        wait until falling_edge(clk);
      end loop;
    end procedure;

    -- Procedute to wait for 'n' rising clock edges
    procedure wait_rising_clk(n : in natural := 1) is
    begin
      for i in 1 to n loop
        wait until rising_edge(clk);
      end loop;
    end procedure;

    -- Procedure to perform a FIFO read
    procedure fifo_rd(
      expected    : in std_logic_vector(G_DATA_WIDTH - 1 downto 0);
      check       : in boolean := true;
      consecutive : in boolean := false
      ) is
      variable v_rd_data : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    begin
      i_rd_en   <= '1';
      wait_falling_clk(1);
      v_rd_data := o_data;
      if v_rd_data /= expected and check = true then
        report "FIFO read did not match the expected data." severity error;
        test_failed <= true;
      end if;
      if not consecutive then
        i_rd_en <= '0';
        wait_falling_clk(1);
      end if;
    end procedure;

    -- Procedure to perform a FIFO write
    procedure fifo_wr(
      data        : in std_logic_vector(G_DATA_WIDTH - 1 downto 0);
      consecutive : in boolean := false
      ) is
    begin
      i_wr_en <= '1';
      i_data  <= data;
      wait_falling_clk(1);
      if not consecutive then
        i_wr_en <= '0';
        i_data  <= (others => 'X');
        wait_falling_clk(1);
      end if;
    end procedure;

    -- Procedure to perform a simultaneous FIFO read and write
    procedure fifo_rw(
      data        : in std_logic_vector(G_DATA_WIDTH - 1 downto 0);
      expected    : in std_logic_vector(G_DATA_WIDTH - 1 downto 0);
      check       : in boolean := true;
      consecutive : in boolean := false
      ) is
      variable v_rd_data : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    begin
      i_wr_en   <= '1';
      i_data    <= data;
      i_rd_en   <= '1';
      wait_falling_clk(1);
      v_rd_data := o_data;
      if v_rd_data /= expected and check = true then
        report "FIFO read did not match the expected data." severity error;
        test_failed <= true;
      end if;
      if not consecutive then
        i_rd_en <= '0';
        i_wr_en <= '0';
        i_data  <= (others => 'X');
        wait_falling_clk(1);
      end if;
    end procedure;

    -- Procedure to perform a FIFO write
    procedure check_flags(
      empty        : in std_logic := '0';
      full         : in std_logic := '0';
      almost_empty : in std_logic := '0';
      almost_full  : in std_logic := '0'
      ) is
    begin
      if o_empty /= empty then
        report "Unexpected value for o_empty:" &
          " Expected " & std_logic'image(empty) &
          " got " & std_logic'image(o_empty) severity error;
        test_failed <= true;
      end if;

      if o_full /= full then
        report "Unexpected value for o_full:" &
          " Expected " & std_logic'image(full) &
          " got " & std_logic'image(o_full) severity error;
        test_failed <= true;
      end if;

      if o_almost_empty /= almost_empty then
        report "Unexpected value for o_almost_empty:" &
          " Expected " & std_logic'image(almost_empty) &
          " got " & std_logic'image(o_almost_empty) severity error;
        test_failed <= true;
      end if;

      if o_almost_full /= almost_full then
        report "Unexpected value for o_almost_full:" &
          " Expected " & std_logic'image(almost_full) &
          " got " & std_logic'image(o_almost_full) severity error;
        test_failed <= true;
      end if;

    end procedure check_flags;

    -- Procedure to perform a FIFO write
    procedure check_errors(
      rd_error : in std_logic := '0';
      wr_error : in std_logic := '0'
      ) is
    begin
      if o_rd_error /= rd_error then
        report "Unexpected value for o_rd_error:" &
          " Expected " & std_logic'image(rd_error) &
          " got " & std_logic'image(o_rd_error) severity error;
        test_failed <= true;
      end if;

      if o_wr_error /= wr_error then
        report "Unexpected value for o_wr_error:" &
          " Expected " & std_logic'image(wr_error) &
          " got " & std_logic'image(o_wr_error) severity error;
        test_failed <= true;
      end if;
    end procedure check_errors;

  begin

    -- Test sequence

    -- Set the almost full/empty distanec to 1.
    i_dist_from_full  <= to_unsigned(1, G_LOG2_DEPTH);
    i_dist_from_empty <= to_unsigned(1, G_LOG2_DEPTH);

    report "Apply the reset then check flags after it's de-asserted" severity note;
    rst <= '1';
    wait_rising_clk(3);
    rst <= '0';
    check_flags(empty     => '1', almost_empty => '1', almost_full => '0', full => '0');
    check_errors(rd_error => '0', wr_error => '0');
    wait_falling_clk(1);

    report "Write 1st word and check flags." severity note;
    fifo_wr(data => X"12");
    check_flags(empty     => '0', almost_empty => '1', almost_full => '0', full => '0');
    check_errors(rd_error => '0', wr_error => '0');

    report "Read back the 1st word and check flags." severity note;
    fifo_rd(expected => X"12");
    check_flags(empty     => '1', almost_empty => '1', almost_full => '0', full => '0');
    check_errors(rd_error => '0', wr_error => '0');

    report "Read an extra word to generate an error." severity note;
    fifo_rd(expected => X"12", check  => false);
    check_flags(empty     => '1', almost_empty => '1', almost_full => '0', full => '0');
    check_errors(rd_error => '1', wr_error => '0');

    report "Reset and check flags again." severity note;
    rst <= '1';
    wait_rising_clk(3);
    rst <= '0';
    check_flags(empty     => '1', almost_empty => '1', almost_full => '0', full => '0');
    check_errors(rd_error => '0', wr_error => '0');
    wait_falling_clk(1);

    report "Write 2 words and check flags." severity note;
    fifo_wr(data => X"34", consecutive => true);
    fifo_wr(data => X"56");
    check_flags(empty          => '0', almost_empty => '0', almost_full => '0', full => '0');
    check_errors(rd_error      => '0', wr_error => '0');

    report "Change distance from empty and re-test flags." severity note;
    i_dist_from_empty <= to_unsigned(2, G_LOG2_DEPTH);
    wait_falling_clk(1);
    check_flags(empty     => '0', almost_empty => '1', almost_full => '0', full => '0');
    check_errors(rd_error => '0', wr_error => '0');

    report "Write 3 words, read 2 check flags." severity note;
    fifo_wr(data => X"78", consecutive => true);
    fifo_wr(data => X"9A", consecutive => true);
    fifo_wr(data => X"BC");

    fifo_rd(expected => X"34", consecutive => true);
    fifo_rd(expected => X"56");
    check_flags(empty          => '0', almost_empty => '0', almost_full => '0', full => '0');
    check_errors(rd_error      => '0', wr_error => '0');

    report "Change distance from empty and re-test flags." severity note;
    i_dist_from_empty <= to_unsigned(3, G_LOG2_DEPTH);
    wait_falling_clk(1);
    check_flags(empty     => '0', almost_empty => '1', almost_full => '0', full => '0');
    check_errors(rd_error => '0', wr_error => '0');

    report "Dumping the max fill level.  It should say 5 out of 7." severity note;
    i_debug_dump <= '1';
    wait_falling_clk(1);
    i_debug_dump <= '0';
    wait_falling_clk(1);

    report "Write words until almost full and check flags." severity note;
    fifo_wr(data => X"DE", consecutive => true);
    fifo_wr(data => X"F0");
    check_flags(empty          => '0', almost_empty => '0', almost_full => '0', full => '0');
    fifo_wr(data => X"11");
    check_flags(empty          => '0', almost_empty => '0', almost_full => '1', full => '0');
    check_errors(rd_error      => '0', wr_error => '0');

    report "Write another word to become full and check flags." severity note;
    fifo_wr(data => X"22");
    check_flags(empty     => '0', almost_empty => '0', almost_full => '1', full => '1');
    check_errors(rd_error => '0', wr_error => '0');

    report "Write another word while full and check error flags." severity note;
    fifo_wr(data => X"33");
    check_flags(empty     => '0', almost_empty => '0', almost_full => '1', full => '1');
    check_errors(rd_error => '0', wr_error => '1');

    report "Dumping the max fill level.  It should say 7 out of 7." severity note;
    i_debug_dump <= '1';
    wait_falling_clk(1);
    i_debug_dump <= '0';
    wait_falling_clk(1);

    report "Apply the reset then check flags after it's de-asserted" severity note;
    rst <= '1';
    wait_rising_clk(3);
    rst <= '0';
    check_flags(empty     => '1', almost_empty => '1', almost_full => '0', full => '0');
    check_errors(rd_error => '0', wr_error => '0');
    wait_falling_clk(1);

    report "Fill the FIFO and check all values are read correctly." severity note;
    fifo_wr(data => X"F1", consecutive => true);
    fifo_wr(data => X"F2", consecutive => true);
    fifo_wr(data => X"F3", consecutive => true);
    fifo_wr(data => X"F4", consecutive => true);
    fifo_wr(data => X"F5", consecutive => true);
    fifo_wr(data => X"F6", consecutive => true);
    fifo_wr(data => X"F7");
    check_flags(empty          => '0', almost_empty => '0', almost_full => '1', full => '1');
    check_errors(rd_error      => '0', wr_error => '0');

    fifo_rd(expected => X"F1", consecutive => true);
    fifo_rd(expected => X"F2", consecutive => true);
    fifo_rd(expected => X"F3", consecutive => true);
    fifo_rd(expected => X"F4", consecutive => true);
    fifo_rd(expected => X"F5", consecutive => true);
    fifo_rd(expected => X"F6", consecutive => true);
    fifo_rw(data => X"F8", expected => X"F7");

    report "End of tests." severity note;
    if test_failed then
      report "Self-test failed." severity error;
    else
      report "Passed all tests." severity note;
    end if;

    test_running <= false;
    wait;
  end process;

end architecture tb_fifo_sync_rtl;

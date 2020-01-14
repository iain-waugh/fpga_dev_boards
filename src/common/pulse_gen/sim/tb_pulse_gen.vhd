-------------------------------------------------------------------------------
--
-- Copyright (c) 2020 Iain Waugh
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : Common Code
-- Author(s)     : Iain Waugh
-- File Name     : tb_pulse_gen.vhd
--
-- Top level testbench for the pulse generator
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pulse_gen is
end entity tb_pulse_gen;

architecture tb_pulse_gen_rtl of tb_pulse_gen is

  -- How many timers do you want?
  -- 1 = only 100ns
  -- 5 = 100ns, 1us, 10us, 100us, 1ms
  -- 8 = 100ns, 1us, 10us, 100us, 1ms, 10ms, 100ms, 1s
  constant G_POWERS_OF_100NS : natural := 5;

  -- Clock and Reset signals
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  signal o_pulse_at_100ns_x_10e : std_logic_vector(G_POWERS_OF_100NS - 1 downto 0);

  constant C_COUNT_MAX : natural := 127;
  signal count         : natural range 0 to C_COUNT_MAX;

begin  -- architecture tb_pulse_gen_rtl

  DUT : entity work.pulse_gen
    generic map (
      -- How many timers do you want?
      -- 1 = only 100ns
      -- 5 = 100ns, 1us, 10us, 100us, 1ms
      -- 8 = 100ns, 1us, 10us, 100us, 1ms, 10ms, 100ms, 1s
      G_POWERS_OF_100NS => G_POWERS_OF_100NS,

      -- How many clocks to make the 1st 100ns pulse?
      G_CLKS_IN_100NS => 10)
    port map (
      -- Clock and Reset signalses
      clk => clk,
      rst => rst,

      o_pulse_at_100ns_x_10e => o_pulse_at_100ns_x_10e);

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
    wait for 100 ns;
    rst <= '0';
    wait;
  end process rst_gen;

  ----------------------------------------------------------------------
  -- Counter
  --  constant C_COUNT_MAX : natural := 127;
  --  signal   count       : natural range 0 to C_COUNT_MAX;
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '0') then
        count <= 0;
      else
        if (count < C_COUNT_MAX) then
          count <= count + 1;
        else
          count <= 0;
        end if;
      end if;
    end if;
  end process;

end architecture tb_pulse_gen_rtl;

-------------------------------------------------------------------------------

configuration tb_pulse_gen_rtl_cfg of tb_pulse_gen is
  for tb_pulse_gen_rtl
  end for;
end tb_pulse_gen_rtl_cfg;


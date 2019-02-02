-------------------------------------------------------------------------------
--
-- Copyright (c) 2019 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : Common Code
-- Author(s)     : Iain Waugh
-- File Name     : debounce.vhd
--
-- Debounce a mechanical switch/button.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity debounce is
  generic (
    G_INVERT_OUTPUT : boolean := false
    );
  port(
    clk : in std_logic;

    i_button : in std_logic;
    i_pulse  : in std_logic;

    o_debounced : out std_logic
    );
end debounce;

architecture debounce_rtl of debounce is

  signal button_now  : std_logic := to_std_logic(G_INVERT_OUTPUT);
  signal button_last : std_logic := to_std_logic(G_INVERT_OUTPUT);

  constant C_MAX_COUNT : natural := 16;

  signal stable_count : unsigned(clog2(C_MAX_COUNT)-1 downto 0) := (others => '0');

begin  -- debounce_rtl

  -- Make a metastable-hardened version of the input that's safe to use
  button_sync : entity work.sync_sl
    port map (
      clk   => clk,
      i_sig => i_button,
      o_sig => button_now);

  ----------------------------------------------------------------------
  -- Note: No reset is used here
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (button_now = button_last) then
        stable_count <= (others => '0');
      else
        if (i_pulse = '1') then
          if (stable_count < C_MAX_COUNT) then
            stable_count <= stable_count + 1;
          else
            stable_count <= (others => '0');
            button_last  <= button_now;
          end if;
        end if;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (G_INVERT_OUTPUT = false) then
        o_debounced <= button_last;
      else
        o_debounced <= not button_last;
      end if;
    end if;
  end process;

end debounce_rtl;

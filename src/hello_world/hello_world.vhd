-------------------------------------------------------------------------------
--
-- Copyright (c) 2019 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : AX309 Project
-- Author(s)     : Iain Waugh
-- File Name     : hello_world.vhd
--
-- The most plain, simple LED blinker
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hello_world is
  port(
    -- Clock and Reset signals
    clk : in std_logic;

    i_pulse  : in  std_logic;
    o_toggle : out std_logic
    );
end hello_world;

architecture hello_world_rtl of hello_world is

  signal toggle : std_logic := '0';

begin  -- hello_world_rtl

  ----------------------------------------------------------------------
  -- 
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (i_pulse = '1') then
        toggle <= not toggle;
      end if;
    end if;
  end process;

  o_toggle <= toggle;

end hello_world_rtl;

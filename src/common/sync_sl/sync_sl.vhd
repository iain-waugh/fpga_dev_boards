-------------------------------------------------------------------------------
--
-- Copyright (c) 2017 Iain Waugh
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : Common Code
-- Author(s)     : Iain Waugh
-- File Name     : sync_sl.vhd
--
-- Metastable-hardening for one std_logic (sl) signal
-- Note: The ASYC_REG attribute is a placement attribute and it goes
--       on both FFs.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity sync_sl is
  port(
    clk : in std_logic;

    i_sig : in  std_logic;
    o_sig : out std_logic
    );
end sync_sl;

architecture sync_sl_rtl of sync_sl is

  signal sig_ss : std_logic := '0';     -- Semi-Synchronised (don't use this)
  signal sig    : std_logic := '0';

  -- Xilinx special attribute to pack 2x FFs right next to each other
  -- with minimal routing delay
  attribute ASYNC_REG           : string;
  attribute ASYNC_REG of sig_ss : signal is "TRUE";
  attribute ASYNC_REG of sig    : signal is "TRUE";

begin  -- debounce_rtl

  ----------------------------------------------------------------------
  -- Make a metastable-hardened version of the input that's safe to use
  process (clk)
  begin
    if (rising_edge(clk)) then
      sig_ss <= i_sig;
      sig    <= sig_ss;
    end if;
  end process;
  o_sig <= sig;

end sync_sl_rtl;

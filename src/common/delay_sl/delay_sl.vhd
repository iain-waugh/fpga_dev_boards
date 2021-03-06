-------------------------------------------------------------------------------
--
-- Copyright (c) 2017 Iain Waugh
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : Common Code
-- Author(s)     : Iain Waugh
-- File Name     : delay_sl.vhd
--
-- Inferring shift registers, with a register on the final stage.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity delay_sl is
  generic(
    G_DELAY : natural := 16
    );
  port(
    clk    : in  std_logic;
    en     : in  std_logic;
    i_data : in  std_logic;
    o_data : out std_logic
    );
end delay_sl;

architecture delay_sl_rtl of delay_sl is

begin

  -----------------------------------------------------------------------------
  -- No delay: Just connect the input to the output
  u_no_delay : if G_DELAY = 0 generate
    o_data <= i_data;
  end generate u_no_delay;

  -----------------------------------------------------------------------------
  -- 1 clock delay: Just register it once
  u_delay_1clk : if G_DELAY = 1 generate
    -- Define local signals
    signal data : std_logic;
  begin

    process (clk)
    begin
      if (rising_edge(clk)) then
        if (en = '1') then
          data <= i_data;
        end if;
      end if;
    end process;
    o_data <= data;

  end generate u_delay_1clk;

  -----------------------------------------------------------------------------
  -- n clock delays: All bits are in a shif-register except for
  --                 the last bit, which is registered
  u_delay_n_clks : if G_DELAY > 1 generate
    -- Define local signals
    type t_delay_line is array (1 to G_DELAY - 1) of std_logic;
    signal sreg : t_delay_line := (others => '0');
  begin  -- block

    process (clk)
    begin
      if (rising_edge(clk)) then
        if (en = '1') then
          sreg <= i_data & sreg(1 to sreg'high - 1);
        end if;
      end if;
    end process;

    -- Register the last bit for better fMax
    process (clk)
    begin
      if (rising_edge(clk)) then
        if (en = '1') then
          o_data <= sreg(sreg'high);
        end if;
      end if;
    end process;

  end generate u_delay_n_clks;

end delay_sl_rtl;

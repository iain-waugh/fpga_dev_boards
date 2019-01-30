-------------------------------------------------------------------------------
--
-- Copyright (c) 2019 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : AX309 Project
-- Author(s)     : Iain Waugh
-- File Name     : pulse_gen.vhd
--
-- Create a set of pulses that go off at intervals of 100ns, 1us, etc.
-- These can be used for timing elsewhere in the system.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.clog2;

entity pulse_gen is
  generic (
    -- How many timers do you want?
    -- 1 = only 100ns
    -- 5 = 100ns, 1us, 10us, 100us, 1ms
    -- 8 = 100ns, 1us, 10us, 100us, 1ms, 10ms, 100ms, 1s
    G_POWERS_OF_100NS : natural := 5;

    -- How many clocks cycles in the 1st 100ns pulse?
    G_CLKS_IN_100NS : natural := 2;

    -- Do you want the output pulses to be aligned with each-other?
    G_ALIGN_OUTPUTS : boolean := true
    );
  port(
    -- Clock and Reset signals
    clk : in std_logic;
    rst : in std_logic;

    o_pulse_at_100ns_x_10e : out std_logic_vector(G_POWERS_OF_100NS - 1 downto 0)
    );
end pulse_gen;

architecture pulse_gen of pulse_gen is

  subtype t_count_to_10 is unsigned(3 downto 0);
  type t_counters is array (1 to G_POWERS_OF_100NS - 1) of t_count_to_10;
  signal count_100ns : unsigned(clog2(G_CLKS_IN_100NS) - 1 downto 0);
  signal counter : t_counters := (others => (others => '0'));

  signal pulse : std_logic_vector(G_POWERS_OF_100NS - 1 downto 0) := (others => '0');

begin  -- pulse_gen

  ----------------------------------------------------------------------
  -- Assertion checking for valid settings
  assert (G_POWERS_OF_100NS >= 1)
    report "G_POWERS_OF_100NS must be 1 or higher" severity error;

  
  ----------------------------------------------------------------------
  -- Create the 100ns pulse
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        count_100ns <= (others => '0');
        pulse(0)   <= '0';

      else
        -- Set a default value for pulse(0)
        pulse(0) <= '0';

        if (count_100ns < G_CLKS_IN_100NS - 1) then
          count_100ns <= count_100ns + 1;
        else
          count_100ns <= (others => '0');
          pulse(0)   <= '1';
        end if;

      end if;
    end if;
  end process;

  
  ----------------------------------------------------------------------
  -- Create the rest of the pulses
  gen_powers : for i in 1 to G_POWERS_OF_100NS - 1 generate

    process (clk)
    begin
      if (rising_edge(clk)) then
        if (rst = '1') then
          counter(i) <= (others => '0');
          pulse(i)   <= '0';

        else
          -- Set a default value for pulse(i)
          pulse(i) <= '0';

          if (pulse(i-1) = '1') then
            if (counter(i) < 9) then
              counter(i) <= counter(i) + 1;
            else
              counter(i) <= (others => '0');
              pulse(i)   <= '1';
            end if;
          end if;

        end if;
      end if;
    end process;

  end generate;


  ----------------------------------------------------------------------
  -- Create delays or pass the signals straight out
  gen_delays : if (G_ALIGN_OUTPUTS = true) generate
    gen_loop : for i in 0 to G_POWERS_OF_100NS - 1 generate
      delay_sl : entity work.delay_sl
        generic map (
          G_DELAY => G_POWERS_OF_100NS - 1 - i)
        port map (
          clk    => clk,
          en     => '1',
          i_data => pulse(i),
          o_data => o_pulse_at_100ns_x_10e(i));
    end generate;
  end generate;

  gen_no_delays : if (G_ALIGN_OUTPUTS = false) generate
    o_pulse_at_100ns_x_10e <= pulse;
  end generate;

end pulse_gen;

-------------------------------------------------------------------------------
--
-- Copyright (c) 2019 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : FPGA Dev Board Project
-- Author(s)     : Iain Waugh
-- File Name     : clk_gen_s6.vhd
--
-- Spartan-6 Clock generation module.
-- This uses a simple interface that should be common across most FPGAs
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity clk_gen is
  generic (
    G_CLOCKS_USED : integer := 1;

    G_CLKFBOUT_MULT  : integer := 1;  -- Multiply value for all CLKOUT clock outputs (1-64)
    G_CLKFBOUT_PHASE : real    := 0.0;  -- Phase offset in degrees of the clock feedback output (0.0-360.0).
    G_CLKIN_PERIOD   : real    := 10.000;  -- Input clock period in ns to ps resolution (i.e. 33.333 is 30MHz).

    -- *_DIVIDE:     Divide amount for CLKOUT# clock output (1-128)
    -- *_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
    -- *_PHASE:      Output phase relationship for CLKOUT# clock output (-360.0-360.0).
    G_CLKOUT0_DIVIDE     : integer := 1;
    G_CLKOUT0_DUTY_CYCLE : real    := 0.5;
    G_CLKOUT0_PHASE      : real    := 0.0;
    --
    G_CLKOUT1_DIVIDE     : integer := 1;
    G_CLKOUT1_DUTY_CYCLE : real    := 0.5;
    G_CLKOUT1_PHASE      : real    := 0.0;
    --
    G_CLKOUT2_DIVIDE     : integer := 1;
    G_CLKOUT2_DUTY_CYCLE : real    := 0.5;
    G_CLKOUT2_PHASE      : real    := 0.0;
    --
    G_CLKOUT3_DIVIDE     : integer := 1;
    G_CLKOUT3_DUTY_CYCLE : real    := 0.5;
    G_CLKOUT3_PHASE      : real    := 0.0;
    --
    G_CLKOUT4_DIVIDE     : integer := 1;
    G_CLKOUT4_DUTY_CYCLE : real    := 0.5;
    G_CLKOUT4_PHASE      : real    := 0.0;
    --
    G_CLKOUT5_DIVIDE     : integer := 1;
    G_CLKOUT5_DUTY_CYCLE : real    := 0.5;
    G_CLKOUT5_PHASE      : real    := 0.0
    );
  port(
    -- Clock and Reset input signals
    clk : in std_logic;
    rst : in std_logic;

    -- Clock and reset output signals
    o_clk_0 : out std_logic;
    o_rst_0 : out std_logic;

    o_clk_1 : out std_logic;
    o_rst_1 : out std_logic;

    o_clk_2 : out std_logic;
    o_rst_2 : out std_logic;

    o_clk_3 : out std_logic;
    o_rst_3 : out std_logic;

    o_clk_4 : out std_logic;
    o_rst_4 : out std_logic;

    o_clk_5 : out std_logic;
    o_rst_5 : out std_logic
    );
end clk_gen;

architecture clk_gen_rtl of clk_gen is

  -- PLL system control signals
  signal clk_ibufg  : std_logic;
  signal clk_fb_out : std_logic;
  signal clk_fb_buf : std_logic;

  signal clk_int : std_logic_vector(5 downto 0);

  signal clk_bufg : std_logic_vector(G_CLOCKS_USED - 1 downto 0);
  signal clk_out  : std_logic_vector(5 downto 0) := (others => '0');
  signal rst_out  : std_logic_vector(5 downto 0) := (others => '1');

  signal locked_async : std_logic;
  signal locked       : std_logic;

begin  -- clk_gen_rtl

  -- Put an IBUFG on the input (because it comes from a pin)
  u_clk_in_ibufg : IBUFG
    port map (I => clk,
              O => clk_ibufg);

  u_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",     -- "HIGH", "LOW" or "OPTIMIZED"
      CLKFBOUT_MULT      => G_CLKFBOUT_MULT,  -- Multiply value for all CLKOUT clock outputs (1-64)
      CLKFBOUT_PHASE     => G_CLKFBOUT_PHASE,  -- Phase offset in degrees of the clock feedback output (0.0-360.0).
      CLKIN_PERIOD       => G_CLKIN_PERIOD,  -- Input clock period in ns to ps resolution (i.e. 33.333 is 30MHz).
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
      CLKOUT0_DIVIDE     => G_CLKOUT0_DIVIDE,
      CLKOUT1_DIVIDE     => G_CLKOUT1_DIVIDE,
      CLKOUT2_DIVIDE     => G_CLKOUT2_DIVIDE,
      CLKOUT3_DIVIDE     => G_CLKOUT3_DIVIDE,
      CLKOUT4_DIVIDE     => G_CLKOUT4_DIVIDE,
      CLKOUT5_DIVIDE     => G_CLKOUT5_DIVIDE,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => G_CLKOUT0_DUTY_CYCLE,
      CLKOUT1_DUTY_CYCLE => G_CLKOUT1_DUTY_CYCLE,
      CLKOUT2_DUTY_CYCLE => G_CLKOUT2_DUTY_CYCLE,
      CLKOUT3_DUTY_CYCLE => G_CLKOUT3_DUTY_CYCLE,
      CLKOUT4_DUTY_CYCLE => G_CLKOUT4_DUTY_CYCLE,
      CLKOUT5_DUTY_CYCLE => G_CLKOUT5_DUTY_CYCLE,
      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Output phase relationship for CLKOUT# clock output (-360.0-360.0).
      CLKOUT0_PHASE      => G_CLKOUT0_PHASE,
      CLKOUT1_PHASE      => G_CLKOUT1_PHASE,
      CLKOUT2_PHASE      => G_CLKOUT2_PHASE,
      CLKOUT3_PHASE      => G_CLKOUT3_PHASE,
      CLKOUT4_PHASE      => G_CLKOUT4_PHASE,
      CLKOUT5_PHASE      => G_CLKOUT5_PHASE,

      CLK_FEEDBACK          => "CLKFBOUT",  -- Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
      COMPENSATION          => "SYSTEM_SYNCHRONOUS",  -- "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL"
      DIVCLK_DIVIDE         => 1,  -- Division value for all output clocks (1-52)
      REF_JITTER            => 0.05,  -- Reference Clock Jitter in UI (0.000-0.999).
      RESET_ON_LOSS_OF_LOCK => false    -- Must be set to FALSE
      )
    port map (
      CLKFBIN  => clk_fb_buf,           -- 1-bit input: Feedback clock input
      CLKIN    => clk_ibufg,            -- 1-bit input: Clock input
      RST      => rst,                  -- 1-bit input: Reset input
      CLKFBOUT => clk_fb_out,   -- 1-bit output: PLL_BASE feedback output
      -- CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
      CLKOUT0  => clk_int(0),
      CLKOUT1  => clk_int(1),
      CLKOUT2  => clk_int(2),
      CLKOUT3  => clk_int(3),
      CLKOUT4  => clk_int(4),
      CLKOUT5  => clk_int(5),
      LOCKED   => locked_async  -- 1-bit asynchronous output: PLL_BASE lock status output
      );

  -- Put a BUFG on the clock feedback path
  u_clk_fb_bufg : BUFG
    port map (I => clk_fb_out,
              O => clk_fb_buf);


  -----------------------------------------------------------------------------
  -- Create clock outputs

  -- Put a global clock buffer on every output that we use
  clk_gen : for i in 0 to 5 generate
    -- Hook up the clocks that we use...
    u_clk_int_bufg_gen : if i < G_CLOCKS_USED generate
      u_clk_int_bufg : BUFG
        port map (I => clk_int(i),
                  O => clk_bufg(i));
      clk_out(i) <= clk_bufg(i);
    end generate u_clk_int_bufg_gen;

    -- ...and zero out the ones we don't
    u_no_clk_gen : if i >= G_CLOCKS_USED generate
      clk_out(i) <= '0';
    end generate u_no_clk_gen;
  end generate;


  -----------------------------------------------------------------------------
  -- Create reset outputs

  -- Synchronise the 'locked' signal to the clk0 domain and delay it
  -- by 16 cycles to give a bit of extra time to stabilise
  -- (it's an old habit, possibly not necessary)
  u_delay_locked : SRL16
    generic map (
      INIT => X"0000")
    port map (
      CLK => clk_bufg(0),
      A0  => '1',
      A1  => '1',
      A2  => '1',
      A3  => '1',
      D   => locked_async,
      Q   => locked
      );

  -- Generate reset outputs that are synchronous to their respective clock domains
  rst_gen : for i in 0 to 5 generate
    -- Hook up the resets that we use...
    u_rst_out_gen : if i < G_CLOCKS_USED generate
      sync_rst : entity work.sync_sl
        port map (
          clk   => clk_bufg(i),
          i_sig => "not"(locked),
          o_sig => rst_out(i));
    end generate;
    -- ...and zero out the ones we don't
    u_no_rst_gen : if i >= G_CLOCKS_USED generate
      rst_out(i) <= '1';
    end generate;
  end generate;


  -----------------------------------------------------------------------------
  -- Final output mappings

  o_clk_0 <= clk_out(0);
  o_clk_1 <= clk_out(1);
  o_clk_2 <= clk_out(2);
  o_clk_3 <= clk_out(3);
  o_clk_4 <= clk_out(4);
  o_clk_5 <= clk_out(5);

  o_rst_0 <= rst_out(0);
  o_rst_1 <= rst_out(1);
  o_rst_2 <= rst_out(2);
  o_rst_3 <= rst_out(3);
  o_rst_4 <= rst_out(4);
  o_rst_5 <= rst_out(5);

end clk_gen_rtl;

-------------------------------------------------------------------------------
--
-- Copyright (c) 2020 Iain Waugh
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : Zybo_z7
-- Author(s)     : Iain Waugh
-- File Name     : zybo_z7.vhd
--
-- Top level template for the Digilent Zybo Z7-10 and Z7-20 boards evaluation board.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity zybo_z7 is
  port(
    ----------------------------------------------------------------------------
    -- Clock Source - Bank xx
    clk_125MHz : in std_logic;          -- "SYSCLK"

    ----------------------------------------------------------------------------
    -- Audio Codec - Bank xx - Connects to SSM2603CPZ
    -- o_ac_bclk    : out   std_logic;
    -- o_ac_mclk    : out   std_logic;
    -- o_ac_muten   : out   std_logic;
    -- o_ac_pbdat   : out   std_logic;
    -- io_ac_pblrc  : inout std_logic;
    -- i_ac_recdat  : in    std_logic;
    -- io_ac_reclrc : inout std_logic;
    -- io_ac_scl    : inout std_logic;
    -- io_ac_sda    : inout std_logic;

    ----------------------------------------------------------------------------
    -- HDMI Output - Bank xx
    -- TMDS Pins
    -- o_hdmi_tx_clk_n : out   std_logic;
    -- o_hdmi_tx_clk_p : out   std_logic;
    -- o_hdmi_tx_n     : out   std_logic_vector(2 downto 0);
    -- o_hdmi_tx_p     : out   std_logic_vector(2 downto 0);
    -- Single-ended pins
    i_hdmi_tx_hpd   : in    std_logic;
    io_hdmi_tx_scl  : inout std_logic;
    io_hdmi_tx_sda  : inout std_logic;

    ----------------------------------------------------------------------------
    -- User LEDs - Bank xx
    o_led    : out std_logic_vector(3 downto 0);  -- "LED[3:0]"
    o_led5_r : out std_logic;
    o_led5_g : out std_logic;
    o_led5_b : out std_logic;
    o_led6_r : out std_logic;
    o_led6_g : out std_logic;
    o_led6_b : out std_logic;

    ----------------------------------------------------------------------------
    -- User Push Buttons - Bank xx
    i_btn : in std_logic_vector(3 downto 0);  -- "BTN[3:0]"

    ----------------------------------------------------------------------------
    -- User Toggle Switches - Bank 35
    i_sw : in std_logic_vector(3 downto 0)  -- "SW[3:0]"
    );
end zybo_z7;

architecture zybo_z7_rtl of zybo_z7 is

  signal clk_250mhz : std_logic := '0';
  signal rst_250mhz : std_logic := '1';

  -- Internal timing pulses
  -- 8 = 100ns, 1us, 10us, 100us, 1ms, 10ms, 100ms, 1s
  constant C_POWERS_OF_100NS  : natural := 8;
  signal pulse_at_100ns_x_10e : std_logic_vector(C_POWERS_OF_100NS - 1 downto 0);


  -- DVI/HDMI Signals
  constant C_MAX_SYNC  : natural := 200;
  constant C_MAX_PORCH : natural := 200;
  constant C_MAX_BLANK : natural := 200;

  constant C_MAX_SIZE_X : natural := 1920;
  constant C_MAX_SIZE_Y : natural := 1080;

  constant C_BITS_RED   : natural := 8;
  constant C_BITS_GREEN : natural := 8;
  constant C_BITS_BLUE  : natural := 8;

  signal pixel_clk        : std_logic := '0';
  signal frame_sync_ext   : std_logic := '0';
  signal frame_sync_local : std_logic := '0';

  signal pixel_in_ready : std_logic := '0';
  signal pixel_red      : unsigned(C_BITS_RED - 1 downto 0);
  signal pixel_green    : unsigned(C_BITS_GREEN - 1 downto 0);
  signal pixel_blue     : unsigned(C_BITS_BLUE - 1 downto 0);
  signal pixel_dval     : std_logic := '0';

  signal dvi_error : std_logic := '0';


  -- Tristate breakout signals
  signal i_audio_gpio   : std_logic_vector(3 downto 0);
  signal o_audio_gpio   : std_logic_vector(3 downto 0) := (others => '0');
  signal audio_gpio_out : std_logic                    := '0';

  signal i_audio_sda   : std_logic;
  signal o_audio_sda   : std_logic := '0';
  signal audio_sda_out : std_logic := '0';

  signal i_hdmi_tx_scl   : std_logic;
  signal o_hdmi_tx_scl   : std_logic := '0';
  signal hdmi_tx_scl_out : std_logic := '0';

  signal i_hdmi_tx_sda   : std_logic;
  signal o_hdmi_tx_sda   : std_logic := '0';
  signal hdmi_tx_sda_out : std_logic := '0';

  signal i_xadc_gio   : std_logic_vector(3 downto 0);
  signal o_xadc_gio   : std_logic_vector(3 downto 0) := (others => '0');
  signal xadc_gio_out : std_logic                    := '0';

  signal i_fmc_scl   : std_logic;
  signal o_fmc_scl   : std_logic := '0';
  signal fmc_scl_out : std_logic := '0';

  signal i_fmc_sda   : std_logic;
  signal o_fmc_sda   : std_logic := '0';
  signal fmc_sda_out : std_logic := '0';

  -- Other system signals
  signal led      : std_logic_vector(o_led'range) := (others => '0');
  signal rgb_led1 : std_logic_vector(2 downto 0)  := (others => '0');
  signal rgb_led2 : std_logic_vector(2 downto 0)  := (others => '0');

begin  -- zybo_z7_rtl

  ----------------------------------------------------------------------------
  -- Create system clocks and resets
  u_clk_gen : entity work.clk_gen
    generic map (
      G_CLOCKS_USED    => 2,
      G_CLKIN_PERIOD   => 8.0,          -- 8ns for a 125MHz clock
      G_CLKFBOUT_MULT  => 8,            -- 125MHz x 8 gets a 1GHz internal PLL
      G_CLKOUT0_DIVIDE => 4,            -- o_clk_0 = 1GHz / 4  = 250MHz
      G_CLKOUT1_DIVIDE => 20)           -- o_clk_0 = 1GHz / 20 = 50MHz
    port map (
      -- Clock and Reset input signals
      clk => clk_125MHz,
      rst => '0',  -- No reset input: Reset is determined by the PLL lock

      -- Clock and reset output signals
      o_clk_0 => clk_250mhz,
      o_rst_0 => rst_250mhz,

      o_clk_1 => pixel_clk,
      o_rst_1 => open,
      o_clk_2 => open,
      o_rst_2 => open,
      o_clk_3 => open,
      o_rst_3 => open,
      o_clk_4 => open,
      o_rst_4 => open,
      o_clk_5 => open,
      o_rst_5 => open);

  ----------------------------------------------------------------------------
  -- Connect 3x buttons to 3x LEDs
  key_0_debounce : entity work.debounce
    generic map (
      G_INVERT_OUTPUT => true)
    port map (
      clk         => clk_250MHz,
      i_button    => i_btn(0),
      i_pulse     => pulse_at_100ns_x_10e(3),
      o_debounced => led(0));

  key_1_debounce : entity work.debounce
    generic map (
      G_INVERT_OUTPUT => true)
    port map (
      clk         => clk_250MHz,
      i_button    => i_btn(1),
      i_pulse     => pulse_at_100ns_x_10e(3),
      o_debounced => led(1));

  key_2_debounce : entity work.debounce
    generic map (
      G_INVERT_OUTPUT => true)
    port map (
      clk         => clk_250MHz,
      i_button    => i_btn(2),
      i_pulse     => pulse_at_100ns_x_10e(3),
      o_debounced => led(2));

  key_3_debounce : entity work.debounce
    generic map (
      G_INVERT_OUTPUT => true)
    port map (
      clk         => clk_250MHz,
      i_button    => i_btn(3),
      i_pulse     => pulse_at_100ns_x_10e(3),
      o_debounced => led(3));

  o_led <= led;

  ----------------------------------------------------------------------------
  -- Make the "Hello  world" LED blink
  u_pulse_gen : entity work.pulse_gen
    generic map (
      -- How many timers do you want?
      G_POWERS_OF_100NS => C_POWERS_OF_100NS,

      -- How many clocks cycles in the 1st 100ns pulse?
      G_CLKS_IN_100NS => 25,            -- for a 100MHz clock

      -- Do you want the output pulses to be aligned with each-other?
      G_ALIGN_OUTPUTS => true)
    port map (
      -- Clock and Reset signals
      clk => clk_250mhz,
      rst => rst_250mhz,

      o_pulse_at_100ns_x_10e => pulse_at_100ns_x_10e);

  u_hello_world : entity work.hello_world
    port map (
      -- Clock and Reset signals
      clk => clk_250mhz,

      i_pulse  => pulse_at_100ns_x_10e(7),
      o_toggle => rgb_led1(0));
  rgb_led1(1) <= rgb_led1(0);
  rgb_led1(2) <= rgb_led1(0);
  o_led5_r    <= rgb_led1(0);
  o_led5_g    <= rgb_led1(1);
  o_led5_b    <= rgb_led1(2);

  ----------------------------------------------------------------------------
  -- Audio Codec - Bank xx - Connects to SSM2603CPZ
  -- TODO

  ----------------------------------------------------------------------------
  -- HDMI Output - Bank 33
  -- o_hdmi_tx_clk_n <= '1';
  -- o_hdmi_tx_clk_p <= '0';
  -- o_hdmi_tx_n     <= (others => '1');
  -- o_hdmi_tx_p     <= (others => '0');
  -- Single-ended pins
  rgb_led2(0)     <= i_hdmi_tx_hpd;
  rgb_led2(1)     <= i_hdmi_tx_hpd;
  rgb_led2(2)     <= i_hdmi_tx_hpd;
  o_led6_r        <= rgb_led2(0);
  o_led6_g        <= rgb_led2(1);
  o_led6_b        <= rgb_led2(2);

  i_hdmi_tx_scl  <= io_hdmi_tx_scl;
  io_hdmi_tx_scl <= o_hdmi_tx_scl when hdmi_tx_scl_out = '1' else 'Z';

  i_hdmi_tx_sda  <= io_hdmi_tx_sda;
  io_hdmi_tx_sda <= o_hdmi_tx_sda when hdmi_tx_sda_out = '1' else 'Z';

  ----------------------------------------------------------------------------
  -- DVI/HDMI Output - Bank 33
  frame_sync_ext <= '0';

  -- Generate a bit of dummy data for the DVI/HDMI output
  -- Note: Currently still in the pixel clk domain.
  --       This wil be updated when we add an asynchronous FIFO
  process (pixel_clk)
  begin
    if (rising_edge(pixel_clk)) then
      if (frame_sync_local = '1') then
        pixel_red   <= (others => '0');
        pixel_green <= (others => '0');
        pixel_blue  <= (others => '0');
      else
        if (pixel_in_ready = '1') then
          pixel_red <= pixel_red + 1;

          if (pixel_red = unsigned(all_ones(C_BITS_RED))) then
            pixel_green <= pixel_green + 1;

            if (pixel_green = unsigned(all_ones(C_BITS_GREEN))) then
              pixel_blue <= pixel_blue + 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  pixel_dval <= pixel_in_ready;

end zybo_z7_rtl;

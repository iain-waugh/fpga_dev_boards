-------------------------------------------------------------------------------
--
-- Copyright (c) 2018 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : Zedboard
-- Author(s)     : Iain Waugh
-- File Name     : zedboard.vhd
--
-- Top level template for the Avnet Zedboard Zynq 7020 evaluation board.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zedboard is
  port(
    ----------------------------------------------------------------------------
    -- Clock Source - Bank 13
    clk_100MHz : in std_logic;          -- "GCLK"

    ----------------------------------------------------------------------------
    -- Audio Codec - Bank 13 - Connects to ADAU1761BCPZ
    i_audio_adr0  : in    std_logic;                     -- "AC-ADR0"
    o_audio_adr1  : out   std_logic;                     -- "AC-ADR1"
    io_audio_gpio : inout std_logic_vector(3 downto 0);  -- "AC-GPIO[3:0]"
    o_audio_mclk  : out   std_logic;                     -- "AC-MCLK"
    o_audio_sck   : out   std_logic;                     -- "AC-SCK"
    io_audio_sda  : inout std_logic;                     -- "AC-SDA"

    ----------------------------------------------------------------------------
    -- OLED Display - Bank 13
    o_oled_dc   : out std_logic;        -- "OLED-DC"
    o_oled_res  : out std_logic;        -- "OLED-RES"
    o_oled_sclk : out std_logic;        -- "OLED-SCLK"
    o_oled_sdin : out std_logic;        -- "OLED-SDIN"
    o_oled_vbat : out std_logic;        -- "OLED-VBAT"
    o_oled_vdd  : out std_logic;        -- "OLED-VDD"

    ----------------------------------------------------------------------------
    -- HDMI Output - Bank 33
    o_hdmi_clk    : out   std_logic;                      -- "HD-CLK"
    o_hdmi_hsync  : out   std_logic;                      -- "HD-HSYNC"
    o_hdmi_vsync  : out   std_logic;                      -- "HD-VSYNC"
    o_hdmi_data   : out   std_logic_vector(15 downto 0);  -- "HD-D[15:0]"
    o_hdmi_dval   : out   std_logic;                      -- "HD-DE"
    o_hdmi_int    : out   std_logic;                      -- "HD-INT"
    io_hdmi_scl   : inout std_logic;                      -- "HD-SCL"
    io_hdmi_sda   : inout std_logic;                      -- "HD-SDA"
    o_hdmi_spdif  : out   std_logic;                      -- "HD-SPDIF"
    i_hdmi_spdifo : in    std_logic;                      -- "HD-SPDIFO"

    ----------------------------------------------------------------------------
    -- User LEDs - Bank 33
    o_led : out std_logic_vector(7 downto 0);  -- "LD[7:0]"

    ----------------------------------------------------------------------------
    -- VGA Output - Bank 33
    o_vga_hs    : out std_logic;             -- "VGA-HS"
    o_vga_vs    : out std_logic;             -- "VGA-VS"
    o_vga_red   : out unsigned(3 downto 0);  -- "VGA-R[3:0]"
    o_vga_green : out unsigned(3 downto 0);  -- "VGA-G[3:0]"
    o_vga_blue  : out unsigned(3 downto 0);  -- "VGA-B[3:0]"

    ----------------------------------------------------------------------------
    -- User Push Buttons - Bank 34
    i_btn_c : in std_logic;             -- "BTNC"
    i_btn_d : in std_logic;             -- "BTND"
    i_btn_l : in std_logic;             -- "BTNL"
    i_btn_r : in std_logic;             -- "BTNR"
    i_btn_u : in std_logic;             -- "BTNU"

    -- ----------------------------------------------------------------------------
    -- USB OTG Reset - Bank 34
    o_otg_vbusoc : out std_logic;       -- "OTG-VBUSOC"

    ----------------------------------------------------------------------------
    -- XADC GIO - Bank 34
    io_xadc_gio : inout std_logic_vector(3 downto 0);  -- "XADC-GIO[3:0]"

    ----------------------------------------------------------------------------
    -- Miscellaneous - Bank 34
    i_pudc_b : in std_logic;            -- "PUDC_B"

    ----------------------------------------------------------------------------
    -- USB OTG Reset - Bank 35
    o_otg_reset_n : out std_logic;      -- "OTG-RESETN"

    ----------------------------------------------------------------------------
    -- User DIP Switches - Bank 35
    i_sw : in std_logic_vector(7 downto 0);  -- "SW[7:0]"

    ----------------------------------------------------------------------------
    -- XADC AD Channels - Bank 35
    i_ad0n_r : in std_logic;            -- "XADC-AD0N-R"
    i_ad0p_r : in std_logic;            -- "XADC-AD0P-R"
    i_ad8n_n : in std_logic;            -- "XADC-AD8N-R"
    i_ad8p_r : in std_logic;            -- "XADC-AD8P-R"

    ----------------------------------------------------------------------------
    -- FMC Expansion Connector - Bank 13
    io_fmc_scl : inout std_logic;       -- "FMC-SCL"
    io_fmc_sda : inout std_logic;       -- "FMC-SDA"

    ----------------------------------------------------------------------------
    -- FMC Expansion Connector - Bank 33
    i_fmc_prsnt : in std_logic          -- "FMC-PRSNT"
    );
end zedboard;

architecture zedboard_rtl of zedboard is

  signal clk_250mhz : std_logic := '0';
  signal rst_250mhz : std_logic := '1';

  -- Internal timing pulses
  -- 8 = 100ns, 1us, 10us, 100us, 1ms, 10ms, 100ms, 1s
  constant C_POWERS_OF_100NS  : natural := 8;
  signal pulse_at_100ns_x_10e : std_logic_vector(C_POWERS_OF_100NS - 1 downto 0);

  -- Tristate breakout signals
  signal i_audio_gpio   : std_logic_vector(3 downto 0);
  signal o_audio_gpio   : std_logic_vector(3 downto 0) := (others => '0');
  signal audio_gpio_out : std_logic                    := '0';

  signal i_audio_sda   : std_logic;
  signal o_audio_sda   : std_logic := '0';
  signal audio_sda_out : std_logic := '0';

  signal i_hdmi_scl   : std_logic;
  signal o_hdmi_scl   : std_logic := '0';
  signal hdmi_scl_out : std_logic := '0';

  signal i_hdmi_sda   : std_logic;
  signal o_hdmi_sda   : std_logic := '0';
  signal hdmi_sda_out : std_logic := '0';

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
  -- TBD

begin  -- zedboard_rtl

  ----------------------------------------------------------------------------
  -- Create system clocks and resets
  u_clk_gen : entity work.clk_gen
    generic map (
      G_CLOCKS_USED    => 1,
      G_CLKIN_PERIOD   => 10.0,         -- 10ns for a 100MHz clock
      G_CLKFBOUT_MULT  => 10,           -- 100MHz x 10 gets a 1GHz internal PLL
      G_CLKOUT0_DIVIDE => 4)            -- o_clk_0 = 1GHz / 4 = 250MHz
    port map (
      -- Clock and Reset input signals
      clk => clk_100mhz,
      rst => '0',  -- No reset input: Reset is determined by the PLL lock

      -- Clock and reset output signals
      o_clk_0 => clk_250mhz,
      o_rst_0 => rst_250mhz,

      o_clk_1 => open,
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
      o_toggle => o_led(0));

  o_led(o_led'high downto 1) <= (others => '0');

  ----------------------------------------------------------------------------
  -- Audio Codec - Bank 13 - Connects to ADAU1761BCPZ
  o_audio_adr1 <= '0';
  o_audio_mclk <= '0';
  o_audio_sck  <= '0';

  i_audio_gpio  <= io_audio_gpio;
  io_audio_gpio <= o_audio_gpio when audio_gpio_out = '1' else (others => 'Z');

  i_audio_sda  <= io_audio_sda;
  io_audio_sda <= o_audio_sda when audio_sda_out = '1' else 'Z';

  ----------------------------------------------------------------------------
  -- OLED Display - Bank 13
  o_oled_dc   <= '0';
  o_oled_res  <= '0';
  o_oled_sclk <= '0';
  o_oled_sdin <= '0';
  o_oled_vbat <= '0';
  o_oled_vdd  <= '0';

  ----------------------------------------------------------------------------
  -- HDMI Output - Bank 33
  o_hdmi_clk   <= '0';
  o_hdmi_hsync <= '0';
  o_hdmi_vsync <= '0';
  o_hdmi_data  <= (others => '0');
  o_hdmi_dval  <= '0';
  o_hdmi_int   <= '0';
  o_hdmi_spdif <= '0';

  i_hdmi_scl  <= io_hdmi_scl;
  io_hdmi_scl <= o_hdmi_scl when hdmi_scl_out = '1' else 'Z';

  i_hdmi_sda  <= io_hdmi_sda;
  io_hdmi_sda <= o_hdmi_sda when hdmi_sda_out = '1' else 'Z';

  ----------------------------------------------------------------------------
  -- VGA Output - Bank 33
  o_vga_hs    <= '0';
  o_vga_vs    <= '0';
  o_vga_red   <= (others => '0');
  o_vga_green <= (others => '0');
  o_vga_blue  <= (others => '0');

  i_xadc_gio  <= io_xadc_gio;
  io_xadc_gio <= o_xadc_gio when xadc_gio_out = '1' else (others => 'Z');

  ----------------------------------------------------------------------------
  -- USB OTG Reset - Bank 35
  o_otg_vbusoc  <= '0';
  o_otg_reset_n <= '0';

  ----------------------------------------------------------------------------
  -- FMC Expansion Connector - Bank 13
  i_fmc_scl  <= io_fmc_scl;
  io_fmc_scl <= o_fmc_scl when fmc_scl_out = '1' else 'Z';

  i_fmc_sda  <= io_fmc_sda;
  io_fmc_sda <= o_fmc_sda when fmc_sda_out = '1' else 'Z';

end zedboard_rtl;

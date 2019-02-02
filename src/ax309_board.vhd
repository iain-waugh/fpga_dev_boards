-------------------------------------------------------------------------------
--
-- Copyright (c) 2018 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : AX309 Project
-- Author(s)     : Iain Waugh
-- File Name     : ax309_board.vhd
--
-- Top level template for the AX309 Spartan 6 LX9 evaluation board.
-- This file and the accompanying UCF can be used to start a project for
-- the board.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ax309_board is
  port(
    -- Clock and Reset signals
    clk_50mhz : in std_logic;
    i_rst_n   : in std_logic;           -- Pushbutton pin - Debounce this

    ---------------------------------------------------------------------------
    -- Miscellaneous
    o_led        : out std_logic_vector(3 downto 0);  -- LEDs
    i_key_in     : in  std_logic_vector(3 downto 0);  -- Pushbutton pins
    o_buzz_out_n : out std_logic;                     -- Loud!

    ---------------------------------------------------------------------------
    -- SDRAM
    o_sdram_clk  : out std_logic;
    o_sdram_cke  : out std_logic;
    o_sdram_ncs  : out std_logic;
    o_sdram_nwe  : out std_logic;
    o_sdram_ncas : out std_logic;
    o_sdram_nras : out std_logic;

    o_sdram_ba   : out   std_logic_vector(1 downto 0);
    o_sdram_a    : out   std_logic_vector(12 downto 0);
    io_sdram_d   : inout std_logic_vector(15 downto 0);
    io_sdram_dqm : inout std_logic_vector(1 downto 0);

    ---------------------------------------------------------------------------
    -- VGA
    o_vga_red   : out std_logic_vector(4 downto 0);
    o_vga_green : out std_logic_vector(5 downto 0);
    o_vga_blue  : out std_logic_vector(4 downto 0);

    o_vga_hs : out std_logic;
    o_vga_vs : out std_logic;

    ---------------------------------------------------------------------------
    -- SD Card Connector
    -- Error on the PCB:
    --   * The FPGA's nCS is routed to DIn
    --   * The FPGA's DIn is routed to GND, so don't drive it high.
    --   * The nCS pin is tied high with no FPGA connection
    -- i.e. The SD card is always enabled and you can't de-select it.
    o_sd_clk     : out std_logic;
    o_sd_gnd     : out std_logic;
    o_sd_datain  : out std_logic;
    i_sd_dataout : in  std_logic;

    ---------------------------------------------------------------------------
    -- USB Serial RS232
    i_rs232_rx : in  std_logic;
    o_rs232_tx : out std_logic;

    ---------------------------------------------------------------------------
    -- DS1302 Real-Time Clock
    o_ds1302_rst  : out   std_logic;
    o_ds1302_sclk : out   std_logic;
    io_ds1302_sio : inout std_logic;

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    io_i2c_scl : inout std_logic;
    io_i2c_sda : inout std_logic;

    ---------------------------------------------------------------------------
    -- 6x7 Segment Display Interface
    o_smg_data_n : out std_logic_vector(7 downto 0);
    o_scan_sig_n : out std_logic_vector(5 downto 0);

    ---------------------------------------------------------------------------
    -- OV2640/OV5640/OV7670 Camera
    -- (optional - could be GPIOs instead)
    o_cam_rst_n : out std_logic;
    o_cam_pwdn  : out std_logic;
    o_cam_xclk  : out std_logic;
    i_cam_pclk  : in  std_logic;
    i_cam_href  : in  std_logic;
    i_cam_vsync : in  std_logic;
    i_cam_d     : in  std_logic_vector(7 downto 0);

    o_cam_sclk  : out   std_logic;
    io_cam_sdat : inout std_logic
    );
end ax309_board;

architecture ax309_board_rtl of ax309_board is

  -- Tristate breakout signals
  signal i_ds1302_sio   : std_logic;
  signal o_ds1302_sio   : std_logic := '0';
  signal ds1302_sio_out : std_logic := '0';

  signal i_i2c_scl   : std_logic;
  signal o_i2c_scl   : std_logic := '1';
  signal i2c_scl_out : std_logic := '0';

  signal i_i2c_sda   : std_logic;
  signal o_i2c_sda   : std_logic := '1';
  signal i2c_sda_out : std_logic := '0';

  signal i_cam_sdat   : std_logic;
  signal o_cam_sdat   : std_logic := '0';
  signal cam_sdat_out : std_logic := '0';

  -- Internal timing pulses
  -- 8 = 100ns, 1us, 10us, 100us, 1ms, 10ms, 100ms, 1s
  constant C_POWERS_OF_100NS  : natural := 8;
  signal pulse_at_100ns_x_10e : std_logic_vector(C_POWERS_OF_100NS - 1 downto 0);

  signal led : std_logic_vector(o_led'range);

begin  -- ax309_board_rtl

  -- Connect 3x buttons to 3x LEDs
  key_1_debounce : entity work.debounce
    port map (
      clk         => clk_50mhz,
      i_button    => i_key_in(0),
      i_pulse     => pulse_at_100ns_x_10e(3),
      o_debounced => o_led(0));

  key_2_debounce : entity work.debounce
    port map (
      clk         => clk_50mhz,
      i_button    => i_key_in(1),
      i_pulse     => pulse_at_100ns_x_10e(3),
      o_debounced => o_led(1));

  key_3_debounce : entity work.debounce
    port map (
      clk         => clk_50mhz,
      i_button    => i_key_in(2),
      i_pulse     => pulse_at_100ns_x_10e(3),
      o_debounced => o_led(2));

  -- Make the "Hello  world" LED blink
  u_pulse_gen : entity work.pulse_gen
    generic map (
      -- How many timers do you want?
      G_POWERS_OF_100NS => C_POWERS_OF_100NS,

      -- How many clocks cycles in the 1st 100ns pulse?
      G_CLKS_IN_100NS => 5,             -- for a 50MHz clock

      -- Do you want the output pulses to be aligned with each-other?
      G_ALIGN_OUTPUTS => true)
    port map (
      -- Clock and Reset signals
      clk => clk_50mhz,
      rst => '0',

      o_pulse_at_100ns_x_10e => pulse_at_100ns_x_10e);

  u_hello_world : entity work.hello_world
    port map (
      -- Clock and Reset signals
      clk => clk_50mhz,

      i_pulse  => pulse_at_100ns_x_10e(7),
      o_toggle => o_led(3));

  o_buzz_out_n <= '1';                  -- Loud when '0'!

  ---------------------------------------------------------------------------
  -- SDRAM
  o_sdram_clk  <= '0';
  o_sdram_cke  <= '0';
  o_sdram_ncs  <= '0';
  o_sdram_nwe  <= '0';
  o_sdram_ncas <= '0';
  o_sdram_nras <= '0';

  o_sdram_ba   <= (others => '0');
  o_sdram_a    <= (others => '0');
  io_sdram_d   <= (others => '0');
  io_sdram_dqm <= (others => '0');

  ---------------------------------------------------------------------------
  -- VGA
  o_vga_hs <= '0';
  o_vga_vs <= '0';

  o_vga_red   <= (others => '0');
  o_vga_green <= (others => '0');
  o_vga_blue  <= (others => '0');

  ---------------------------------------------------------------------------
  -- SD Card Connector
  o_sd_clk    <= '0';
  o_sd_gnd    <= '0';
  o_sd_datain <= '0';

  ---------------------------------------------------------------------------
  -- USB Serial RS232
  o_rs232_tx <= '0';

  ---------------------------------------------------------------------------
  -- DS1302 Real-Time Clock
  o_ds1302_rst  <= '0';
  o_ds1302_sclk <= '0';
  io_ds1302_sio <= o_ds1302_sio when ds1302_sio_out = '1' else 'Z';
  i_ds1302_sio  <= io_ds1302_sio;

  ---------------------------------------------------------------------------
  -- I2C EEPROM
  io_i2c_scl <= o_i2c_scl when i2c_scl_out = '1' else 'Z';
  i_i2c_scl  <= io_i2c_scl;

  io_i2c_sda <= o_i2c_sda when i2c_sda_out = '1' else 'Z';
  i_i2c_sda  <= io_i2c_sda;

  ---------------------------------------------------------------------------
  -- 6x7 Segment Display Interface
  o_smg_data_n <= (others => '1');
  o_scan_sig_n <= (others => '1');

  ---------------------------------------------------------------------------
  -- OV2640/OV5640/OV7670 Camera
  -- (optional - could be GPIOs instead)
  o_cam_rst_n <= '0';
  o_cam_pwdn  <= '0';
  o_cam_xclk  <= '0';

  o_cam_sclk  <= '0';
  io_cam_sdat <= o_cam_sdat when cam_sdat_out = '1' else 'Z';
  i_cam_sdat  <= io_cam_sdat;

end ax309_board_rtl;

-------------------------------------------------------------------------------
--
-- Copyright (c) 2020 Iain Waugh
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : AX309 Dev Board
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
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity ax309_board is
  port(
    -- Clock and Reset signals
    clk_50MHz : in std_logic;
    i_rst_n   : in std_logic;           -- Pushbutton pin - Debounce this

    ---------------------------------------------------------------------------
    -- Miscellaneous
    o_led        : out std_logic_vector(3 downto 0);  -- LEDs
    i_key_in_n   : in  std_logic_vector(3 downto 0);  -- Pushbutton pins
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
    o_vga_hs : out std_logic;
    o_vga_vs : out std_logic;

    o_vga_red   : out unsigned(4 downto 0);
    o_vga_green : out unsigned(5 downto 0);
    o_vga_blue  : out unsigned(4 downto 0);

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

  signal clk_250MHz : std_logic := '0';
  signal rst_250MHz : std_logic := '1';

  -- Internal timing pulses
  -- 8 = 100ns, 1us, 10us, 100us, 1ms, 10ms, 100ms, 1s
  constant C_POWERS_OF_100NS  : natural := 8;
  signal pulse_at_100ns_x_10e : std_logic_vector(C_POWERS_OF_100NS - 1 downto 0);


  -- VGA Signals
  constant C_MAX_SYNC  : natural := 200;
  constant C_MAX_PORCH : natural := 200;
  constant C_MAX_BLANK : natural := 200;

  constant C_MAX_SIZE_X : natural := 1920;
  constant C_MAX_SIZE_Y : natural := 1080;

  constant C_BITS_RED   : natural := 5;
  constant C_BITS_GREEN : natural := 6;
  constant C_BITS_BLUE  : natural := 5;

  signal pixel_clk        : std_logic := '0';
  signal frame_sync_ext   : std_logic := '0';
  signal frame_sync_local : std_logic := '0';

  signal pixel_in_ready : std_logic := '0';
  signal pixel_red      : unsigned(C_BITS_RED - 1 downto 0);
  signal pixel_green    : unsigned(C_BITS_GREEN - 1 downto 0);
  signal pixel_blue     : unsigned(C_BITS_BLUE - 1 downto 0);
  signal pixel_dval     : std_logic := '0';

  signal vga_error : std_logic := '0';


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

  -- Other system signals
  signal led : std_logic_vector(o_led'range);

begin  -- ax309_board_rtl

  ----------------------------------------------------------------------------
  -- Create system clocks and resets
  u_clk_gen : entity work.clk_gen
    generic map (
      G_CLOCKS_USED    => 2,
      G_CLKIN_PERIOD   => 20.0,         -- 20ns for a 50MHz clock
      G_CLKFBOUT_MULT  => 10,    -- 50MHz x 10 gets a 500MHz internal PLL
      G_CLKOUT0_DIVIDE => 2,            -- o_clk_0 = 500MHz / 2 = 250MHz
      G_CLKOUT1_DIVIDE => 10)           -- o_clk_0 = 500MHz / 10 = 50MHz
    port map (
      -- Clock and Reset input signals
      clk => clk_50MHz,
      rst => '0',  -- No reset input: Reset is determined by the PLL lock

      -- Clock and reset output signals
      o_clk_0 => clk_250MHz,
      o_rst_0 => rst_250MHz,

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
  key_1_debounce : entity work.debounce
    generic map (
      G_INVERT_OUTPUT => true)
    port map (
      clk         => clk_250MHz,
      i_button    => i_key_in_n(0),
      i_pulse     => pulse_at_100ns_x_10e(3),
      o_debounced => led(0));

  key_2_debounce : entity work.debounce
    generic map (
      G_INVERT_OUTPUT => true)
    port map (
      clk         => clk_250MHz,
      i_button    => i_key_in_n(1),
      i_pulse     => pulse_at_100ns_x_10e(3),
      o_debounced => led(1));

  ----------------------------------------------------------------------------
  -- Make the "Hello  world" LED blink
  u_pulse_gen : entity work.pulse_gen
    generic map (
      -- How many timers do you want?
      G_POWERS_OF_100NS => C_POWERS_OF_100NS,

      -- How many clocks cycles in the 1st 100ns pulse?
      G_CLKS_IN_100NS => 25,            -- for a 250MHz clock

      -- Do you want the output pulses to be aligned with each-other?
      G_ALIGN_OUTPUTS => true)
    port map (
      -- Clock and Reset signals
      clk => clk_250MHz,
      rst => rst_250MHz,

      o_pulse_at_100ns_x_10e => pulse_at_100ns_x_10e);

  u_hello_world : entity work.hello_world
    port map (
      -- Clock and Reset signals
      clk => clk_250MHz,

      i_pulse  => pulse_at_100ns_x_10e(7),
      o_toggle => led(2));

  led(3) <= vga_error;

  o_led        <= led;
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
  frame_sync_ext <= '0';

  -- Generate a bit of dummy data for the VGA output
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

  -- Timings from http://www.tinyvga.com/vga-timing/800x600@72Hz
  u_vga_driver : entity work.vga_driver
    generic map (
      G_MAX_SYNC  => C_MAX_SYNC,
      G_MAX_PORCH => C_MAX_PORCH,
      G_MAX_BLANK => C_MAX_BLANK,

      G_MAX_SIZE_X => C_MAX_SIZE_X,
      G_MAX_SIZE_Y => C_MAX_SIZE_Y,

      G_BITS_RED   => C_BITS_RED,
      G_BITS_GREEN => C_BITS_GREEN,
      G_BITS_BLUE  => C_BITS_BLUE)
    port map (
      -- Timing control signals (data_clk domain)
      i_h_sync_time => to_unsigned(120, num_bits(C_MAX_SYNC)),
      i_v_sync_time => to_unsigned(6, num_bits(C_MAX_SYNC)),

      i_h_b_porch_time => to_unsigned(60, num_bits(C_MAX_PORCH)),
      i_h_f_porch_time => to_unsigned(60, num_bits(C_MAX_PORCH)),
      i_v_b_porch_time => to_unsigned(30, num_bits(C_MAX_PORCH)),
      i_v_f_porch_time => to_unsigned(30, num_bits(C_MAX_PORCH)),

      i_h_b_blank_time => to_unsigned(0, num_bits(C_MAX_BLANK)),
      i_h_f_blank_time => to_unsigned(0, num_bits(C_MAX_BLANK)),
      i_v_b_blank_time => to_unsigned(0, num_bits(C_MAX_BLANK)),
      i_v_f_blank_time => to_unsigned(0, num_bits(C_MAX_BLANK)),

      i_h_pic_size => to_unsigned(800, num_bits(C_MAX_SIZE_X)),
      i_v_pic_size => to_unsigned(600, num_bits(C_MAX_SIZE_Y)),

      i_border_red   => unsigned(all_zeros(C_BITS_RED)),
      i_border_green => unsigned(all_zeros(C_BITS_GREEN)),
      i_border_blue  => unsigned(all_zeros(C_BITS_BLUE)),

      -- Pixel data and handshaking signals (data_clk domain)
      data_clk      => pixel_clk,       -- Using 'pixel_clk' for now
      o_pixel_ready => pixel_in_ready,
      i_pixel_red   => pixel_red,
      i_pixel_green => pixel_green,
      i_pixel_blue  => pixel_blue,
      i_pixel_dval  => pixel_dval,

      -- VGA signals (pixel_clk domain)
      pixel_clk    => pixel_clk,
      i_frame_sync => frame_sync_ext,
      o_frame_sync => frame_sync_local,

      o_vga_hs => o_vga_hs,
      o_vga_vs => o_vga_vs,

      o_vga_red   => o_vga_red,
      o_vga_green => o_vga_green,
      o_vga_blue  => o_vga_blue,

      o_error => vga_error);

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

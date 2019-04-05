-------------------------------------------------------------------------------
--
-- Copyright (c) 2019 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : FPGA Dev Board Project
-- Author(s)     : Iain Waugh
-- File Name     : tb_vga_driver.vhd
--
-- Top-level testbench to provide stimulus for a VGA driver
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;


entity tb_vga_driver is
-- No ports on the top-level entity
end entity tb_vga_driver;


architecture tb_vga_driver_rtl of tb_vga_driver is

  -- VGA Constants
  constant C_MAX_SYNC  : natural := 200;
  constant C_MAX_PORCH : natural := 200;
  constant C_MAX_BLANK : natural := 200;

  constant C_MAX_SIZE_X : natural := 1920;
  constant C_MAX_SIZE_Y : natural := 1080;

  constant C_BITS_RED   : natural := 5;
  constant C_BITS_GREEN : natural := 6;
  constant C_BITS_BLUE  : natural := 5;

  -- component ports
  -- Clock and Reset signals
  signal data_clk : std_logic := '0';

  -- Timing control signals (data_clk domain)
  signal i_h_sync_time : unsigned(clog2(C_MAX_SYNC) - 1 downto 0);
  signal i_v_sync_time : unsigned(clog2(C_MAX_SYNC) - 1 downto 0);

  signal i_h_b_porch_time : unsigned(clog2(C_MAX_PORCH) - 1 downto 0);
  signal i_h_f_porch_time : unsigned(clog2(C_MAX_PORCH) - 1 downto 0);
  signal i_v_b_porch_time : unsigned(clog2(C_MAX_PORCH) - 1 downto 0);
  signal i_v_f_porch_time : unsigned(clog2(C_MAX_PORCH) - 1 downto 0);

  signal i_h_b_blank_time : unsigned(clog2(C_MAX_PORCH) - 1 downto 0);
  signal i_h_f_blank_time : unsigned(clog2(C_MAX_PORCH) - 1 downto 0);
  signal i_v_b_blank_time : unsigned(clog2(C_MAX_PORCH) - 1 downto 0);
  signal i_v_f_blank_time : unsigned(clog2(C_MAX_PORCH) - 1 downto 0);

  signal i_h_pic_size : unsigned(clog2(C_MAX_SIZE_X) - 1 downto 0);
  signal i_v_pic_size : unsigned(clog2(C_MAX_SIZE_Y) - 1 downto 0);

  signal i_blank_red   : unsigned(C_BITS_RED - 1 downto 0)   := (others => '0');
  signal i_blank_green : unsigned(C_BITS_GREEN - 1 downto 0) := (others => '0');
  signal i_blank_blue  : unsigned(C_BITS_BLUE - 1 downto 0)  := (others => '0');

  -- Pixel data and handshaking signals (data_clk domain)
  signal o_pixel_ready : std_logic;  -- Only take valid data when 'ready' is high
  signal pixel_red   : unsigned(C_BITS_RED - 1 downto 0)   := (others => '0');
  signal pixel_green : unsigned(C_BITS_GREEN - 1 downto 0) := (others => '0');
  signal pixel_blue  : unsigned(C_BITS_BLUE - 1 downto 0)  := (others => '0');
  signal pixel_dval  : std_logic                           := '0';

  -- VGA Signals
  signal pixel_clk    : std_logic := '0';
  signal i_frame_sync : std_logic := '0';
  signal o_frame_sync : std_logic := '0';

  signal o_vga_hs : std_logic := '0';
  signal o_vga_vs : std_logic := '0';

  signal o_vga_red   : unsigned(C_BITS_RED - 1 downto 0)   := (others => '0');
  signal o_vga_green : unsigned(C_BITS_GREEN - 1 downto 0) := (others => '0');
  signal o_vga_blue  : unsigned(C_BITS_BLUE - 1 downto 0)  := (others => '0');

  signal clk : std_logic := '0';
  signal rst : std_logic := '1';

  constant C_COUNT_MAX : natural := 127;
  signal count         : unsigned(clog2(C_COUNT_MAX) - 1 downto 0);

begin  -- architecture tb_vga_driver_rtl

  -- Component instantiation
  DUT : entity work.vga_driver
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
      i_h_sync_time => to_unsigned(120, clog2(C_MAX_SYNC)),
      i_v_sync_time => to_unsigned(6, clog2(C_MAX_SYNC)),

      i_h_b_porch_time => to_unsigned(60, clog2(C_MAX_PORCH)),
      i_h_f_porch_time => to_unsigned(60, clog2(C_MAX_PORCH)),
      i_v_b_porch_time => to_unsigned(30, clog2(C_MAX_PORCH)),
      i_v_f_porch_time => to_unsigned(30, clog2(C_MAX_PORCH)),

      i_h_b_blank_time => to_unsigned(0, clog2(C_MAX_BLANK)),
      i_h_f_blank_time => to_unsigned(0, clog2(C_MAX_BLANK)),
      i_v_b_blank_time => to_unsigned(0, clog2(C_MAX_BLANK)),
      i_v_f_blank_time => to_unsigned(0, clog2(C_MAX_BLANK)),

      i_h_pic_size => to_unsigned(800, clog2(C_MAX_SIZE_X)),
      i_v_pic_size => to_unsigned(600, clog2(C_MAX_SIZE_Y)),

      i_blank_red   => unsigned(zeros(C_BITS_RED)),
      i_blank_green => unsigned(zeros(C_BITS_GREEN)),
      i_blank_blue  => unsigned(zeros(C_BITS_BLUE)),

      -- Pixel data and handshaking signals (data_clk domain)
      data_clk      => pixel_clk,       -- Using 'pixel_clk' for now
      o_pixel_ready => o_pixel_ready,
      i_pixel_red   => pixel_red,
      i_pixel_green => pixel_green,
      i_pixel_blue  => pixel_blue,
      i_pixel_dval  => pixel_dval,

      -- VGA signals (pixel_clk domain)
      pixel_clk    => pixel_clk,
      i_frame_sync => i_frame_sync,
      o_frame_sync => o_frame_sync,

      o_vga_hs => o_vga_hs,
      o_vga_vs => o_vga_vs,

      o_vga_red   => o_vga_red,
      o_vga_green => o_vga_green,
      o_vga_blue  => o_vga_blue,

      o_error => open
      );

  -------------------------------------------------------------------------------
  -- System clock generation
  clk_gen : process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process clk_gen;
  pixel_clk <= clk;
  data_clk  <= clk;

  -----------------------------------------------------------------------------
  -- Reset generation
  rst_gen : process
  begin
    rst <= '1';
    wait for 100 ns;
    rst <= '0';
    wait;
  end process rst_gen;
  i_frame_sync <= rst;

  ----------------------------------------------------------------------
  -- Counter
  --  constant C_COUNT_MAX : natural := 127;
  --  signal   count       : natural range 0 to C_COUNT_MAX;
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        count <= (others => '0');
      else
        if (o_pixel_ready = '1') then
          if (count < C_COUNT_MAX) then
            count <= count + 1;
          else
            count <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;

  pixel_red   <= count(pixel_red'high downto 0);
  pixel_green <= count(pixel_green'high downto 0);
  pixel_blue  <= count(pixel_blue'high downto 0);
  pixel_dval  <= o_pixel_ready and not rst;

end architecture tb_vga_driver_rtl;

-------------------------------------------------------------------------------

configuration tb_vga_driver_rtl_cfg of tb_vga_driver is
  for tb_vga_driver_rtl
  end for;
end tb_vga_driver_rtl_cfg;

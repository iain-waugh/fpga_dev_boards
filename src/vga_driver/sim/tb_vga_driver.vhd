-------------------------------------------------------------------------------
--
-- Copyright (c) 2020 Iain Waugh
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

  constant C_LOG2_PIXEL_FIFO_DEPTH : natural := 5;

  signal pixel_clk : std_logic;

  -- Horizontal signals
  signal i_h_f_porch_time : unsigned(num_bits(C_MAX_PORCH) - 1 downto 0);
  signal i_h_sync_time    : unsigned(num_bits(C_MAX_SYNC) - 1 downto 0);
  signal i_h_b_porch_time : unsigned(num_bits(C_MAX_PORCH) - 1 downto 0);

  -- Vertical signals
  signal i_v_f_porch_time : unsigned(num_bits(C_MAX_PORCH) - 1 downto 0);
  signal i_v_sync_time    : unsigned(num_bits(C_MAX_SYNC) - 1 downto 0);
  signal i_v_b_porch_time : unsigned(num_bits(C_MAX_PORCH) - 1 downto 0);

  -- Un-addressable border colour
  signal i_h_border_size : unsigned(num_bits(C_MAX_SIZE_X) - 1 downto 0);
  signal i_v_border_size : unsigned(num_bits(C_MAX_SIZE_Y) - 1 downto 0);

  -- Addressable video
  signal i_h_pic_size : unsigned(num_bits(C_MAX_SIZE_X) - 1 downto 0);
  signal i_v_pic_size : unsigned(num_bits(C_MAX_SIZE_Y) - 1 downto 0);

  -- What colour do you want the border to be?
  signal i_border_red   : unsigned(C_BITS_RED - 1 downto 0);
  signal i_border_green : unsigned(C_BITS_GREEN - 1 downto 0);
  signal i_border_blue  : unsigned(C_BITS_BLUE - 1 downto 0);

  -- Pixel data and handshaking signals
  signal o_pixel_ready : std_logic;
  signal o_p_fifo_half : std_logic;
  signal i_pixel_red   : unsigned(C_BITS_RED - 1 downto 0);
  signal i_pixel_green : unsigned(C_BITS_GREEN - 1 downto 0);
  signal i_pixel_blue  : unsigned(C_BITS_BLUE - 1 downto 0);
  signal i_pixel_dval  : std_logic;

  -- Video signals
  signal i_frame_sync : std_logic;
  signal o_frame_sync : std_logic;

  signal o_vga_hs : std_logic;
  signal o_vga_vs : std_logic;

  signal o_vga_red   : unsigned(C_BITS_RED - 1 downto 0);
  signal o_vga_green : unsigned(C_BITS_GREEN - 1 downto 0);
  signal o_vga_blue  : unsigned(C_BITS_BLUE - 1 downto 0);

  signal o_error : std_logic;

  constant C_COUNT_MAX : natural := 127;
  signal count         : unsigned(num_bits(C_COUNT_MAX) - 1 downto 0);

begin  -- architecture tb_vga_driver_rtl

  -- Horizontal signals
   i_h_f_porch_time <= to_unsigned(8, num_bits(C_MAX_PORCH));
   i_h_sync_time    <= to_unsigned(32, num_bits(C_MAX_SYNC));
   i_h_b_porch_time <= to_unsigned(40, num_bits(C_MAX_PORCH));

  -- Vertical signals
   i_v_f_porch_time <= to_unsigned(3, num_bits(C_MAX_PORCH));
   i_v_sync_time    <= to_unsigned(6, num_bits(C_MAX_SYNC));
   i_v_b_porch_time <= to_unsigned(6, num_bits(C_MAX_PORCH));

  -- Un-addressable border colour
   i_h_border_size <= to_unsigned(80, num_bits(C_MAX_SIZE_X));
   i_v_border_size <= to_unsigned(15, num_bits(C_MAX_SIZE_Y));

   -- Addressable video
   i_h_pic_size <= to_unsigned(320, num_bits(C_MAX_SIZE_X));
   i_v_pic_size <= to_unsigned(200, num_bits(C_MAX_SIZE_Y));

   -- What colour do you want the border to be?
   i_border_red   <= to_unsigned(7, C_BITS_RED);
   i_border_green <= to_unsigned(7, C_BITS_GREEN);
   i_border_blue  <= to_unsigned(7, C_BITS_BLUE);

  -- Component instantiation
  DUT : entity work.vga_driver
    generic map (
      G_MAX_SYNC  => C_MAX_SYNC,
      G_MAX_PORCH => C_MAX_PORCH,

      G_MAX_SIZE_X => C_MAX_SIZE_X,
      G_MAX_SIZE_Y => C_MAX_SIZE_Y,

      G_BITS_RED   => C_BITS_RED,
      G_BITS_GREEN => C_BITS_GREEN,
      G_BITS_BLUE  => C_BITS_BLUE,

      G_LOG2_PIXEL_FIFO_DEPTH => C_LOG2_PIXEL_FIFO_DEPTH)
    port map (
      pixel_clk => pixel_clk,

      -- Horizontal signals
      i_h_f_porch_time => i_h_f_porch_time,
      i_h_sync_time    => i_h_sync_time,
      i_h_b_porch_time => i_h_b_porch_time,

      -- Vertical signals
      i_v_f_porch_time => i_v_f_porch_time,
      i_v_sync_time    => i_v_sync_time,
      i_v_b_porch_time => i_v_b_porch_time,

      -- Un-addressable border colour
      i_h_border_size => i_h_border_size,
      i_v_border_size => i_v_border_size,

      -- Addressable video
      i_h_pic_size => i_h_pic_size,
      i_v_pic_size => i_v_pic_size,

      -- What colour do you want the border to be?
      i_border_red   => i_border_red,
      i_border_green => i_border_green,
      i_border_blue  => i_border_blue,

      -- Pixel data and handshaking signals
      o_pixel_ready => o_pixel_ready,
      o_p_fifo_half => o_p_fifo_half,
      i_pixel_red   => i_pixel_red,
      i_pixel_green => i_pixel_green,
      i_pixel_blue  => i_pixel_blue,
      i_pixel_dval  => i_pixel_dval,

      -- Video signals
      i_frame_sync => i_frame_sync,
      o_frame_sync => o_frame_sync,

      o_vga_hs => o_vga_hs,
      o_vga_vs => o_vga_vs,

      o_vga_red   => o_vga_red,
      o_vga_green => o_vga_green,
      o_vga_blue  => o_vga_blue,

      o_error => o_error);

  -------------------------------------------------------------------------------
  -- System clock generation
  clk_gen : process
  begin
    pixel_clk <= '0';
    wait for 5 ns;
    pixel_clk <= '1';
    wait for 5 ns;
  end process clk_gen;

  -----------------------------------------------------------------------------
  -- Reset generation
  rst_gen : process
  begin
    i_frame_sync <= '1';
    wait for 100 ns;
    i_frame_sync <= '0';
    wait;
  end process rst_gen;

  ----------------------------------------------------------------------
  -- Counter
  --  constant C_COUNT_MAX : natural := 127;
  --  signal   count       : natural range 0 to C_COUNT_MAX;
  process (pixel_clk)
  begin
    if rising_edge(pixel_clk) then
      if (i_frame_sync = '1') then
        count <= (others => '0');
      else
        if o_pixel_ready = '1' then
          if count < C_COUNT_MAX then
            count <= count + 1;
          else
            count <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;

  i_pixel_red   <= count(i_pixel_red'high downto 0);
  i_pixel_green <= count(i_pixel_green'high downto 0);
  i_pixel_blue  <= count(i_pixel_blue'high downto 0);
  i_pixel_dval  <= o_pixel_ready and not i_frame_sync;

end architecture tb_vga_driver_rtl;

-------------------------------------------------------------------------------

configuration tb_vga_driver_rtl_cfg of tb_vga_driver is
  for tb_vga_driver_rtl
  end for;
end tb_vga_driver_rtl_cfg;

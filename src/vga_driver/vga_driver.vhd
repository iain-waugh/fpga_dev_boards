-------------------------------------------------------------------------------
--
-- Copyright (c) 2019 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : AX309 Project
-- Author(s)     : Iain Waugh
-- File Name     : vga_driver.vhd
--
-- VGA output driver.
--
-- The next version will have pixel input based on
-- 'fval', 'lval' and 'dval' for video data.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

entity vga_driver is
  generic(
    G_MAX_SYNC  : natural := 100;
    G_MAX_PORCH : natural := 100;
    G_MAX_BLANK : natural := 100;

    G_MAX_SIZE_X : natural := 1920;
    G_MAX_SIZE_Y : natural := 1200;

    G_BITS_RED   : natural := 5;
    G_BITS_GREEN : natural := 6;
    G_BITS_BLUE  : natural := 5
    );
  port(
    -- Clock and Reset signals
    data_clk : in std_logic;

    -- Timing control signals (data_clk domain)
    i_frame_sync : in std_logic; -- Effectively resets the frame counters

    i_h_sync_time : in unsigned(clog2(G_MAX_SYNC) - 1 downto 0);
    i_v_sync_time : in unsigned(clog2(G_MAX_SYNC) - 1 downto 0);

    i_h_b_porch_time : in unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
    i_h_f_porch_time : in unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
    i_v_b_porch_time : in unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
    i_v_f_porch_time : in unsigned(clog2(G_MAX_PORCH) - 1 downto 0);

    i_h_b_blank_time : in unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
    i_h_f_blank_time : in unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
    i_v_b_blank_time : in unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
    i_v_f_blank_time : in unsigned(clog2(G_MAX_PORCH) - 1 downto 0);

    i_h_pic_size : in unsigned(clog2(G_MAX_SIZE_X) - 1 downto 0);
    i_v_pic_size : in unsigned(clog2(G_MAX_SIZE_Y) - 1 downto 0);

    i_blank_colour : in std_logic_vector(G_BITS_RED + G_BITS_GREEN + G_BITS_BLUE - 1 downto 0);

    -- Pixel data and handshaking signals (data_clk domain)
    o_rdb_ready : out std_logic; -- Only take valid data when 'ready' is high
    i_rgb_data  : in  std_logic_vector(G_BITS_RED + G_BITS_GREEN + G_BITS_BLUE - 1 downto 0);
    i_rgb_dval  : in  std_logic;

    -- VGA signals (pixel_clk domain)
    pixel_clk : in std_logic;
    pixel_rst : in std_logic;

    o_vga_hs : out std_logic;
    o_vga_vs : out std_logic;

    o_vga_red   : out unsigned(G_BITS_RED - 1 downto 0);
    o_vga_green : out unsigned(G_BITS_GREEN - 1 downto 0);
    o_vga_blue  : out unsigned(G_BITS_BLUE - 1 downto 0)
    );
end vga_driver;

architecture vga_driver_rtl of vga_driver is

  -- The horizontal sequence is:
  --   hsync  back porch      picture      front porch
  --  |-----|------------|---------------|-------------|
  --
  -- Similarly for the vertical sequence.
  -- 
  type t_video_state is (sync, b_porch, pic, f_porch);
  signal h_state : t_video_state;
  signal v_state : t_video_state;

  signal h_sync_count : unsigned(clog2(G_MAX_SYNC) - 1 downto 0);
  signal v_sync_count : unsigned(clog2(G_MAX_SYNC) - 1 downto 0);

  signal h_porch_count : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
  signal v_porch_count : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);

  signal h_blank_count : unsigned(clog2(G_MAX_BLANK) - 1 downto 0);
  signal v_blank_count : unsigned(clog2(G_MAX_BLANK) - 1 downto 0);

  signal h_pic_count : unsigned(clog2(G_MAX_SIZE_X) - 1 downto 0);
  signal v_pic_count : unsigned(clog2(G_MAX_SIZE_Y) - 1 downto 0);

begin  -- vga_driver_rtl


end vga_driver_rtl;

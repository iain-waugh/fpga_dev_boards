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

  -- component generics
  constant G_MAX_SYNC  : natural := 100;
  constant G_MAX_PORCH : natural := 100;
  constant G_MAX_BLANK : natural := 100;

  constant G_MAX_SIZE_X : natural := 1920;
  constant G_MAX_SIZE_Y : natural := 1200;

  constant G_BITS_RED   : natural := 5;
  constant G_BITS_GREEN : natural := 6;
  constant G_BITS_BLUE  : natural := 5;

  -- component ports
  -- Clock and Reset signals
  signal data_clk : std_logic := '0';

  -- Timing control signals (data_clk domain)
  signal i_h_sync_time : unsigned(clog2(G_MAX_SYNC) - 1 downto 0);
  signal i_v_sync_time : unsigned(clog2(G_MAX_SYNC) - 1 downto 0);

  signal i_h_b_porch_time : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
  signal i_h_f_porch_time : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
  signal i_v_b_porch_time : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
  signal i_v_f_porch_time : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);

  signal i_h_b_blank_time : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
  signal i_h_f_blank_time : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
  signal i_v_b_blank_time : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);
  signal i_v_f_blank_time : unsigned(clog2(G_MAX_PORCH) - 1 downto 0);

  signal i_h_pic_size : unsigned(clog2(G_MAX_SIZE_X) - 1 downto 0);
  signal i_v_pic_size : unsigned(clog2(G_MAX_SIZE_Y) - 1 downto 0);

  signal i_blank_red   : unsigned(G_BITS_RED - 1 downto 0)   := (others => '0');
  signal i_blank_green : unsigned(G_BITS_GREEN - 1 downto 0) := (others => '0');
  signal i_blank_blue  : unsigned(G_BITS_BLUE - 1 downto 0)  := (others => '0');

  -- Pixel data and handshaking signals (data_clk domain)
  signal o_pixel_ready : std_logic;  -- Only take valid data when 'ready' is high
  signal i_pixel_red   : unsigned(G_BITS_RED - 1 downto 0)   := (others => '0');
  signal i_pixel_green : unsigned(G_BITS_GREEN - 1 downto 0) := (others => '0');
  signal i_pixel_blue  : unsigned(G_BITS_BLUE - 1 downto 0)  := (others => '0');
  signal i_pixel_dval  : std_logic                           := '0';

  -- VGA signals (pixel_clk domain)
  signal pixel_clk    : std_logic := '0';
  signal i_frame_sync : std_logic := '0';

  signal o_vga_hs : std_logic := '0';
  signal o_vga_vs : std_logic := '0';

  signal o_vga_red   : unsigned(G_BITS_RED - 1 downto 0)   := (others => '0');
  signal o_vga_green : unsigned(G_BITS_GREEN - 1 downto 0) := (others => '0');
  signal o_vga_blue  : unsigned(G_BITS_BLUE - 1 downto 0)  := (others => '0');

  signal clk : std_logic := '0';
  signal rst : std_logic := '1';

  constant C_COUNT_MAX : natural := 127;
  signal count         : natural range 0 to C_COUNT_MAX;

begin  -- architecture tb_vga_driver_rtl

  i_h_sync_time <= to_unsigned(50, i_h_sync_time'length);
  i_v_sync_time <= to_unsigned(50, i_v_sync_time'length);

  i_h_b_porch_time <= to_unsigned(40, i_h_b_porch_time'length);
  i_h_f_porch_time <= to_unsigned(40, i_h_f_porch_time'length);
  i_v_b_porch_time <= to_unsigned(40, i_v_b_porch_time'length);
  i_v_f_porch_time <= to_unsigned(40, i_v_f_porch_time'length);

  i_h_b_blank_time <= to_unsigned(0, i_h_b_blank_time'length);
  i_h_f_blank_time <= to_unsigned(0, i_h_f_blank_time'length);
  i_v_b_blank_time <= to_unsigned(0, i_v_b_blank_time'length);
  i_v_f_blank_time <= to_unsigned(0, i_v_f_blank_time'length);

  i_h_pic_size <= to_unsigned(640, i_h_pic_size'length);
  i_v_pic_size <= to_unsigned(480, i_v_pic_size'length);


  -- Component instantiation
  DUT : entity work.vga_driver
    generic map (
      G_MAX_SYNC  => G_MAX_SYNC,
      G_MAX_PORCH => G_MAX_PORCH,
      G_MAX_BLANK => G_MAX_BLANK,

      G_MAX_SIZE_X => G_MAX_SIZE_X,
      G_MAX_SIZE_Y => G_MAX_SIZE_Y,

      G_BITS_RED   => G_BITS_RED,
      G_BITS_GREEN => G_BITS_GREEN,
      G_BITS_BLUE  => G_BITS_BLUE)
    port map (
      -- Clock and Reset signals
      data_clk => data_clk,

      -- Timing control signals (data_clk domain)
      i_h_sync_time => i_h_sync_time,
      i_v_sync_time => i_v_sync_time,

      i_h_b_porch_time => i_h_b_porch_time,
      i_h_f_porch_time => i_h_f_porch_time,
      i_v_b_porch_time => i_v_b_porch_time,
      i_v_f_porch_time => i_v_f_porch_time,

      i_h_b_blank_time => i_h_b_blank_time,
      i_h_f_blank_time => i_h_f_blank_time,
      i_v_b_blank_time => i_v_b_blank_time,
      i_v_f_blank_time => i_v_f_blank_time,

      i_h_pic_size => i_h_pic_size,
      i_v_pic_size => i_v_pic_size,

      i_blank_red   => i_blank_red,
      i_blank_green => i_blank_green,
      i_blank_blue  => i_blank_blue,

      -- Pixel data and handshaking signals (data_clk domain)
      o_pixel_ready => o_pixel_ready,
      i_pixel_red   => i_pixel_red,
      i_pixel_green => i_pixel_green,
      i_pixel_blue  => i_pixel_blue,
      i_pixel_dval  => i_pixel_dval,

      -- VGA signals (pixel_clk domain)
      pixel_clk    => pixel_clk,
      i_frame_sync => i_frame_sync,

      o_vga_hs => o_vga_hs,
      o_vga_vs => o_vga_vs,

      o_vga_red   => o_vga_red,
      o_vga_green => o_vga_green,
      o_vga_blue  => o_vga_blue);

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
      if (rst = '0') then
        count <= 0;
      else
        if (count < C_COUNT_MAX) then
          count <= count + 1;
        else
          count <= 0;
        end if;
      end if;
    end if;
  end process;


end architecture tb_vga_driver_rtl;

-------------------------------------------------------------------------------

configuration tb_vga_driver_rtl_cfg of tb_vga_driver is
  for tb_vga_driver_rtl
  end for;
end tb_vga_driver_rtl_cfg;

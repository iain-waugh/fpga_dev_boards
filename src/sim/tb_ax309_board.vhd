-------------------------------------------------------------------------------
--
-- Copyright (c) 2019 CadHut
-- All rights reserved.
--
-------------------------------------------------------------------------------
-- Project Name  : FPGA Dev Board
-- Author(s)     : Iain Waugh
-- File Name     : tb_ax309_board.vhd
--
-- Top level testbench
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ax309_board is
end entity tb_ax309_board;

architecture tb_ax309_board_rtl of tb_ax309_board is

  -- component ports
  -- Clock and Reset signals
  signal clk_50mhz : std_logic := '0';
  signal i_rst_n   : std_logic := '1';
  signal rst       : std_logic := '0';

  ---------------------------------------------------------------------------
  -- Miscellaneous
  signal o_led        : std_logic_vector(3 downto 0);
  signal i_key_in_n   : std_logic_vector(3 downto 0) := (others => '0');
  signal o_buzz_out_n : std_logic;

  ---------------------------------------------------------------------------
  -- SDRAM
  signal o_sdram_clk  : std_logic;
  signal o_sdram_cke  : std_logic;
  signal o_sdram_ncs  : std_logic;
  signal o_sdram_nwe  : std_logic;
  signal o_sdram_ncas : std_logic;
  signal o_sdram_nras : std_logic;

  signal o_sdram_ba   : std_logic_vector(1 downto 0);
  signal o_sdram_a    : std_logic_vector(12 downto 0);
  signal io_sdram_d   : std_logic_vector(15 downto 0);
  signal io_sdram_dqm : std_logic_vector(1 downto 0);

  ---------------------------------------------------------------------------
  -- VGA
  signal o_vga_hs : std_logic;
  signal o_vga_vs : std_logic;

  signal o_vga_red   : unsigned(4 downto 0);
  signal o_vga_green : unsigned(5 downto 0);
  signal o_vga_blue  : unsigned(4 downto 0);

  ---------------------------------------------------------------------------
  -- SD Card Connector
  -- Error on the PCB:
  --   * The FPGA's nCS is routed to DIn
  --   * The FPGA's DIn is routed to GND, so don't drive it high.
  --   * The nCS pin is tied high with no FPGA connection
  -- i.e. The SD card is always enabled and you can't de-select it.
  signal o_sd_clk     : std_logic;
  signal o_sd_gnd     : std_logic;
  signal o_sd_datain  : std_logic;
  signal i_sd_dataout : std_logic := '0';

  ---------------------------------------------------------------------------
  -- USB Serial RS232
  signal i_rs232_rx : std_logic := '0';
  signal o_rs232_tx : std_logic;

  ---------------------------------------------------------------------------
  -- DS1302 Real-Time Clock
  signal o_ds1302_rst  : std_logic;
  signal o_ds1302_sclk : std_logic;
  signal io_ds1302_sio : std_logic;

  ---------------------------------------------------------------------------
  -- I2C EEPROM
  signal io_i2c_scl : std_logic;
  signal io_i2c_sda : std_logic;

  ---------------------------------------------------------------------------
  -- 6x7 Segment Display Interface
  signal o_smg_data_n : std_logic_vector(7 downto 0);
  signal o_scan_sig_n : std_logic_vector(5 downto 0);

  ---------------------------------------------------------------------------
  -- OV2640/OV5640/OV7670 Camera
  -- (optional - could be GPIOs instead)
  signal o_cam_rst_n : std_logic;
  signal o_cam_pwdn  : std_logic;
  signal o_cam_xclk  : std_logic;
  signal i_cam_pclk  : std_logic                    := '0';
  signal i_cam_href  : std_logic                    := '0';
  signal i_cam_vsync : std_logic                    := '0';
  signal i_cam_d     : std_logic_vector(7 downto 0) := (others => '0');

  signal o_cam_sclk  : std_logic;
  signal io_cam_sdat : std_logic;

  constant C_COUNT_MAX : natural := 127;
  signal count         : natural range 0 to C_COUNT_MAX;

begin  -- architecture tb_ax309_board_rtl

  -- component instantiation
  DUT : entity work.ax309_board
    port map (
      -- Clock and Reset signals
      clk_50mhz => clk_50mhz,
      i_rst_n   => i_rst_n,

      ---------------------------------------------------------------------------
      -- Miscellaneous
      o_led        => o_led,
      i_key_in_n   => i_key_in_n,
      o_buzz_out_n => o_buzz_out_n,

      ---------------------------------------------------------------------------
      -- SDRAM
      o_sdram_clk  => o_sdram_clk,
      o_sdram_cke  => o_sdram_cke,
      o_sdram_ncs  => o_sdram_ncs,
      o_sdram_nwe  => o_sdram_nwe,
      o_sdram_ncas => o_sdram_ncas,
      o_sdram_nras => o_sdram_nras,

      o_sdram_ba   => o_sdram_ba,
      o_sdram_a    => o_sdram_a,
      io_sdram_d   => io_sdram_d,
      io_sdram_dqm => io_sdram_dqm,

      ---------------------------------------------------------------------------
      -- VGA
      o_vga_red   => o_vga_red,
      o_vga_green => o_vga_green,
      o_vga_blue  => o_vga_blue,

      o_vga_hs => o_vga_hs,
      o_vga_vs => o_vga_vs,

      ---------------------------------------------------------------------------
      -- SD Card Connector
      -- Error on the PCB:
      --   * The FPGA's nCS is routed to DIn
      --   * The FPGA's DIn is routed to GND, so don't drive it high.
      --   * The nCS pin is tied high with no FPGA connection
      -- i.e. The SD card is always enabled and you can't de-select it.
      o_sd_clk     => o_sd_clk,
      o_sd_gnd     => o_sd_gnd,
      o_sd_datain  => o_sd_datain,
      i_sd_dataout => i_sd_dataout,

      ---------------------------------------------------------------------------
      -- USB Serial RS232
      i_rs232_rx => i_rs232_rx,
      o_rs232_tx => o_rs232_tx,

      ---------------------------------------------------------------------------
      -- DS1302 Real-Time Clock
      o_ds1302_rst  => o_ds1302_rst,
      o_ds1302_sclk => o_ds1302_sclk,
      io_ds1302_sio => io_ds1302_sio,

      ---------------------------------------------------------------------------
      -- I2C EEPROM
      io_i2c_scl => io_i2c_scl,
      io_i2c_sda => io_i2c_sda,

      ---------------------------------------------------------------------------
      -- 6x7 Segment Display Interface
      o_smg_data_n => o_smg_data_n,
      o_scan_sig_n => o_scan_sig_n,

      ---------------------------------------------------------------------------
      -- OV2640/OV5640/OV7670 Camera
      -- (optional - could be GPIOs instead)
      o_cam_rst_n => o_cam_rst_n,
      o_cam_pwdn  => o_cam_pwdn,
      o_cam_xclk  => o_cam_xclk,
      i_cam_pclk  => i_cam_pclk,
      i_cam_href  => i_cam_href,
      i_cam_vsync => i_cam_vsync,
      i_cam_d     => i_cam_d,

      o_cam_sclk  => o_cam_sclk,
      io_cam_sdat => io_cam_sdat);

  -------------------------------------------------------------------------------
  -- System clock generation
  clk_gen : process
  begin
    clk_50mhz <= '0';
    wait for 10 ns;
    clk_50mhz <= '1';
    wait for 10 ns;
  end process clk_gen;

  -----------------------------------------------------------------------------
  -- Reset generation
  rst_gen : process
  begin
    i_rst_n <= '0';
    wait for 30 ns;
    i_rst_n <= '1';
    wait;
  end process rst_gen;
  rst <= not i_rst_n;

  ----------------------------------------------------------------------
  -- Counter
  --  constant C_COUNT_MAX : natural := 127;
  --  signal   count       : natural range 0 to C_COUNT_MAX;
  process (clk_50mhz)
  begin
    if (rising_edge(clk_50mhz)) then
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

end architecture tb_ax309_board_rtl;

-------------------------------------------------------------------------------

configuration tb_ax309_board_rtl_cfg of tb_ax309_board is
  for tb_ax309_board_rtl
  end for;
end tb_ax309_board_rtl_cfg;

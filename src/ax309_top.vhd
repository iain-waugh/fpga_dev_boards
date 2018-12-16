-------------------------------------------------------------------------------
--
-- Copyright (c) 2018 CadHut
-- All rights reserved.
--
-- Redistribution and use in source and binary forms (with or without
-- modification) is not permitted.
--
-------------------------------------------------------------------------------
-- Project Name  : CadHut AX309 Demo
-- Author(s)     : Iain
-- File Name     : ax309_top.vhd
--
-- 
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ax309_top is
  port(
    -- Clock and Reset signals
    clk_50mhz : in std_logic;
    i_rst_n   : in std_logic;           -- Pushbutton pin - Debounce this

    ---------------------------------------------------------------------------
    -- Miscellaneous pins
    o_led      : out std_logic_vector(3 downto 0);  -- LEDs
    i_key_in   : in  std_logic_vector(3 downto 0);  -- Pushbutton pins
    o_buzz_out : out std_logic;                     -- Loud!

    ---------------------------------------------------------------------------
    -- SDRAM pins
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
    -- VGA pins
    o_vga_red   : out std_logic_vector(4 downto 0);
    o_vga_green : out std_logic_vector(5 downto 0);
    o_vga_blue  : out std_logic_vector(4 downto 0);

    o_vga_hs : out std_logic;
    o_vga_vs : out std_logic;

    ---------------------------------------------------------------------------
    -- SD Card Connector pins
    -- Error on the PCB:
    --   * The FPGA's nCS is routed to DIn
    --   * The FPGA's DIn is routed to GND, so don't drive it high.
    --   * The nCS pin is tied high with no FPGA connection
    -- i.e. The SD card is always enabled and you can't de-select it.

    - Corrected :
    o_sd_clk     : out std_logic;
    o_sd_gnd     : out std_logic;
    o_sd_datain  : out std_logic;
    i_sd_dataout : in  std_logic;

    ---------------------------------------------------------------------------
    -- USB Serial RS232 pins
    i_rs232_rx : in  std_logic;
    o_rs232_tx : out std_logic;

    ---------------------------------------------------------------------------
    -- DS1302 Real-Time Clock pins
    o_ds1302_rst  : out   std_logic;
    o_ds1302_sclk : out   std_logic;
    io_ds1302_sio : inout std_logic;

    ---------------------------------------------------------------------------
    -- I2C EEPROM pins
    io_scl : inout std_logic;
    io_sda : inout std_logic;

    ---------------------------------------------------------------------------
    -- 6x7 Segment Display Interface pins
    o_smg_data : out std_logic_vector(7 downto 0);
    o_scan_sig : out std_logic_vector(5 downto 0);

    ---------------------------------------------------------------------------
    -- OV2640/OV5640/OV7670 Camera pins
    -- (optional - could be GPIOs instead)
    o_cam_rst_n : out std_logic;
    o_cam_pwdn  : out std_logic;
    o_cam_xclk  : out std_logic;
    i_cam_pclk  : in  std_logic;
    i_cam_href  : in  std_logic;
    i_cam_vsync : in  std_logic;
    i_cam_d     : in  std_logic_vector(7 downto 0);

    o_cmos_sclk  : out   std_logic;
    io_cmos_sdat : inout std_logic;
    );
end ax309_top;

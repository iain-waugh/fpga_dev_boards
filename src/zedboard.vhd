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
    -- ----------------------------------------------------------------------------
    -- Clock Source - Bank 13
    clk_100MHz : in std_logic;          -- "GCLK"

    -- ----------------------------------------------------------------------------
    -- Audio Codec - Bank 13 - Connects to ADAU1761BCPZ
    i_audio_adr   : in    std_logic_vector(1 downto 0);  -- "AC-ADR[1:0]"
    io_audio_gpio : inout std_logic_vector(3 downto 0);  -- "AC-GPIO[3:0]"
    o_audio_mclk  : out   std_logic;                     -- "AC-MCLK"
    o_audio_sck   : out   std_logic;                     -- "AC-SCK"
    io_audio_sda  : inout std_logic;                     -- "AC-SDA"

    -- ----------------------------------------------------------------------------
    -- OLED Display - Bank 13
    o_oled_dc   : out std_logic;        -- "OLED-DC"
    o_oled_res  : out std_logic;        -- "OLED-RES"
    o_oled_sclk : out std_logic;        -- "OLED-SCLK"
    o_oled_sdin : out std_logic;        -- "OLED-SDIN"
    o_oled_vbat : out std_logic;        -- "OLED-VBAT"
    o_oled_vdd  : out std_logic;        -- "OLED-VDD"

    -- ----------------------------------------------------------------------------
    -- HDMI Output - Bank 33
    o_hd_clk    : out   std_logic;                      -- "HD-CLK"
    o_hd_hsync  : out   std_logic;                      -- "HD-HSYNC"
    o_hd_vsync  : out   std_logic;                      -- "HD-VSYNC"
    o_hd_d      : out   std_logic_vector(15 downto 0);  -- "HD-D[15:0]"
    o_hd_de     : out   std_logic;                      -- "HD-DE"
    o_hd_int    : out   std_logic;                      -- "HD-INT"
    io_hd_scl   : inout std_logic;                      -- "HD-SCL"
    io_hd_sda   : inout std_logic;                      -- "HD-SDA"
    o_hd_spdif  : out   std_logic;                      -- "HD-SPDIF"
    i_hd_spdifo : in    std_logic;                      -- "HD-SPDIFO"

    -- ----------------------------------------------------------------------------
    -- User LEDs - Bank 33
    o_led : out std_logic_vector(7 downto 0);  -- "LD[7:0]"

    -- ----------------------------------------------------------------------------
    -- VGA Output - Bank 33
    o_vga_hs    : out std_logic;                     -- "VGA-HS"
    o_vga_vs    : out std_logic;                     -- "VGA-VS"
    o_vga_red   : out unsigned(3 downto 0);  -- "VGA-R[3:0]"
    o_vga_green : out unsigned(3 downto 0);  -- "VGA-G[3:0]"
    o_vga_blue  : out unsigned(3 downto 0);  -- "VGA-B[3:0]"

    -- ----------------------------------------------------------------------------
    -- User Push Buttons - Bank 34
    i_btnc : in std_logic;              -- "BTNC"
    i_btnd : in std_logic;              -- "BTND"
    i_btnl : in std_logic;              -- "BTNL"
    i_btnr : in std_logic;              -- "BTNR"
    i_btnu : in std_logic;              -- "BTNU"

    -- ----------------------------------------------------------------------------
    -- USB OTG Reset - Bank 34
    o_otg_vbusoc : out std_logic;       -- "OTG-VBUSOC"

    -- ----------------------------------------------------------------------------
    -- XADC GIO - Bank 34
    io_xadc_gio : inout std_logic_vector(3 downto 0);  -- "XADC-GIO[3:0]"

    -- ----------------------------------------------------------------------------
    -- Miscellaneous - Bank 34
    i_pudc_b : in std_logic;            -- "PUDC_B"

    -- ----------------------------------------------------------------------------
    -- USB OTG Reset - Bank 35
    o_otg_reset_n : out std_logic;      -- "OTG-RESETN"

    -- ----------------------------------------------------------------------------
    -- User DIP Switches - Bank 35
    i_sw : in std_logic_vector(7 downto 0);  -- "SW[7:0]"

    -- ----------------------------------------------------------------------------
    -- XADC AD Channels - Bank 35
    i_ad0n_r : in std_logic;            -- "XADC-AD0N-R"
    i_ad0p_r : in std_logic;            -- "XADC-AD0P-R"
    i_ad8n_n : in std_logic;            -- "XADC-AD8N-R"
    i_ad8p_r : in std_logic;            -- "XADC-AD8P-R"

    -- ----------------------------------------------------------------------------
    -- FMC Expansion Connector - Bank 13
    io_fmc_scl : inout std_logic;       -- "FMC-SCL"
    io_fmc_sda : inout std_logic;       -- "FMC-SDA"

    -- ----------------------------------------------------------------------------
    -- FMC Expansion Connector - Bank 33
    i_fmc_prsnt : in std_logic          -- "FMC-PRSNT"
    );
end zedboard;

architecture zedboard_rtl of zedboard is

begin  -- zedboard_rtl


end zedboard_rtl;

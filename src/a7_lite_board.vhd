library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity a7_lite_board is
    port (
        ------------------------------------------------------
        -- 50MHz clock
        clk : in std_logic;

        ------------------------------------------------------
        -- Reset signal hooked up to K3
        rst : in std_logic;

        ------------------------------------------------------
        -- Two output LEDs
        o_led1 : out std_logic;
        o_led2 : out std_logic;

        ------------------------------------------------------
        -- Push buttons 1 and 2
        i_key1 : in std_logic;
        i_key2 : in std_logic;

        ------------------------------------------------------
        -- UART Interface hooked up to a USB converter
        o_uart_tx : out std_logic;
        i_uart_rx : in std_logic;

        ------------------------------------------------------
        -- MicroSD card interface
        o_sd_clk   : out std_logic;
        io_sd_data : inout std_logic_vector(3 downto 0);
        io_sd_cmd  : inout std_logic;

        ------------------------------------------------------
        -- DDR3 Ram signals
        -- Note: use UG583
        o_ddr3_clk_p, o_ddr3_clk_n : out std_logic;
        o_ddr3_clken : out std_logic;

        o_ddr3_addr  : out std_logic_vector(14 downto 0);
        o_ddr3_ba    : out std_logic_vector(2 downto 0);

        io_ddr3_dq   : inout std_logic_vector(15 downto 0);
        o_ddr3_dm    : out std_logic_vector(1 downto 0);
        io_ddr3_dqs_p, io_ddr3_dqs_n : inout std_logic_vector(1 downto 0);

        o_ddr3_nrst  : out std_logic;
        o_ddr3_n_wen : out std_logic;
        o_ddr3_n_ras : out std_logic;
        o_ddr3_n_cas : out std_logic;
        o_ddr3_odt   : out std_logic;

        ------------------------------------------------------
        -- HDMI Signals
        o_hdmi_scl : out std_logic;
        io_hdmi_sda : inout std_logic;

        o_hdmi_d_p, o_hdmi_d_n : out std_logic_vector(2 downto 0);
        o_hdmi_clk_p, o_hdmi_clk_n : out std_logic
    );
end entity;

architecture a7_lite_board_rtl of a7_lite_board is

begin

end architecture a7_lite_board_rtl;
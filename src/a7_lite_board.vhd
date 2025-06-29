library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.util_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity a7_lite_board is
    port (
        ------------------------------------------------------
        -- 50MHz clock
        i_clk_50 : in std_logic;

        ------------------------------------------------------
        -- Reset signal hooked up to K3
        i_nrst : in std_logic;

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
        o_ddr3_clk_p : out std_logic;
        o_ddr3_clk_n : out std_logic;
        o_ddr3_clken : out std_logic;

        o_ddr3_addr  : out std_logic_vector(14 downto 0);
        o_ddr3_ba    : out std_logic_vector(2 downto 0);

        io_ddr3_dq   : inout std_logic_vector(15 downto 0);
        o_ddr3_dm    : out std_logic_vector(1 downto 0);
        io_ddr3_dqs_p : inout std_logic_vector(1 downto 0);
        io_ddr3_dqs_n : inout std_logic_vector(1 downto 0);

        o_ddr3_nrst  : out std_logic;
        o_ddr3_n_wen : out std_logic;
        o_ddr3_n_ras : out std_logic;
        -- o_ddr3_n_cas : out std_logic;
        o_ddr3_odt   : out std_logic;

        ------------------------------------------------------
        -- HDMI Signals
        o_hdmi_scl : out std_logic;
        io_hdmi_sda : inout std_logic;

        o_hdmi_d_p : out std_logic_vector(2 downto 0);
        o_hdmi_d_n : out std_logic_vector(2 downto 0);
        o_hdmi_clk_p : out std_logic;
        o_hdmi_clk_n : out std_logic
    );
end entity;

architecture a7_lite_board_rtl of a7_lite_board is
    signal clk_250 : std_logic;
    signal rst_250 : std_logic;

    signal pulses : std_logic_vector(7 downto 0);

    signal hdmi_tmds_d : std_logic_vector(2 downto 0);
    signal hdmi_clk : std_logic;
begin
    clk_gen_inst: entity work.clk_gen
     generic map (
        G_CLOCKS_USED => 1,
        G_CLKFBOUT_MULT => 20, -- 1GHz internal PLL
        G_CLKFBOUT_PHASE => 0.0,
        G_CLKIN_PERIOD => 20.0,

        G_CLKOUT0_DIVIDE => 4,  -- 250MHz system clock
        G_CLKOUT0_DUTY_CYCLE => 0.5,
        G_CLKOUT0_PHASE => 0.0
    )
     port map(
        clk => i_clk_50,
        rst => "not"(i_nrst),

        o_clk_0 => clk_250,
        o_rst_0 => rst_250
    );


    inst_pulse_gen: entity work.pulse_gen
     generic map(
        G_POWERS_OF_100NS => 8,
        G_CLKS_IN_100NS => 25,
        G_ALIGN_OUTPUTS => true
    )
     port map(
        clk => clk_250,
        rst => rst_250,
        o_pulse_at_100ns_x_10e => pulses
    );

    hello_world_inst: entity work.hello_world
     port map(
        clk => clk_250,
        i_pulse => pulses(7),
        o_toggle => o_led1
    );

    o_led2 <= '1';

    o_uart_tx <= '0';
    
    o_sd_clk <= '0';
    io_sd_data <= (others => '0');
    io_sd_cmd <= '0';

    o_ddr3_clk_p <= '0';
    o_ddr3_clk_n <= '0';
    o_ddr3_clken <= '0';
    o_ddr3_addr <= (others => '0');
    o_ddr3_ba <= (others => '0');
    io_ddr3_dq <= (others => '0');
    o_ddr3_dm <= (others => '0');
    io_ddr3_dqs_p <= (others => '0');
    io_ddr3_dqs_n <= (others => '0');
    o_ddr3_nrst <= '0'; -- keep the DDR3 resetting as its not in use
    o_ddr3_n_wen <= '1';
    o_ddr3_n_ras <= '1';
    -- o_ddr3_n_cas <= '1';
    o_ddr3_odt <= '0';

    o_hdmi_scl <= '0';
    io_hdmi_sda <= '0';

    hdmi_tmds_d <= (others => '0');
    hdmi_clk <= '0';

    g_buf_hdmi_tmds : for i in 0 to 2 generate
        hdmi_tmds_buf : OBUFDS
        port map(
            O  => o_hdmi_d_p(i),
            OB => o_hdmi_d_n(i),
            I => hdmi_tmds_d(i)
        );
    end generate g_buf_hdmi_tmds;
    
    hdmi_clk_buf : OBUFDS
    port map(
        O => o_hdmi_clk_p,
        OB => o_hdmi_clk_n,
        I => hdmi_clk
    );
end architecture a7_lite_board_rtl;

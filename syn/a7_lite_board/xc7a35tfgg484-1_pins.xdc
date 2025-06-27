# Basic IO - CLK, Buttons and LEDs
set_property PACKAGE_PIN J19 [get_ports {i_clk_50}]
set_property PACKAGE_PIN L18 [get_ports {i_nrst}]
set_property PACKAGE_PIN AA1 [get_ports {i_key1}]
set_property PACKAGE_PIN W1  [get_ports {i_key2}]
set_property PACKAGE_PIN M18 [get_ports {o_led1}]
set_property PACKAGE_PIN N18 [get_ports {o_led2}]

# UART
set_property PACKAGE_PIN U2 [get_ports {i_uart_rx}]
set_property PACKAGE_PIN V2 [get_ports {o_uart_tx}]

# MicroSD Card Interface
set_property PACKAGE_PIN AA8 [get_ports {io_sd_cmd}]
set_property PACKAGE_PIN U7 [get_ports {o_sd_clk}]
set_property PACKAGE_PIN W9 [get_ports {io_sd_data[0]}]
set_property PACKAGE_PIN Y9 [get_ports {io_sd_data[1]}]
set_property PACKAGE_PIN Y7 [get_ports {io_sd_data[2]}]
set_property PACKAGE_PIN Y8 [get_ports {io_sd_data[3]}]

# DDR3 pins
set_property PACKAGE_PIN N5 [get_ports {o_ddr3_addr[14]}]
set_property PACKAGE_PIN L5 [get_ports {o_ddr3_addr[13]}]
set_property PACKAGE_PIN L4 [get_ports {o_ddr3_addr[12]}]
set_property PACKAGE_PIN P6 [get_ports {o_ddr3_addr[11]}]
set_property PACKAGE_PIN M2 [get_ports {o_ddr3_addr[10]}]
set_property PACKAGE_PIN L1 [get_ports {o_ddr3_addr[9]}]
set_property PACKAGE_PIN P2 [get_ports {o_ddr3_addr[8]}]
set_property PACKAGE_PIN K6 [get_ports {o_ddr3_addr[7]}]
set_property PACKAGE_PIN N2 [get_ports {o_ddr3_addr[6]}]
set_property PACKAGE_PIN J6 [get_ports {o_ddr3_addr[5]}]
set_property PACKAGE_PIN M5 [get_ports {o_ddr3_addr[4]}]
set_property PACKAGE_PIN K4 [get_ports {o_ddr3_addr[3]}]
set_property PACKAGE_PIN K3 [get_ports {o_ddr3_addr[2]}]
set_property PACKAGE_PIN M6 [get_ports {o_ddr3_addr[1]}]
set_property PACKAGE_PIN P1 [get_ports {o_ddr3_addr[0]}]

set_property PACKAGE_PIN J4 [get_ports {o_ddr3_ba[0]}]
set_property PACKAGE_PIN R1 [get_ports {o_ddr3_ba[1]}]
set_property PACKAGE_PIN M1 [get_ports {o_ddr3_ba[2]}]

#set_property PACKAGE_PIN N3 [get_ports {o_ddr3_n_cas}]
set_property PACKAGE_PIN N4 [get_ports {o_ddr3_clken}]

set_property PACKAGE_PIN P4 [get_ports {o_ddr3_clk_n}]
set_property PACKAGE_PIN P5 [get_ports {o_ddr3_clk_p}]

set_property PACKAGE_PIN E2 [get_ports {o_ddr3_dm[0]}]
set_property PACKAGE_PIN H3 [get_ports {o_ddr3_dm[1]}]

set_property PACKAGE_PIN B2 [get_ports {io_ddr3_dq[0]}]
set_property PACKAGE_PIN F1 [get_ports {io_ddr3_dq[1]}]
set_property PACKAGE_PIN B1 [get_ports {io_ddr3_dq[2]}]
set_property PACKAGE_PIN D2 [get_ports {io_ddr3_dq[3]}]
set_property PACKAGE_PIN C2 [get_ports {io_ddr3_dq[4]}]
set_property PACKAGE_PIN F3 [get_ports {io_ddr3_dq[5]}]
set_property PACKAGE_PIN A1 [get_ports {io_ddr3_dq[6]}]
set_property PACKAGE_PIN G1 [get_ports {io_ddr3_dq[7]}]
set_property PACKAGE_PIN J5 [get_ports {io_ddr3_dq[8]}]
set_property PACKAGE_PIN G2 [get_ports {io_ddr3_dq[9]}]
set_property PACKAGE_PIN K1 [get_ports {io_ddr3_dq[10]}]
set_property PACKAGE_PIN G3 [get_ports {io_ddr3_dq[11]}]
set_property PACKAGE_PIN H2 [get_ports {io_ddr3_dq[12]}]
set_property PACKAGE_PIN H5 [get_ports {io_ddr3_dq[13]}]
set_property PACKAGE_PIN J1 [get_ports {io_ddr3_dq[14]}]
set_property PACKAGE_PIN H4 [get_ports {io_ddr3_dq[15]}]

set_property PACKAGE_PIN D1 [get_ports {io_ddr3_dqs_n[0]}]
set_property PACKAGE_PIN J2 [get_ports {io_ddr3_dqs_n[1]}]

set_property PACKAGE_PIN E1 [get_ports {io_ddr3_dqs_p[0]}]
set_property PACKAGE_PIN K2 [get_ports {io_ddr3_dqs_p[1]}]

set_property PACKAGE_PIN F4 [get_ports {o_ddr3_nrst}]
set_property PACKAGE_PIN L3 [get_ports {o_ddr3_odt}]
set_property PACKAGE_PIN M3 [get_ports {o_ddr3_n_ras}]
set_property PACKAGE_PIN L6 [get_ports {o_ddr3_n_wen}]

# HDMI pins
set_property PACKAGE_PIN J14 [get_ports {o_hdmi_scl}]
set_property PACKAGE_PIN H14 [get_ports {io_hdmi_sda}]

set_property PACKAGE_PIN K21 [get_ports {o_hdmi_d_p[0]}]
set_property PACKAGE_PIN J20 [get_ports {o_hdmi_d_p[1]}]
set_property PACKAGE_PIN G17 [get_ports {o_hdmi_d_p[2]}]

set_property PACKAGE_PIN K22 [get_ports {o_hdmi_d_n[0]}]
set_property PACKAGE_PIN J21 [get_ports {o_hdmi_d_n[1]}]
set_property PACKAGE_PIN G18 [get_ports {o_hdmi_d_n[2]}]

set_property PACKAGE_PIN L19 [get_ports {o_hdmi_clk_p}]
set_property PACKAGE_PIN L20 [get_ports {o_hdmi_clk_n}]

######################################################################
# IO Standards

# Basic ports
set_property IOSTANDARD LVCMOS33 [get_ports {
    i_clk_50 i_nrst i_key1 i_key2 o_led1 o_led2 o_uart_tx i_uart_rx 
    o_sd_clk io_sd_data io_sd_cmd o_hdmi_scl io_hdmi_sda
}]

# HDMI
set_property IOSTANDARD TMDS_33 [get_ports { o_hdmi_d_p o_hdmi_d_n o_hdmi_clk_p o_hdmi_clk_n }]

# DDR3 Ram
set_property IOSTANDARD SSTL135 [get_ports -of_objects [get_iobanks 35]];

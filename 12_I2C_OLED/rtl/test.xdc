set_property PACKAGE_PIN E3 [get_ports clk]
set_property PACKAGE_PIN C2 [get_ports rst_n]
set_property PACKAGE_PIN A18 [get_ports SDA]
set_property PACKAGE_PIN K16 [get_ports SCL]

set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports SDA]
set_property IOSTANDARD LVCMOS33 [get_ports SCL]


set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

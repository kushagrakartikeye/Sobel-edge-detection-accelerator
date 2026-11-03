## Configuration Settings
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Primary 100MHz Clock (Nexys 4 DDR onboard oscillator E3)
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports clk]

## Controls
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports rst]
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports enable]

## Output Indicator (LED LD0)
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports edge_out]

## 8-Bit Threshold Bus (Switches SW1 to SW8)
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports {threshold[0]}]
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports {threshold[1]}]
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports {threshold[2]}]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports {threshold[3]}]
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports {threshold[4]}]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports {threshold[5]}]
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports {threshold[6]}]
set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS33 } [get_ports {threshold[7]}]

## USB-UART Interface Pins (Nexys 4 DDR FTDI Bridge)
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports uart_rxd]
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports uart_txd]

## False Paths (Ignores timing analysis for asynchronous switches/LEDs/UART)
set_false_path -from [get_ports {rst enable threshold[*] uart_rxd}]
set_false_path -to [get_ports {edge_out uart_txd}]
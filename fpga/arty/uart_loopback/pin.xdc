# Clock signal
set_property -dict {IOSTANDARD LVCMOS33  PACKAGE_PIN E3} [get_ports { CLOCK_100 }];

# Reset
set_property -dict {IOSTANDARD LVCMOS33  PACKAGE_PIN C2} [get_ports { RESETn }];

## Uart TX/RX
set_property -dict {IOSTANDARD LVCMOS33  PACKAGE_PIN D10} [get_ports { UART_TXD }];
set_property -dict {IOSTANDARD LVCMOS33  PACKAGE_PIN A9}  [get_ports { UART_RXD }];

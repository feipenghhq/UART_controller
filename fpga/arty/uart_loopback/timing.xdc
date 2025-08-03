# Main clock
create_clock -period 10.000 [get_ports CLOCK_100]
set_input_jitter [get_clocks -of_objects [get_ports CLOCK_100]] 0.100
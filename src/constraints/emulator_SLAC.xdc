#------------------------------------------------------------------------------
#
# Constraint file for RD53 Emulator in a xc7k160 on SLAC SA-256-100-98-C00 
# RD53 Readout Board
#
# Single instance of Emulator
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Version number for bitfile that can be seen at the top of the 'bit' file and
# can be read by the Hardware Manager
# '51AC' ~ 'SLAC'  :-)
#------------------------------------------------------------------------------
# Versions
# 0300      Initial version with project moved to Vivado 2017.4
#------------------------------------------------------------------------------
# "03xx" used hitmaker3 with a ROM
set_property BITSTREAM.CONFIG.USERID 32'h51AC0300 [current_design]
# "04xx" used hitmaker4 with a DPRAM loaded by CPU
#set_property BITSTREAM.CONFIG.USERID 32'h51AC0400 [current_design]

################################## Clock Constraints ##########################
## Clock freq 156.25 MHz
##create_clock -period 6.400 -waveform {0.000 3.200} [get_ports USER_SMA_CLOCK_P]

## Clock freq 160 MHz
#create_clock -period 6.25 -waveform {0.000 3.125} [get_ports USER_SMA_CLOCK_P] 

## Clock freq 250 MHz
create_clock -period 4.0 -waveform {0.000 2.0} [get_ports USER_SMA_CLOCK_P] 


################################# Location constraints ########################


#------------------------------------------------------------------------------
# Input clock USER_SMA_CLOCK on schematic nets EXT_CLK0_P and EXT_CLK0_M
# BANK16 2.5V
#------------------------------------------------------------------------------
set_property    PACKAGE_PIN E11         [get_ports USER_SMA_CLOCK_P]
set_property    IOSTANDARD  LVDS_25     [get_ports USER_SMA_CLOCK_P]
set_property    DIFF_TERM   TRUE        [get_ports USER_SMA_CLOCK_*]

set_property    PACKAGE_PIN D11         [get_ports USER_SMA_CLOCK_N]
set_property    IOSTANDARD  LVDS_25     [get_ports USER_SMA_CLOCK_N]



#------------------------------------------------------------------------------
# Trigger and Control inputs, Debug outputs to display port sockets
# BANK15 2.5V
# Schematics nets FEB0_CMD_P/CMD_M from Displayport conn DP1A
#------------------------------------------------------------------------------
set_property    IOSTANDARD  LVDS_25     [get_ports ttc_data_*]
set_property    DIFF_TERM   TRUE        [get_ports ttc_data_*]


set_property    PACKAGE_PIN F15         [get_ports ttc_data_p]
set_property    PACKAGE_PIN F16         [get_ports ttc_data_n]

# Since this is for a single RD53 instance there is only one ttc input pair
#   DP2A
#   set_property    PACKAGE_PIN B16         [get_ports ttc_data_p[1]]
#   set_property    PACKAGE_PIN A16         [get_ports ttc_data_n[1]]
#   
#   DP3A
#   set_property    PACKAGE_PIN F18         [get_ports ttc_data_p[2]]
#   set_property    PACKAGE_PIN E19         [get_ports ttc_data_n[2]]
#   
#   DP4A
#   set_property    PACKAGE_PIN A20         [get_ports ttc_data_p[3]]
#   set_property    PACKAGE_PIN A21         [get_ports ttc_data_n[3]]

#------------------------------------------------------------------------------
# Debug outputs
#------------------------------------------------------------------------------
set_property    IOSTANDARD  LVCMOS25    [get_ports p_debug*]
set_property    PACKAGE_PIN B13	        [get_ports {p_debug[0]}]
set_property    PACKAGE_PIN C13	        [get_ports {p_debug[1]}]
set_property    PACKAGE_PIN A14	        [get_ports {p_debug[2]}]
set_property    PACKAGE_PIN A13	        [get_ports {p_debug[3]}]
set_property    PACKAGE_PIN B12	        [get_ports {p_debug[4]}]
set_property    PACKAGE_PIN C12	        [get_ports {p_debug[5]}]
set_property    PACKAGE_PIN G16	        [get_ports {p_debug[6]}]
set_property    PACKAGE_PIN G15	        [get_ports {p_debug[7]}]
set_property    PACKAGE_PIN A18	        [get_ports {p_debug[8]}]
set_property    PACKAGE_PIN B17	        [get_ports {p_debug[9]}]
set_property    PACKAGE_PIN A15	        [get_ports {p_debug[10]}]
set_property    PACKAGE_PIN B15	        [get_ports {p_debug[11]}]
set_property    PACKAGE_PIN C15	        [get_ports {p_debug[12]}]
set_property    PACKAGE_PIN C14	        [get_ports {p_debug[13]}]
set_property    PACKAGE_PIN D14	        [get_ports {p_debug[14]}]
set_property    PACKAGE_PIN E14	        [get_ports {p_debug[15]}]
set_property    PACKAGE_PIN C20	        [get_ports {p_debug[16]}]
set_property    PACKAGE_PIN C19	        [get_ports {p_debug[17]}]
set_property    PACKAGE_PIN D20	        [get_ports {p_debug[18]}]
set_property    PACKAGE_PIN D19	        [get_ports {p_debug[19]}]
set_property    PACKAGE_PIN J17	        [get_ports {p_debug[20]}]
set_property    PACKAGE_PIN J16	        [get_ports {p_debug[21]}]
set_property    PACKAGE_PIN G17	        [get_ports {p_debug[22]}]
set_property    PACKAGE_PIN H17	        [get_ports {p_debug[23]}]
set_property    PACKAGE_PIN B21	        [get_ports {p_debug[24]}]
set_property    PACKAGE_PIN B20	        [get_ports {p_debug[25]}]
set_property    PACKAGE_PIN D22	        [get_ports {p_debug[26]}]
set_property    PACKAGE_PIN D21	        [get_ports {p_debug[27]}]
set_property    PACKAGE_PIN B22	        [get_ports {p_debug[28]}]
set_property    PACKAGE_PIN C22	        [get_ports {p_debug[29]}]

set_property    IOSTANDARD  LVCMOS25    [get_ports p_uart*]
set_property    PACKAGE_PIN A19	        [get_ports p_uart_rxd]
set_property    PACKAGE_PIN B18	        [get_ports p_uart_txd]
#   set_property    PACKAGE_PIN A19	        [get_ports {p_debug[30]}]
#   set_property    PACKAGE_PIN B18	        [get_ports {p_debug[31]}]



#------------------------------------------------------------------------------
# CHIP OUTPUT to YARR through Displayport connector DP1A
# BANK33 1.8V
# Schematic nets FEB0_GRX0_P/M, FEB0_GRX1_P/M, FEB0_GRX0_P/M, FEB0_GRX3_P/M
#------------------------------------------------------------------------------
set_property    IOSTANDARD  LVDS    [get_ports cmd_out_*]
set_property    DIFF_TERM   TRUE    [get_ports cmd_out_p[*]]
#------------------------------------------------------------------------------
# Lane 0
set_property    PACKAGE_PIN AA6     [get_ports cmd_out_p[0]]
set_property    PACKAGE_PIN AB6     [get_ports cmd_out_n[0]]

# Lane 1
set_property    PACKAGE_PIN AA9     [get_ports cmd_out_p[1]]
set_property    PACKAGE_PIN AA8     [get_ports cmd_out_n[1]]

# Lane 2
set_property    PACKAGE_PIN U8      [get_ports cmd_out_p[2]]
set_property    PACKAGE_PIN V8      [get_ports cmd_out_n[2]]

# Lane 3
set_property    PACKAGE_PIN V7      [get_ports cmd_out_p[3]]
set_property    PACKAGE_PIN W7      [get_ports cmd_out_n[3]]



#------------------------------------------------------------------------------
# Bank 14 3.3V
#------------------------------------------------------------------------------
# LED drive outputs
#------------------------------------------------------------------------------
set_property    IOSTANDARD  LVCMOS33    [get_ports {led[*]}]
set_property    PACKAGE_PIN N17         [get_ports {led[0]}]
set_property    PACKAGE_PIN R21         [get_ports {led[1]}]
set_property    PACKAGE_PIN R22         [get_ports {led[2]}]
set_property    PACKAGE_PIN M16         [get_ports {led[3]}]

#------------------------------------------------------------------------------
# Coax i/o on SLAC board
#------------------------------------------------------------------------------
# TRIG_L
#   set_property   PACKAGE_PIN N18          [get_ports trig_l]
#   set_property   IOSTANDARD  LVCMOS33     [get_ports trig_l]

# HITIN_L
#   set_property   PACKAGE_PIN L19          [get_ports hitin_l]
#   set_property   IOSTANDARD  LVCMOS33     [get_ports hitin_l]

# HITOUT
#   set_property   PACKAGE_PIN M17          [get_ports hitout]
#   set_property   IOSTANDARD  LVCMOS33     [get_ports hitout]


#------------------------------------------------------------------------------
# Power supply sync drivers (For switching power supply noise reduction?)
#------------------------------------------------------------------------------
# PWR_SYNC_SCLK
#   set_property   PACKAGE_PIN J19          [get_ports pwr_sync_sclk]
#   set_property   IOSTANDARD  LVCMOS33     [get_ports pwr_sync_sclk]

# PWR_SYNC_FCLK
#   set_property   PACKAGE_PIN G20          [get_ports pwr_sync_fclk]
#   set_property   IOSTANDARD  LVCMOS33     [get_ports pwr_sync_fclk]


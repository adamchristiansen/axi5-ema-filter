# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Adam Christiansen

# These must match the testbench.
set width 24
set radix 10

# Indices for the sugnal buses.
set upper [expr $width - 1]
set lower 0

# Signal names.
set ema_aclk            "top.ema_filter_tb.ema_aclk"
set ema_aresetn         "top.ema_filter_tb.ema_aresetn"
set ema_s_axis_x_tdata  "top.ema_filter_tb.ema_s_axis_x_tdata\[$upper:$lower\]"
set ema_s_axis_x_tvalid "top.ema_filter_tb.ema_s_axis_x_tvalid"
set ema_m_axis_y_tdata  "top.ema_filter_tb.ema_m_axis_y_tdata\[$upper:$lower\]"
set ema_m_axis_y_tvalid "top.ema_filter_tb.ema_m_axis_y_tvalid"
set ema_alpha           "top.ema_filter_tb.ema_alpha\[$upper:$lower\]"

# Add signals.
gtkwave::/Edit/Insert_Comment "Clock & Reset"
gtkwave::addSignalsFromList [list $ema_aclk $ema_aresetn]
gtkwave::/Edit/Insert_Blank
gtkwave::/Edit/Insert_Comment "Input Signal"
gtkwave::addSignalsFromList [list $ema_s_axis_x_tdata $ema_s_axis_x_tvalid]
gtkwave::/Edit/Insert_Blank
gtkwave::/Edit/Insert_Comment "Filtered Signal"
gtkwave::addSignalsFromList [list $ema_m_axis_y_tdata $ema_m_axis_y_tvalid]
gtkwave::/Edit/Insert_Blank
gtkwave::/Edit/Insert_Comment "EMA Coefficient"
gtkwave::addSignalsFromList [list $ema_alpha]

# Set all of the listed waveforms to fixed-point.
#
# Loop over each waveform instead of highlighting all and manipulating them as a batch. Some
# commands do not work as a batch and instead only modify the most recently highlighted waveform.
foreach name [list $ema_s_axis_x_tdata $ema_m_axis_y_tdata $ema_alpha] {
    gtkwave::highlightSignalsFromList [list $name]
    gtkwave::/Edit/Data_Format/Signed_Decimal
    gtkwave::/Edit/Data_Format/Fixed_Point_Shift/Specify $radix
    gtkwave::/Edit/Data_Format/Fixed_Point_Shift/On
    gtkwave::setTraceHighlightFromNameMatch $name off
    gtkwave::unhighlightSignalsFromList [list $name]
}

# Set all of the listed waveforms as analog.
#
# Loop over each waveform instead of highlighting all and manipulating them as a batch. Some
# commands do not work as a batch and instead only modify the most recently highlighted waveform.
foreach name [list $ema_s_axis_x_tdata $ema_m_axis_y_tdata] {
    gtkwave::highlightSignalsFromList [list $name]
    gtkwave::/Edit/Data_Format/Analog/Step
    gtkwave::/Edit/Insert_Analog_Height_Extension
    gtkwave::/Edit/Insert_Analog_Height_Extension
    gtkwave::/Edit/Insert_Analog_Height_Extension
    gtkwave::unhighlightSignalsFromList [list $name]
}

# View settings.
gtkwave::nop
gtkwave::/Time/Zoom/Zoom_Full

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DONE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DOWN_OUT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ERROR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "IDEL" -parent ${Page_0}
  ipgui::add_param $IPINST -name "PACK_NUM" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SAMP_DATA" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SYNC_STAT" -parent ${Page_0}


}

proc update_PARAM_VALUE.DONE { PARAM_VALUE.DONE } {
	# Procedure called to update DONE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DONE { PARAM_VALUE.DONE } {
	# Procedure called to validate DONE
	return true
}

proc update_PARAM_VALUE.DOWN_OUT { PARAM_VALUE.DOWN_OUT } {
	# Procedure called to update DOWN_OUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DOWN_OUT { PARAM_VALUE.DOWN_OUT } {
	# Procedure called to validate DOWN_OUT
	return true
}

proc update_PARAM_VALUE.ERROR { PARAM_VALUE.ERROR } {
	# Procedure called to update ERROR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ERROR { PARAM_VALUE.ERROR } {
	# Procedure called to validate ERROR
	return true
}

proc update_PARAM_VALUE.IDEL { PARAM_VALUE.IDEL } {
	# Procedure called to update IDEL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IDEL { PARAM_VALUE.IDEL } {
	# Procedure called to validate IDEL
	return true
}

proc update_PARAM_VALUE.PACK_NUM { PARAM_VALUE.PACK_NUM } {
	# Procedure called to update PACK_NUM when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PACK_NUM { PARAM_VALUE.PACK_NUM } {
	# Procedure called to validate PACK_NUM
	return true
}

proc update_PARAM_VALUE.SAMP_DATA { PARAM_VALUE.SAMP_DATA } {
	# Procedure called to update SAMP_DATA when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SAMP_DATA { PARAM_VALUE.SAMP_DATA } {
	# Procedure called to validate SAMP_DATA
	return true
}

proc update_PARAM_VALUE.SYNC_STAT { PARAM_VALUE.SYNC_STAT } {
	# Procedure called to update SYNC_STAT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SYNC_STAT { PARAM_VALUE.SYNC_STAT } {
	# Procedure called to validate SYNC_STAT
	return true
}


proc update_MODELPARAM_VALUE.IDEL { MODELPARAM_VALUE.IDEL PARAM_VALUE.IDEL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IDEL}] ${MODELPARAM_VALUE.IDEL}
}

proc update_MODELPARAM_VALUE.SYNC_STAT { MODELPARAM_VALUE.SYNC_STAT PARAM_VALUE.SYNC_STAT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SYNC_STAT}] ${MODELPARAM_VALUE.SYNC_STAT}
}

proc update_MODELPARAM_VALUE.PACK_NUM { MODELPARAM_VALUE.PACK_NUM PARAM_VALUE.PACK_NUM } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PACK_NUM}] ${MODELPARAM_VALUE.PACK_NUM}
}

proc update_MODELPARAM_VALUE.SAMP_DATA { MODELPARAM_VALUE.SAMP_DATA PARAM_VALUE.SAMP_DATA } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SAMP_DATA}] ${MODELPARAM_VALUE.SAMP_DATA}
}

proc update_MODELPARAM_VALUE.ERROR { MODELPARAM_VALUE.ERROR PARAM_VALUE.ERROR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ERROR}] ${MODELPARAM_VALUE.ERROR}
}

proc update_MODELPARAM_VALUE.DONE { MODELPARAM_VALUE.DONE PARAM_VALUE.DONE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DONE}] ${MODELPARAM_VALUE.DONE}
}

proc update_MODELPARAM_VALUE.DOWN_OUT { MODELPARAM_VALUE.DOWN_OUT PARAM_VALUE.DOWN_OUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DOWN_OUT}] ${MODELPARAM_VALUE.DOWN_OUT}
}



local mui = include( "mui/mui" )
local MUI = mui.internals

local mui_mf_lineleader = include( SCRIPT_PATHS.qed_uitr .. "/mui/mui_mf_lineleader" )

local oldInitMui = mui.initMui
function mui.initMui( ... )
	oldInitMui( ... )

	MUI._widgetFactory["uitrMainframeLineLeader"] = mui_mf_lineleader
end

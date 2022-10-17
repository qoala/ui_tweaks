
function checkOption( optionId )
	local settingsFile = savefiles.getSettings( "settings" )
	local uitr = settingsFile.data.uitr
	return uitr and uitr[optionId]
end

function getOptions( )
	local settingsFile = savefiles.getSettings( "settings" )
	return settingsFile.data.uitr or {}
end

return {
	checkOption = checkOption,
	getOptions = getOptions,
}

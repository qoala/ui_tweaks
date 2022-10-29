local mui_defs = include( "mui/mui_defs")
local mui_tooltip = include( "mui/mui_tooltip")
local util = include( "client_util" )
local array = include( "modules/array" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local options_dialog = include( "hud/options_dialog" )

local uitr_util = include( SCRIPT_PATHS.qed_uitr .. "/uitr_util" )

-- ===

local function getValue( uitrSettings, optionDef )
	local value = uitrSettings[optionDef.id]
	if value ~= nil then
		return value
	-- Otherwise return the default value
	elseif optionDef.value ~= nil then
		return optionDef.value
	elseif optionDef.check then
		return true
	end
end

local function initUitrSettings( settings )
	if not settings.uitr then settings.uitr = {} end

	for _,optionDef in ipairs( uitr_util.UITR_OPTIONS ) do
		if settings.uitr[optionDef.id] == nil then
			settings.uitr[optionDef.id] = getValue(settings.uitr, optionDef)
		end
	end
end

local function onClickUitrResetOptions( dialog )
	dialog:refreshUitrSettings( {} )
end

-- ===

local function checkOptionApply( self, uitrSettings, widget )
	uitrSettings[self.id] = widget:getValue()
	return uitrSettings[self.id]
end
local function checkOptionRetrieve( self, uitrSettings )
	return getValue(uitrSettings, self)
end
local function comboOptionApply( self, uitrSettings, widget )
	uitrSettings[self.id] = self.values[widget:getIndex()]
	return uitrSettings[self.id]
end
local function comboOptionRetrieve( self, uitrSettings )
	if self.strings then
		return self.strings[array.find(self.values, getValue(uitrSettings, self))]
	else
		return tostring(getValue(uitrSettings, self))
	end
end

local function checkNeedsCampaign( self, setting, widget )
	if setting.needsCampaign and self._game then
		local value = setting:apply({}, widget.binder.widget)
		local uiTweaks = self._game.simCore:getParams().difficultyOptions.uiTweaks
		local uitrNeedsCampaignWarning = widget.binder.uitrNeedsCampaignWarning
		uitrNeedsCampaignWarning:setVisible( value and not uiTweaks )
	end
end

local function onChangedOption( self, setting, widget )
	-- Enable/Disable other options
	if setting.maskFn then
		self:refreshUitrMasks()
	end

	-- Reload warnings
	if setting.needsReload and self._game then
		local tempSettings = {}
		self:retrieveUitrSettings(tempSettings)
		local originalSettings = self._originalSettings.uitr or {}

		local needsReload = false
		for _,optionDef in ipairs( uitr_util.UITR_OPTIONS ) do
			if optionDef.needsReload and getValue(tempSettings, optionDef) ~= getValue(originalSettings, optionDef) then
				needsReload = true
			end
		end

		local uitrReloadWarning = self._screen.binder.uitrReloadWarning
		uitrReloadWarning:setVisible( needsReload )
	end
	checkNeedsCampaign( self, setting, widget )
end

-- ===

local oldInit = options_dialog.init
function options_dialog:init(...)
	oldInit(self, ...)

	local oldOnClick = self._screen.binder.acceptBtn.binder.btn.onClick._fn
	local oldRetrieveSettings
	local oldRetrieveSettingsIndex
	do
		local i = 1
		while true do
			local n, v = debug.getupvalue(oldOnClick, i)
			assert(n)
			if n == "retrieveSettings" then
				oldRetrieveSettings = v
				oldRetrieveSettingsIndex = i
				break
			end
			i = i + 1
		end
	end

	local retrieveSettings = function(dialog)
		local settings = oldRetrieveSettings(dialog)

		if not settings.uitr then settings.uitr = {} end
		dialog:retrieveUitrSettings( settings.uitr )

		return settings
	end

	debug.setupvalue(oldOnClick, oldRetrieveSettingsIndex, retrieveSettings)
end

local oldShow = options_dialog.show
function options_dialog:show(...)
	oldShow(self, ...)

	local uitrResetBtn = self._screen.binder.uitrResetOptionsBtn
	uitrResetBtn:setText( STRINGS.UITWEAKSR.UI.BTN_RESET_OPTIONS )
	uitrResetBtn.onClick = util.makeDelegate(nil, onClickUitrResetOptions, self)

	local uitrReloadWarning = self._screen.binder.uitrReloadWarning
	uitrReloadWarning:setText( STRINGS.UITWEAKSR.UI.RELOAD_WARNING )

	if not self._appliedSettings.uitr then self._appliedSettings.uitr = {} end
	self:refreshUitrSettings( self._appliedSettings.uitr )
end

local oldHide = options_dialog.hide
function options_dialog:hide( ... )
	oldHide(self, ...)

	if self._game and self._game.hud then
		self._game.hud:refreshHud()
	end
end

function options_dialog:refreshUitrSettings( uitrSettings )
	local list = self._screen.binder.uitrOptionsList
	list:clearItems()

	for _,optionDef in ipairs( uitr_util.UITR_OPTIONS ) do
		local setting = util.tdupe(optionDef)
		local widget
		if setting.check then
			widget = list:addItem( setting, "CheckOption" )
			widget.binder.widget:setText( setting.name )
			widget.binder.widget.onClick = util.makeDelegate( nil, onChangedOption, self, setting, widget )
			widget.binder.sectionHeaderLine:setVisible( not not setting.sectionHeader )
			widget.binder.uitrNeedsCampaignWarning:setText( STRINGS.UITWEAKSR.UI.CAMPAIGN_WARNING )

			setting.apply = checkOptionApply
			setting.retrieve = checkOptionRetrieve
			widget.binder.widget:setValue( setting:retrieve(uitrSettings) )
			checkNeedsCampaign( self, setting, widget )
		elseif setting.values then
			widget = list:addItem( setting, "ComboOption" )
			widget.binder.dropTxt:setText( setting.name )
			for i, item in ipairs(setting.values) do
				widget.binder.widget:addItem( setting.strings and setting.strings[i] or item )
			end
			widget.binder.widget.onTextChanged = util.makeDelegate( nil, onChangedOption, self, setting, widget )
			widget.binder.sectionHeaderLine:setVisible( not not setting.sectionHeader )
			widget.binder.uitrNeedsCampaignWarning:setText( STRINGS.UITWEAKSR.UI.CAMPAIGN_WARNING )

			setting.apply = comboOptionApply
			setting.retrieve = comboOptionRetrieve
			widget.binder.widget:setValue( setting:retrieve(uitrSettings) )
			checkNeedsCampaign( self, setting, widget )
		elseif setting.spacer then
			widget = list:addItem( setting, "OptionSpacer" )
		end
		widget:setTooltip( setting.tip )

		setting.list_index = list:getItemCount()
		assert(setting.list_index > 0)
	end

	list:scrollItems(0)
	self:refreshUitrMasks()
end

function options_dialog:retrieveUitrSettings( uitrSettings )
	local items = self._screen.binder.uitrOptionsList:getItems()

	for _,item in ipairs(items) do
		local setting = item.user_data
		if setting and setting.apply then
			local widget = item.widget.binder.widget
			setting:apply(uitrSettings, widget)
		end
	end
end

function options_dialog:refreshUitrMasks()
	local masks = {}
	local items = self._screen.binder.uitrOptionsList:getItems()
	for _,item in ipairs(items) do
		local setting = item.user_data
		if setting and setting.maskFn then
			local widget = item.widget.binder.widget
			local mask = setting:maskFn(setting:apply({}, widget))
			if mask then
				for maskId,maskValue in pairs(mask) do
					masks[maskId] = (masks[maskId] == nil or masks[maskId]) and maskValue
				end
			end
		end
	end
	for _,item in ipairs(items) do
		local setting = item.user_data
		local enabled = nil
		if setting and setting.id == "enabled" then
			-- skip
		elseif setting and masks[setting.id] ~= nil then
			enabled = masks[setting.id]
		elseif setting and masks[true] ~= nil then
			enabled = masks[true]
		end
		if enabled ~= nil then
			local inputWidget = item.widget.binder.widget
			if inputWidget and not inputWidget.isnull then
				inputWidget:setDisabled(not enabled)
			end
			item.widget:setVisible(enabled)
		end
	end
end

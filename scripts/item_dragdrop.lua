local upgradeScreen = include ( 'states/state-upgrade-screen' )
local mui_defs = include("mui/mui_defs")
local mui_button = include( "mui/widgets/mui_button" )
local util = include( "modules/util" )
local guiex = include( "client/guiex" )
local cdefs = include( "client_defs" )
local unitdefs = include("sim/unitdefs")
local simfactory = include( "sim/simfactory" )

local function updateButton(screen, widget, item, encumbered)
	if item then
		guiex.updateButtonFromItem( screen, nil, widget, item, nil, encumbered )
	else
		guiex.updateButtonEmptySlot( widget, encumbered )
	end
end

-- copy/pasted out of desperation from state-upgrade-screen.  Otherwise I was
-- trying to fish more stuff out of the onClick delegate.
local function getInventory( unitDef )
	local unit = simfactory.createUnit( unitdefs.createUnitData( unitDef ), nil )
	local inventory = {}

	for i,item in ipairs(unitDef.upgrades) do
		local itemDef, upgradeParams
		if type(unitDef.upgrades[i]) == "string" then
			itemDef = unitdefs.lookupTemplate( unitDef.upgrades[i] )
		else
			upgradeParams = unitDef.upgrades[i].upgradeParams
			itemDef = unitdefs.lookupTemplate( unitDef.upgrades[i].upgradeName )
		end

		if itemDef then
			local itemUnit = simfactory.createUnit( util.extend( itemDef )( upgradeParams and util.tcopy( upgradeParams )), nil )
			if itemUnit:getTraits().augment and itemUnit:getTraits().installed then
			else
				table.insert(inventory,{item=itemUnit,upgrade=unitDef.upgrades[i],index = i })
			end
		end
	end
	return inventory
end

local function onDragDropInventory( self, item, upgrade, unit, unitDef, itemIndex, fromStorage )
	local inventory = getInventory( unitDef )
	local dragIndex = self.screen._lastDragIndex
	local upgradeInsertAt

	if dragIndex > #inventory then
		if fromStorage then
			upgradeInsertAt = #unitDef.upgrades + 1
		else
			upgradeInsertAt = #unitDef.upgrades -- we'll be removing it first.
		end
	else
		upgradeInsertAt = inventory[dragIndex].index
	end

	if fromStorage then
		if #inventory >= 8 then
			MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/upgrade_cancel_unit")
			-- can't open a modal, still in the middle of the DragDrop event, so the modal won't work
		else
			MOAIFmodDesigner.playSound("SpySociety/HUD/gameplay/HUD_ItemStorage_TakeOut")
			table.insert( unitDef.upgrades, upgradeInsertAt, upgrade )
			table.remove( self._agency.upgrades, itemIndex )
		end
	else
		-- reorder
		table.remove( unitDef.upgrades, itemIndex )
		table.insert( unitDef.upgrades, upgradeInsertAt, upgrade )
	end

	self:refreshInventory(unitDef, self._selectedIndex)
	return true
end

-- reorder inventory UI items on dragOver.	only mucks with the display.
local function onDragOverInventory( screen, idx )
	if screen._lastDragIndex == idx then
		return true
	else
		screen._lastDragIndex = idx
	end

	local dragItem = screen:getDragDrop()

	local inventory = {}
	for i, widget in screen.binder:forEach( "inv_" ) do
		if widget._item and widget._item ~= dragItem and widget:getAlias() then -- getAlias ensures item still exists
			table.insert(inventory, widget._item)
		end
	end

	if #inventory >= 8 then -- if we were reordering with a full inventory this will be 7
		return true
	end

	idx = math.min(#inventory + 1, idx) -- clamp to last empty slot
	table.insert(inventory, idx, dragItem)

	for i, widget in screen.binder:forEach( "inv_" ) do
		local item = inventory[i]

		local encumbered = widget.binder.encumbered._cont._isVisible
		updateButton(screen, widget, item, encumbered)

		if item and i == idx then
			widget.binder.btn:setColor(0.9, 0.75, 0.37, 1)
		end
	end

	return true
end

-- we treat the entire drag area as one big target, capturing mouse-over
-- events whilst in drag mode.	I tried to do this with 8 individual drag
-- targets but it just didn't work well.

local function handleMouseOverDuringDrag( self, ev )
	if ev.screen:getDragDrop() and ev.eventType == mui_defs.EVENT_MouseMove
		and ev.screen:getInputLock() == self and self._prop:inside( ev.x, ev.y ) then
		local xmin, ymin, zmin, xmax, ymax, zmax = self._prop:getWorldBounds()

		local idx = math.floor((ev.x - xmin) / ((xmax - xmin) / 4)) + 1

		if ev.y < ymin + ((ymax - ymin) / 2) then
			idx = idx + 4
		end

		return onDragOverInventory(ev.screen, idx)
	else
		return mui_button.handleInputEvent( self, ev )
	end
end

local function onDragEnterInventory( dragWidget )
	dragWidget._button.handleInputEvent = handleMouseOverDuringDrag
	return true
end

-- stash a copy of the original inventory so as to have something
-- to draw in dragLeave events; calling refreshInventory there isn't an option.

local function saveInventory( screen )
	local inv = {}

	for i, widget in screen.binder:forEach( "inv_" ) do
		local item = { encumbered = widget.binder.encumbered._cont._isVisible }
		if widget:getAlias() then
			item.item = widget._item
		end

		table.insert(inv, item)
	end

	return inv
end

local function restoreInventory( screen, inv )
	for i, tbl in ipairs(inv) do
		local widget = screen:findWidget( "inv_" .. i)
		-- widget.binder.btn:setColor(0.95, 1, 0.47, 1)
		updateButton( screen, widget, tbl.item, tbl.encumbered )
	end
end

local function onDragLeaveInventory( state, dragWidget )
	restoreInventory( state.screen, state._saved_inventory )
	dragWidget._button.handleInputEvent = mui_button.handleInputEvent
	return true
end


local function onDragCommon( self, upgrade, item )
	local widget = self.screen:startDragDrop( item, "DragItem" )
	widget.binder.img:setImage( item:getUnitData().profile_icon_100 )

	self.screen._lastDragIndex = nil
	self._saved_inventory = saveInventory( self.screen )

	self.screen:findWidget( "dragAugment" ).onDragDrop = function() util.coDelegate( self.onDragToAugments, self, upgrade, item ) end
end

local newFunctions = {}

local function onDragInventory( _, self, upgrade, item, oldOnDragDrop )
	onDragCommon( self, upgrade, item )

	local unit, unitDef, itemIndex = oldOnDragDrop[2], oldOnDragDrop[3], oldOnDragDrop[6]

	self.screen:findWidget( "drag" ).onDragDrop = function(item) return onDragDropInventory(self, item, upgrade, unit, unitDef, itemIndex, false) end
	self.screen:findWidget( "storageDrag" ).onDragDrop = function() util.coDelegate( oldOnDragDrop ) end
	self.screen:findWidget( "storageDragHilite" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
	return true
end

local function onDragStorage( _, self, upgrade, item, oldOnDragDrop )
	onDragCommon( self, upgrade, item )

	local unit, unitDef, itemIndex = oldOnDragDrop[2], oldOnDragDrop[3], oldOnDragDrop[6]

	self.screen:findWidget( "drag" ).onDragDrop = function(item) return onDragDropInventory(self, item, upgrade, unit, unitDef, itemIndex, true) end
	self.screen:findWidget( "dragHilite" ):setColor( cdefs.COLOR_DRAG_DROP:unpack() )
	return true
end

local function refreshInventory( originalFunction, self, unitDef, index )
	originalFunction( self, unitDef, index )

	self._saved_inventory = {}
	local dragWidget = self.screen:findWidget( "drag" )
	dragWidget.onDragEnter = util.makeDelegate( nil, onDragEnterInventory, dragWidget )
	dragWidget.onDragLeave = util.makeDelegate( nil, onDragLeaveInventory, self, dragWidget )
end

local patches = {
	{ package = upgradeScreen, name = 'onDragInventory',  f = onDragInventory },
	{ package = upgradeScreen, name = 'onDragStorage',    f = onDragStorage },
	{ package = upgradeScreen, name = 'refreshInventory', f = refreshInventory }
}

return monkeyPatch( patches )


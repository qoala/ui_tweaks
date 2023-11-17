local serverdefs = include("modules/serverdefs")
local util = include("client_util")
local locationPopup = include('client/fe/locationpopup')
local rig_util = include("gameplay/rig_util")
local mapScreen = include("states/state-map-screen")

local uitr_util = include(SCRIPT_PATHS.qed_uitr .. "/uitr_util")

local function calcTravelTime(loc0, loc1)
    return serverdefs.BASE_TRAVEL_TIME + serverdefs.calculateTravelTime(loc0, loc1)
end

-- ===
-- Modified copy of the tooltip in vanilla state-map-screen.

local LOGO_COLOR = {144 / 255, 1, 1, 1}

local LocationTooltip = class()
mapScreen._location_tooltip = LocationTooltip

function LocationTooltip:init(mapscreen, widget, campaign, situation, x, y)
    self._mapscreen = mapscreen
    self._widget = widget
    self._situation = situation
    self._campaign = campaign
    self._x, self._y = x, y
    self._screen = widget:getScreen()
end

function LocationTooltip:activate()
    local corpData = serverdefs.getCorpData(self._situation)

    -- make the location details appear
    if not self.popup_widget then

        self.popup_widget = self._screen:createFromSkin("location_info", {xpx = true, ypx = true})
        self._screen.binder.pnl:addChild(self.popup_widget)

        self.popup = locationPopup(self.popup_widget, self._campaign, self._situation, LOGO_COLOR)
    else
        self.popup_widget:setVisible(true)
    end

    -- self.popup_widget:setPosition(x, self._y)

    local W, H = self._screen:getResolution()
    local x = self._x + self._mapscreen.locationOffsetX
    x = math.min(x, W / 2 - 200)
    x = math.max(x, -W / 2 + 200)

    self.popup_widget:setPosition(x, self._y)

    self.popup_widget:createTransition("activate_below_popup")

    local campaign = self._campaign
    if campaign and campaign.hours >= 120 and campaign.difficultyOptions.maxHours == math.huge and
            campaign.difficultyOptions.dangerZones == false then
        lblToString(
                serverdefs.MAP_LOCATIONS[self._situation.mapLocation].x,
                serverdefs.MAP_LOCATIONS[self._situation.mapLocation].y, self._screen)
    end

    self._mapscreen:UpdateMapColours(corpData.region)

    self._widget.binder.icon:setColor(244 / 255, 255 / 255, 120 / 255, 1)

    self._buttonRoutine = MOAICoroutine.new()
    self._buttonRoutine:run(
            function()
                rig_util.waitForAnim(self._widget.binder.anim:getProp(), "over")
                self._widget.binder.anim:getProp():setPlayMode(KLEIAnim.LOOP)
                self._widget.binder.anim:setAnim("idle")
            end)

    self._mapscreen:_setRelativeTravelOrigin(self._situation.mapLocation)
end

function LocationTooltip:deactivate()
    self._mapscreen:_setRelativeTravelOrigin(nil)

    -- hide the location details
    self.popup_widget:createTransition(
            "deactivate_below_popup", function(transition)
                self.popup_widget:setVisible(false)
            end, {easeOut = true})

    self._mapscreen:UpdateMapColours()

    self._widget.binder.anim:setAnim("idle")
    if self._widget._pnl._selected ~= self._widget then
        self._widget.binder.icon:setColor(1, 1, 1, 1)
    end
    if self._buttonRoutine then
        self._buttonRoutine:stop()
        self._buttonRoutine = nil
    end
end

function LocationTooltip:setPosition()
end

---

local function createIconFadeTimer()
    timer = MOAITimer.new()
    timer:setSpan(2)
    timer:setMode(MOAITimer.PING_PONG)
    timer:start()
    local iconDriver = function(uniforms)
        local t = math.max(0, timer:getTime() - 0.5) / 1.5 -- 0 <-> 2 => 0 <-> 1

        v = 0.35 - 0.25 * math.cos(t * math.pi) -- 0.1 <-> 0.6
        uniforms:setUniformFloat("ease", v)
    end

    return timer, iconDriver
end

local oldOnLoad = mapScreen.onLoad
function mapScreen:onLoad(...)
    -- ID of highlighted location
    self._locationHighlight = nil
    -- Table of 'location' widgets, indexed by mapLocation ID.
    self._locationWidgets = {}
    -- Distance from current location, indexed by mapLocation ID.
    self._locationDirectDistances = {}
    -- 2D table of location-location distances. Indexed as [startLocationID][endLocationID].
    self._locationCrossDistances = {}

    self._locationIconTimer, self._locationIconDriver = createIconFadeTimer()

    return oldOnLoad(self, ...)
end
local oldOnUnload = mapScreen.onUnload
function mapScreen:onUnload(...)
    self._locationIconTimer:stop()
    return oldOnUnload(self, ...)
end

function mapScreen:refreshUITR()
    for locID, widget in pairs(self._locationWidgets) do
        if self._locationHighlight == locID then
            self:_widgetShowTimeHighlighted(widget)
        elseif self._locationHighlight then
            self:_widgetShowTime(widget)
        else
            self:_widgetShowIcon(widget)
        end
    end
end

local oldAddLocation = mapScreen.addLocation
function mapScreen:addLocation(situation, popin, ...)
    local locID = situation.mapLocation
    local location = serverdefs.MAP_LOCATIONS[locID]
    local x, y, widget = oldAddLocation(self, situation, popin, ...)
    if not widget then
        local parent = self._screen.binder.pnl.binder.maproot.binder.under
        widget = parent._children[#parent._children]
    end
    if not location or not widget then
        simlog(
                "[UITR][WARN] Failed to modify widget for location %s:%s", tostring(situation.name),
                tostring(location and location.name))
        return x, y, widget
    end
    self._locationWidgets[locID] = widget
    self._locationCrossDistances[locID] = {}

    -- Attach shading timer.
    local iconUniforms = KLEIShaderUniforms.new()
    iconUniforms:setUniformDriver(self._locationIconDriver)
    widget.binder.icon._cont:getProp():setShaderUniforms(iconUniforms)

    -- Travel time to this location from current.
    local travelTime = calcTravelTime(self._campaign.location, locID)
    self:_widgetShowIcon(widget, travelTime)
    self._locationDirectDistances[locID] = travelTime

    -- Override vanilla tooltip
    local toolTip = self._location_tooltip(self, widget, self._campaign, situation, x, y)
    widget.binder.btn:setTooltip(toolTip)
end

function mapScreen:_widgetShowIcon(widget, travelTime)
    if travelTime then
        widget.binder.locationTravelTime:setText(
                util.sformat(
                        STRINGS.UITWEAKSR.UI.MAP_TRAVEL_TIME, travelTime))
    end

    local opt = uitr_util.checkOption("mapCrossDistanceMode")
    widget.binder.icon:setVisible(true)
    widget.binder.icon._cont:getProp():setShader(nil)
    widget.binder.locationEmptyIcon:setVisible(false)
    if opt then
        widget.binder.locationTravelTime:setVisible(true)
        widget.binder.locationTravelTime:setPosition(0, 25)
    else
        widget.binder.locationTravelTime:setVisible(false)
    end
end
function mapScreen:_widgetShowTime(widget, travelTime)
    if travelTime then
        widget.binder.locationTravelTime:setText(
                util.sformat(
                        STRINGS.UITWEAKSR.UI.MAP_TRAVEL_TIME, travelTime))
    end

    local opt = uitr_util.checkOption("mapCrossDistanceMode")
    if opt then
        widget.binder.icon._cont:getProp():setShader(
                MOAIShaderMgr.getShader(
                        MOAIShaderMgr.KLEI_POST_PROCESS_PASS_THROUGH_EASE))

        widget.binder.locationEmptyIcon:setVisible(true)
        widget.binder.locationTravelTime:setVisible(true)
        widget.binder.locationTravelTime:setPosition(0, 0)
    else
        widget.binder.icon:setVisible(true)
        widget.binder.icon._cont:getProp():setShader(nil)
        widget.binder.locationEmptyIcon:setVisible(false)
        widget.binder.locationTravelTime:setVisible(false)
    end
end
function mapScreen:_widgetShowTimeHighlighted(widget, travelTime)
    if travelTime then
        widget.binder.locationTravelTime:setText(
                util.sformat(
                        STRINGS.UITWEAKSR.UI.MAP_TRAVEL_TIME, travelTime))
    end

    widget.binder.icon:setVisible(true)
    widget.binder.locationTravelTime:setVisible(false)
end

function mapScreen:_setRelativeTravelOrigin(locationID)
    if locationID then
        local distances = self._locationCrossDistances[locationID] or {}
        for loc1, widget in pairs(self._locationWidgets) do
            if loc1 == locationID then
                self:_widgetShowTimeHighlighted(widget, self._locationDirectDistances[loc1])
            else
                local travelTime = distances[loc1]
                if not travelTime then
                    travelTime = calcTravelTime(locationID, loc1)
                    distances[loc1] = travelTime
                end
                self:_widgetShowTime(widget, travelTime)
            end
        end
    else
        for loc1, widget in pairs(self._locationWidgets) do
            self:_widgetShowIcon(widget, self._locationDirectDistances[loc1])
        end
    end
end

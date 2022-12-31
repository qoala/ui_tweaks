-- Widgets that pass image properties into a mui_texture (mui_imagebutton, mui_image, etc),
-- can specify stickyColor=true on any or all of its images.
--
-- If provided, then that image will retain its color after being overridden to a different file.
-- Otherwise, mui_texture:setImageAtIndex("newfile", idx) would drop the color spec from that slot.
-- Commonly an issue with mui_imagebutton:setImage("iconForAllButtonStates"), for which guiex
-- helpers usually exist to then re-apply state-specific colors (but hardcoded into guiex, not the
-- original colors).
--
-- mui_texture:setColorAtIndex(clr, idx) will still overwrite the color, including replacing the
-- currently saved sticky color, if that slot is sticky.
-- If this is undesirable (e.g. wishing to ignore the hardcoded colors in guiex), instead specifying
-- stickyColorLock=true will disable :setColorAtIndex for that slot. The lock bit can be updated at
-- runtime with mui_texture:setStickyColorLockAtIndex(lock, idx).
--
local mui_texture = require("mui/widgets/mui_texture")

local oldInit = mui_texture.init
function mui_texture:init(screen, def, ...)
    oldInit(self, screen, def, ...)

    if self._images and type(def.images) == "table" then
        self._stickyColors = {}
        for i, imgDef in ipairs(def.images) do
            local img = self._images[i]
            if img and (imgDef.stickyColor or imgDef.stickyColorLock) then
                self._stickyColors[i] = {color = img.color, lock = imgDef.stickyColorLock}
            end
        end
    end
end

local oldSetImageAtIndex = mui_texture.setImageAtIndex
function mui_texture:setImageAtIndex(imageFile, idx, ...)
    oldSetImageAtIndex(self, imageFile, idx, ...)

    local stickyColor = self._stickyColors[idx]
    if stickyColor and stickyColor.color then
        self._images[idx].color = stickyColor.color
    end
end

local oldSetColorAtIndex = mui_texture.setColorAtIndex
function mui_texture:setColorAtIndex(clr, idx, ...)
    oldSetColorAtIndex(self, clr, idx, ...)

    local stickyColor = self._stickyColors[idx]
    if stickyColor and not stickyColor.lock then
        stickyColor.color = clr
    end
end

function mui_texture:setStickyColorLockAtIndex(lock, idx)
    local stickyColor = self._stickyColors[idx]
    if stickyColor then
        stickyColor.lock = lock
    end
end

--
-- mui_group elements can specify an inheritDefs property to override properties on their children.
-- Notably, given a skin with a top-level group element, a usage of that skin can specify this to
-- propagate per-usage values inwards when the skin is resolved.
--
-- inheritDefs is a table with (key = child name) and (value = override table).
-- Overrides apply like util.extend().
--
local mui_binder = require("mui/mui_binder")
local mui_defs = require("mui/mui_defs")
local mui_container = require("mui/widgets/mui_container")
local mui_widget = require("mui/widgets/mui_widget")

local mui_group = require("mui/widgets/mui_group")

local qutil = include(SCRIPT_PATHS.qed_uitr .. "/qed_util")

-- Overwrite mui_group:init
-- Add inheritDef handling when creating child widgets.
function mui_group:init(screen, def)
    mui_widget.init(self, def)

    self._cont = mui_container(def)
    self._children = {}

    for i, childdef in ipairs(def.children) do
        if def.inheritDef and def.inheritDef[childdef.name] then
            -- Vanilla mui applies util.inherit to defs at various places, which is shallow-only,
            -- and sets up circular metamethod references.
            -- qutil.extendData provides a deep merge without choking on circular references.
            childdef = qutil.extendData(def.inheritDef[childdef.name], childdef) {}
        end

        local child = screen:createWidget(childdef)
        self:addChild(child)
    end

    self.binder = mui_binder.create(self)
end

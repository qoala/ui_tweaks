local cdefs = include("client_defs")
local mui_defs = include("mui/mui_defs")
local mui_util = include("mui/mui_util")

table.insert(cdefs.ALL_KEYBINDINGS, {txt = STRINGS.UITWEAKSR.UI.OPTIONS_KEYBIND_CATEGORY})
table.insert(
        cdefs.ALL_KEYBINDINGS, {
            name = "UITR_VISIONMODE",
            txt = STRINGS.UITWEAKSR.UI.OPTIONS_KEYBIND_VISIONMODE,
            defaultBinding = mui_util.makeBinding(mui_defs.K_B),
        })

-- focus_target but for penalties, such as sprint warnings. (red instead of green)
cdefs.RENDER_FILTERS["uitr_focus_penalty"] = {
    shader = KLEIAnim.SHADER_HILITE,
    r = 255 / 255,
    g = 110 / 255,
    b = 110 / 255,
    a = 0.8,
    lum = 1.0,
}

local LevelSpecialFeature = class("LevelSpecialFeature", util_require("base.BaseView"))

function LevelSpecialFeature:initUI(csbName, icon)
    self:createCsbNode(csbName, true)
    local sp_wanfa = self:findChild("sp_wanfa")

    util_changeTexture(sp_wanfa, icon)
end

return LevelSpecialFeature

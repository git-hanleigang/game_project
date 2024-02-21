---
--xcyy
--2018年5月30日
--FreeSpinWildEffect.lua
local FreeSpinWildEffect = class("FreeSpinWildEffect", util_require("base.BaseView"))

function FreeSpinWildEffect:initUI(data)
    self:createCsbNode("Socre_LightCherry_Wild2_Eff.csb")
end

function FreeSpinWildEffect:toAction(actionName)
    self:runCsbAction(actionName)
end

return FreeSpinWildEffect
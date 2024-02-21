---
--xcyy
--2018年5月29日
--FreeSpinStartEffect.lua

local FreeSpinStartEffect = class("FreeSpinStartEffect", util_require("base.BaseView"))

function FreeSpinStartEffect:initUI(data)
    self:createCsbNode("GoldExpress_bonus_xiaza.csb")
end

function FreeSpinStartEffect:toAction(actionName)
    self:runCsbAction(actionName)
end

return FreeSpinStartEffect
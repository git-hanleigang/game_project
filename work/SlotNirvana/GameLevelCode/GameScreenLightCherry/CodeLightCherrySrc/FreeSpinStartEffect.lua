---
--xcyy
--2018年5月29日
--FreeSpinStartEffect.lua

local FreeSpinStartEffect = class("FreeSpinStartEffect", util_require("base.BaseView"))

function FreeSpinStartEffect:initUI(data)
    self:createCsbNode("LightCherry_FreeSpin_start.csb")
end

function FreeSpinStartEffect:runAction()
    self:runCsbAction("actionframe",true)
end

return FreeSpinStartEffect
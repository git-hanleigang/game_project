---
--xcyy
--2018年5月23日
--VegasWinEffect.lua

local VegasWinEffect = class("VegasWinEffect",util_require("base.BaseView"))

function VegasWinEffect:initUI()
    self:createCsbNode("Socre_Vegas_Feature_fankui.csb")
end


function VegasWinEffect:onEnter()
end

function VegasWinEffect:onExit()

end

-- 更新赢钱数
function VegasWinEffect:playEffect()
    self:runCsbAction("actionframe")
end

return VegasWinEffect
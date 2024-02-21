---
--xcyy
--2018年5月23日
--VegasRespinResetEffect.lua

local VegasRespinResetEffect = class("VegasRespinResetEffect",util_require("base.BaseView"))

function VegasRespinResetEffect:initUI()
    self:createCsbNode("Vegas_fscounter_reset.csb")
end


function VegasRespinResetEffect:onEnter()
end

function VegasRespinResetEffect:onExit()
end
-- 更新赢钱数
function VegasRespinResetEffect:playAddRespinNum()
    self:runCsbAction("idle1")
end

return VegasRespinResetEffect
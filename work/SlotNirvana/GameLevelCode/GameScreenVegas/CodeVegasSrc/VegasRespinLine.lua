---
--xcyy
--2018年5月23日
--VegasRespinLine.lua

local VegasRespinLine = class("VegasRespinLine",util_require("base.BaseView"))

function VegasRespinLine:initUI()
    self:createCsbNode("vegas_respin_line.csb")
end


function VegasRespinLine:onEnter()
end

function VegasRespinLine:onExit()

end

-- 更新赢钱数
function VegasRespinLine:playEffect()

end

return VegasRespinLine
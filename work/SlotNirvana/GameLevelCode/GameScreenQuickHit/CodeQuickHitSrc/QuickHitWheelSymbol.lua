---
--xhkj
--2018年6月11日
--QuickHitWheelSymbol.lua

local QuickHitWheelSymbol = class("QuickHitWheelSymbol", util_require("base.BaseView"))

function QuickHitWheelSymbol:initUI(data)

    local resourceFilename = data
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe")
end


function QuickHitWheelSymbol:onEnter()
 

end

function QuickHitWheelSymbol:onExit()
    
end

return QuickHitWheelSymbol
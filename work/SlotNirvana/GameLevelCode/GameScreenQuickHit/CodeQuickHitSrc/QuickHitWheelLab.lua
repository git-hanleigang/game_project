---
--xhkj
--2018年6月11日
--QuickHitWheelLab.lua

local QuickHitWheelLab = class("QuickHitWheelLab", util_require("base.BaseView"))

function QuickHitWheelLab:initUI(data)

    local resourceFilename = data
    self:createCsbNode(resourceFilename)
 
end


function QuickHitWheelLab:onEnter()
 

end


function QuickHitWheelLab:onExit()
    
end

return QuickHitWheelLab
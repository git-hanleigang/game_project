---
--xhkj
--2018年6月11日
--CrazyBombWheelPoint.lua

local CrazyBombWheelPoint = class("CrazyBombWheelPoint", util_require("base.BaseView"))

function CrazyBombWheelPoint:initUI(name)

    local resourceFilename = "CrazyBomb_Wheel_Point.csb"
    self:createCsbNode(resourceFilename)

end


function CrazyBombWheelPoint:onEnter()
   
end


function CrazyBombWheelPoint:onExit()
    
end

return CrazyBombWheelPoint
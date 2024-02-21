---
--xhkj
--2018年6月11日
--CrazyBombWheelBg.lua

local CrazyBombWheelBg = class("CrazyBombWheelBg", util_require("base.BaseView"))

function CrazyBombWheelBg:initUI(name)

    local resourceFilename = "CrazyBomb/GameScreenCrazyBombBgWheel.csb"
    self:createCsbNode(resourceFilename)

    

end


function CrazyBombWheelBg:onEnter()
   
end


function CrazyBombWheelBg:onExit()
    
end




return CrazyBombWheelBg
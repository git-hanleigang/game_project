---
--xhkj
--2018年6月11日
--CrazyBombWheelClickAnimation.lua

local CrazyBombWheelClickAnimation = class("CrazyBombWheelClickAnimation", util_require("base.BaseView"))

function CrazyBombWheelClickAnimation:initUI(name)

    local resourceFilename = "Socre_CrazyBomb_lunpandianji.csb"
    self:createCsbNode(resourceFilename)

end


function CrazyBombWheelClickAnimation:onEnter()
   
end


function CrazyBombWheelClickAnimation:onExit()
    
end


return CrazyBombWheelClickAnimation
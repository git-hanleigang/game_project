---
--xhkj
--2018年6月11日
--CrazyBombBgRing.lua

local CrazyBombBgRing = class("CrazyBombBgRing", util_require("base.BaseView"))

function CrazyBombBgRing:initUI(name)

    local resourceFilename = "CrazyBomb/CrazyBomb_Ring.csb"
    self:createCsbNode(resourceFilename)

end


function CrazyBombBgRing:onEnter()
   
end


function CrazyBombBgRing:onExit()
    
end


return CrazyBombBgRing
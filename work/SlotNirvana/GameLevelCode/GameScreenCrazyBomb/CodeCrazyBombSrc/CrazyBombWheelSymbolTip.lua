---
--xhkj
--2018年6月11日
--CrazyBombWheelSymbolTip.lua

local CrazyBombWheelSymbolTip = class("CrazyBombWheelSymbolTip", util_require("base.BaseView"))

function CrazyBombWheelSymbolTip:initUI(name)

    local resourceFilename = "lunpan_yidong.csb"
    self:createCsbNode(resourceFilename)

end


function CrazyBombWheelSymbolTip:onEnter()
   
end


function CrazyBombWheelSymbolTip:onExit()
    
end

return CrazyBombWheelSymbolTip
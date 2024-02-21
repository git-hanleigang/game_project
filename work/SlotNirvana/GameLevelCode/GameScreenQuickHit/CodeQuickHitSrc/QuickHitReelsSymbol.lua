---
--xhkj
--2018年6月11日
--QuickHitReelsSymbol.lua

local QuickHitReelsSymbol = class("QuickHitReelsSymbol", util_require("base.BaseView"))

function QuickHitReelsSymbol:initUI()

    local resourceFilename = "Socre_QuickHit_Wheel4.csb"
    self:createCsbNode(resourceFilename)
    self:setAnchorPoint(0,0)
    self:runCsbAction("actionframe",true)
end


function QuickHitReelsSymbol:onEnter()
 

end


function QuickHitReelsSymbol:onExit()
    
end

return QuickHitReelsSymbol
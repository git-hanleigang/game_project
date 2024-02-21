---
--xhkj
--2018年6月11日
--QuickHitBonusTip.lua

local QuickHitBonusTip = class("QuickHitBonusTip", util_require("base.BaseView"))

function QuickHitBonusTip:initUI()

    local resourceFilename = "Socre_QuickHit_bonus_wheel.csb"
    self:createCsbNode(resourceFilename)
    
    self:runCsbAction("idle",true)
end


function QuickHitBonusTip:onEnter()
 

end


function QuickHitBonusTip:onExit()
    
end

return QuickHitBonusTip
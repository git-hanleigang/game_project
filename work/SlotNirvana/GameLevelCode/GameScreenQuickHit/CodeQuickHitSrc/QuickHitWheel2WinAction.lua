---
--xhkj
--2018年6月11日
--QuickHitWheel2WinAction.lua

local QuickHitWheel2WinAction = class("QuickHitWheel2WinAction", util_require("base.BaseView"))

function QuickHitWheel2WinAction:initUI()


    self:createCsbNode("Socre_QuickHit_Wheelsanjiao.csb")
    
    self:runCsbAction("hide")
end



function QuickHitWheel2WinAction:onEnter()
 

end

function QuickHitWheel2WinAction:onExit()
    
end

return QuickHitWheel2WinAction
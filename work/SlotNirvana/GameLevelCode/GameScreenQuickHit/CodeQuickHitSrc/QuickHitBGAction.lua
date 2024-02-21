---
--xhkj
--2018年6月11日
--QuickHitBGAction.lua

local QuickHitBGAction = class("QuickHitBGAction", util_require("base.BaseView"))

function QuickHitBGAction:initUI()

    local resourceFilename = "Socre_QuickHit_Wheelbgtexiao.csb"
    self:createCsbNode(resourceFilename)
    
    -- self:runCsbAction("idle",true)
end


function QuickHitBGAction:onEnter()
 

end

function QuickHitBGAction:runSelfCsbAction(_name,_loop,_func)
 
    self:runCsbAction(_name,_loop,_func)
end


function QuickHitBGAction:onExit()
    
end

return QuickHitBGAction
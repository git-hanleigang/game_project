---
--xhkj
--2018年6月11日
--QuickHitAddWildReelsBoomAction.lua

local QuickHitAddWildReelsBoomAction = class("QuickHitAddWildReelsBoomAction", util_require("base.BaseView"))


function QuickHitAddWildReelsBoomAction:initUI()

    local resourceFilename="Socre_QuickHit_Wildxialuofankui.csb"
    self:createCsbNode(resourceFilename)
 
    self:runCsbAction("animation0",false,function(  )
        self:removeSelf()
    end)
    


end


function QuickHitAddWildReelsBoomAction:onEnter()
   

end


function QuickHitAddWildReelsBoomAction:onExit()
    
end

function QuickHitAddWildReelsBoomAction:removeSelf()
    self:removeFromParent()
end

function QuickHitAddWildReelsBoomAction:initMachine(machine)
    self.m_machine = machine
end

return QuickHitAddWildReelsBoomAction
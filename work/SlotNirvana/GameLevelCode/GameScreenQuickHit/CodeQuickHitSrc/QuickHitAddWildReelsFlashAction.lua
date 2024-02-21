---
--xhkj
--2018年6月11日
--QuickHitAddWildReelsFlashAction.lua

local QuickHitAddWildReelsFlashAction = class("QuickHitAddWildReelsFlashAction", util_require("base.BaseView"))


function QuickHitAddWildReelsFlashAction:initUI()

    local resourceFilename="Socre_QuickHit_Wildxialuo.csb"
    self:createCsbNode(resourceFilename)
 
    self:runCsbAction("animation0")
    


end


function QuickHitAddWildReelsFlashAction:onEnter()
   

end


function QuickHitAddWildReelsFlashAction:onExit()
    
end

function QuickHitAddWildReelsFlashAction:removeSelf()

end

function QuickHitAddWildReelsFlashAction:initMachine(machine)
    self.m_machine = machine
end

return QuickHitAddWildReelsFlashAction
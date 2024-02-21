---
--xcyy
--2018年5月23日
--FarmBonus_BarnView.lua

local FarmBonus_BarnView = class("FarmBonus_BarnView",util_require("base.BaseView"))


function FarmBonus_BarnView:initUI()

    self:createCsbNode("Farm_gucang.csb")

    self.m_BarnSpineNode = util_spineCreate("Farm_gucang" , true, true)
    self:addChild(self.m_BarnSpineNode)
    self.m_BarnSpineNode:setPosition(-80,120)
    util_spinePlay(self.m_BarnSpineNode,"idleframe",true)


end

function FarmBonus_BarnView:initMachine( machine)
    self.m_machine = machine
end

function FarmBonus_BarnView:onEnter()
 

end


function FarmBonus_BarnView:onExit()
 
end



return FarmBonus_BarnView
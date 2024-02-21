---
--xcyy
--2018年5月23日
--FarmCollect_BarnView.lua

local FarmCollect_BarnView = class("FarmCollect_BarnView",util_require("base.BaseView"))


function FarmCollect_BarnView:initUI()

    self:createCsbNode("Farm_gucang.csb")

    self.m_BarnSpineNode = util_spineCreate("Farm_gucang" , true, true)
    self:findChild("Node_1"):addChild(self.m_BarnSpineNode)
    self.m_BarnSpineNode:setPosition(-120,120)
    util_spinePlay(self.m_BarnSpineNode,"idleframe",true)

end

function FarmCollect_BarnView:initMachine( machine)
    self.m_machine = machine
end

function FarmCollect_BarnView:onEnter()
 

end


function FarmCollect_BarnView:onExit()
 
end



return FarmCollect_BarnView
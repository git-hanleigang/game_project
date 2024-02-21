---
--xcyy
--2018年5月23日
--FarmBonus_CowView.lua

local FarmBonus_CowView = class("FarmBonus_CowView",util_require("base.BaseView"))


function FarmBonus_CowView:initUI()

    self:createCsbNode("Farm_game_niu.csb")


    self.m_CowSpineNode = util_spineCreate("Farm_game_cow" , true, true)
    self:addChild(self.m_CowSpineNode)

    util_spinePlay(self.m_CowSpineNode,"idleframe",true)
    
end


function FarmBonus_CowView:onEnter()
 

end

function FarmBonus_CowView:onExit()
 
end



return FarmBonus_CowView
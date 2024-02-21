 --[[--
]]
local StatuePeoplesLevelUpAnimaNode = class("StatuePeoplesLevelUpAnimaNode", BaseView)
function StatuePeoplesLevelUpAnimaNode:initUI(_animType)
    self.m_animType = _animType
    StatuePeoplesLevelUpAnimaNode.super.initUI(self)
end

function StatuePeoplesLevelUpAnimaNode:getCsbName()
    if self.m_animType == "before" then
        return "CardRes/season202102/Statue/Statue_effect_Shengji_before.csb"
    elseif self.m_animType == "behind" then
        return "CardRes/season202102/Statue/Statue_effect_Shengji_behind.csb"
    end
end

function StatuePeoplesLevelUpAnimaNode:playLevelUpAnima()
    self:runCsbAction("shengji", false, nil, 60)
end

return StatuePeoplesLevelUpAnimaNode
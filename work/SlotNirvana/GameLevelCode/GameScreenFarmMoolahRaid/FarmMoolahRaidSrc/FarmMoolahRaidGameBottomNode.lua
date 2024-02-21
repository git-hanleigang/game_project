local FarmMoolahRaidGameBottomNode = class("FarmMoolahRaidGameBottomNode", util_require("views.gameviews.GameBottomNode"))

function FarmMoolahRaidGameBottomNode:initUI(machine)
    FarmMoolahRaidGameBottomNode.super.initUI(self, machine)
    if self.m_betTipsNode then
        self.m_betTipsNode:setVisible(false)
    end
    if self:findChild("btn_add") then
        self:findChild("btn_add"):setTouchEnabled(false)
    end
    if self:findChild("btn_sub") then
        self:findChild("btn_sub"):setTouchEnabled(false)
    end
    if self:findChild("btn_MaxBet") then
        self:findChild("btn_MaxBet"):setTouchEnabled(false)
    end
end

function FarmMoolahRaidGameBottomNode:getBetSound()
    return ""
end

function FarmMoolahRaidGameBottomNode:addTaskNode()
    self:initTishi()
end

function FarmMoolahRaidGameBottomNode:openMissionLead()
end

function FarmMoolahRaidGameBottomNode:addNewMissionTips()
end

return FarmMoolahRaidGameBottomNode

local RocketPupGameBottomNode = class("RocketPupGameBottomNode", util_require("views.gameviews.GameBottomNode"))

function RocketPupGameBottomNode:initUI(machine)
    RocketPupGameBottomNode.super.initUI(self, machine)
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

function RocketPupGameBottomNode:getBetSound()
    return ""
end

function RocketPupGameBottomNode:addTaskNode()
    self:initTishi()
end

function RocketPupGameBottomNode:openMissionLead()
end

function RocketPupGameBottomNode:addNewMissionTips()
end

return RocketPupGameBottomNode

local MasterStampGameBottomNode = class("MasterStampGameBottomNode", util_require("views.gameviews.GameBottomNode"))

function MasterStampGameBottomNode:initUI(machine)
    MasterStampGameBottomNode.super.initUI(self, machine)
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

function MasterStampGameBottomNode:getBetSound()
    return ""
end

function MasterStampGameBottomNode:addTaskNode()
    self:initTishi()
end

function MasterStampGameBottomNode:openMissionLead()
end

function MasterStampGameBottomNode:addNewMissionTips()
end

return MasterStampGameBottomNode

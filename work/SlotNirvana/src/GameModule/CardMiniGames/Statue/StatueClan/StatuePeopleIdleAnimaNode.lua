 --[[--
]]
local StatuePeopleIdleAnimaNode = class("StatuePeopleIdleAnimaNode", BaseView)
function StatuePeopleIdleAnimaNode:initUI(_statueType)
    self.m_statueType = _statueType
    StatuePeopleIdleAnimaNode.super.initUI(self)
end

function StatuePeopleIdleAnimaNode:getCsbName()
    if self.m_statueType == 1 then
        return "CardRes/season202102/Statue/Statue_shenxiang_left.csb"
    elseif self.m_statueType == 2 then
        return "CardRes/season202102/Statue/Statue_shenxiang_right.csb"
    end
end

function StatuePeopleIdleAnimaNode:initCsbNodes()
    self.m_nodeLv3 = self:findChild('Node_lv3')
    self.m_nodeLv4 = self:findChild('Node_lv4')
    self.m_nodeLv3:setVisible(false)
    self.m_nodeLv4:setVisible(false)
end

function StatuePeopleIdleAnimaNode:playIdle(_level)
    self.m_nodeLv3:setVisible(false)
    self.m_nodeLv4:setVisible(false)
    if _level == 2 then
        self.m_nodeLv3:setVisible(true)
        self:runCsbAction("idle_3", true, nil, 60)
    elseif _level == 3 then
        self.m_nodeLv4:setVisible(true)
        self:runCsbAction("idle_4", true, nil, 60)
    end
end

return StatuePeopleIdleAnimaNode
--[[
    
]]
local QuestPassRewardSpecialItemNode = class("QuestPassRewardSpecialItemNode", BaseView)

function QuestPassRewardSpecialItemNode:initDatas(_type,des_str)
    self.m_type = _type
    self.m_des_str = des_str
end

function QuestPassRewardSpecialItemNode:getCsbName()
    return QUEST_RES_PATH.QuestPassSpeicalRewardNode
end

function QuestPassRewardSpecialItemNode:initCsbNodes()
    self.m_node_Points = self:findChild("node_Points")
    self.m_lb_num1 = self:findChild("lb_num1")

    self.m_node_Coins = self:findChild("node_Coins")
    self.m_lb_num2 = self:findChild("lb_num2")
end

function QuestPassRewardSpecialItemNode:initUI()
    QuestPassRewardSpecialItemNode.super.initUI(self)
    self.m_node_Points:setVisible(self.m_type == 1)
    self.m_node_Coins:setVisible(self.m_type == 2)
    self.m_lb_num1:setString("" ..self.m_des_str)
    self.m_lb_num2:setString("" ..self.m_des_str)
end

return QuestPassRewardSpecialItemNode
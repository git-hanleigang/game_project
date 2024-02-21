
local ApolloSlotNode = class("ApolloSlotNode",util_require("Levels.SlotsNode"))

ApolloSlotNode.m_specialRunUI = nil
-- 还原到初始被创建的状态
function ApolloSlotNode:reset()
    if self.m_specialRunUI then
        self.m_specialRunUI:removeFeatureNode()
        self.m_specialRunUI:removeFromParent()
        self.m_specialRunUI = nil
    end
    self.m_stage = nil
    self.m_multiple = nil

    if self:getCcbProperty("Node_shine") then
        self:getCcbProperty("Node_shine"):removeAllChildren()
    end

    ApolloSlotNode.super.reset(self)
end

return ApolloSlotNode
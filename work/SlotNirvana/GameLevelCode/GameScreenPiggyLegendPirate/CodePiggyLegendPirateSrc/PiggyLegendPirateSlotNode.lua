
local PiggyLegendPirateSlotNode = class("PiggyLegendPirateSlotNode",util_require("Levels.SlotsNode"))

PiggyLegendPirateSlotNode.m_numLabel = nil--图标上额外加的数字
-- 还原到初始被创建的状态
function PiggyLegendPirateSlotNode:reset()
    if self.m_numLabel then
        self.m_numLabel:removeFromParent()
        self.m_numLabel = nil
    end
    PiggyLegendPirateSlotNode.super.reset(self)
end

return PiggyLegendPirateSlotNode
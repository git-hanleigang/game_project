
local ZeusVsHadesSlotNode = class("ZeusVsHadesSlotNode",util_require("Levels.SlotsNode"))

ZeusVsHadesSlotNode.m_numLabel = nil--图标上额外加的数字
ZeusVsHadesSlotNode.m_bonusNode = nil--图标上挂的一个图标
-- 还原到初始被创建的状态
function ZeusVsHadesSlotNode:reset()
    if self.m_numLabel then
        self.m_numLabel:removeFromParent()
        self.m_numLabel = nil
    end
    if self.m_bonusNode then
        self.m_bonusNode:removeFromParent()
        self.m_bonusNode = nil
    end
    ZeusVsHadesSlotNode.super.reset(self)
end

return ZeusVsHadesSlotNode

-- FIX IOS 139 1
local Christmas2021SlotsNode = class("Christmas2021SlotsNode", util_require("Levels.SlotsNode"))
-- 还原到初始被创建的状态
function Christmas2021SlotsNode:reset()
    Christmas2021SlotsNode.super.reset(self)
    if self.m_tangGuoNode then
        self.m_tangGuoNode:removeFromParent()
        self.m_tangGuoNode = nil
    end
end

function Christmas2021SlotsNode:clear()
    Christmas2021SlotsNode.super.clear(self)
    if self.m_tangGuoNode then
        self.m_tangGuoNode:removeFromParent()
        self.m_tangGuoNode = nil
    end
end
return Christmas2021SlotsNode
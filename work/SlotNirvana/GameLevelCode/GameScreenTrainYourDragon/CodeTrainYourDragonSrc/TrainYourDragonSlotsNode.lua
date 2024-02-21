
-- FIX IOS 139 1
local TrainYourDragonSlotsNode = class("TrainYourDragonSlotsNode", util_require("Levels.SlotsNode"))
-- 还原到初始被创建的状态
function TrainYourDragonSlotsNode:reset()
    TrainYourDragonSlotsNode.super.reset(self)
    if self.m_shuziNode then
        self.m_shuziNode:removeFromParent()
        self.m_shuziNode = nil
    end
end

function TrainYourDragonSlotsNode:clear()
    TrainYourDragonSlotsNode.super.clear(self)
    if self.m_shuziNode then
        self.m_shuziNode:removeFromParent()
        self.m_shuziNode = nil
    end
end
return TrainYourDragonSlotsNode
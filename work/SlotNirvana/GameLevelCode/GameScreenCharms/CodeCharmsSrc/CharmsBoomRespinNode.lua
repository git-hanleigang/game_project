

local CharmsBoomNode = class("CharmsBoomNode", util_require("Levels.RespinNode"))
function CharmsBoomNode:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = globalData.slotRunData.levelConfigData:getBoomNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    else
        self.m_runningData = globalData.slotRunData.levelConfigData:getBoomNormalFreeSpinRespinCloumnByColumnIndex(self.p_rowIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end
function CharmsBoomNode:checkRemoveNextNode()
   return true
end
return CharmsBoomNode


local CharmsBoomNode = class("CharmsBoomNode", 
                                    util_require("Levels.RespinNode"))
function CharmsBoomNode:setMachine( machine )
    self.m_machine = machine
end

function CharmsBoomNode:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = self.m_machine.m_configData:getBoomNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    else
        self.m_runningData = self.m_machine.m_configData:getBoomNormalFreeSpinRespinCloumnByColumnIndex(self.p_rowIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

function CharmsBoomNode:checkRemoveNextNode()
    return true
end

return CharmsBoomNode
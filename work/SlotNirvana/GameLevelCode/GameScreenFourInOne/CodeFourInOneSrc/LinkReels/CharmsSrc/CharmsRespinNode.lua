

local CharmsNode = class("CharmsNode", 
                                    util_require("Levels.RespinNode"))

function CharmsNode:checkRemoveNextNode()
    return true
end
function CharmsNode:initMachine(machine)
    self.m_machine = machine
end
function CharmsNode:changeNodeDisplay( node )
    if node.p_symbolType and self.m_machine:isFixSymbol(node.p_symbolType) ~= true then
        node:runAnim("animation0") 
    end
end
function CharmsNode:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = self.m_machine.m_configData:getNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    else
        self.m_runningData = self.m_machine.m_configData:getNormalFreeSpinRespinCloumnByColumnIndex(self.p_rowIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

return CharmsNode
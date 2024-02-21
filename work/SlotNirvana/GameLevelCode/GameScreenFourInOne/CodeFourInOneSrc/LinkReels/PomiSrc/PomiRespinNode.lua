

local PomiNode = class("PomiNode",util_require("Levels.RespinNode"))

PomiNode.SYMBOL_Pomi_Bonus = 494
PomiNode.SYMBOL_Pomi_GRAND = 4104
PomiNode.SYMBOL_Pomi_MAJOR = 4103
PomiNode.SYMBOL_Pomi_MINOR = 4102
PomiNode.SYMBOL_Pomi_MINI = 4101
PomiNode.SYMBOL_Pomi_Reel_Up = 4105 -- 服务器没定义
PomiNode.SYMBOL_Pomi_Double_bet = 4106 -- 服务器没定义

function PomiNode:setMachine( machine )
    self.m_machine = machine
end
function PomiNode:checkRemoveNextNode()
    return true
end
--创建slotsnode 播放动画
function PomiNode:playCreateSlotsNodeAnima(node)
    if node and node.p_symbolType then
        if self:isFixSymbol(node.p_symbolType) then
            node:runAnim("idle", true) 
        end
    end
end
-- 是不是 respinBonus小块
function PomiNode:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_Pomi_Bonus or 
        symbolType == self.SYMBOL_Pomi_MINI or 
        symbolType == self.SYMBOL_Pomi_MINOR or 
        symbolType == self.SYMBOL_Pomi_MAJOR or 
        symbolType == self.SYMBOL_Pomi_GRAND or
        symbolType == self.SYMBOL_Pomi_Reel_Up or
        symbolType == self.SYMBOL_Pomi_Double_bet  then
        return true
    end
    return false
end
function PomiNode:changeNodeDisplay( node )
    if node and node.p_symbolType then
        if not self:isFixSymbol(node.p_symbolType) then
            node:runAnim("Dark")
        end
    end
end

function PomiNode:changeRunningData()
    self.m_runningData = self.m_machine.m_configData:get6ReelNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end
function PomiNode:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = self.m_machine.m_configData:getNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    else
        self.m_runningData = self.m_machine.m_configData:getNormalFreeSpinRespinCloumnByColumnIndex(self.p_rowIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

return PomiNode
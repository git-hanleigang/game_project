
local RespinNode = util_require("Levels.RespinNode")
local PomiNode = class("PomiNode",RespinNode)

local NODE_TAG = 10

PomiNode.REPIN_NODE_TAG = 1000

PomiNode.SYMBOL_FIX_Reel_Up = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 16
PomiNode.SYMBOL_FIX_Double_bet = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14


PomiNode.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
PomiNode.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
PomiNode.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
PomiNode.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

PomiNode.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE 


function PomiNode:checkRemoveNextNode()
    return true
end

function PomiNode:initClipNode(clipNode,opacity)
    RespinNode.initClipNode(self,clipNode)
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
    if symbolType == self.SYMBOL_FIX_SYMBOL or 
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR or 
        symbolType == self.SYMBOL_FIX_GRAND or
        symbolType == self.SYMBOL_FIX_Reel_Up or
        symbolType == self.SYMBOL_FIX_Double_bet  then
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
    self.m_runningData = globalData.slotRunData.levelConfigData:get6ReelNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

return PomiNode
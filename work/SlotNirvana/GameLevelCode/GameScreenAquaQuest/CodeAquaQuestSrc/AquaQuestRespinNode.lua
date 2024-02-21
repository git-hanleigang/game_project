local RespinNode = util_require("Levels.BaseReel.BaseRespinNode")
local AquaQuestRespinNode = class("AquaQuestRespinNode", RespinNode)

--[[
    初始化小块显示
]]
function AquaQuestRespinNode:initSymbolNode(hasFeature)
    AquaQuestRespinNode.super.initSymbolNode(self,hasFeature)
    --初始化显示隐藏裁切区域外的小块
    local symbolNode = self:getSymbolByRow(2)
    if symbolNode and symbolNode.p_symbolType ~= self.m_machine.SYMBOL_FIX_SYMBOL_EMPTY then
        self.m_machine:changeSymbolType(symbolNode,self.m_machine.SYMBOL_FIX_SYMBOL_EMPTY,true)
    end

end

--[[
    滚轮停止
]]
function AquaQuestRespinNode:slotReelDown()
    AquaQuestRespinNode.super.slotReelDown(self)
    --隐藏裁切区域外的小块
    local symbolNode = self:getSymbolByRow(2)
    if symbolNode and symbolNode.p_symbolType ~= self.m_machine.SYMBOL_FIX_SYMBOL_EMPTY then
        self.m_machine:changeSymbolType(symbolNode,self.m_machine.SYMBOL_FIX_SYMBOL_EMPTY,true)
    end
end

return AquaQuestRespinNode

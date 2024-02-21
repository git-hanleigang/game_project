---
--xcyy
--2018年5月23日
--BunnyBountyRespinNode.lua

local BunnyBountyRespinNode = class("BunnyBountyRespinNode",util_require("Levels.BaseReel.BaseRespinNode"))

--[[
    初始化小块显示
]]
function BunnyBountyRespinNode:initSymbolNode(hasFeature)
    BunnyBountyRespinNode.super.initSymbolNode(self,hasFeature)
    --初始化显示隐藏裁切区域外的小块
    local symbolNode = self:getSymbolByRow(2)
    if symbolNode and symbolNode.p_symbolType ~= self.m_machine.SYMBOL_SCORE_EMPTY then
        self.m_machine:changeSymbolType(symbolNode,self.m_machine.SYMBOL_SCORE_EMPTY,true)
    end

end

--裁切遮罩透明度
function BunnyBountyRespinNode:initClipOpacity(opacity)
    self.m_bgNode = util_createAnimation("Socre_BunnyBounty_Empty.csb")
    self.m_clipNode:addChild(self.m_bgNode, 1)
    self.m_bgNode:setPosition(cc.p(self.m_reelSize.width / 2, self.m_reelSize.height / 2))
end

--[[
    开始滚动
]]
function BunnyBountyRespinNode:startMove(func)
    BunnyBountyRespinNode.super.startMove(self,func)
end

function BunnyBountyRespinNode:setSymbolShow(isShow)
    local lockSymbol = self:getLockSymbolNode()
    if lockSymbol then
        lockSymbol:setVisible(isShow)
    end
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if rollNode then
            rollNode:setVisible(isShow)
        end
    
        if bigRollNode then
            bigRollNode:setVisible(isShow)
        end
    end)
end

--[[
    滚轮停止
]]
function BunnyBountyRespinNode:slotReelDown()
    BunnyBountyRespinNode.super.slotReelDown(self)
    --隐藏裁切区域外的小块
    local symbolNode = self:getSymbolByRow(2)
    if symbolNode and symbolNode.p_symbolType ~= self.m_machine.SYMBOL_SCORE_EMPTY then
        self.m_machine:changeSymbolType(symbolNode,self.m_machine.SYMBOL_SCORE_EMPTY,true)
    end
end

return BunnyBountyRespinNode
---
--xcyy
--2018年5月23日
--RobinIsHoodReelNode.lua

local RobinIsHoodReelNode = class("RobinIsHoodReelNode",util_require("Levels.BaseReel.BaseReelNode"))

function RobinIsHoodReelNode:onEnter()
    RobinIsHoodReelNode.super.onEnter(self)
end

function RobinIsHoodReelNode:onExit( )
    
    RobinIsHoodReelNode.super.onExit(self)
end

--[[
    重置所有滚动点层级
    @isNormal: 普通层级排序(下压上)
]]
function RobinIsHoodReelNode:resetAllRollNodeZOrder(isNormal)
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbolNode = self:getSymbolByRow(iRow)
        if symbolNode and symbolNode.p_symbolType then
            local isSpecialSymbol = self:checkIsSpecialSymbol(symbolNode.p_symbolType)
            
            --根据小块的层级设置滚动点的层级
            local zOrder = 0
            if type(self.m_getSymbolZOrderFunc) == "function" then
                zOrder = self.m_getSymbolZOrderFunc(symbolNode.p_symbolType)
            else
                zOrder = self.m_machine:getBounsScatterDataZorder(symbolNode.p_symbolType)
            end
            if symbolNode.p_symbolType ~= 95 and isSpecialSymbol and not isNormal then
                symbolNode.p_showOrder = zOrder + iRow
            else
                symbolNode.p_showOrder = zOrder - iRow
            end
            

            self:setRollNodeZOrder(rollNode,iRow,symbolNode.p_showOrder,isSpecialSymbol)
        end
    end)
end

return RobinIsHoodReelNode
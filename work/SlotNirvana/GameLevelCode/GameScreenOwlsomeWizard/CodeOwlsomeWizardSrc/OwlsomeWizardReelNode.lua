---
--xcyy
--2018年5月23日
--OwlsomeWizardReelNode.lua
local PublicConfig = require "OwlsomeWizardPublicConfig"
local OwlsomeWizardReelNode = class("OwlsomeWizardReelNode",util_require("Levels.BaseReel.BaseReelNode"))

--[[
    重置所有滚动点层级
]]
function OwlsomeWizardReelNode:resetAllRollNodeZOrder()
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbolNode = self:getSymbolByRow(iRow)
        if symbolNode and symbolNode.p_symbolType then
            local isSpecialSymbol = self:checkIsSpecialSymbol(symbolNode.p_symbolType)
            --根据小块的层级设置滚动点的层级
            local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
            

            --根据小块的层级设置滚动点的层级
            local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
            if self.m_machine:isFixSymbol(symbolNode.p_symbolType) then
                symbolNode.p_showOrder = zOrder + iRow
            else
                symbolNode.p_showOrder = zOrder - iRow
            end

            self:setRollNodeZOrder(rollNode,iRow,symbolNode.p_showOrder,isSpecialSymbol)
        end
    end)
end



return OwlsomeWizardReelNode
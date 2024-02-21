---
--xcyy
--2018年5月23日
--GhostBlasterReelNode.lua

local GhostBlasterReelNode = class("GhostBlasterReelNode",util_require("Levels.BaseReel.BaseReelNode"))

--[[
    按照配置初始轮盘
]]
function GhostBlasterReelNode:initSymbolByCfg()
    local initDatas = self.m_configData:getInitReelDatasByColumnIndex(self.m_colIndex)
    local startIndex = 1
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        self:removeSymbolByRowIndex(iRow)
        local symbolType = initDatas[iRow]
        if not symbolType then
            symbolType = initDatas[1]
        end

        local startIndex = startIndex + 1
        if iRow > #initDatas then
            startIndex = 1
        end

        local isInLongSymbol = self:checkIsInLongSymbol(iRow)
        --检测是否是大信号
        local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)

        if not isInLongSymbol then
            local symbolNode = self.m_createSymbolFunc(symbolType, iRow, self.m_colIndex, self.m_isLastNode)
            if isSpecialSymbol and bigRollNode then
                bigRollNode:addChild(symbolNode)
            else
                rollNode:addChild(symbolNode)
            end
            symbolNode:setPosition(cc.p(0,0))
            
            symbolNode:setName("symbol")
            if type(self.m_updateGridFunc) == "function" then
                self.m_updateGridFunc(symbolNode,true)
            end
            if type(self.m_checkAddSignFunc) == "function" then
                self.m_checkAddSignFunc(symbolNode)
            end
            --根据小块的层级设置滚动点的层级
            if symbolNode.p_showOrder and symbolNode.p_showOrder > 0 then
                self:setRollNodeZOrder(rollNode,iRow,symbolNode.p_showOrder,isSpecialSymbol)
            else
                local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
                symbolNode.p_showOrder = zOrder - iRow
                self:setRollNodeZOrder(rollNode,iRow,symbolNode.p_showOrder,isSpecialSymbol)
            end
        end
    end)
end

return GhostBlasterReelNode
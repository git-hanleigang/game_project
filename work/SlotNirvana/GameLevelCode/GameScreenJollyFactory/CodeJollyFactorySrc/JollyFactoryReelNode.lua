---
--xcyy
--2018年5月23日
--JollyFactoryReelNode.lua
local JollyFactoryReelNode = class("JollyFactoryReelNode",util_require("Levels.BaseReel.BaseReelNode"))

--[[
    重新加载滚动节点上的小块
]]
function JollyFactoryReelNode:reloadRollNode(rollNode,rowIndex)
    JollyFactoryReelNode.super.reloadRollNode(self,rollNode,rowIndex)
    util_setCascadeOpacityEnabledRescursion(rollNode,true)
end

--[[
    获取一个不是长条的小块
]]
function JollyFactoryReelNode:getNextNotLongSymbol()
    local symbolList = {7,8,9,10,11}
    local symbolType = symbolList[math.random(1,#symbolList)]
    return symbolType
end

function JollyFactoryReelNode:reloadSymbolByList(symbolList,longInfo)
    local initDatas = clone(symbolList)
    local startIndex = 1

    self.m_LongSymbolInfo = clone(longInfo)

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

        if not tolua.isnull(rollNode) then
            rollNode:stopAllActions()
        end

        if not tolua.isnull(bigRollNode) then
            bigRollNode:stopAllActions()
        end

        if iRow > self.m_rowNum then
            self:reloadRollNode(rollNode,iRow)
            return
        end

        local isInLongSymbol = self:checkIsInLongSymbol(iRow)
        --检测是否是大信号
        local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)

        if not isInLongSymbol then
            local symbolNode = self.m_createSymbolFunc(symbolType,iRow, self.m_colIndex, self.m_isLastNode,true)
            
            --检测是否是大信号
            if isSpecialSymbol and bigRollNode then
                bigRollNode:addChild(symbolNode)
            else
                rollNode:addChild(symbolNode)
            end
            symbolNode:setName("symbol")
            symbolNode:setPosition(cc.p(0,0))
            symbolNode.m_longInfo = nil
    
            local isLong = self:checkIsBigSymbol(symbolType)
            if isLong then
                local pos,longInfo = self:getLongSymbolPos(iRow,symbolType)
                symbolNode:setPosition(pos)
                symbolNode.m_longInfo = longInfo
                if longInfo then
                    --将偏移位置的滚动点上的小块移除
                    local maxCount = longInfo.maxCount
                    local curCount = longInfo.curCount
                    if maxCount > curCount then
                        for index = 1,maxCount - curCount do
                            self:removeSymbolByRowIndex(iRow - index)
                        end
                    end
                end
            end

             
            if type(self.m_updateGridFunc) == "function" then
                self.m_updateGridFunc(symbolNode)
            end
            if type(self.m_checkAddSignFunc) == "function" then
                self.m_checkAddSignFunc(symbolNode)
            end
    
            --根据小块的层级设置滚动点的层级
            local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
            symbolNode.p_showOrder = zOrder - iRow
    
            self:setRollNodeZOrder(rollNode,iRow,symbolNode.p_showOrder,isSpecialSymbol)
        end
        
    end)
end

--[[
    图标掉出画面动画
]]
function JollyFactoryReelNode:runSymbolOutAni()
    for iRow = 1,self.m_rowNum do
        local rollNode,bigRollNode = self:getRollNodeByRowIndex(iRow)
        self:getOutAction(rollNode,iRow)
        self:getOutAction(bigRollNode,iRow)
    end
end

--[[
    获取动作
]]
function JollyFactoryReelNode:getOutAction(rollNode,rowIndex)
    local startPos = cc.p(rollNode:getPosition())
    local endPos = self:getOutPos(rollNode,rowIndex,startPos)
    local actionList = {
        cc.MoveTo:create(7 / 30,endPos),
        cc.CallFunc:create(function()
           rollNode:setPosition(startPos) 
        end)
    }

    rollNode:runAction(cc.Sequence:create(actionList))
end

--[[
    获取画面外的坐标
]]
function JollyFactoryReelNode:getOutPos(rollNode,rowIndex,startPos)
    local endPos = cc.p(startPos.x,startPos.y - self.m_parentData.slotNodeH * (self.m_rowNum + 1))
    return endPos
    -- rollNode:setPositionY((iRow - 1 + 0.5) * self.m_parentData.slotNodeH)
end

return JollyFactoryReelNode
---
--xcyy
--2018年5月23日
--JuicyHolidayReelNode.lua
local PublicConfig = require "JuicyHolidayPublicConfig"
local JuicyHolidayReelNode = class("JuicyHolidayReelNode",util_require("Levels.BaseReel.BaseReelNode"))

--[[
    获取下个小块
]]
function JuicyHolidayReelNode:getNextSymbolType()
    -- reelDatas lastReelIndex
    --检测假滚卷轴是否存在
    if not self.m_parentData.reelDatas then
        self:resetReelDatas()
    end

    local function getNext()
        if self.m_mysteryType then
            --如果没有设置目标值,则随机一个普通的信号值
            if not self.m_targetSymbolType then
                self.m_targetSymbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_2)
            end
            return self.m_targetSymbolType
        end

        if self.m_parentData.beginReelIndex > #self.m_parentData.reelDatas then
            self.m_parentData.beginReelIndex = 1
        end
        local symbolType = self.m_parentData.reelDatas[self.m_parentData.beginReelIndex]
        self.m_parentData.beginReelIndex = self.m_parentData.beginReelIndex + 1

        local isLong,count = self:checkIsBigSymbol(symbolType)

        --长条小块且剩余的小块数量不足以支撑长条小块移除
        if isLong and self.m_leftCount <= count then
            symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_2)
        end

        return symbolType
    end

    --网络消息已经回来(动态升行期间不适用真数据)
    if not self.m_isWaittingNetBack and not self.m_isChangeSize then
        if self.m_leftCount > 0 then
            self.m_leftCount = self.m_leftCount - 1
            --返回假滚卷轴
            local symbolType = getNext()
            return symbolType
        elseif self.m_lastNodeCount > 0 then
            local symbolType
            if #self.m_lastList <= 0 then
                symbolType = getNext()
            else
                symbolType = self.m_lastList[1]
                table.remove(self.m_lastList,1)
            end

            if not symbolType then
                symbolType = getNext()
            end

            self.m_lastNodeCount = self.m_lastNodeCount - 1
            self.m_isLastNode = true
            if self.m_lastNodeCount <= 0 then
                self.m_lastNodeCount = 0
            end

            --返回真实小块数据
            return symbolType
        end
    end

    self.m_isLastNode = false
    --返回假滚卷轴
    local symbolType = getNext()
    return symbolType
end

--[[
    重新加载滚动节点上的小块
]]
function JuicyHolidayReelNode:reloadRollNode(rollNode,rowIndex)

    self:removeSymbolByRowIndex(rowIndex)

    local symbolType = self:getNextSymbolType()
    local preSymbol = self:getSymbolByRollNode(rollNode)
    if not tolua.isnull(preSymbol) and symbolType == preSymbol.p_symbolType then
        preSymbol:setPosition(cc.p(0,0))
        preSymbol.m_longInfo = nil
        preSymbol.m_isLastSymbol = self.m_isLastNode

        local isLong = self:checkIsBigSymbol(symbolType)
        if self.m_isLastNode and isLong then
            local pos,longInfo = self:getLongSymbolPos(self.m_curRowIndex,symbolType)
            preSymbol:setPosition(pos)
            preSymbol.m_longInfo = longInfo
            if longInfo then
                --将偏移位置的滚动点上的小块移除
                local maxCount = longInfo.maxCount
                local curCount = longInfo.curCount
                if maxCount > curCount then
                    for index = 1,maxCount - curCount do
                        self:removeSymbolByRowIndex(rowIndex - index)
                    end
                end
            end
        end
        
        if type(self.m_updateGridFunc) == "function" then
            self.m_updateGridFunc(preSymbol)
        end
        if type(self.m_checkAddSignFunc) == "function" then
            self.m_checkAddSignFunc(preSymbol)
        end

        --根据小块的层级设置滚动点的层级
        local zOrder = self:getSymbolZOrderByType(preSymbol.p_symbolType)
        preSymbol.p_showOrder = zOrder - rowIndex

        self:setRollNodeZOrder(rollNode,rowIndex,preSymbol.p_showOrder,false)
    else
        local isInLongSymbol = self:checkIsInLongSymbol(rowIndex)
        local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)
        rollNode.m_isLastSymbol = self.m_isLastNode
        if not isInLongSymbol then
            local symbolNode = self.m_createSymbolFunc(symbolType, self.m_curRowIndex, self.m_colIndex, self.m_isLastNode,true)
            
            --检测是否是大信号
            if isSpecialSymbol and self.m_bigReelNodeLayer then
                local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
                if bigRollNode then
                    bigRollNode:addChild(symbolNode)
                else
                    rollNode:addChild(symbolNode)
                end
            else
                rollNode:addChild(symbolNode)
            end
            symbolNode:setName("symbol")
            symbolNode:setPosition(cc.p(0,0))
            symbolNode.m_longInfo = nil

            local isLong = self:checkIsBigSymbol(symbolType)
            if self.m_isLastNode and isLong then
                local pos,longInfo = self:getLongSymbolPos(self.m_curRowIndex,symbolType)
                symbolNode:setPosition(pos)
                symbolNode.m_longInfo = longInfo
                if longInfo then
                    --将偏移位置的滚动点上的小块移除
                    local maxCount = longInfo.maxCount
                    local curCount = longInfo.curCount
                    if maxCount > curCount then
                        for index = 1,maxCount - curCount do
                            self:removeSymbolByRowIndex(rowIndex - index)
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
            symbolNode.p_showOrder = zOrder - rowIndex

            self:setRollNodeZOrder(rollNode,rowIndex,symbolNode.p_showOrder,isSpecialSymbol)
        end
    end

    if self.m_isLastNode then
        self.m_curRowIndex = self.m_curRowIndex + 1
    end
end

return JuicyHolidayReelNode
---
--xcyy
--2018年5月23日
--DazzlingDiscoClassicReelNode.lua

local DazzlingDiscoClassicReelNode = class("DazzlingDiscoClassicReelNode",util_require("Levels.BaseReel.BaseReelNode"))

--信号基础层级
local BASE_SLOT_ZORDER = {
    Normal  =   1000,       --  基础信号层级
    BIG     =   10000      --  大信号层级
}
DazzlingDiscoClassicReelNode.m_curSymbolType = 100


--[[
    初始化滚动的点
]]
function DazzlingDiscoClassicReelNode:initBaseRollNodes()
    --计算需要创建的滚动的点的数量
    local nodeCount = self:getMaxNodeCount()
    --创建对应数量的滚动点
    for index = 1,nodeCount do
        local rollNode = cc.Node:create()
        self.m_rollNodes[#self.m_rollNodes + 1] = rollNode
        self.m_clipNode:addChild(rollNode,BASE_SLOT_ZORDER.Normal)
        local pos = cc.p(self.m_reelSize.width / 2,(index - 1) * self.m_parentData.slotNodeH)
        rollNode:setPosition(pos)

        if self.m_bigReelNodeLayer then
            self.m_bigReelNodeLayer:createRollNode(self.m_colIndex)
        end
    end
end

--[[
    获取最大的滚动点数量 
]]
function DazzlingDiscoClassicReelNode:getMaxNodeCount()
    local nodeCount = math.ceil(self.m_reelSize.height / self.m_parentData.slotNodeH) + 5

    
    -- local needAddCount = 0
    -- --检测当前滚轮上最长的长条
    -- for iRow = 1,#self.m_rollNodes do
    --     local symbolNode = self:getSymbolByRollNode(self.m_rollNodes[iRow])--self:getSymbolByRow(iRow)
    --     if symbolNode and symbolNode.p_symbolType then
    --         local isBig,count = self:checkIsBigSymbol(symbolNode.p_symbolType)
    --         if isBig and count > needAddCount then
    --             needAddCount = count - 1
    --         end
    --     end
    -- end

    -- nodeCount = nodeCount + needAddCount
    return nodeCount
end

--[[
    检测小块是否出界
]]
function DazzlingDiscoClassicReelNode:checkRollNodeIsOutLine(rollNode)
    local isOutLine = false
    local symbolNode = self:getSymbolByRow(1)
    local isBig,longCount = false,1
    --判断是否是长条信号
    if symbolNode and symbolNode.p_symbolType then
        isBig,longCount = self:checkIsBigSymbol(symbolNode.p_symbolType)
    end

    local slotHight = self.m_parentData.slotNodeH
    local bottomBorder = -slotHight
    if isBig then
        bottomBorder = -slotHight * (longCount - 1)
    end
    if rollNode:getPositionY() < bottomBorder then
        for curCount = 1,longCount do
            --最后一个小块
            local lastNode = self.m_rollNodes[#self.m_rollNodes]
            --第一个小块
            local firstNode = self.m_rollNodes[1]
            firstNode:setPositionY(lastNode:getPositionY() + slotHight)

            --如果出界把第一个小块移动到队列尾部
            for index = 1,#self.m_rollNodes - 1 do
                self.m_rollNodes[index] = self.m_rollNodes[index + 1]
            end
    
            self.m_rollNodes[#self.m_rollNodes] = firstNode
    
            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:putFirstRollNodeToTail(self.m_colIndex)
                self.m_bigReelNodeLayer:refreshRollNodePosByTarget(firstNode,self.m_colIndex,#self.m_rollNodes)
            end

            self:reloadRollNode(firstNode,#self.m_rollNodes)
        end
        
    end
end

--[[
    开始滚动
]]
function DazzlingDiscoClassicReelNode:startMove(func)
    self:setIsWaitNetBack(true)
    
    self.m_isLastNode = false

    self.m_curRowIndex = 1

    self:resetSymbolStatus()

    self.m_lastNodeCount = math.floor(self.m_reelSize.height / self.m_parentData.slotNodeH) 
    self.m_maxCount = self.m_lastNodeCount
    
    self.m_parentData.isDone = false

    function callBack()
        if type(func) == "function" then
            func()
        end
        self:startSchedule()
    end

    self.m_leftCount = self.m_configData.p_reelRunDatas[self.m_colIndex]
    if self.m_configData.p_reelBeginJumpTime and self.m_configData.p_reelBeginJumpTime > 0 then
        self:addJumoActionAfterReel(callBack)
    else
        callBack()
    end
end

--[[
    开启计时器
]]
function DazzlingDiscoClassicReelNode:startSchedule()

    self.m_machine:registScheduleCallBack(self.m_colIndex,function(dt)
        if globalData.slotRunData.gameRunPause then
            return
        end

        --检测是否需要升行或降行
        if self.m_isChangeSize then
            self:dynamicChangeSize(dt)
        end

        local offset = math.floor(dt * self.m_reelMoveSpeed) 
        
        --刷新小块位置,如果下面的点移动到可视区域外,怎把该点移动到队尾
        self:updateRollNodePos(offset)

        -- self:checkAddRollNode()

        --第一个小块永远是最下面的点,如果该点上的小块是真实数据小块,则滚动停止
        local symbolNode = self:getSymbolByRow(1)
        local rollNode = self:getRollNodeByRowIndex(1)
        local posY = rollNode:getPositionY()
        if symbolNode and symbolNode.m_isLastSymbol then
            self:slotReelDown()
        end
    end)
end

--[[
    刷新小块位置
]]
function DazzlingDiscoClassicReelNode:updateRollNodePos(offset)

    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if offset > self.m_parentData.slotNodeH * 1.5 then
            offset = self.m_parentData.slotNodeH
        end
        rollNode:setPositionY(rollNode:getPositionY() - offset)
        if bigRollNode then
            bigRollNode:setPositionY(bigRollNode:getPositionY() - offset)
        end
    end)

    --只检测第一个小块是否出界即可
    self:checkRollNodeIsOutLine(self.m_rollNodes[1])
end

--[[
    重置小块位置
]]
function DazzlingDiscoClassicReelNode:resetRollNodePos()
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        rollNode:setPositionY((iRow - 1) * self.m_parentData.slotNodeH)
        if self.m_bigReelNodeLayer then
            self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,self.m_colIndex,iRow)
        end
    end)
end

--[[
    滚轮停止
]]
function DazzlingDiscoClassicReelNode:slotReelDown()
    --滚轮停止
    self.m_scheduleNode:unscheduleUpdate()
    self.m_machine:unRegistScheduleCallBack(self.m_colIndex)

    self.m_isChangeSize = false
    self.m_parentData.isDone = true

    --重置小块
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbolType = self.m_netList[iRow]
        local isLastNode = true
        if not symbolType then
            isLastNode = false
            symbolType = self:getNextSymbolType()
        end
        self.m_curSymbolType = symbolType
        self:reloadRollNodeBySymbolType(iRow,symbolType,isLastNode)
        
    end)
    self:resetRollNodePos()
    self:resetSymbolRowIndex()

    --回弹动作
    self:runBackAction(function()
        
    end)

    if type(self.m_doneFunc) == "function" then
        self.m_doneFunc(self.m_colIndex)
    end

    --检测滚动节点数量是否大于与裁切层可显示数量
    self:checkReduceRollNode()
end

--[[
    重新加载滚动节点上的小块
]]
function DazzlingDiscoClassicReelNode:reloadRollNode(rollNode,rowIndex)

    self:removeSymbolByRowIndex(rowIndex)

    local symbolType = self:getNextSymbolType()

    local isInLongSymbol = self:checkIsInLongSymbol(rowIndex)
    local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)
    rollNode.m_isLastSymbol = self.m_isLastNode

    if not isInLongSymbol then
        self.m_curSymbolType = symbolType
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

    if self.m_isLastNode then
        self.m_curRowIndex = self.m_curRowIndex + 1
    end
end

--[[
    判断是否在长条小块内
]]
function DazzlingDiscoClassicReelNode:checkIsInLongSymbol(rowIndex)
    local isInLongSymbol = false
    --遍历小块,如果该点在长条小块范围内,不创建信号块
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbol = nil
        if bigRollNode then
            symbol = self:getSymbolByRollNode(bigRollNode)
        end

        if not symbol then
            symbol = self:getSymbolByRollNode(rollNode)
        end

        if symbol and symbol.p_symbolType then
            local isBig,count = self:checkIsBigSymbol(symbol.p_symbolType)
            if isBig and rowIndex <= iRow + count - 1 and rowIndex >= iRow then
                isInLongSymbol = true
                return true
            end
        end
    end)

    return isInLongSymbol
end

--[[
    获取下个小块
]]
function DazzlingDiscoClassicReelNode:getNextSymbolType()
    --检测假滚卷轴是否存在
    if not self.m_parentData.reelDatas then
        self.m_machine:checkUpdateReelDatas(self.m_parentData)
    end

    local function getNext()
        if self.m_mysteryType then
            --如果没有设置目标值,则随机一个普通的信号值
            if not self.m_targetSymbolType then
                self.m_targetSymbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_5)
            end
            return self.m_targetSymbolType
        end

        if self.m_parentData.beginReelIndex > #self.m_parentData.reelDatas then
            self.m_parentData.beginReelIndex = 1
        end
        local symbolType = self.m_parentData.reelDatas[self.m_parentData.beginReelIndex]
        self.m_parentData.beginReelIndex = self.m_parentData.beginReelIndex + 1

        --长条小块且剩余的小块数量不足以支撑长条小块移除
        if symbolType == 94 and self.m_leftCount <= 3 then
            symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_5)
        end

        if self.m_curSymbolType ~= 94 or symbolType ~= 94 then
            --插入真实数据的位置是否为空信号
            if self.m_leftCount == 0 and #self.m_lastList > 0 and self.m_lastList[1] ~= 100  then
                symbolType = 100
            elseif self.m_curSymbolType == 100 and symbolType == 100 then
                if self.m_machine.m_isTriggerJackpotReels then
                    symbolType = math.random(101,105)
                else
                    symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,TAG_SYMBOL_TYPE.SYMBOL_SCORE_5)
                end
                
            elseif self.m_curSymbolType ~= 100 and symbolType ~= 100 and self.m_curSymbolType ~= 94 and symbolType ~= 94 then
                --防止插入数据位置有多个非空信号值
                symbolType = 100
            end
        end
        
        

        util_printLog("当前小块信号值为:"..symbolType..",colIndex = "..self.m_colIndex)
        return symbolType
    end

    --网络消息已经回来(动态升行期间不适用真数据)
    if not self.m_isWaittingNetBack and not self.m_isChangeSize then
        -- util_printLog("测试代码 colIndex = "..self.m_colIndex..",当前剩余假滚小块数量:"..self.m_leftCount..",当前剩余真实小块数量:"..self.m_lastNodeCount)
        if self.m_leftCount > 0 then
            self.m_leftCount = self.m_leftCount - 1
            --返回假滚卷轴
            local symbolType = getNext()
            -- util_printLog("测试代码 当前小块信号值为:"..symbolType..",colIndex = "..self.m_colIndex)
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
            -- util_printLog("测试代码 当前小块信号值为:"..symbolType..",colIndex = "..self.m_colIndex)
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
    回弹动作
]]
function DazzlingDiscoClassicReelNode:runBackAction(func)

    local moveTime = self.m_configData.p_reelResTime
    local dis = self.m_configData.p_reelResDis

    local endCount = 0
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        rollNode:stopAllActions()
        local seq = {}
        local pos = cc.p(rollNode:getPosition())
        local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y - 12)))
        local action2 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y + 6)))
        local action3 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y)))
        local action4 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y + 5)))
        local action5 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y)))
        local action6 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y + 3)))
        local action7 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y)))
        local action8 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y + 2)))
        local action9 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y)))
        seq = {action1,action2,action3,action4,action5,action6,action7,action8,action9}

        if type(func) == "function" then
            seq[#seq + 1] = cc.CallFunc:create(function()
                endCount = endCount + 1
                if endCount >= #self.m_rollNodes then
                    func()
                end
            end)
        end
        
        local sequece =cc.Sequence:create(seq)

        rollNode:runAction(sequece)

        --大信号回弹
        if bigRollNode then
            bigRollNode:stopAllActions()
            local seq = {}
            local pos = cc.p(bigRollNode:getPosition())
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y - 12)))
            local action2 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y + 6)))
            local action3 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y)))
            local action4 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y + 5)))
            local action5 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y)))
            local action6 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y + 3)))
            local action7 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y)))
            local action8 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y + 2)))
            local action9 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 10, cc.p(pos.x,pos.y)))
            seq = {action1,action2,action3,action4,action5,action6,action7,action8,action9}
            
            local sequece =cc.Sequence:create(seq)

            bigRollNode:runAction(sequece)
        end
    end)
end

--[[
    按照配置初始轮盘
]]
function DazzlingDiscoClassicReelNode:initSymbolByCfg()
    local initDatas = self.m_configData:getInitReelDatasByColumnIndex(self.m_colIndex)
    local startIndex = 1
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        self:removeSymbolByRowIndex(iRow)
        local symbolType = initDatas[iRow]
        if not symbolType then
            symbolType = self:getNextSymbolType()
        end

        local startIndex = startIndex + 1
        if iRow > #initDatas then
            startIndex = 1
        end

        local isInLongSymbol = self:checkIsInLongSymbol(iRow)
        --检测是否是大信号
        local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)

        if not isInLongSymbol then
            self.m_curSymbolType = symbolType
            local symbolNode = self.m_createSymbolFunc(symbolType, iRow, self.m_colIndex, self.m_isLastNode)
            if isSpecialSymbol and bigRollNode then
                bigRollNode:addChild(symbolNode)
            else
                rollNode:addChild(symbolNode)
            end
            symbolNode:setPosition(cc.p(0,0))
            
            symbolNode:setName("symbol")
            if type(self.m_updateGridFunc) == "function" then
                self.m_updateGridFunc(symbolNode)
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

return DazzlingDiscoClassicReelNode
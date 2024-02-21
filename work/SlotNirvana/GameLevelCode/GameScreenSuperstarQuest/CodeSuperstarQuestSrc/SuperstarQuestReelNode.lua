---
--xcyy
--2018年5月23日
--SuperstarQuestReelNode.lua

local SuperstarQuestReelNode = class("SuperstarQuestReelNode",util_require("Levels.BaseReel.BaseReelNode"))

--[[
    创建裁切层
]]
function SuperstarQuestReelNode:createClipNode()
    self.m_clipNode = ccui.Layout:create()
    self.m_clipNode:setAnchorPoint(cc.p(0.5, 0))
    self.m_clipNode:setTouchEnabled(false)
    self.m_clipNode:setSwallowTouches(false)
    local size = CCSizeMake(self.m_parentData.reelWidth * 2,self.m_parentData.reelHeight) 
    self.m_reelSize = size
    self.m_clipNode:setPosition(cc.p(self.m_parentData.reelWidth / 2,0))
    self.m_clipNode:setContentSize(self.m_reelSize)
    self.m_clipNode:setClippingEnabled(true)
    self:addChild(self.m_clipNode)

    --显示区域
    -- self.m_clipNode:setBackGroundColor(cc.c3b(255, 0, 0))
    -- self.m_clipNode:setBackGroundColorOpacity(255)
    -- self.m_clipNode:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--[[
    检测小块是否出界
]]
function SuperstarQuestReelNode:checkRollNodeIsOutLine(rollNode)
    local isOutLine = false
    local symbolNode = self:getSymbolByRow(1)
    local isBig,longCount = false,1
    --判断是否是长条信号
    if symbolNode and symbolNode.p_symbolType then
        isBig,longCount = self:checkIsBigSymbol(symbolNode.p_symbolType)
        if symbolNode.m_longInfo then
            longCount = symbolNode.m_longInfo.curCount
        end
    end

    local slotHight = self.m_parentData.slotNodeH
    local bottomBorder = -slotHight / 2
    if isBig then
        bottomBorder = -slotHight * (longCount - 0.5)
    end
    if rollNode:getPositionY() < bottomBorder then
        for curCount = 1,longCount do
            --最后一个小块
            local lastNode = self.m_rollNodes[#self.m_rollNodes]

            --第一个小块
            local firstNode = self.m_rollNodes[1]
            local firstBigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,1)

            local tail = firstNode:getChildByName("tail")
            if not tolua.isnull(tail) then
                local pos = util_convertToNodeSpace(tail,self.m_clipNode)
                util_changeNodeParent(self.m_clipNode,tail,firstNode:getLocalZOrder() - 1)
                tail:setPosition(pos)
                local actionList = {
                    cc.MoveTo:create(self.m_parentData.slotNodeH / self.m_reelMoveSpeed,cc.p(pos.x,pos.y - self.m_parentData.slotNodeH)),
                    cc.RemoveSelf:create()
                    
                }
                tail:runAction(cc.Sequence:create(actionList))
            end

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

        --重置滚动点层级
        self:resetAllRollNodeZOrder()
        
    end
end

--[[
    重新加载滚动节点上的小块
]]
function SuperstarQuestReelNode:reloadRollNode(rollNode,rowIndex)

    self:removeSymbolByRowIndex(rowIndex)

    local symbolType = self:getNextSymbolType()

    local isInLongSymbol = self:checkIsInLongSymbol(rowIndex)
    local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)
    rollNode.m_isLastSymbol = self.m_isLastNode
    if not isInLongSymbol then
        local symbolNode = self.m_createSymbolFunc(symbolType, self.m_curRowIndex, self.m_colIndex, self.m_isLastNode,true)

        local tail
        if symbolType ~= self.m_machine.SYMBOL_WILD_1 and self.m_machine:isWildSymbol(symbolType) and self.m_machine.m_isEnter then
            tail = util_spineCreate("Socre_SuperstarQuest_Wild_tw",true,true)
            if symbolType == self.m_machine.SYMBOL_WILD_2 then
                tail:setSkin("skin2")
            elseif symbolType == self.m_machine.SYMBOL_WILD_3 then
                tail:setSkin("skin3")
            elseif symbolType == self.m_machine.SYMBOL_WILD_4 then
                tail:setSkin("skin4")
            end
            util_spinePlay(tail,"idleframe")
            tail:setName("tail")
        end
        
        --检测是否是大信号
        if isSpecialSymbol and self.m_bigReelNodeLayer then
            local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
            if tail then
                rollNode:addChild(tail)
            end
            if bigRollNode then
                bigRollNode:addChild(symbolNode)
                
            else
                rollNode:addChild(symbolNode)
            end
        else
            if tail then
                rollNode:addChild(tail)
            end
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

    if self.m_isLastNode then
        self.m_curRowIndex = self.m_curRowIndex + 1
    end
end

--[[
    设置层级
]]
function SuperstarQuestReelNode:setRollNodeZOrder(rollNode,rowIndex,showOrder,isBigSymbol)
    if isBigSymbol and self.m_bigReelNodeLayer then
        local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
        if bigRollNode then
            bigRollNode:setLocalZOrder(showOrder + (self.m_colIndex - 1) * 10)
        end
    end

    rollNode:setLocalZOrder(showOrder)
end

function SuperstarQuestReelNode:getTailByRowIndex(rowIndex)
    local rollNode = self.m_rollNodes[rowIndex]

    local tail = rollNode:getChildByName("tail")
    return tail
end



return SuperstarQuestReelNode
---
--xcyy
--2018年5月23日
--CashTornadoReelNode.lua

local CashTornadoReelNode = class("CashTornadoReelNode",util_require("Levels.BaseReel.BaseReelNode"))

--滚动方向
local DIRECTION = {
    Vertical = 0,       --纵向
    Horizontal = 1,     --横向

}

--信号基础层级
local BASE_SLOT_ZORDER = {
    Normal  =   1000,       --  基础信号层级
    BIG     =   10000      --  大信号层级
}

--如果symbolType为97，添加的时候添加一个底板，跟着97同频刷帧

--[[
    层级关系如图所示
    rootNode
        scheduleNode
        clipNode
            rollNodes
      
]]
function CashTornadoReelNode:initUI()
    CashTornadoReelNode.super.initUI(self)

    -- self:createDiBan()
end

function CashTornadoReelNode:onEnter()
    CashTornadoReelNode.super.onEnter(self)
end

function CashTornadoReelNode:onExit( )
    
    CashTornadoReelNode.super.onExit(self)
end

--[[
    创建裁切层
]]
function CashTornadoReelNode:createClipNode()
    self.m_clipNode = ccui.Layout:create()
    self.m_clipNode:setAnchorPoint(cc.p(0.5, 0))
    self.m_clipNode:setTouchEnabled(false)
    self.m_clipNode:setSwallowTouches(false)
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮横向不裁切
        local size = CCSizeMake(self.m_parentData.reelWidth * 1.5,self.m_parentData.reelHeight - 280) 
        self.m_reelSize = size
        self.m_clipNode:setPosition(cc.p(self.m_parentData.reelWidth / 2,140))
    else--横向滚轮纵向不裁切
        local size = CCSizeMake(self.m_parentData.reelWidth,self.m_parentData.reelHeight * 1.5) 
        self.m_reelSize = size
        self.m_clipNode:setPosition(cc.p(0,self.m_parentData.reelHeight / 2))
    end
    self.m_clipNode:setContentSize(self.m_reelSize)
    self.m_clipNode:setClippingEnabled(true)
    self:addChild(self.m_clipNode)

    -- --显示区域
    -- self.m_clipNode:setBackGroundColor(cc.c3b(255, 0, 0))
    -- self.m_clipNode:setBackGroundColorOpacity(255)
    -- self.m_clipNode:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--[[
    初始化滚动的点
]]
function CashTornadoReelNode:initBaseRollNodes()
    --计算需要创建的滚动的点的数量
    local nodeCount = self:getMaxNodeCount()
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        --创建对应数量的滚动点
        for index = 1,nodeCount do
            local rollNode = cc.Node:create()
            self.m_rollNodes[#self.m_rollNodes + 1] = rollNode
            self.m_clipNode:addChild(rollNode,BASE_SLOT_ZORDER.Normal)
            rollNode:setPosition(cc.p(self.m_reelSize.width / 2,(index - 2 + 0.5) * self.m_parentData.slotNodeH))

            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:createRollNode(self.m_colIndex)
            end
        end
    else --横向滚轮
        --创建对应数量的滚动点
        for index = 1,nodeCount do
            local rollNode = cc.Node:create()
            self.m_rollNodes[#self.m_rollNodes + 1] = rollNode
            self.m_clipNode:addChild(rollNode,BASE_SLOT_ZORDER.Normal)
            local posX = self.m_reelSize.width - (index - 1 + 0.5) * self.m_parentData.slotNodeW
            rollNode:setPosition(cc.p(posX,self.m_reelSize.height / 2))

            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:createRollNode(self.m_colIndex)
            end
        end
    end
end

--[[
    按照配置初始轮盘
]]
function CashTornadoReelNode:initSymbolByCfg()
    local initDatas = self.m_configData:getInitReelDatasByColumnIndex(self.m_colIndex)
    local startIndex = 1

    --计算长条信号
    self:updateLongSymbolInfo(initDatas)

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

        if iRow > self.m_rowNum then
            self:reloadRollNode(rollNode,iRow)
            return
        end

        local isInLongSymbol = self:checkIsInLongSymbol(iRow)
        --检测是否是大信号
        local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)

        if not isInLongSymbol then
            local symbolNode = self.m_createSymbolFunc(symbolType, self.m_curRowIndex, self.m_colIndex, self.m_isLastNode,true)
            
            --检测是否是大信号
            if isSpecialSymbol and bigRollNode then
                if self.m_colIndex == 5 and symbolType == 97 and not bigRollNode.diBan then
                    bigRollNode.diBan = self:getDiban()
                    local pos = util_convertToNodeSpace(bigRollNode,self.m_clipNode)
                    bigRollNode.diBan:setPosition(pos)
                end
                bigRollNode:addChild(symbolNode)
            else
                if self.m_colIndex == 5 and symbolType == 97 and not rollNode.diBan then
                    rollNode.diBan = self:getDiban()
                    local pos = util_convertToNodeSpace(rollNode,self.m_clipNode)
                    rollNode.diBan:setPosition(pos)
                end
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
    重新加载滚动节点上的小块
]]
function CashTornadoReelNode:reloadRollNode(rollNode,rowIndex)

    self:removeSymbolByRowIndex(rowIndex)

    local symbolType = self:getNextSymbolType()
    

    local isInLongSymbol = self:checkIsInLongSymbol(rowIndex)
    local isSpecialSymbol = self:checkIsSpecialSymbol(symbolType)
    rollNode.m_isLastSymbol = self.m_isLastNode
    if not isInLongSymbol then
        local symbolNode = self.m_createSymbolFunc(symbolType, self.m_curRowIndex, self.m_colIndex, self.m_isLastNode,true)
        
        --检测是否是大信号
        if isSpecialSymbol and self.m_bigReelNodeLayer then
            local bigRollNode = self.m_bigReelNodeLayer:getRollNode(self.m_colIndex,rowIndex)
            if bigRollNode then
                if self.m_colIndex == 5 then
                    if symbolType == 97 and not bigRollNode.diBan then
                        bigRollNode.diBan = self:getDiban()
                        local pos = util_convertToNodeSpace(bigRollNode,self.m_clipNode)
                        bigRollNode.diBan:setPosition(pos)

                    end
                end
                
                bigRollNode:addChild(symbolNode)
            else
                if self.m_colIndex == 5 then
                    if symbolType == 97 and not rollNode.diBan then
                        rollNode.diBan = self:getDiban()
                        local pos = util_convertToNodeSpace(rollNode,self.m_clipNode)
                        rollNode.diBan:setPosition(pos)
                    end
                end
                
                rollNode:addChild(symbolNode)
            end
        else
            if self.m_colIndex == 5 then
                if symbolType == 97 and not rollNode.diBan then
                    
                    rollNode.diBan = self:getDiban()
                    local pos = util_convertToNodeSpace(rollNode,self.m_clipNode)
                    rollNode.diBan:setPosition(pos)
                end
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
    刷新小块位置
]]
function CashTornadoReelNode:updateRollNodePos(offset)

    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        if self.m_direction == DIRECTION.Vertical then --纵向滚轮
            if offset > self.m_parentData.slotNodeH then
                offset = self.m_parentData.slotNodeH
            end
            rollNode:setPositionY(rollNode:getPositionY() - offset)
            local symbol = nil
            if bigRollNode then
                symbol = self:getSymbolByRollNode(bigRollNode)
            end

            if not symbol then
                symbol = self:getSymbolByRollNode(rollNode)
            end

            if symbol and symbol.p_symbolType then
                if self.m_colIndex == 5 and symbol.p_symbolType == 97 then
                    if rollNode.diBan then
                        local pos = util_convertToNodeSpace(rollNode,self.m_clipNode)
                        rollNode.diBan:setPosition(pos)
                    end
                else
                    if rollNode.diBan then
                        rollNode.diBan:stopAllActions()
                        rollNode.diBan:removeFromParent()
                        rollNode.diBan = nil
                    end
                end
            end 
            
            
            if bigRollNode then
                bigRollNode:setPositionY(bigRollNode:getPositionY() - offset)
                if self.m_colIndex == 5 then
                    if bigRollNode.diBan then
                        bigRollNode.diBan:setPositionY(bigRollNode.diBan:getPositionY() - offset)
                    end
                end
                
            end
        else --横向滚轮
            if offset > self.m_parentData.slotNodeW then
                offset = self.m_parentData.slotNodeW
            end
            rollNode:setPositionX(rollNode:getPositionX() + offset)
            if bigRollNode then
                bigRollNode:setPositionX(bigRollNode:getPositionX() + offset)
            end
        end
    end)

    --只检测第一个小块是否出界即可
    self:checkRollNodeIsOutLine(self.m_rollNodes[1])
end

--[[
    检测小块是否出界
]]
function CashTornadoReelNode:checkRollNodeIsOutLine(rollNode)
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

    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        local slotHight = self.m_parentData.slotNodeH
        local bottomBorder = -slotHight / 2
        if isBig then
            bottomBorder = -slotHight * (longCount - 0.5)
        end
        if rollNode:getPositionY() < bottomBorder then
            if self.m_colIndex == 5 then
                if symbolNode and symbolNode.p_symbolType then
                    if symbolNode.p_symbolType == 97 and not tolua.isnull(rollNode.diBan) then
                        rollNode.diBan:stopAllActions()
                        rollNode.diBan:removeFromParent()
                        rollNode.diBan = nil
                    end
                end
                
            end
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

            --重置滚动点层级
            self:resetAllRollNodeZOrder()
            
        end
    else --横向滚轮
        local slotWidth = self.m_parentData.slotNodeW
        local posX = rollNode:getPositionX()
        local rightBorder = slotWidth / 2 + self.m_reelSize.width
        if isBig then
            rightBorder = self.m_reelSize.width + slotWidth * (longCount - 0.5)
        end
        if rollNode:getPositionX() > rightBorder then

            for curCount = 1,longCount do
                --最后一个小块
                local lastNode = self.m_rollNodes[#self.m_rollNodes]
                --第一个小块
                local firstNode = self.m_rollNodes[1]
                firstNode:setPositionX(lastNode:getPositionX() - slotWidth)

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
end

--[[
    重置小块位置
]]
function CashTornadoReelNode:resetRollNodePos()
    if self.m_direction == DIRECTION.Vertical then --纵向滚轮
        self:forEachRollNode(function(rollNode,bigRollNode,iRow)
            local symbol = nil
            if bigRollNode then
                symbol = self:getSymbolByRollNode(bigRollNode)
            end

            if not symbol then
                symbol = self:getSymbolByRollNode(rollNode)
            end
            rollNode:setPositionY((iRow - 2 + 0.5) * self.m_parentData.slotNodeH)
            -- rollNode:setPositionY((iRow - 1 + 0.5) * self.m_parentData.slotNodeH)

            if symbol and symbol.p_symbolType then
                if symbol.p_symbolType == 97 and self.m_colIndex == 5 and rollNode.diBan then
                    rollNode.diBan:stopAllActions()
                    rollNode.diBan:setPositionY((iRow - 1 + 0.5) * self.m_parentData.slotNodeH)
                elseif symbol.p_symbolType ~= 97 and self.m_colIndex == 5 and rollNode.diBan then
                    
                    rollNode.diBan:stopAllActions()
                    rollNode.diBan:removeFromParent()
                    rollNode.diBan = nil
                end
            end 
            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,self.m_colIndex,iRow)
            end
        end)
    else --横向滚轮
        self:forEachRollNode(function(rollNode,bigRollNode,iRow)
            local posX = self.m_reelSize.width - (iRow - 1 + 0.5) * self.m_parentData.slotNodeW
            rollNode:setPositionX(posX)
            if self.m_bigReelNodeLayer then
                self.m_bigReelNodeLayer:refreshRollNodePosByTarget(rollNode,self.m_colIndex,iRow)
            end
        end)
    end
end

--[[
    回弹动作
]]
function CashTornadoReelNode:runBackAction(func)

    local moveTime = self.m_configData.p_reelResTime
    local dis = self.m_configData.p_reelResDis

    local endCount = 0
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        rollNode:stopAllActions()
        local seq = {}
        local pos = cc.p(rollNode:getPosition())
        if self.m_direction == DIRECTION.Vertical then --纵向滚轮
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
            local action2 = cc.MoveTo:create(moveTime / 2,pos)
            seq = {action1,action2}
        else --横向滚轮
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x + dis,pos.y)))
            local action2 = cc.MoveTo:create(moveTime / 2,pos)
            seq = {action1,action2}
        end

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

        if self.m_colIndex == 5 and rollNode.diBan then
            rollNode.diBan:stopAllActions()
            local seq = {}
            local pos = util_convertToNodeSpace(rollNode,self.m_clipNode)
            rollNode.diBan:setPosition(pos)
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
            local action2 = cc.MoveTo:create(moveTime / 2,pos)
            seq = {action1,action2}

            
            local sequece =cc.Sequence:create(seq)

            rollNode.diBan:runAction(sequece)
        end
        

        --大信号回弹
        if bigRollNode then
            bigRollNode:stopAllActions()
            local seq = {}
            local pos = cc.p(bigRollNode:getPosition())
            if self.m_direction == DIRECTION.Vertical then --纵向滚轮
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                local action2 = cc.MoveTo:create(moveTime / 2,pos)
                seq = {action1,action2}
            else --横向滚轮
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x + dis,pos.y)))
                local action2 = cc.MoveTo:create(moveTime / 2,pos)
                seq = {action1,action2}
            end
            
            local sequece =cc.Sequence:create(seq)

            bigRollNode:runAction(sequece)

            if self.m_colIndex == 5 and bigRollNode.diBan then
                bigRollNode.diBan:stopAllActions()
                local seq = {}
                local pos = cc.p(bigRollNode.diBan:getPosition())
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                local action2 = cc.MoveTo:create(moveTime / 2,pos)
                seq = {action1,action2}
    
                
                local sequece =cc.Sequence:create(seq)
    
                bigRollNode.diBan:runAction(sequece)
            end
        end
    end)
end

--[[
    @desc: 开始滚动之前添加一个回弹效果
    time:2020-07-21 19:23:58
    @return:
]]
function CashTornadoReelNode:addJumoActionAfterReel(func)
    local endCount = 0
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local seq = {}
        local pos = cc.p(rollNode:getPosition())
        local moveTime = self.m_configData.p_reelBeginJumpTime / 2
        local moveDistance = self.m_configData.p_reelBeginJumpHight
        if self.m_direction == DIRECTION.Vertical then --纵向滚轮
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x,pos.y + moveDistance)))
            local action2 = cc.MoveTo:create(moveTime,pos)
            seq = {action1,action2}
        else --横向滚轮
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x - moveDistance,pos.y)))
            local action2 = cc.MoveTo:create(moveTime,pos)
            seq = {action1,action2}
        end

        seq[#seq + 1] = cc.CallFunc:create(function()
            endCount = endCount + 1
            if endCount >= #self.m_rollNodes then
                if type(func) == "function" then
                    func()
                end
            end
        end)

        local sequece =cc.Sequence:create(seq)
        rollNode:runAction(sequece)

        if self.m_colIndex == 5 and rollNode.diBan then
            rollNode.diBan:stopAllActions()
            local seq = {}
            local pos = util_convertToNodeSpace(rollNode,self.m_clipNode)
            rollNode.diBan:setPosition(pos)
            local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x,pos.y + moveDistance)))
            local action2 = cc.MoveTo:create(moveTime / 2,pos)
            seq = {action1,action2}

            
            local sequece =cc.Sequence:create(seq)

            rollNode.diBan:runAction(sequece)
        end

        --大信号
        if bigRollNode then
            local seq = {}
            local pos = cc.p(bigRollNode:getPosition())
            local moveTime = self.m_configData.p_reelBeginJumpTime / 2
            local moveDistance = self.m_configData.p_reelBeginJumpHight
            if self.m_direction == DIRECTION.Vertical then --纵向滚轮
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x,pos.y + moveDistance)))
                local action2 = cc.MoveTo:create(moveTime,pos)
                seq = {action1,action2}
            else --横向滚轮
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x - moveDistance,pos.y)))
                local action2 = cc.MoveTo:create(moveTime,pos)
                seq = {action1,action2}
            end

            local sequece =cc.Sequence:create(seq)
            bigRollNode:runAction(sequece)

            if self.m_colIndex == 5 and bigRollNode.diBan then
                bigRollNode.diBan:stopAllActions()
                local seq = {}
                local pos = util_convertToNodeSpace(bigRollNode,self.m_clipNode)
                bigRollNode.diBan:setPosition(pos)
                local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime, cc.p(pos.x,pos.y + moveDistance)))
                local action2 = cc.MoveTo:create(moveTime / 2,pos)
                seq = {action1,action2}
    
                
                local sequece =cc.Sequence:create(seq)
    
                bigRollNode.diBan:runAction(sequece)
            end
        end
    end)
end

--[[
    重置所有滚动点层级
]]
function CashTornadoReelNode:resetAllRollNodeZOrder()
    self:forEachRollNode(function(rollNode,bigRollNode,iRow)
        local symbolNode = self:getSymbolByRow(iRow)
        if symbolNode and symbolNode.p_symbolType then
            local isSpecialSymbol = self:checkIsSpecialSymbol(symbolNode.p_symbolType)
            --根据小块的层级设置滚动点的层级
            local zOrder = self:getSymbolZOrderByType(symbolNode.p_symbolType)
            symbolNode.p_showOrder = zOrder - iRow

            self:setRollNodeZOrder(rollNode,iRow,symbolNode.p_showOrder,isSpecialSymbol)
        else
            print("11111")
        end
    end)
end


function CashTornadoReelNode:createDiBan()
    self.dibanList = {}
    --预先创建5个
    if self.m_colIndex == 5 then
        for i = 1, 5 do
            self:createBonus4DiBan()
        end
        
    end
end

function CashTornadoReelNode:createBonus4DiBan()
    local diban = util_createAnimation("CashTornado_Bonus4_diban.csb")
    self.m_clipNode:addChild(diban,BASE_SLOT_ZORDER.Normal - 900)
    -- diban:setVisible(false)
    -- table.insert( self.dibanList, diban )
    return diban
end

function CashTornadoReelNode:getDiban()
    -- if table_length(self.dibanList) <= 0 then
        local diban = self:createBonus4DiBan()
        diban:setVisible(true)
        return diban
    -- else
    --     local diban = self.dibanList[1]
    --     table.remove( self.dibanList,1)
    --     diban:setVisible(true)
    --     return diban
    -- end
end

function CashTornadoReelNode:pushBackDiban(diban)
    diban:setVisible(false)
    table.insert( self.dibanList, diban )
end

function CashTornadoReelNode:ctor(params)
    CashTornadoReelNode.super.ctor(self,params)
    self.dibanList = {}
end


return CashTornadoReelNode
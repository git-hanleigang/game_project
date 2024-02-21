local PiggyLegendPirateRespinNode = class("PiggyLegendPirateRespinNode", util_require("Levels.RespinNode"))

--裁切遮罩透明度
function PiggyLegendPirateRespinNode:initClipOpacity(opacity)
    if false and opacity and opacity>0 then
        -- local pos = cc.p(0 , 0)
        -- local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
        -- local spPath = "common/PepperBlast_RESPIN_DI.png"
        -- opacity = 255
        -- local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
        -- self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

function PiggyLegendPirateRespinNode:setQuickRunState()
    
end

--根据配置随机
function PiggyLegendPirateRespinNode:getRunningSymbolTypeByConfig()
    local type = self.m_runningData[self.m_runningDataIndex]
    if self.m_runningDataIndex >= #self.m_runningData then
        self.m_runningDataIndex = 1
    else
        self.m_runningDataIndex = self.m_runningDataIndex + 1
    end
    local reSpinNodePos = self.m_machine:getPosReelIdx(self.p_rowIndex, self.p_colIndex)
    if self.m_machine.m_reSpinBonusQuickPos ~= reSpinNodePos then
        if type == self.m_machine.SYMBOL_BONUS3 then
            type = self.m_machine.SYMBOL_BONUS1
        end
    end
    
    return type
end

--设置回弹
function PiggyLegendPirateRespinNode:setRunDis(dis)
    self.m_resDis = dis
end

--执行回弹动作
function PiggyLegendPirateRespinNode:runBaseResAction()
    self:baseResetNodePos()
    local baseResTime = 0
    --最终停止小块回弹
    if self.m_baseFirstNode then
        local offPos = self.m_baseFirstNode:getPositionY()-self.m_baseStartPosY
        local actionTable ,downTime = self:getBaseResAction(0)
        local reSpinNodePos = self.m_machine:getPosReelIdx(self.p_rowIndex, self.p_colIndex)
        if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
            actionTable ,downTime = self:getBaseResActionQuick(0)
        end

        if actionTable and #actionTable>0 then
            self.m_baseFirstNode:runAction(cc.Sequence:create(actionTable))
        end
        if baseResTime<downTime then
            baseResTime = downTime
        end
    end
    --上边缘小块回弹
    if self.m_baseNextNode then
        local offPos = self.m_baseFirstNode:getPositionY() - self.m_baseStartPosY - self.m_slotNodeHeight
        local actionTable ,downTime = self:getBaseResAction(0)
        local reSpinNodePos = self.m_machine:getPosReelIdx(self.p_rowIndex, self.p_colIndex)
        if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
            actionTable ,downTime = self:getBaseResActionQuick(0)
        end

        if actionTable and #actionTable>0 then
            self.m_baseNextNode:runAction(cc.Sequence:create(actionTable))

        end
        
        self.m_moveSpeed = 1500

        --回弹结束后移除上边缘小块
        if downTime>0 then
            --检测时长
            if baseResTime<downTime then
                baseResTime = downTime
            end
            performWithDelay(self,function()
                self:baseRemoveNode(self.m_baseNextNode)
                self.m_baseNextNode = nil
                if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
                    self.m_machine.m_respinView:changeLastOneAnimTipVisible(false)
                end
                
            end,downTime)
        else
            self:baseRemoveNode(self.m_baseNextNode)
            self.m_baseNextNode = nil
            if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
                self.m_machine.m_respinView:changeLastOneAnimTipVisible(false)
            end
        end
    end
    return baseResTime
end

--获取回弹动作序列
function PiggyLegendPirateRespinNode:getBaseResActionQuick(startPos)
    local timeDown = 0
    local speedActionTable = {}
    local dis =  startPos + self.m_resDis
    local speedStart = self.m_moveSpeed
    local preSpeed = speedStart/ 118
    for i= 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = moveDis / speedStart
        timeDown = timeDown + time
        local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end
    -- local delayTime = cc.DelayTime:create(0.2)
    local moveBy = cc.MoveBy:create(0.2,cc.p(0, - self.m_resDis))
    -- speedActionTable[#speedActionTable + 1] = delayTime
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.2
    return speedActionTable, timeDown
end

--刷新滚动
function PiggyLegendPirateRespinNode:baseUpdateMove(dt)
    if globalData.slotRunData.gameRunPause then
        return
    end
    self.m_baseCurDistance = self.m_baseCurDistance+ self:getBaseMoveDis(dt)
    local reSpinNodePos = self.m_machine:getPosReelIdx(self.p_rowIndex, self.p_colIndex)
    if self.m_machine.m_reSpinBonusQuickPos == reSpinNodePos then
        if self.m_baseCurDistance-self.m_baseLastDistance >=self.m_slotNodeHeight then
            --计算滚动距离
            -- self.m_baseMoveCount = math.floor((self.m_baseCurDistance-self.m_baseLastDistance)/self.m_slotNodeHeight)
            -- self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight*self.m_baseMoveCount
            self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight
            --改变小块
            self:baseChangeNextNode()

            local reduceOff = 1
            if self.m_machine.m_isPlayReSpinQuick then
                reduceOff = 3.8
            end
            if self.m_runNodeNum <= 15 then
                self.m_moveSpeed = self.m_moveSpeed - 69*reduceOff
            end
            --检测是否结束
            if self:baseCheckOverMove() then
                --结束滚动
                self:baseOverMove()
            end
        else
            --刷新小块坐标
            self:updateBaseNodePos()
        end
    else
        if self.m_baseCurDistance-self.m_baseLastDistance >=self.m_slotNodeHeight then
            --计算滚动距离
            -- self.m_baseMoveCount = math.floor((self.m_baseCurDistance-self.m_baseLastDistance)/self.m_slotNodeHeight)
            -- self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight*self.m_baseMoveCount
            self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight
            --改变小块
            self:baseChangeNextNode()
            --检测是否结束
            if self:baseCheckOverMove() then
                --结束滚动
                self:baseOverMove()
            end
        else
            --刷新小块坐标
            self:updateBaseNodePos()
        end
    end
end

--结束回调
function PiggyLegendPirateRespinNode:baseOverCallBack()
    self:baseResetNodePos()
    --没有节点默认idle状态
    if not self.m_lastNode or self:getTypeIsEndType(self.m_lastNode.p_symbolType) == false then
        self:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
     else 
        self:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
     end
    if  self.m_DownCallback ~= nil then
        self.m_DownCallback(self.m_lastNode,self:getRespinNodeStatus())
    end

    
end

--获取小块类型
function PiggyLegendPirateRespinNode:getBaseNodeType()
    if self.m_runNodeNum == 0 and self.m_runLastNodeType ~= nil then
        return self.m_runLastNodeType
    else 
        -- 假滚最后一个 强制改成和服务器给的结果一样
        if self.m_runNodeNum == 1 and self.m_runLastNodeType ~= nil and self.m_moveSpeed < 1500 then
            -- local aa = 1
            return self.m_runLastNodeType
        end

        if self.m_runningData == nil then
            return self:randomRuningSymbolType()
        else
            if self.m_runNodeNum == -1 and self.m_runLastNodeType == self.m_machine.SYMBOL_BONUS3 then
                if self.m_runningData[self.m_runningDataIndex] == self.m_machine.SYMBOL_BONUS3 then
                    self.m_runningDataIndex = self.m_runningDataIndex + 1
                end
            end
            return self:getRunningSymbolTypeByConfig()
        end
    end
end

--获得下一个小块
function PiggyLegendPirateRespinNode:getBaseNextNode(nodeType,score)
    local node = nil
    if self.m_runNodeNum == 0 then
        --最后一个小块
        node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex, true, self.m_runNodeNum)
    else
        if self.m_runNodeNum == 1 then
            node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex, self.p_colIndex, false, self.m_runNodeNum)
        else
            node = self.getSlotNodeBySymbolType(nodeType, nil, nil, false, self.m_runNodeNum)
        end
    end
    if self:getTypeIsEndType(nodeType ) == false then
        node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    else
        node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
    end
    node.score = score
    node.p_symbolType = nodeType
    return node
end

return PiggyLegendPirateRespinNode

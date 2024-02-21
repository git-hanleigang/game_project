local BunnysLockRespinNode = class("BunnysLockRespinNode", util_require("Levels.RespinNode"))

local NODE_TAG = 10
local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20

--裁切区域
function BunnysLockRespinNode:initClipNode(clipNode,opacity)
    if not clipNode then
          local nodeHeight = self.m_slotReelHeight / self.m_machineRow
          local size = cc.size(self.m_slotNodeWidth,nodeHeight - 1)
          local pos = cc.p(-math.ceil( self.m_slotNodeWidth / 2 ),- nodeHeight / 2)
          self.m_clipNode = util_createOneClipNode(RESPIN_CLIPMODE.RECT,size,pos)
          self:addChild(self.m_clipNode)
          --设置裁切块属性
          local originalPos = cc.p(0,0)
          util_setClipNodeInfo(self.m_clipNode,RESPIN_CLIPTYPE.SINGLE,RESPIN_CLIPMODE.RECT,size,originalPos)
    else
          self.m_clipNode = clipNode
    end
    self:initClipOpacity(opacity)
end

--裁切遮罩透明度
function BunnysLockRespinNode:initClipOpacity(opacity)
    self.m_maskNode = util_createAnimation("BunysLock_symbol_dark.csb")
    self.m_clipNode:addChild(self.m_maskNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    self.m_maskNode:setVisible(false)
    self.m_maskNode:setScale(1.05)

    self.m_noticeAni = util_createAnimation("BunysLock_bonus_yugao.csb")
    self.m_clipNode:addChild(self.m_noticeAni, REEL_SYMBOL_ORDER.REEL_ORDER_3 + 3000)
    self.m_noticeAni:setVisible(false)
end

function BunnysLockRespinNode:toDarkAni()
    self.m_maskNode:setVisible(true)
    self.m_maskNode:runCsbAction("dark")
end

function BunnysLockRespinNode:hideDarkAni()
    self.m_maskNode:runCsbAction("dark_over",false,function()
        self.m_maskNode:setVisible(false)
    end)
end

function BunnysLockRespinNode:playNoticeAni()
    self.m_noticeAni:setVisible(true)
    self.m_noticeAni:runCsbAction("actionframe",false,function()
        self.m_noticeAni:setVisible(false)
    end)
end

--刷新滚动
function BunnysLockRespinNode:baseUpdateMove(dt)
    if globalData.slotRunData.gameRunPause then
        return
    end
    self.m_baseCurDistance = self.m_baseCurDistance+ self:getBaseMoveDis(dt)
    if self.m_baseCurDistance-self.m_baseLastDistance >=self.m_slotNodeHeight then
        --计算滚动距离
        -- self.m_baseMoveCount = math.floor((self.m_baseCurDistance-self.m_baseLastDistance)/self.m_slotNodeHeight)
        -- self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight*self.m_baseMoveCount
        self.m_baseLastDistance = self.m_baseLastDistance+self.m_slotNodeHeight
        
        --检测是否结束
        if self:baseCheckOverMove() then
            --结束滚动
            self:baseOverMove()
        else
            --改变小块
            self:baseChangeNextNode()
        end
    else
        --刷新小块坐标
        self:updateBaseNodePos()
    end
end

--获得下一个小块
function BunnysLockRespinNode:getBaseNextNode(nodeType,score)
    nodeType = self.m_machine:getMysteryType(nodeType)
    local node = nil
    if self.m_runNodeNum == 0 then
        --最后一个小块
        node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex, true)
    else
        node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex)
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

--设置滚动速度
function BunnysLockRespinNode:changeRunSpeed(isQuick)
    if isQuick then
          self:setRunSpeed(MOVE_SPEED * 2)
    else
          self:setRunSpeed(MOVE_SPEED)
    end
end

--获取回弹动作序列
function BunnysLockRespinNode:getBaseResAction(startPos)
    if self.m_baseFirstNode and self.m_baseFirstNode.p_symbolType then
        for k,endInfo in pairs(self.m_symbolTypeEnd) do
            if self.m_baseFirstNode.p_symbolType == endInfo.type then
                return {},0
            end
        end
        
    end

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
    local moveBy = cc.MoveBy:create(0.1,cc.p(0, - self.m_resDis))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.1
    return speedActionTable, timeDown
end

--执行回弹动作
function BunnysLockRespinNode:runBaseResAction()
    self:baseResetNodePos()
    local baseResTime = 0
    --最终停止小块回弹
    if self.m_baseFirstNode then
        local offPos = self.m_baseFirstNode:getPositionY()-self.m_baseStartPosY
        local actionTable ,downTime = self:getBaseResAction(0)
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
        if actionTable and #actionTable>0 then
            self.m_baseNextNode:runAction(cc.Sequence:create(actionTable))
        end
        --回弹结束后移除上边缘小块
        if downTime>0 then
            --检测时长
            if baseResTime<downTime then
                baseResTime = downTime
            end
            performWithDelay(self,function()
                -- self:baseRemoveNode(self.m_baseNextNode)
                -- self.m_baseNextNode = nil
                self.m_baseNextNode:setLocalZOrder(10)
            end,downTime)
        else
            -- self:baseRemoveNode(self.m_baseNextNode)
            -- self.m_baseNextNode = nil
            self.m_baseNextNode:setLocalZOrder(10)
        end
    end
    return baseResTime
end

--创建下一个节点
function BunnysLockRespinNode:baseCreateNextNode()
    if self.m_isGetNetData == true then
        self.m_runNodeNum = self.m_runNodeNum - 1
    end
    --创建下一个
    local nodeType,score = self:getBaseNodeType()
    local node = self:getBaseNextNode(nodeType,score)
    --最后一个小块
    if self.m_runNodeNum == 0 then
        self.m_lastNode = node
    end
    self:playCreateSlotsNodeAnima(node)
    node:setTag(NODE_TAG) 
    self.m_clipNode:addChild(node)
    --赋值给下一个节点
    self.m_baseNextNode = node
    self:updateBaseNodePos()
    self:changeNodeDisplay( node )
end

--开始滚动
function BunnysLockRespinNode:baseStartMove()
    if self:getRespinNodeStatus() == RESPIN_NODE_STATUS.IDLE then
        self:setUseMystery(true)
        self:setRespinNodeStatus(RESPIN_NODE_STATUS.RUNNING)
        if not self.m_baseNextNode then
            self:baseCreateNextNode()
        end
        self:onUpdate(handler(self,self.baseUpdateMove))
    end
end

--传入高亮类型 随机类型
function BunnysLockRespinNode:setEndSymbolType(symbolTypeEnd, symbolRandomType)
    self.m_symbolTypeEnd = symbolTypeEnd
    self.m_runningData = symbolRandomType 
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--根据配置随机
function BunnysLockRespinNode:getRunningSymbolTypeByConfig()

    -- local mysteryType = self.SYMBOL_BONUS
    -- local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    -- if selfData and selfData.change_num then
    --     mysteryType = selfData.change_num
    -- end

    -- --前半段假滚全部滚mystery信号
    -- if self.m_isUseMystery then
    --     if self.p_rowIndex == 2 and self.p_colIndex == 3 and mysteryType == self.m_machine.SYMBOL_BONUS then
    --         return TAG_SYMBOL_TYPE.SYMBOL_BONUS
    --     end
    --     return self.m_machine.Socre_MYSTERY
    -- end

    -- if self.p_rowIndex == 2 and self.p_colIndex == 3 and mysteryType == self.m_machine.SYMBOL_BONUS then
    --     return TAG_SYMBOL_TYPE.SYMBOL_BONUS
    -- end

    -- --如果最终轮盘上的值等于mystery,则假滚出的都是mystery图标
    -- local symbolType = self.m_machine:getMatrixPosSymbolType(self.p_rowIndex,self.p_colIndex)
    -- if symbolType == mysteryType then
    --     return symbolType
    -- end

    local type = self.m_runningData[self.m_runningDataIndex]
    if self.m_runningDataIndex >= #self.m_runningData then
        self.m_runningDataIndex = 1
    else
        self.m_runningDataIndex = self.m_runningDataIndex + 1
    end
    return type
end

--获取网络消息
function BunnysLockRespinNode:setRunInfo(runNodeLen, lastNodeType)
    self.m_isGetNetData = true
    self.m_runNodeNum = runNodeLen
    self.m_runLastNodeType = lastNodeType
end

function BunnysLockRespinNode:setUseMystery(isUse)
    self.m_isUseMystery = isUse
end

return BunnysLockRespinNode
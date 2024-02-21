local MayanMysteryRespinNode = class("MayanMysteryRespinNode", util_require("Levels.RespinNode"))

local MOVE_SPEED = 1500
local RES_DIS = 20

MayanMysteryRespinNode.SYMBOL_EMPTY = 100
MayanMysteryRespinNode.SYMBOL_BONUS = 94

--裁切遮罩透明度
function MayanMysteryRespinNode:initClipOpacity()
    
end

--裁切区域
function MayanMysteryRespinNode:initClipNode(clipNode,opacity)
    if not clipNode then
        local nodeHeight = 423 / self.m_machineRow
        local size = cc.size(self.m_slotNodeWidth-8, nodeHeight)
        local pos = cc.p(-math.ceil((self.m_slotNodeWidth-8) / 2), -nodeHeight / 2)
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

--创建下一个节点
function MayanMysteryRespinNode:baseCreateNextNode()
    if self.m_isGetNetData == true then
        self.m_runNodeNum = self.m_runNodeNum - 1
    end
    --创建下一个
    local nodeType,score = self:getBaseNodeType()
    local node = self:getBaseNextNode(nodeType,score)
    if node.p_symbolType == 94 then
        node:setScale(0.95)
    end
    --最后一个小块
    if self.m_runNodeNum == 0 then
        self.m_lastNode = node
    end
    self:playCreateSlotsNodeAnima(node)
    node:setTag(10) 
    if node.p_symbolType == self.SYMBOL_EMPTY then
        self.m_clipNode:addChild(node, 1)
    else
        self.m_clipNode:addChild(node, 2)
    end
    --赋值给下一个节点
    self.m_baseNextNode = node
    self:updateBaseNodePos()
    self:changeNodeDisplay( node )
end

--设置滚动速度
function MayanMysteryRespinNode:changeRunSpeed(isQuick , quickNum)
    if isQuick then
        self:setRunSpeed(MOVE_SPEED * 2)
    else
        self:setRunSpeed(MOVE_SPEED)
    end
    self.m_isQuick = isQuick
end
  
--设置回弹距离
function MayanMysteryRespinNode:changeResDis(isQuick)
    if isQuick then
        self.m_resDis = RES_DIS * 3
    else
        self.m_resDis = RES_DIS
    end
end

--获取回弹动作序列
function MayanMysteryRespinNode:getBaseResAction(startPos)
    local timeDown = 0
    local speedActionTable = {}
    local dis =  startPos + self.m_resDis
    local speedStart = self.m_moveSpeed
    local preSpeed = speedStart/ 118
    for i= 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = 0
        --判断是否在快滚状态下
        if self.m_moveSpeed == MOVE_SPEED * 2 then
            time = moveDis / speedStart * 10
            timeDown = timeDown + time
        else
            time = moveDis / speedStart
            timeDown = timeDown + time
        end
        local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end
    local moveBy = cc.MoveBy:create(0.1,cc.p(0, - self.m_resDis))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.1
    return speedActionTable, timeDown
end

--执行回弹动作
function MayanMysteryRespinNode:runBaseResAction()
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
        --快滚时将上边缘小块变为bonus
        if self.m_isQuick then
            if self.m_baseNextNode.p_symbolImage then
                self.m_baseNextNode.p_symbolImage:removeFromParent()
                self.m_baseNextNode.p_symbolImage = nil
            end

            if self.m_baseNextNode.p_symbolType == self.SYMBOL_EMPTY then
                self.m_machine:changeSymbolType(self.m_baseNextNode, self.SYMBOL_BONUS, true)
            end
        end
       
        self.m_baseNextNode:setLocalZOrder(SHOW_ZORDER.SHADE_LAYER_ORDER + 1)
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
                self:baseRemoveNode(self.m_baseNextNode)
                self.m_baseNextNode = nil
            end,downTime)
        else
            self:baseRemoveNode(self.m_baseNextNode)
            self.m_baseNextNode = nil
        end
    end
    return baseResTime
end

--获取随机信号
function MayanMysteryRespinNode:randomRuningSymbolType()
    local nodeType = nil
    if xcyy.SlotsUtil:getArc4Random() % 30 == 1 and self.m_runNodeNum ~= 0 then
        -- nodeType = self:getRandomEndType()
        if nodeType == nil then
            nodeType = self:randomSymbolRandomType()
        end
    else 
        nodeType = self:randomSymbolRandomType()
    end
    return nodeType
end

--获取网络消息
function MayanMysteryRespinNode:setRunInfo(runNodeLen, lastNodeType)
    if self.m_machine.m_respinView and not self.m_machine.m_respinView:isLastSpin() then
        self.m_isGetNetData = true
        self.m_runNodeNum = runNodeLen
    end
    self.m_runLastNodeType = lastNodeType
end
  
--设置开始滚动真实长度
function MayanMysteryRespinNode:setRunLong(runNodeLen)
    self.m_isGetNetData = true
    self.m_runNodeNum = runNodeLen
end
return MayanMysteryRespinNode
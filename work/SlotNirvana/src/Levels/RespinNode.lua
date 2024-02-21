-----
---
---
-----
local RespinNode = class("RespinNode",util_require("Levels.BaseRespin"))

local NODE_TAG = 10
local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20

RespinNode.m_clipNode = nil
RespinNode.m_DownCallback = nil
RespinNode.m_DownBeforeResCallback = nil

RespinNode.m_moveSpeed = nil
RespinNode.m_resDis = nil

RespinNode.p_rowIndex = nil
RespinNode.p_colIndex = nil

RespinNode.m_isGetNetData = nil
RespinNode.m_runNodeNum = nil
RespinNode.m_lastNode = nil
RespinNode.m_runLastNodeType = nil

RespinNode.m_RespinNodeStatus = nil
RespinNode.m_runningDataIndex = nil
RespinNode.m_runningData = nil
--新滚动相关
RespinNode.m_baseLastDistance = nil                                 --上次移动距离
RespinNode.m_baseCurDistance = nil                                  --本次移动距离
RespinNode.m_baseMoveCount = nil                                    --滚动个数
RespinNode.m_baseStartPosY = nil                                    --开始和结束坐标
RespinNode.m_baseFirstNode = nil                                    --传入首个节点
RespinNode.m_baseNextNode = nil                                     --下一个小块

--子类可以重写修改滚动参数
function RespinNode:initUI(rsView, _machine)
    self:setMachine(_machine)
    self:setRunSpeed(self:getBaseMoveSpeed(MOVE_SPEED))
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()
end
--子类继承修正裁框坐标
function RespinNode:changeNodePos()

end
--子类继承修改节点显示内容
function RespinNode:changeNodeDisplay(node)

end
--子类可以重写 最后一个上边缘小块是否提前移除不参与回弹
function RespinNode:checkRemoveNextNode()
    return false
end
--裁切区域
function RespinNode:initClipNode(clipNode,opacity)
    if not clipNode then
          local nodeHeight = self.m_slotReelHeight / self.m_machineRow
          local size = cc.size(self.m_slotNodeWidth,nodeHeight + 1)
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
function RespinNode:initClipOpacity(opacity)
    if opacity and opacity>0 then
          local pos = cc.p(-self.m_slotNodeWidth*0.5-2 , -self.m_slotNodeHeight*0.5-5)
          local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
          local spPath = nil --RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
          local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,opacity,spPath)
          self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

--子类可以重写 读取配置
function RespinNode:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    else
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalFreeSpinRespinCloumnByColumnIndex(self.p_rowIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end
--初始化配置
function RespinNode:initConfigData()
    self:initRunningData()
end
--初始化数据
function RespinNode:initBaseData()
    --初始化内部需要的数据
    self.m_runningDataIndex = nil
    self.m_runNodeNum = 1
    self:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)           --运行状态
    self.m_baseLastDistance = 0                                 --上次移动距离
    self.m_baseCurDistance = 0                                  --本次移动距离
    self.m_baseMoveCount = 0                                    --滚动个数
    self.m_baseStartPosY = 0                                    --开始和结束坐标
    self.m_baseFirstNode = nil                                  --传入首个节点
    self.m_baseNextNode = nil                                   --下一个小块
end
--退出时调用
function RespinNode:clearBaseData()
 
    self:baseClearNode(self.m_baseFirstNode)            --移除节点
    self:baseClearNode(self.m_baseNextNode)             --移除节点
    self.m_slotNodeHeight = nil                         --滚动高度
    self.m_moveSpeed = nil                              --滚动速度
    self.m_resDis =nil                                  --回弹距离

    self.m_baseFirstNode = nil                          --传入首个节点
    self.m_RespinNodeStatus = nil                       --运行状态
    self.m_baseLastDistance = nil                       --上次移动距离
    self.m_baseCurDistance = nil                        --本次移动距离
    self.m_baseStartPosY = nil                          --开始和结束坐标
    self.m_baseNextNode = nil                           --下一个小块
end


--展示
function RespinNode:onEnter()

end
--移除
function RespinNode:onExit()
    self:clearBaseData()
end
--放入首节点
function RespinNode:setFirstSlotNode(node)
    util_changeNodeParent(self.m_clipNode,node)
    node:setPosition(cc.p(0, 0))
    node:setTag(NODE_TAG)
    node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    self.m_lastNode = node
    self:changeNodePos()
    self.m_baseFirstNode = node                            --传入首个节点
    self.m_baseStartPosY = self.m_baseFirstNode:getPositionY()  --开始和结束坐标
    self:changeNodeDisplay( node )
end
--开始滚动
function RespinNode:startMove()
    self.m_isGetNetData = false
    self.m_runNodeNum = 1
    self.m_lastNode = nil
    self.m_isQuickStop = false
    self:baseStartMove()
end
--获取网络消息
function RespinNode:setRunInfo(runNodeLen, lastNodeType)
    self.m_isGetNetData = true
    self.m_runNodeNum = runNodeLen
    self.m_runLastNodeType = lastNodeType
end
--快停
function RespinNode:quicklyStop()
    self.m_isQuickStop = true
    if self.m_runNodeNum >= 1 then
        self.m_runNodeNum = 1
    end
end
--最终停止节点
function RespinNode:getLastNode()
   return self.m_lastNode
end
--设置滚动速度
function RespinNode:setRunSpeed(speed)
    self.m_moveSpeed = speed
end
--读取滚动速度
function RespinNode:getRunSpeed()
    return self.m_moveSpeed
end
--获取基础滚动速度
function RespinNode:getBaseMoveSpeed(_moveSpeed)
    local moveSpeed = _moveSpeed or MOVE_SPEED
    if self.m_machine and self.m_machine.m_configData.p_respinReelMoveSpeedMul then
        moveSpeed = moveSpeed * self.m_machine.m_configData.p_respinReelMoveSpeedMul
    end
    return moveSpeed
end
--设置回调
function RespinNode:setReelDownCallBack(cb, cb1)
   self.m_DownCallback = cb
   self.m_DownBeforeResCallback = cb1
end
--获取运行状态
function RespinNode:getNodeRunning()
   if self:getRespinNodeStatus() == RESPIN_NODE_STATUS.RUNNING then
      return true
   end
   return false
end
--设置状态
function RespinNode:setRespinNodeStatus(status)
    self.m_RespinNodeStatus = status
end
--读取状态
function RespinNode:getRespinNodeStatus()
    return self.m_RespinNodeStatus
end
--获取随机信号
function RespinNode:randomRuningSymbolType()
    local nodeType = nil
    if xcyy.SlotsUtil:getArc4Random() % 30 == 1 and self.m_runNodeNum ~= 0 then
        nodeType = self:getRandomEndType()
        if nodeType == nil then
        nodeType = self:randomSymbolRandomType()
        end
    else 
        nodeType = self:randomSymbolRandomType()
    end
    return nodeType
end
--根据配置随机
function RespinNode:getRunningSymbolTypeByConfig()
    local type = self.m_runningData[self.m_runningDataIndex]
    if self.m_runningDataIndex >= #self.m_runningData then
        self.m_runningDataIndex = 1
    else
        self.m_runningDataIndex = self.m_runningDataIndex + 1
    end
    return type
end
-----------------------------------------新滚动相关
--刷新坐标
function RespinNode:updateBaseNodePos()
    if self.m_baseFirstNode then
        self.m_baseFirstNode:setPosition(0,self.m_baseStartPosY+self.m_baseLastDistance-self.m_baseCurDistance)
    end
    if self.m_baseNextNode then
        self.m_baseNextNode:setPosition(0,self.m_baseStartPosY+self.m_baseLastDistance-self.m_baseCurDistance+self.m_slotNodeHeight)
    end
end
--获取小块类型
function RespinNode:getBaseNodeType()
    if self.m_runNodeNum == 0 and self.m_runLastNodeType ~= nil then
        return self.m_runLastNodeType
    else 
        if self.m_runningData == nil then
            return self:randomRuningSymbolType()
        else
            return self:getRunningSymbolTypeByConfig()
        end
    end
end
--获得下一个小块
function RespinNode:getBaseNextNode(nodeType,score)
    local node = nil
    if self.m_runNodeNum == 0 then
        --最后一个小块
        node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex, true)
    else
        node = self.getSlotNodeBySymbolType(nodeType)
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
--创建下一个节点
function RespinNode:baseCreateNextNode()
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
--播放动画
function RespinNode:playCreateSlotsNodeAnima(node)

end

function RespinNode:baseClearNode(node)
    if not tolua.isnull(node) then
        if node:getParent() and self.m_clipNode and node:getParent() == self.m_clipNode then
            node:removeFromParent(false)
            self.pushSlotNodeToPoolBySymobolType(node)  
        end
    end
end
--移除节点
function RespinNode:baseRemoveNode(node)
    if not tolua.isnull(node) then
        if node:getTag() == NODE_TAG then
            node:removeFromParent(false)
            self.pushSlotNodeToPoolBySymobolType(node)  
        end
    end
end
--切换新的节点
function RespinNode:baseChangeNextNode()
    self:baseRemoveNode(self.m_baseFirstNode)
    self.m_baseFirstNode = self.m_baseNextNode
    self:baseCreateNextNode()
end
--开始滚动
function RespinNode:baseStartMove()
    if self:getRespinNodeStatus() == RESPIN_NODE_STATUS.IDLE then
        self:setRespinNodeStatus(RESPIN_NODE_STATUS.RUNNING)
        self:baseCreateNextNode()
        self:onUpdate(handler(self,self.baseUpdateMove))
    end
end
--停止滚动
function RespinNode:baseStopMove()
    if self:getRespinNodeStatus() == RESPIN_NODE_STATUS.RUNNING then
        self:unscheduleUpdate()
    end
end
--刷新滚动
function RespinNode:baseUpdateMove(dt)
    if globalData.slotRunData.gameRunPause then
        return
    end
    self.m_baseCurDistance = self.m_baseCurDistance+ self:getBaseMoveDis(dt)
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
--获得本次移动距离
function RespinNode:getBaseMoveDis(dt)
    local moveDis = self.m_moveSpeed *dt
    if moveDis>self.m_slotNodeHeight then
        moveDis = self.m_slotNodeHeight
    end
    return moveDis
end
--检测是否可以结束滚动
function RespinNode:baseCheckOverMove()
    if self.m_lastNode ~= nil and self.m_runNodeNum <= 0 then
        return true
    end
    return false
end
--结束滚动
function RespinNode:baseOverMove()
    self:baseStopMove()
    self:baseChangeNextNode()
    self.m_baseLastDistance = 0
    self.m_baseCurDistance = 0
    --是否移除上边缘节点
    if self:checkRemoveNextNode() then
        self:baseRemoveNode(self.m_baseNextNode)
        self.m_baseNextNode = nil
    end
    --回弹前的回调
    if  self.m_DownBeforeResCallback ~= nil then
        self.m_DownBeforeResCallback(self.m_lastNode)
    end
    --开始回弹
    local baseResTime = self:runBaseResAction()
    --回调
    if baseResTime>0 then
        performWithDelay(self,handler(self,self.baseOverCallBack),baseResTime)
    else
        self:baseOverCallBack()
    end
end
--重置节点坐标
function RespinNode:baseResetNodePos()
    if self.m_baseFirstNode then
        self.m_baseFirstNode:setPosition(0,self.m_baseStartPosY)
    end
    if self.m_baseNextNode then
        self.m_baseNextNode:setPosition(0,self.m_baseStartPosY+self.m_slotNodeHeight)
    end
end
--结束回调
function RespinNode:baseOverCallBack()
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
--执行回弹动作
function RespinNode:runBaseResAction()
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
--获取回弹动作序列
function RespinNode:getBaseResAction(startPos)
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
------------------------------新滚动相关 END
return RespinNode
local RespinNode = util_require("Levels.RespinNode")
local GeminiJourneyRespinNode = class("GeminiJourneyRespinNode", RespinNode)

local NODE_TAG = 10
local MOVE_SPEED = 1500 --滚动速度 像素/每秒
local RES_DIS = 20
GeminiJourneyRespinNode.REPIN_NODE_TAG = 1000

--子类可以重写修改滚动参数
function GeminiJourneyRespinNode:initUI(rsView)
    self.m_moveSpeed = MOVE_SPEED
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()

    self.m_reelIndex = nil
end

--裁切区域
function GeminiJourneyRespinNode:initClipNode(clipNode,opacity, _reelIndex)
    if not clipNode then
        --   local nodeHeight = self.m_slotReelHeight / self.m_machineRow
          local nodeHeight = 90--self.m_slotReelHeight / self.m_machineRow
          local nodeWidth = 90
          local size = cc.size(nodeWidth, nodeHeight)
          local pos = cc.p(-math.ceil(nodeWidth / 2 ), -nodeHeight / 2)
          self.m_clipNode = util_createOneClipNode(RESPIN_CLIPMODE.RECT,size,pos)
          self:addChild(self.m_clipNode)
          --设置裁切块属性
          local originalPos = cc.p(0,0)
          util_setClipNodeInfo(self.m_clipNode,RESPIN_CLIPTYPE.SINGLE,RESPIN_CLIPMODE.RECT,size,originalPos)
    else
          self.m_clipNode = clipNode
    end
    self:initClipOpacity(opacity, _reelIndex)
end
--裁切遮罩透明度
function GeminiJourneyRespinNode:initClipOpacity(opacity, _reelIndex)
    if false then
        local csbName = "Socre_GeminiJourney_Empty1.csb"
        if _reelIndex == 2 then
            csbName = "Socre_GeminiJourney_Empty2.csb"
        end
        local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
        local spPath = nil --RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
        local colorNode = util_createAnimation(csbName)--util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,opacity,spPath)
        colorNode:runCsbAction("idle", true)

        colorNode:setScale(1.03)
        self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
        colorNode:setName("colorNode")
        -- self.m_clipNode:setVisible(false)
    end
end

--放入light首节点
function GeminiJourneyRespinNode:setLightFirstSlotNode(node)
    GeminiJourneyRespinNode.super.setFirstSlotNode(self,node)
    node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
    node:setTag(self.REPIN_NODE_TAG)
end

function GeminiJourneyRespinNode:setReelIndex(_reelIndex)
    self.m_reelIndex = _reelIndex
end

function GeminiJourneyRespinNode:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_colIndex)
    else
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalFreeSpinRespinCloumnByColumnIndex(self.p_colIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--结束回调
function GeminiJourneyRespinNode:baseOverCallBack()
    self:baseResetNodePos()
    --没有节点默认idle状态
    if not self.m_lastNode or self:getTypeIsEndType(self.m_lastNode.p_symbolType) == false then
        self:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
     else 
        self:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
     end
    if self.m_DownCallback ~= nil then
        self.m_DownCallback(self.m_lastNode,self:getRespinNodeStatus(), self.m_reelIndex)
    end
end

--播放动画
function GeminiJourneyRespinNode:playCreateSlotsNodeAnima(node)
    if self.m_machine:getCurSymbolIsBonus(node.p_symbolType) then
        node:runAnim("idleframe2", false)
    end
end

--获得下一个小块
function GeminiJourneyRespinNode:getBaseNextNode(nodeType,score)
    local node = nil
    if self.m_runNodeNum == 0 then
        --最后一个小块
        node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex, true, self.m_reelIndex)
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
function GeminiJourneyRespinNode:baseCreateNextNode()
    if self.m_isGetNetData == true then
        self.m_runNodeNum = self.m_runNodeNum - 1
    end
    --创建下一个
    local nodeType,score = self:getBaseNodeType()
    if nodeType == self.m_machine.SYMBOL_SCORE_BONUS_2 then
        if self.m_reelIndex and self.m_machine.m_respinUnlockRowTbl[self.m_reelIndex] and self.m_machine.m_respinUnlockRowTbl[self.m_reelIndex] == 5 then
            nodeType = self.m_machine.SYMBOL_SCORE_BONUS_3
        end
    end
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

--设置滚动速度
function GeminiJourneyRespinNode:changeRunSpeed(isQuick)
    if isQuick then
        self:setRunSpeed(MOVE_SPEED * 2)
    else
        self:setRunSpeed(MOVE_SPEED)
    end
end

--设置回弹距离
function GeminiJourneyRespinNode:changeResDis(isQuick)
    if isQuick then
        self.m_resDis = RES_DIS * 3
    else
        self.m_resDis = RES_DIS
    end
end

--执行回弹动作
function GeminiJourneyRespinNode:runBaseResAction()
    self:baseResetNodePos()
    local baseResTime = 0
    --最终停止小块回弹
    if self.m_baseFirstNode then
        local offPos = self.m_baseFirstNode:getPositionY() - self.m_baseStartPosY
        local actionTable, downTime = self:getBaseResAction(0)
        if actionTable and #actionTable > 0 then
            self.m_baseFirstNode:runAction(cc.Sequence:create(actionTable))
        end
        if baseResTime < downTime then
            baseResTime = downTime
        end
    end
    --上边缘小块回弹
    if self.m_baseNextNode then
        if self.m_baseNextNode.p_symbolImage then
            self.m_baseNextNode.p_symbolImage:removeFromParent()
            self.m_baseNextNode.p_symbolImage = nil
        end
        self.m_baseNextNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self, self.m_machine.SYMBOL_SCORE_BONUS_3), self.m_machine.SYMBOL_SCORE_BONUS_3)
        self.m_machine:updateReelGridNode(self.m_baseNextNode, self.m_reelIndex)
        self.m_baseNextNode:setLocalZOrder(SHOW_ZORDER.SHADE_LAYER_ORDER + 1)
        self.m_baseNextNode:runAnim("idleframe2", false)
        local offPos = self.m_baseFirstNode:getPositionY() - self.m_baseStartPosY - self.m_slotNodeHeight
        local actionTable, downTime = self:getBaseResAction(0)
        if actionTable and #actionTable > 0 then
            self.m_baseNextNode:runAction(cc.Sequence:create(actionTable))
        end
        --回弹结束后移除上边缘小块
        if downTime > 0 then
            --检测时长
            if baseResTime < downTime then
                baseResTime = downTime
            end
            performWithDelay(
                self,
                function()
                    self:baseRemoveNode(self.m_baseNextNode)
                    self.m_baseNextNode = nil
                    --快滚状态
                    --     if self.m_moveSpeed == MOVE_SPEED * 2 then
                    --       self.m_machine.m_respinView:removeLightWithoutTimes(self.p_colIndex)
                    --     end
                end,
                downTime
            )
        else
            self:baseRemoveNode(self.m_baseNextNode)
            self.m_baseNextNode = nil
        end
    end
    return baseResTime
end

--获取回弹动作序列
function GeminiJourneyRespinNode:getBaseResAction(startPos)
    local timeDown = 0
    local speedActionTable = {}
    local dis = startPos + self.m_resDis
    local speedStart = self.m_moveSpeed
    local preSpeed = speedStart / 118
    local isStopQucikSound = false
    for i = 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = 0
        --判断是否在快滚状态下
        if self.m_moveSpeed == MOVE_SPEED * 2 then
            isStopQucikSound = true
            moveDis = moveDis + 2
            time = moveDis / speedStart * 8
            timeDown = timeDown + time
        else
            time = moveDis / speedStart
            timeDown = timeDown + time
        end
        local moveBy = cc.MoveBy:create(time, cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end
    local moveBy = cc.MoveBy:create(0.1, cc.p(0, -self.m_resDis))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    if isStopQucikSound then
        speedActionTable[#speedActionTable + 1] = cc.CallFunc:create(function()
            self.m_rsView:stopQucikRunSound()
        end)
    end
    timeDown = timeDown + 0.1
    return speedActionTable, timeDown
end

return GeminiJourneyRespinNode

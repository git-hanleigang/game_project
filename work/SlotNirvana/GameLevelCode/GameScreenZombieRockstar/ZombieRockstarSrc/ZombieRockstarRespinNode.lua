local ZombieRockstarRespinNode = class("ZombieRockstarRespinNode", util_require("Levels.RespinNode"))

local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20
local NODE_TAG = 10

-- 构造函数
function ZombieRockstarRespinNode:ctor()
    ZombieRockstarRespinNode.super.ctor(self)
    self.m_isQuick = false
    self.m_isLastRespin = false
end

function ZombieRockstarRespinNode:initRunningData()
    self.m_runningData = globalData.slotRunData.levelConfigData:getNormalReelDatasByColumnIndex(self.p_colIndex)
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--获取小块类型
function ZombieRockstarRespinNode:getBaseNodeType()
    if self.m_runNodeNum == 0 and self.m_runLastNodeType ~= nil then
        return self.m_runLastNodeType
    else 
        -- 假滚最后一个 强制改成和服务器给的结果一样
        if self.m_runNodeNum == 1 and self.m_runLastNodeType ~= nil and self.m_isReduce then
            return self.m_runLastNodeType
        end

        if globalData.slotRunData.currSpinMode == RESPIN_MODE then
            return self:randomRuningSymbolType()
        else
            if self.m_runningData == nil then
                return self:randomRuningSymbolType()
            else
                local symbolType = self:getRunningSymbolTypeByConfig()
                if self.m_machine.m_isPlayBuffEffect == 3 then
                    if symbolType == 100 and ((self.p_rowIndex == 3 and self.p_colIndex == 1) or (self.p_rowIndex == 1 and self.p_colIndex == 5)) then
                        return math.random(0, 5)
                    end
                    return symbolType
                end
                return symbolType
            end
        end
    end
end

--裁切遮罩透明度
function ZombieRockstarRespinNode:initClipOpacity(opacity)
    
end

---------------------------------快滚相关-------------------------------------------
--设置滚动速度
function ZombieRockstarRespinNode:changeRunSpeed(isQuick, isLastRespin)
    if isQuick then
        self:setRunSpeed(MOVE_SPEED * 2)
    else
        self:setRunSpeed(MOVE_SPEED)
    end

    self.m_isQuick = isQuick
    self.m_isLastRespin = isLastRespin

    self:changeResDis(isQuick, isLastRespin)
end

--设置回弹距离
function ZombieRockstarRespinNode:changeResDis(isQuick, isLastRespin)
    if isQuick then
        if isLastRespin then
            self.m_resDis = RES_DIS * 6
        else
            self.m_resDis = RES_DIS
        end
    else
        self.m_resDis = RES_DIS
    end
end

--获取回弹动作序列
function ZombieRockstarRespinNode:getBaseResAction(startPos)
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
          if self.m_moveSpeed == MOVE_SPEED * 2 and self.m_isLastRespin then
                time = moveDis / speedStart * 12
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
function ZombieRockstarRespinNode:runBaseResAction()
    self:baseResetNodePos()
    local baseResTime = 0
    --最终停止小块回弹
    if self.m_baseFirstNode then
        local offPos = self.m_baseFirstNode:getPositionY()-self.m_baseStartPosY
        local actionTable ,downTime = self:getBaseResAction(0)
        if self.m_isReduce then
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
        self.m_baseNextNode:setLocalZOrder(SHOW_ZORDER.SHADE_LAYER_ORDER + 1)
        local offPos = self.m_baseFirstNode:getPositionY() - self.m_baseStartPosY - self.m_slotNodeHeight
        local actionTable ,downTime = self:getBaseResAction(0)
        if self.m_isReduce then
            actionTable ,downTime = self:getBaseResActionQuick(0)
        end

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
----------------------------------------------------------------------------

--创建下一个节点
function ZombieRockstarRespinNode:baseCreateNextNode()
    if self.m_isGetNetData == true then
        self.m_runNodeNum = self.m_runNodeNum - 1
    end
    if self.m_isQuickStop and not self.m_isGetNetData then
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

--获取网络消息
function ZombieRockstarRespinNode:setLastSymbolType(lastNodeType)
    self.m_runLastNodeType = lastNodeType
end

function ZombieRockstarRespinNode:setNodeReduceSpeed(_isReduce)
    self.m_isReduce = _isReduce
end

--刷新滚动
function ZombieRockstarRespinNode:baseUpdateMove(dt)
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

        if self.m_isReduce then
            local reduceOff = 3
            if self.m_runNodeNum <= 20 then
                self.m_moveSpeed = self.m_moveSpeed - 40*reduceOff
            end
            if self.m_moveSpeed <= 200 then
                self.m_moveSpeed = 200
            end
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
end

--获取回弹动作序列
function ZombieRockstarRespinNode:getBaseResActionQuick(startPos)
    local resDis = 65
    local timeDown = 0
    local speedActionTable = {}
    local dis =  startPos + resDis
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
    local moveBy = cc.MoveBy:create(0.2,cc.p(0, -resDis))
    -- speedActionTable[#speedActionTable + 1] = delayTime
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.2
    return speedActionTable, timeDown
end

return ZombieRockstarRespinNode
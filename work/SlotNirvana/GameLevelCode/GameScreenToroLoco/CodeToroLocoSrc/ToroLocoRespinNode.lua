---
--xcyy
--2018年5月23日
--ToroLocoRespinNode.lua

local ToroLocoRespinNode = class("ToroLocoRespinNode",util_require("Levels.RespinNode"))

local NODE_TAG = 10
local MOVE_SPEED = 2000     --滚动速度 像素/每秒
local RES_DIS = 20
ToroLocoRespinNode.SYMBOL_EMPTY = 100
ToroLocoRespinNode.SYMBOL_BONUS = 94

-- 构造函数
function ToroLocoRespinNode:ctor()
    ToroLocoRespinNode.super.ctor(self)
    self.m_isQuick = false
    self.m_isLastRespin = false
end

--裁切遮罩透明度
function ToroLocoRespinNode:initClipOpacity(opacity)

end

---------------------------------快滚相关-------------------------------------------
--设置滚动速度
function ToroLocoRespinNode:changeRunSpeed(isQuick, isLastRespin)
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
function ToroLocoRespinNode:changeResDis(isQuick, isLastRespin)
    if isQuick then
        if isLastRespin then
            self.m_resDis = RES_DIS * 3
        else
            self.m_resDis = RES_DIS
        end
    else
        self.m_resDis = RES_DIS
    end
end

--获取回弹动作序列
function ToroLocoRespinNode:getBaseResAction(startPos)
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
function ToroLocoRespinNode:runBaseResAction()
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
        if self.m_isQuick and self.m_isLastRespin then
            if self.m_baseNextNode.p_symbolImage then
                self.m_baseNextNode.p_symbolImage:removeFromParent()
                self.m_baseNextNode.p_symbolImage = nil
            end

            local symbolType = self.SYMBOL_BONUS
            if self.m_baseNextNode.p_symbolType == self.SYMBOL_EMPTY then
                self.m_machine:changeSymbolType(self.m_baseNextNode, symbolType, true)
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
----------------------------------------------------------------------------

--获取随机信号
function ToroLocoRespinNode:randomRuningSymbolType()
    local nodeType = nil
    local random = math.random(1,100)
    if random <= 23 then
        nodeType = self.SYMBOL_BONUS
    else
        nodeType = self.SYMBOL_EMPTY
    end
    return nodeType
end

return ToroLocoRespinNode
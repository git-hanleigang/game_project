

local GoldieGrizzliesRespinNode = class("GoldieGrizzliesRespinNode", util_require("Levels.RespinNode"))

local MOVE_SPEED = 2000     --滚动速度 像素/每秒
local RES_DIS = 20

-- 构造函数
function GoldieGrizzliesRespinNode:ctor()
    GoldieGrizzliesRespinNode.super.ctor(self)
    self.m_isQuick = false
end

--子类可以重写修改滚动参数
function GoldieGrizzliesRespinNode:initUI(rsView)
    GoldieGrizzliesRespinNode.super.initUI(self,rsView)
    
end

--裁切遮罩透明度
function GoldieGrizzliesRespinNode:initClipOpacity(opacity)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.respinType then
        local bgNode = util_createAnimation("GoldieGrizzlies_respindi.csb")
        bgNode:findChild("respindi_blue"):setVisible(selfData.respinType == self.m_machine.SYMBOL_BONUS_2)
        bgNode:findChild("respindi_green"):setVisible(selfData.respinType == self.m_machine.SYMBOL_BONUS_3)
        bgNode:findChild("respindi_red"):setVisible(selfData.respinType == self.m_machine.SYMBOL_BONUS_1)
        self.m_clipNode:addChild(bgNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
        -- bgNode:setScale(0.95)
    end
end

---------------------------------快滚相关-------------------------------------------
--设置滚动速度
function GoldieGrizzliesRespinNode:changeRunSpeed(isQuick)
    if isQuick then
        self:setRunSpeed(MOVE_SPEED * 2)
    else
        self:setRunSpeed(MOVE_SPEED)
    end

    self.m_isQuick = isQuick

    self:changeResDis(isQuick)
end

--设置回弹距离
function GoldieGrizzliesRespinNode:changeResDis(isQuick)
    if isQuick then
          self.m_resDis = RES_DIS * 3
    else
          self.m_resDis = RES_DIS
    end
end

--获取回弹动作序列
function GoldieGrizzliesRespinNode:getBaseResAction(startPos)
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
function GoldieGrizzliesRespinNode:runBaseResAction()
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
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local symbolType = self.m_machine.SYMBOL_BONUS_3
            if selfData and selfData.respinType then
                symbolType = selfData.respinType
            end
            if self.m_baseNextNode.p_symbolType ~= symbolType then
                self.m_baseNextNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,symbolType), symbolType)
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

return GoldieGrizzliesRespinNode
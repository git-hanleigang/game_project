local MagicSpiritNode = class("MagicSpiritNode", util_require("Levels.RespinNode"))

local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20          --回弹

local BASE_RUN_NUM = 20     --滚动参数 滚动数量
local BASE_COL_INTERVAL = 3 --滚动参数 列间隔递增

--子类继承修改节点显示内容
function MagicSpiritNode:changeNodeDisplay(node)

    local isInRandomTypeList = false
    for i=1,#self.m_symbolRandomType do
        local randomType = self.m_symbolRandomType[i]
        if node.p_symbolType == randomType then
            isInRandomTypeList = true
            break 
        end
    end
    
    if not isInRandomTypeList then
        -- self.SYMBOL_RS_SCORE_BLANK 是默认respin滚动的图标
        self:hideNodeShow(node)
    end

    if self:getTypeIsEndType(node.p_symbolType ) == false then
        if node.p_symbolType and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)   
        else
            node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
        end
        
    else
        node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
    end
end

function MagicSpiritNode:hideNodeShow(symbol_node)
    if(not symbol_node)then
        return
    end

    self.m_machine:removeBaseReelMulLab(symbol_node )
    local blankType = self.m_machine.SYMBOL_RS_SCORE_BLANK
    local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
    symbol_node:changeCCBByName(ccbName, blankType)
    symbol_node:changeSymbolImageByName( ccbName )
end



--设置滚动速度
function MagicSpiritNode:changeRunSpeed(isQuick)
    if isQuick then
        local quickSpeed = self:getQuickRunSpeed()
        self:setRunSpeed(quickSpeed)
    else
        self:setRunSpeed(MOVE_SPEED)
    end
end
--快滚时间修改为指定时间
function MagicSpiritNode:getQuickRunSpeed()
    local runLong = BASE_RUN_NUM + (self.p_colIndex- 1) * BASE_COL_INTERVAL
    local runTime = 1
    return runLong * self.m_slotNodeHeight / runTime
end
--是否为快滚
function MagicSpiritNode:isQuickRun()
    return self.m_moveSpeed == self:getQuickRunSpeed()
end
--设置回弹距离
function MagicSpiritNode:changeResDis(isQuick)
    if isQuick then
          self.m_resDis = RES_DIS * 3
    else
          self.m_resDis = RES_DIS
    end
end

--执行回弹动作
function MagicSpiritNode:runBaseResAction()
    self:baseResetNodePos()
    local baseResTime = 0
    --最终停止小块回弹
    if self.m_baseFirstNode then
          local offPos = self.m_baseFirstNode:getPositionY()-self.m_baseStartPosY
          local actionTable ,downTime = self:getBaseResAction(0, self.m_baseFirstNode)
          if actionTable and #actionTable>0 then
              self.m_baseFirstNode:runAction(cc.Sequence:create(actionTable))
          end
          if baseResTime<downTime then
              baseResTime = downTime
          end
    end
    --上边缘小块回弹
    if self.m_baseNextNode then
          if self.m_baseNextNode.p_symbolImage then
                self.m_baseNextNode.p_symbolImage:removeFromParent()
                self.m_baseNextNode.p_symbolImage = nil
          end
          local randomList = {
            self.m_machine.SYMBOL_CLASSIC1,
            self.m_machine.SYMBOL_CLASSIC2,
            self.m_machine.SYMBOL_CLASSIC3
          }
          local symbolType = randomList[math.random(1, #randomList)]
          self.m_baseNextNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self, symbolType), symbolType)
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

--获取回弹动作序列
function MagicSpiritNode:getBaseResAction(startPos, symbolNode)
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
          if self:isQuickRun() then
                time = moveDis / speedStart * 8
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


return MagicSpiritNode

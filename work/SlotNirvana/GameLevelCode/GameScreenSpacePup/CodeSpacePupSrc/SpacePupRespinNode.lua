
local RespinNode = util_require("Levels.RespinNode")
local SpacePupRespinNode = class("SpacePupRespinNode",RespinNode)

local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20

--裁切遮罩透明度
function SpacePupRespinNode:initClipOpacity(opacity)
      if opacity and opacity>0 then

            local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
            local spPath = nil --RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
            self.m_colorNode = util_createAnimation("SpacePup_respindange.csb")--util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,opacity,spPath)

            self.m_colorNode:runCsbAction("idleframe")
            self.m_colorNode:setScale(1.03)
            self.m_clipNode:addChild(self.m_colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
            self.m_clipNode:setVisible(false)
      end
end

--设置滚动速度
function SpacePupRespinNode:changeRunSpeed(isQuick)
      if isQuick then
            self:setRunSpeed(MOVE_SPEED * 2)
      else
            self:setRunSpeed(MOVE_SPEED)
      end
end

--设置回弹距离
function SpacePupRespinNode:changeResDis(isQuick)
      if isQuick then
            self.m_resDis = RES_DIS * 3
      else
            self.m_resDis = RES_DIS
      end
end

--执行回弹动作
function SpacePupRespinNode:runBaseResAction()
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
            if self.m_baseNextNode.p_symbolImage then
                  self.m_baseNextNode.p_symbolImage:removeFromParent()
                  self.m_baseNextNode.p_symbolImage = nil
            end
            self.m_baseNextNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self,self.m_machine.SYMBOL_SCORE_BONUS), self.m_machine.SYMBOL_SCORE_BONUS)
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
                      --快滚状态
                  --     if self.m_moveSpeed == MOVE_SPEED * 2 then
                  --       self.m_machine.m_respinView:removeLightWithoutTimes(self.p_colIndex)
                  --     end
                  end,downTime)
            else
                  self:baseRemoveNode(self.m_baseNextNode)
                  self.m_baseNextNode = nil
            end
      end
      return baseResTime
end

--获取回弹动作序列
function SpacePupRespinNode:getBaseResAction(startPos)
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
                  moveDis = moveDis + 2
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

return SpacePupRespinNode
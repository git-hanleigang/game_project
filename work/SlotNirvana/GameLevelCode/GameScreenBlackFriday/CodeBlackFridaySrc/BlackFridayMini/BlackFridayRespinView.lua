

local BlackFridayRespinView = class("BlackFridayRespinView", 
                                    util_require("Levels.RespinView"))


local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}
-- 

function BlackFridayRespinView:initUI(respinNodeName)
      BlackFridayRespinView.super.initUI(self,respinNodeName)
      --是否停轮
      self.m_isRepinDown = false
end

function BlackFridayRespinView:runNodeEnd(endNode)

      if endNode then
            local info = self:getEndTypeInfo(endNode.p_symbolType)
            if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
                  if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS3 then
                        -- 滚动出来 bonus3之后 暂时添加到列表 存起来 飞的时候 用
                        self.m_machine.m_machine:addBonus3List(endNode, self.m_machine.m_machineIndex)
                        if self.curColPlaySound and not self.m_isQuicklyRun then
                              gLobalSoundManager:playSound(self.m_machine.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_bonus3Buling)
                              self.curColPlaySound = nil
                        end
                  end
                  if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS2 then
                        if self.curColPlaySound and not self.m_isQuicklyRun then
                              gLobalSoundManager:playSound(self.m_machine.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_bonus2Buling)
                              self.curColPlaySound = nil
                        end
                  end

                  if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS1 then
                        -- bonus1上面的 动画
                        self.m_machine.m_machine:playBonus1CoinsEffect(endNode, "buling", "idleframe2")
                        if self.curColPlaySound and not self.m_isQuicklyRun then
                              gLobalSoundManager:playSound(self.m_machine.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_bonus1Buling)
                              self.curColPlaySound = nil
                        end

                        if self.m_isQuicklyRun and self.m_isPLayBonus1Sound then
                              gLobalSoundManager:playSound(self.m_machine.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_bonus1Buling)
                              self.m_isPLayBonus1Sound = nil
                        end
                  end

                  endNode:runAnim(info.runEndAnimaName, false,function() 
                        if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS3 then
                              local child = endNode:getCcbProperty("spine"):getChildren()
                              local symbol_node = endNode:checkLoadCCbNode()
                              local spineNode = symbol_node:getCsbAct()
                              for spineIndex = 1, #child do
                                    util_spinePlay(child[spineIndex],"fly2",true)
                              end
                        end
                        if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS2 then
                              local symbol_node = endNode:checkLoadCCbNode()
                              local spineNode = symbol_node:getCsbAct()
                              endNode:runAnim("idleframe_jackpot3",true)
                        end
                  end)
                  
            end

            self:removeLight(endNode)
      end
end

function BlackFridayRespinView:oneReelDown(_Col)
      if self.m_isQuicklyRun then
            return
      end
      self.curColPlaySound = _Col
      
      if self.m_machine.m_machineIndex == 1 then
            gLobalSoundManager:playSound("BlackFridaySounds/sound_BlackFriday_reel_down.mp3")
      end
      --第一个小棋盘集满
      if self.m_machine.m_machineIndex == 2 then
            local isPLay1 = self:getColIsHaveBonus(1, _Col)
            local isPLay2 = self:getColIsHaveBonus(2, _Col)
            if isPLay1 and isPLay2 then
                  gLobalSoundManager:playSound("BlackFridaySounds/sound_BlackFriday_reel_down.mp3")
            end
      end

      --第一个第二个都集满
      if self.m_machine.m_machineIndex == 3 then
            local isPLay1 = self:getColIsHaveBonus(1, _Col)
            local isPLay2 = self:getColIsHaveBonus(2, _Col)
            local isPLay3 = self:getColIsHaveBonus(3, _Col)
            if isPLay1 and isPLay2 and isPLay3 then
                  gLobalSoundManager:playSound("BlackFridaySounds/sound_BlackFriday_reel_down.mp3")
            end
      end
end

-- 查找当前列 是否集满了
-- 3个小棋盘 列停止音效只播放一次
function BlackFridayRespinView:getColIsHaveBonus(_miniIndex, _col)
      local miniMachine = self.m_machine.m_machine.m_miniMachine[_miniIndex]
      local storedIcons = miniMachine.m_runSpinResultData.p_storedIcons
      local num = 0
      for row=1,3 do
            if miniMachine["banzi"..row] and not miniMachine["banzi"..row]:isVisible() then
                  local posIndex = self.m_machine.m_machine:getPosReelIdx(row, _col)
                  for i,vInfo in ipairs(storedIcons) do
                        if posIndex == vInfo[1] then
                              num = num + 1
                        end
                  end
            end
      end
      if num >= 3 then
            return true
      else
            return false
      end
end

---获取所有参与结算节点
function BlackFridayRespinView:getAllCleaningNode()
      --从 从上到下 左到右排序
      local cleaningNodes = {}
      local childs = self:getChildren()

      for i=1,#childs do
            local node = childs[i]
            if node:getTag() == self.REPIN_NODE_TAG  and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
                  cleaningNodes[#cleaningNodes + 1] =  node
            end
      end


      --排序
      local sortNode = {}
      for iCol = 1 , self.m_machineColmn do
            
            local sameRowNode = {}
            for i = 1, #cleaningNodes do
                  local  node = cleaningNodes[i]
                  if node.p_cloumnIndex == iCol then
                        sameRowNode[#sameRowNode + 1] = node
                  end   
            end 
            table.sort( sameRowNode, function(a, b)
                  return b.p_rowIndex  <  a.p_rowIndex
            end)

            for i=1,#sameRowNode do
                  sortNode[#sortNode + 1] = sameRowNode[i]
            end
      end
      cleaningNodes = sortNode
      return cleaningNodes
end

--repsinNode滚动完毕后 置换层级
function BlackFridayRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            endNode:removeFromParent()
            self:addChild(endNode , REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex, self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)
      if self.m_respinNodeStopCount == self.m_respinNodeRunCount then
            self.m_isRepinDown = true
            self.m_machine:reSpinReelDown()
      end
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function BlackFridayRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
      self.m_machineElementData = machineElement
      for i=1,#machineElement do
            local nodeInfo = machineElement[i]
            local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

            local pos = self:convertToNodeSpace(nodeInfo.Pos)
            machineNode:setPosition(pos)
            self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
            machineNode:setVisible(nodeInfo.isVisible)
            if nodeInfo.isVisible then
                  -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end
            if nodeInfo.Type == self.m_machine.SYMBOL_BONUS1 then
                  self.m_machine.m_machine:playBonus1CoinsEffect(machineNode, "idleframe", "idleframe2")
            end
            if nodeInfo.Type == self.m_machine.SYMBOL_BONUS2 then
                  machineNode:runAnim("idleframe_jackpot2",true)
            end
            if nodeInfo.Type == self.m_machine.SYMBOL_BONUS3 then
                  machineNode:runAnim("idle2",true)
            end

            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end

      self:readyMove()
end

  --[[
      快滚特效
]]
function BlackFridayRespinView:runQuickEffect()
      if not self.m_qucikRespinNode then
            self.m_qucikRespinNode = {}
      else
            if #self.m_qucikRespinNode >= 1 then
                  return
            end
      end

      for j=1,#self.m_respinNodes do
          local repsinNode = self.m_respinNodes[j]
          --bonus数量
          local bonus_count = 0
          if self.m_machine.m_runSpinResultData.p_storedIcons then
              bonus_count = #self.m_machine.m_runSpinResultData.p_storedIcons
          end

          if bonus_count >= 14 then
              --存储快滚的小块
            if repsinNode.m_runLastNodeType == self.m_machine.SYMBOL_SCORE_BLANK then
                  self.m_qucikRespinNode[#self.m_qucikRespinNode + 1] = {
                        key = self.m_machine:getNodeTag(repsinNode.p_colIndex,repsinNode.p_rowIndex,SYMBOL_NODE_TAG),
                        node = repsinNode
                  }
            end
          end
      end

      self.m_machine.m_lightEffectNode:removeAllChildren(true)
      self.m_single_lights = {}
      for index=1, #self.m_qucikRespinNode do
            local quickRunInfo = self.m_qucikRespinNode[index]
            if not quickRunInfo.isEnd then
                  local light_effect = util_createAnimation("BlackFriday_respin_run.csb")
                  light_effect:runCsbAction("actionframe",true)  --普通滚动状态
                  self.m_machine.m_lightEffectNode:addChild(light_effect)
                  self.m_single_lights[quickRunInfo.key] = light_effect
                  light_effect:setPosition(util_convertToNodeSpace(quickRunInfo.node,self.m_machine.m_lightEffectNode))
            end
      end
end

  --[[
    移除快滚框
]]
function BlackFridayRespinView:removeLight(respinNode)
      if not self.m_qucikRespinNode then
            return
      end

      local nodeTag = self.m_machine:getNodeTag(respinNode.p_cloumnIndex,respinNode.p_rowIndex,SYMBOL_NODE_TAG)

      for index=1,#self.m_qucikRespinNode do
          local quickRunInfo = self.m_qucikRespinNode[index]
          if quickRunInfo.key == nodeTag and respinNode.p_symbolType ~= self.m_machine.SYMBOL_SCORE_BLANK then
              if self.m_single_lights[nodeTag] then
                  self.m_single_lights[nodeTag]:removeFromParent(true)
                  self.m_single_lights[nodeTag] = nil
                  self.m_qucikRespinNode = nil
                  break
              end
          end
      end
      
end

function BlackFridayRespinView:quicklyStop()
      self.m_isQuicklyRun = true
      self.m_isPLayBonus1Sound = true
      BlackFridayRespinView.super.quicklyStop(self)

      gLobalSoundManager:playSound("BlackFridaySounds/sound_BlackFriday_reel_down_quick.mp3")

end

--组织滚动信息 开始滚动
function BlackFridayRespinView:startMove()
      self.m_isQuicklyRun = false

      self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
      self.m_respinNodeRunCount = 0
      self.m_respinNodeStopCount = 0

      local isRun = false
      for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  isRun = true
                  
                  self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                  self.m_respinNodes[i]:startMove()
            end
      end

      if isRun then
            self.m_isRepinDown = false
      else
            self.m_isRepinDown = true
      end
end

return BlackFridayRespinView
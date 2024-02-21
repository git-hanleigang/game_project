

local SpookySnacksRespinView = class("SpookySnacksRespinView", 
                                    util_require("Levels.RespinView"))
local PublicConfig = require "SpookySnacksPublicConfig"
local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

SpookySnacksRespinView.m_quickRunSound = nil
-- 

function SpookySnacksRespinView:initUI(respinNodeName)
      SpookySnacksRespinView.super.initUI(self,respinNodeName)
      --是否停轮
      self.m_isRepinDown = false
      self.m_isQuicklyRun = false
      -- self.m_quickBuling = true

      
end

function SpookySnacksRespinView:createRespinNode(symbolNode, status)

      local respinNode = util_createView(self.m_respinNodeName)
      respinNode:setMachine(self.m_machine)
      respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
      respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
      respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
      respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)
      
      respinNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
      respinNode:setReelDownCallBack(function(symbolType, status)
        if self.respinNodeEndCallBack ~= nil then
              self:respinNodeEndCallBack(symbolType, status)
        end
      end, function(symbolType)
        if self.respinNodeEndBeforeResCallBack ~= nil then
              self:respinNodeEndBeforeResCallBack(symbolType)
        end
      end)
  
      self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)
      
      respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),130)
      respinNode.p_rowIndex = symbolNode.p_rowIndex
      respinNode.p_colIndex = symbolNode.p_cloumnIndex
      respinNode:initConfigData()
      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
            util_changeNodeParent(self,symbolNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + symbolNode.p_cloumnIndex * 10 - symbolNode.p_rowIndex)
            symbolNode:setTag(self.REPIN_NODE_TAG)
      else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
  end

function SpookySnacksRespinView:runNodeEnd(endNode)

      if endNode then
            local info = self:getEndTypeInfo(endNode.p_symbolType)
            if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
                  if endNode.p_symbolType == self.m_machine.SYMBOL_BONUS3 then
                        -- 滚动出来 bonus3之后 暂时添加到列表 存起来 飞的时候 用
                        self.m_machine.m_machine:addBonus3List(endNode, self.m_machine.m_machineIndex)
                  end

                  --快停时
                  if self.m_isQuicklyRun then
                        if self.m_machine.m_machine.m_quickBuling then
                              local type = self.m_machine.m_machine:changeReelsOtherSymbolType()
                              local soundName = self:getBulindSoundForType(type)
                              gLobalSoundManager:playSound(soundName)
                              self.m_machine.m_machine.m_quickBuling = false
                        end 
                  else
                        if self.m_machine.m_machine.m_vecExpressSound[endNode.p_cloumnIndex] == false then
                              local type = self.m_machine.m_machine:changeReelsOtherSymbolType2(endNode.p_cloumnIndex)
                              local soundName = self:getBulindSoundForType(type)
                              gLobalSoundManager:playSound(soundName)
                              self.m_machine.m_machine.m_vecExpressSound[endNode.p_cloumnIndex] = true
                        end
                        
                  end
                  

                  self:isShowShake(endNode)
                  endNode:runAnim(info.runEndAnimaName, false,function() 
                        local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
                        local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                        util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + endNode.p_cloumnIndex * 10 - endNode.p_rowIndex)
                        endNode:setTag(self.REPIN_NODE_TAG)
                        endNode:setPosition(pos)
                        endNode:runAnim("idleframe2",true)     
                  end)
                  
            end

            self:removeLight(endNode)
      end
end


function SpookySnacksRespinView:getBulindSoundForType(type)
      if type == self.m_machine.SYMBOL_BONUS1 then
            return PublicConfig.SoundConfig.sound_SpookySnacks_bonus1_buling
      elseif type == self.m_machine.SYMBOL_BONUS2 then
            return PublicConfig.SoundConfig.sound_SpookySnacks_bonus2_buling
      elseif type == self.m_machine.SYMBOL_BONUS3 then
            return PublicConfig.SoundConfig.sound_SpookySnacks_bonus3_buling
      end
end


function SpookySnacksRespinView:oneReelDown(_Col)
      if self.m_isQuicklyRun then
            return
      end
      if self.m_machine.m_machine.m_respinReelStopSound[_Col] == false then
            gLobalSoundManager:playSound("SpookySnacksSounds/sound_SpookySnacks_reel_stop.mp3")
            self.m_machine.m_machine.m_respinReelStopSound[_Col] = true
      end
      
end

-- 查找当前列 是否集满了
-- 3个小棋盘 列停止音效只播放一次
function SpookySnacksRespinView:getColIsHaveBonus(_miniIndex, _col)
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
function SpookySnacksRespinView:getAllCleaningNode()
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
function SpookySnacksRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1
      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self.m_machine:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self.m_machine,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + endNode.p_cloumnIndex * 10 - endNode.p_rowIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
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
function SpookySnacksRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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
            if nodeInfo.Type == self.m_machine.SYMBOL_BONUS1 then
                machineNode:runAnim("idleframe2",true)
            end
            if nodeInfo.Type == self.m_machine.SYMBOL_BONUS2 then
                  machineNode:runAnim("idleframe2",true)
            end
            if nodeInfo.Type == self.m_machine.SYMBOL_BONUS3 then
                  machineNode:runAnim("idleframe2",true)
            end

            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end

      self:readyMove()
end



  --[[
      快滚特效
]]
function SpookySnacksRespinView:runQuickEffect()
      
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
                  local light_effect = util_createAnimation("SpookySnacks_Respin_run.csb")
                  
                        
                  self.m_machine.m_lightEffectNode:addChild(light_effect)
                  gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respin_quick_show)
                  light_effect:runCsbAction("start",false,function ()
                        light_effect:runCsbAction("run1",true)  --普通滚动状态
                  end)
                  self.m_single_lights[quickRunInfo.key] = light_effect
                  light_effect:setPosition(util_convertToNodeSpace(quickRunInfo.node,self.m_machine.m_lightEffectNode))
            end
      end
end

  --[[
    移除快滚框
]]
function SpookySnacksRespinView:removeLight(respinNode)
      if not self.m_qucikRespinNode then
            return
      end
      if self.m_quickRunSound then
            gLobalSoundManager:stopAudio(self.m_quickRunSound)
            self.m_quickRunSound = nil
      end
      local nodeTag = self.m_machine:getNodeTag(respinNode.p_cloumnIndex,respinNode.p_rowIndex,SYMBOL_NODE_TAG)

      for index=1,#self.m_qucikRespinNode do
          local quickRunInfo = self.m_qucikRespinNode[index]
            if quickRunInfo.key == nodeTag and respinNode.p_symbolType ~= self.m_machine.SYMBOL_SCORE_BLANK then
                  if self.m_single_lights[nodeTag] then
                        if self.m_quickRunSound then
                              gLobalSoundManager:stopAudio(self.m_quickRunSound)
                              self.m_quickRunSound = nil
                        end
                        self.m_single_lights[nodeTag]:removeFromParent(true)
                        self.m_single_lights[nodeTag] = nil
                        self.m_qucikRespinNode = nil
                        break
                  end
            elseif quickRunInfo.key == nodeTag and respinNode.p_symbolType == self.m_machine.SYMBOL_SCORE_BLANK then
                  if self.m_single_lights[nodeTag] then
                        if self.m_quickRunSound then
                              gLobalSoundManager:stopAudio(self.m_quickRunSound)
                              self.m_quickRunSound = nil
                        end
                        self.m_single_lights[nodeTag]:runCsbAction("run1",true)  --普通滚动状态
                  end
            end
      end
      
end

function SpookySnacksRespinView:changeLightingAct()
      if not self.m_qucikRespinNode then
            return
      end

      for index=1,#self.m_qucikRespinNode do
          local quickRunInfo = self.m_qucikRespinNode[index]
            if quickRunInfo.key then
                  if self.m_single_lights[quickRunInfo.key] then
                        self.m_quickRunSound = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respin_quick_run)
                        self.m_single_lights[quickRunInfo.key]:runCsbAction("run",true)
                  end
            end
      end
end

function SpookySnacksRespinView:isShowShake(respinNode)

      local function newShakeAnimation(_shakeNode,_sx,_sy,_time,func)
            local changePosY = _sx
            local changePosX = _sy
            local actionList = {}
            local oldPos = cc.p(_shakeNode:getPosition())
            local count = _time * 10/2
            for i = 1, count do
                  actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
                  actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
                  actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x - changePosX, oldPos.y + changePosY))
                  actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
                  actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x + changePosX, oldPos.y + changePosY))
                  actionList[#actionList + 1] = cc.MoveTo:create(1 / 30, cc.p(oldPos.x, oldPos.y))
            end
            actionList[#actionList + 1] = cc.CallFunc:create(function ()
                  if func then
                        func()
                  end
              end)
            local seq = cc.Sequence:create(actionList)
            _shakeNode:runAction(seq)
      end
      
      if not self.m_qucikRespinNode then
            return
      end

      local nodeTag = self.m_machine:getNodeTag(respinNode.p_cloumnIndex,respinNode.p_rowIndex,SYMBOL_NODE_TAG)

      for index=1,#self.m_qucikRespinNode do
          local quickRunInfo = self.m_qucikRespinNode[index]
          if quickRunInfo.key == nodeTag and respinNode.p_symbolType ~= self.m_machine.SYMBOL_SCORE_BLANK then
              if self.m_single_lights[nodeTag] then
                  if not self.m_machine.m_machine.isShakeForRespin then
                        self.m_machine.m_machine.isShakeForRespin = true
                        --棋盘震动
                        newShakeAnimation(self.m_machine.m_machine:findChild("root"),7,7,1,function ()
                              self.m_machine.m_machine.isShakeForRespin = false
                        end)

                        return
                  end
                  
                  
              end
          end
      end
end

function SpookySnacksRespinView:quicklyStop()
      self.m_isQuicklyRun = true
      SpookySnacksRespinView.super.quicklyStop(self)

      gLobalSoundManager:playSound("SpookySnacksSounds/sound_SpookySnacks_reel_stop_quick.mp3")

end

--组织滚动信息 开始滚动
function SpookySnacksRespinView:startMove()
      
      self.m_isQuicklyRun = false
      

      self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
      self.m_respinNodeRunCount = 0
      self.m_respinNodeStopCount = 0

      local isRun = false
      self:changeLightingAct()
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

function SpookySnacksRespinView:changeActNodeZOrder(symbolNode,isChange)
      if isChange then
            symbolNode:setLocalZOrder(10000)
      else
            symbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + symbolNode.p_cloumnIndex * 10 - symbolNode.p_rowIndex)
      end
end

return SpookySnacksRespinView
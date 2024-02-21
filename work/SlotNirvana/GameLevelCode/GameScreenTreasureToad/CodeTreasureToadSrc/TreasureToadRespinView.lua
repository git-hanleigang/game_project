

local TreasureToadRespinView = class("TreasureToadRespinView", 
                                    util_require("Levels.RespinView"))
local PublicConfig = require "TreasureToadPublicConfig"
TreasureToadRespinView.SYMBOL_FIX_SYMBOL = 94
TreasureToadRespinView.SYMBOL_FIX_SYMBOL1 = 95
TreasureToadRespinView.SYMBOL_FIX_SYMBOL2 = 96
TreasureToadRespinView.m_vecExpressSound = {false, false, false, false, false}


local BASE_COL_INTERVAL = 3
--滚动参数
local BASE_RUN_NUM = 20

local TOP_ZORDER = 10000

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

function TreasureToadRespinView:initUI(respinNodeName)
      self.m_respinNodeName = respinNodeName 
      self.m_baseRunNum = BASE_RUN_NUM

      self.scaleBigIndex = 0        --中间放大系数
      self.middle_num = 0           --中间滚动长度
      self.isQuickStop = false
      self.isOnceQuickStop = false

      self.isScale = false
      self.btestChangeBigSound = nil
end

--三个特效框分别为：发散框、idle框、放大框
function TreasureToadRespinView:createMiddleKuang()
      if self.m_machine:checkTreasureToadABTest() then           --ABtest
            self.middleKuang = util_createAnimation("TreasureToad_Respin_zhongjian_gezi_0.csb")         --固定框
            self.kuangLight1 = util_createAnimation("TreasureToad_Respin_zhongjian_gezi_1.csb")       --发散idle框
            
      else
            self.middleKuang = util_createAnimation("TreasureToad_Respin_zhongjian_gezi.csb")         --固定框
            self.kuangLight1 = util_createAnimation("TreasureToad_Respin_zhongjian_gezi_4.csb")       --常驻idle框
      end
      self.kuangLight2 = util_createAnimation("TreasureToad_Respin_zhongjian_gezi_2.csb")       --常驻idle框
      
      self.kuangLight3 = util_createAnimation("TreasureToad_Respin_zhongjian_gezi_3.csb")       --放大idle框
      local respinNode = self:getRespinNode(2,3)
      local pos = util_convertToNodeSpace(respinNode,self)
      self.middleKuang:setPosition(pos)
      self:addChild(self.middleKuang,TOP_ZORDER + 100)
      self.middleKuang:findChild("tx1"):addChild(self.kuangLight1)
      self.kuangLight1:setVisible(false)
      self.middleKuang:findChild("tx2"):addChild(self.kuangLight2)
      self.kuangLight2:setVisible(false)
      self.middleKuang:findChild("tx3"):addChild(self.kuangLight3)
      self.kuangLight3:setVisible(false)
      self.middleKuang:runCsbAction("idle",true)
      if self.m_machine:checkTreasureToadABTest() then           --ABtest
            self.kuangLight2:setVisible(true)
            self.kuangLight2:runCsbAction("idle",true)
            
      else
            self:changeLightingBeforeForIndex(1)
      end
      

end

function TreasureToadRespinView:createRespinLine()
      self.respinLine = util_createAnimation("TreasureToad_Respin_Xian.csb")         --线
      local pos = util_convertToNodeSpace(self.m_machine:findChild("lineNode"),self)
      self:addChild(self.respinLine,VIEW_ZORDER.NORMAL + 10)
      self.respinLine:setPosition(pos)
end

function TreasureToadRespinView:createRespinNode(symbolNode, status)

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
      
      respinNode:initClipNode(nil,130)
      respinNode.p_rowIndex = symbolNode.p_rowIndex
      respinNode.p_colIndex = symbolNode.p_cloumnIndex
      respinNode:initConfigData()
      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
            respinNode.m_baseFirstNode = symbolNode
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)

            util_changeNodeParent(self,symbolNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 + symbolNode.p_cloumnIndex * 10 - symbolNode.p_rowIndex)
            symbolNode:setTag(self.REPIN_NODE_TAG)
      else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      if self:isFixSymbol(symbolNode.p_symbolType) then
            local idleName = self:getIdleframeName(symbolNode.p_symbolType)
            symbolNode:runAnim(idleName,true)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
      if respinNode.p_rowIndex == 2 and respinNode.p_colIndex == 3 then
            respinNode:setLocalZOrder(TOP_ZORDER)
            if self.m_machine:checkTreasureToadABTest() then      --ABtest
                  respinNode:setIsABTest(false)
            else
                  respinNode:setIsABTest(true)
            end
      end
      
  end

function TreasureToadRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
      for j=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[j]
            local bFix = false 
            local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
            if repsinNode.p_colIndex == 3 and repsinNode.p_rowIndex == 2 then
                  runLong = self.middle_num
            end
            for i=1, #storedNodeInfo do
                  local stored = storedNodeInfo[i]
                  if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                        repsinNode:setRunInfo(runLong, stored.type)
                        bFix = true
                  end
            end
            
            for i=1,#unStoredReels do
                  local data = unStoredReels[i]
                  if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                        repsinNode:setRunInfo(runLong, data.type)
                  end
            end
      end
end

function TreasureToadRespinView:oneReelDown()
      if not self.isQuickStop then
            gLobalSoundManager:playSound("TreasureToadSounds/sound_TreasureToad_reel_down.mp3")
      end
      
end

function TreasureToadRespinView:quicklyStop()
      self.isQuickStop = true
      self.isOnceQuickStop = true
      TreasureToadRespinView.super.quicklyStop(self)
      gLobalSoundManager:playSound("TreasureToadSounds/sound_TreasureToad_reel_down_quick.mp3")
end

---获取所有参与结算节点
function TreasureToadRespinView:getAllCleaningNode()
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

--组织滚动信息 开始滚动
function TreasureToadRespinView:startMove()
      self.m_vecExpressSound = {false, false, false, false, false}
      self.isQuickStop = false
      self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
      self.m_respinNodeRunCount = 0
      self.m_respinNodeStopCount = 0
      if self.btestChangeBigSound then
            gLobalSoundManager:stopAudio(self.btestChangeBigSound)
            self.btestChangeBigSound = nil
      end
      for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  local repsinNode = self.m_respinNodes[i]
                  if repsinNode.p_colIndex == 3 and repsinNode.p_rowIndex == 2 then
                        repsinNode:setEcpectation(false)
                        local runLong = self.m_baseRunNum + (repsinNode.p_colIndex- 1) * BASE_COL_INTERVAL
                        --最后一次放大
                        if self.m_machine:getCurRespinCount() == 1 then
                              self.scaleBigIndex = 3
                              if self.m_machine:checkTreasureToadABTest() then      --ABtest
                                    self.middle_num = math.ceil(runLong * 3)
                                    repsinNode:changeRunSpeed(true)
                                    self:showLightingForIndex(self.scaleBigIndex)
                                    self.middleKuang:runCsbAction("fangda")
                                    repsinNode:runAction(self:getScaleBigAni())
                                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_middle_kuang_strong)
                              else
                                    self.middle_num = math.ceil(runLong * 20)
                                    repsinNode:setResDis(true)
                                    repsinNode:changeRunSpeed(true)
                                    self:changeLightingBeforeForIndex(self.scaleBigIndex)
                                    -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_middle_kuang_strong2)
                              end
                              
                              
                              
                        --self.m_machine:getCurRespinCount() <= 3 and self.m_machine:getCurRespinCount() > 1
                        elseif self:changeJudgingConditions() then
                              self.scaleBigIndex = 2
                              repsinNode:setEcpectation(false)
                              if self.m_machine:checkTreasureToadABTest() then      --ABtest
                                    self.middle_num = math.ceil(runLong * 1.5)
                                    repsinNode:changeRunSpeed(false)
                                    self:showLightingForIndex(self.scaleBigIndex)
                              else
                                    repsinNode:setResDis(true)
                                    repsinNode:changeRunSpeed(true)
                                    self.middle_num = math.ceil(runLong * 20)
                                    self:changeLightingBeforeForIndex(self.scaleBigIndex)
                              end
                              self.middleKuang:runCsbAction("actionframe",true)
                        else
                              self.scaleBigIndex = 1
                              
                              self.middle_num = math.ceil(runLong * 1.5)
                              repsinNode:changeRunSpeed(false)
                              
                              if self.m_machine:checkTreasureToadABTest() then      --ABtest
                                    self:showLightingForIndex(self.scaleBigIndex)
                              else
                                    repsinNode:setResDis(false)
                                    self:changeLightingBeforeForIndex(self.scaleBigIndex)
                              end
                        end
                  end
                  self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                  self.m_respinNodes[i]:startMove()
            end
      end
end

function TreasureToadRespinView:changeJudgingConditions()
      if self.m_machine:checkTreasureToadABTest() then      --ABtest
            if self.m_machine:getCurRespinCount() <= 3 and self.m_machine:getCurRespinCount() > 1 then
                  return true
            else
                  return false
            end
      else
            if self:getCurNormalBonusNum() >= 8 and self:getCurNormalBonusNum() <= 14 then
                  return true
            else
                  return false
            end
      end
end

function TreasureToadRespinView:isFixSymbol(symbolType)
      if symbolType == self.SYMBOL_FIX_SYMBOL or 
          symbolType == self.SYMBOL_FIX_SYMBOL1 or 
          symbolType == self.SYMBOL_FIX_SYMBOL2 then
          return true
      end
      return false
end

function TreasureToadRespinView:getIdleframeName(symbolType)
      if symbolType == self.SYMBOL_FIX_SYMBOL1 then
            return "idleframe2"
      else
            return "idleframe2_2"
      end
end

function TreasureToadRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            if endNode.p_symbolType == self.SYMBOL_FIX_SYMBOL2 then
                  gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bonus2_buling)
                  gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_incredible_bonus2)
            elseif endNode.p_symbolType == self.SYMBOL_FIX_SYMBOL1 then
                  gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bonus2_buling)
                  gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_unbelievable_bonus1)
            else
                  if not self.isQuickStop then
                        if self.m_vecExpressSound[endNode.p_cloumnIndex] == false then
                              gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bonus_buling)
                              self.m_vecExpressSound[endNode.p_cloumnIndex] = true
                        end
                  else
                        if self.isOnceQuickStop then
                              gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_bonus_buling)
                              self.isOnceQuickStop = false
                        end
                  end
                  
            end
            endNode:runAnim(info.runEndAnimaName, false,function ()
                  local idleName = self:getIdleframeName(endNode.p_symbolType)
                  endNode:runAnim(idleName,true)
                  
            end)
      end
      if endNode.p_cloumnIndex == 3 and endNode.p_rowIndex == 2 then
            if endNode.p_symbolType == self.SYMBOL_FIX_SYMBOL2 then
                  --棋盘震动
                  util_shakeNode(self.m_machine:findChild("root"),7,7,40/60)
            end
            local respinNode = self:getRespinNode(2,3)
            if self.scaleBigIndex == 3 then
                  self.scaleBigIndex = 1
                  
                  util_setCascadeOpacityEnabledRescursion(self.middleKuang, true)
                  util_setCascadeColorEnabledRescursion(self.middleKuang, true)
                  if self.m_machine:getCurRespinCount() == 0 then
                        if self.m_machine:checkTreasureToadABTest() then      --ABtest
                              self.middleKuang:runCsbAction("over3",false,function ()
                                    self:showLightingForIndex(4)
                              end)
                        else
                              if self.isScale then
                                    self.m_machine:delayCallBack(0.5,function ()
                                          self.middleKuang:runCsbAction("over3",false,function ()
                                                self:changeLightingBeforeForIndex(4)
                                          end)
                                    end)
                              else
                                    self:changeLightingBeforeForIndex(4)
                              end
                        end     
                  else
                        if self.m_machine:checkTreasureToadABTest() then      --ABtest
                              self.middleKuang:runCsbAction("over",false,function ()
                                    self.middleKuang:runCsbAction("idle",true)
                                    self:showLightingForIndex(self.scaleBigIndex)
                                    
                              end)
                        else
                              if self.isScale then
                                    self.m_machine:delayCallBack(0.5,function ()
                                          self.middleKuang:runCsbAction("over",false,function ()
                                                -- self.middleKuang:runCsbAction("idle",true)
                                                self:changeLightingBeforeForIndex(self.scaleBigIndex) 
                                          end)
                                    end)
                                    
                              else
                                    self:changeLightingBeforeForIndex(self.scaleBigIndex) 
                              end
                        end
                        
                        
                  end
                  if self.m_machine:checkTreasureToadABTest() then
                        respinNode:runAction(self:getScaleSmallAni())
                        self.isScaleBig = false
                  else
                        if self.isScale then
                              if self.btestChangeBigSound then
                                    gLobalSoundManager:stopAudio(self.btestChangeBigSound)
                                    self.btestChangeBigSound = nil
                              end
                              self.m_machine:delayCallBack(0.5,function ()
                                    respinNode:runAction(self:getScaleSmallAni())
                                    self.isScaleBig = false
                              end)
                        end
                        
                  end
                  
            elseif self.scaleBigIndex == 2 then
                  util_setCascadeOpacityEnabledRescursion(self.middleKuang, true)
                  util_setCascadeColorEnabledRescursion(self.middleKuang, true)
                  if self.m_machine:checkTreasureToadABTest() then            --ABtest
                        self.middleKuang:runCsbAction("over2",false,function ()
                              self.middleKuang:runCsbAction("idle",true)   
                              self:showLightingForIndex(self.scaleBigIndex)
                              
                        end)
                  else
                        local actName = "over4"
                        -- if self.m_machine:getCurRespinCount() == 0 then
                        --       actName = "over3"
                        -- end
                        if self.isScale then
                              self.m_machine:delayCallBack(0.5,function ()
                                    self.middleKuang:runCsbAction(actName,false,function ()
                                          self:changeLightingBeforeForIndex(self.scaleBigIndex) 
                                    end)
                              end)
                              
                        else
                              self:changeLightingBeforeForIndex(self.scaleBigIndex) 
                        end
                        
                        if self.isScale then
                              if self.btestChangeBigSound then
                                    gLobalSoundManager:stopAudio(self.btestChangeBigSound)
                                    self.btestChangeBigSound = nil
                              end
                              self.m_machine:delayCallBack(0.5,function ()
                                    respinNode:runAction(self:getScaleSmallAni())
                                    self.isScaleBig = false
                              end)
                        end
                  end
            else
                  -- self.scaleBigIndex = 1
                  self.middleKuang:runCsbAction("idle",true)
                  if self.m_machine:checkTreasureToadABTest() then      --ABtest
                        self:showLightingForIndex(self.scaleBigIndex)
                  else
                        -- self:changeLightingBeforeForIndex(self.scaleBigIndex)
                  end
                  
            end   
      end

end

function TreasureToadRespinView:showLightingForIndex(index)
      if index == 1 then
            self.kuangLight3:setVisible(false)
            self.kuangLight1:setVisible(false)
      elseif index == 2 then
            self.kuangLight3:setVisible(false)
            self.kuangLight1:setVisible(true)
            self.kuangLight1:runCsbAction("idle",true)
      elseif index == 3 then
            self.kuangLight3:setVisible(true)
            self.kuangLight1:setVisible(true)
            self.kuangLight1:runCsbAction("idle",true)
            self.kuangLight3:runCsbAction("idle",true)
      else
            self.kuangLight3:setVisible(false)
            self.kuangLight2:setVisible(false)
            self.kuangLight1:setVisible(false)
      end
end

function TreasureToadRespinView:changeLightingBeforeForIndex(index)
      if index == 1 then
            self.kuangLight1:setVisible(true)
            self.kuangLight2:setVisible(false)
            self.kuangLight3:setVisible(false)
            self.kuangLight1:runCsbAction("idle2",true)
      elseif index == 2 then
            self.kuangLight1:setVisible(false)
            self.kuangLight2:setVisible(true)
            self.kuangLight3:setVisible(false)
            self.kuangLight2:runCsbAction("idle",true)
      elseif index == 3 then
            self.kuangLight3:setVisible(true)
            self.kuangLight1:setVisible(true)
            self.kuangLight2:setVisible(false)
            self.kuangLight3:runCsbAction("idle",true)
            self.kuangLight1:runCsbAction("idle2",true)
      else
            self.kuangLight3:setVisible(false)
            self.kuangLight2:setVisible(false)
            self.kuangLight1:setVisible(false)
      end
end

function TreasureToadRespinView:changeLightingOverForIndex(index)
      if index == 1 then         --如果当前在第一阶段，其他位置停轮后判断若是第二阶段的数量，则在次数修改为第二阶段
            if self:getCurNormalBonusNum() >= 8 and self:getCurNormalBonusNum() <= 14 then
                  index = 2
                  self.scaleBigIndex = 2
                  local repsinNode = self:getRespinNode(2,3)
                  repsinNode:setResDis(true)
                  repsinNode:changeRunSpeed(true)
                  repsinNode:changeRunNodeNum2()
                  self:changeLightingBeforeForIndex(self.scaleBigIndex)
            end
      end
      if index ~= 1 then
      -- elseif index == 2 then
            local respinNode = self:getRespinNode(2,3)
            respinNode:setEcpectation(true)
            self.middleKuang:runCsbAction("fangda")
            local respinNode = self:getRespinNode(2,3)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_middle_kuang_strong2)
            self.m_machine:delayCallBack(1,function ()
                  if self.btestChangeBigSound then
                        gLobalSoundManager:stopAudio(self.btestChangeBigSound)
                        self.btestChangeBigSound = nil
                  end
                  self.btestChangeBigSound = gLobalSoundManager:playSound("TreasureToadSounds/sound_TreasureToad_quick_run.mp3",true)
            end)
            respinNode:runAction(self:getScaleBigAni())
            respinNode:setDtNum(0)
      -- elseif index == 3 then
      --       local respinNode = self:getRespinNode(2,3)
      --       respinNode:setEcpectation(true)
      --       self.middleKuang:runCsbAction("fangda")
      --       local respinNode = self:getRespinNode(2,3)
      --       gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_middle_kuang_strong2)
      --       respinNode:runAction(self:getScaleBigAni())
      --       respinNode:setDtNum(0)
      end
end

--repsinNode滚动完毕后 置换层级
function TreasureToadRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            if endNode.p_cloumnIndex == 3 and endNode.p_rowIndex == 2 then
                  util_changeNodeParent(self,endNode,TOP_ZORDER + 200)
            else
                  util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2+ endNode.p_cloumnIndex * 10 - endNode.p_rowIndex)
            end
            
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
            if self.m_machine:isShowCollectForRespin() then
                  self.m_machine:delayCallBack(0.5,function ()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
                  end)
            else
                  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
            end
         
      end
      if self.m_machine:checkTreasureToadABTest() then      --ABtest
            
      else
            if ((self.m_respinNodeStopCount == self.m_respinNodeRunCount - 1)) and not self.isQuickStop then
                  --中间期待发生变化  
                  self:changeLightingOverForIndex(self.scaleBigIndex)
            end
      end
      
end

function TreasureToadRespinView:changeLockSymbol(fixPos)
      local respinNode = self:getRespinNode(fixPos.iX,fixPos.iY)
      if respinNode and respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
            local blankType = self.m_machine.SYMBOL_RS_SCORE_BLANK
            local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
            local node = respinNode.m_baseFirstNode
            if node then
                  node:changeCCBByName(ccbName, blankType)
                  node:changeSymbolImageByName( ccbName )
            end
            respinNode:setFirstSlotNode(node)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
            
      end
      
end

function TreasureToadRespinView:changeLockSymbolForSpecial()
      local respinNode = self:getRespinNode(2,3)
      if respinNode and respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
            local blankType = self.m_machine.SYMBOL_RS_SCORE_BLANK1
            local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
            local node = respinNode.m_baseFirstNode
            if node then
                  node:changeCCBByName(ccbName, blankType)
                  node:changeSymbolImageByName( ccbName )
            end
            respinNode:setFirstSlotNode(node)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
            
      end
      
end

function TreasureToadRespinView:changeBlankSymbol(type,pos,score,nodeType)
      local fixPos = self.m_machine:getRowAndColByPos(pos)
      local respinNode = self:getRespinNode(fixPos.iX,fixPos.iY)
      if respinNode and respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.IDLE then
            local blankType = type
            local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
            local node = respinNode.m_baseFirstNode
            if node then
                  node:changeCCBByName(ccbName, blankType)
                  node:changeSymbolImageByName( ccbName )
                  self.m_machine:addLevelBonusSpineForSpecial(node,score,nodeType)
            end
            if nodeType == "Bonus1" then
                  node:runAnim("idleframe2",true)
            else
                  node:runAnim("idleframe2_2",true)
            end
            
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)


            local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self,node,REEL_SYMBOL_ORDER.REEL_ORDER_2 + node.p_cloumnIndex * 10 - node.p_rowIndex)
            node:setTag(self.REPIN_NODE_TAG)
            node:setPosition(pos)
      end
      
end

function TreasureToadRespinView:getScaleBigAni()
      self.isScale = true
      local scaleIndex = 1.3
      if self.m_machine:checkTreasureToadABTest() then      --ABtest
            scaleIndex = 1.3
      else
            scaleIndex = 1.5
      end
      local scaleAct = cc.ScaleTo:create(20/60, scaleIndex)
      return scaleAct
  end
  
function TreasureToadRespinView:getScaleSmallAni()
      self.isScale = false
      local time = 10/60
      -- if self.m_machine:checkTreasureToadABTest() then      --ABtest
      --       time = 10/60
      -- else
      --       time = 15/60
      -- end
      local scaleAct = cc.ScaleTo:create(time, 1.0)
      return scaleAct
end

--[[
    三个档位：棋盘中普通bonus个数小于8、棋盘中的普通bonus个数 大于等于8，小于等于14 时、respin次数的最后一次
    优化：棋盘中普通bonus个数小于8
         棋盘中的普通bonus个数 大于等于8，小于等于14 时
         棋盘中的普通bonus个数 大于等于8，小于等于14 时，停轮后
         respin次数的最后一次
         respin次数的最后一次，停轮后
]]
--获取普通bonus个数
function TreasureToadRespinView:getCurNormalBonusNum()
      local list = self:getAllCleaningNode()
      local num = 0
      for k,lockNode in pairs(list) do
            if lockNode.p_symbolType and (lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL2 and lockNode.p_symbolType ~= self.SYMBOL_FIX_SYMBOL1) then
                  num = num + 1
            end
      end
      return num
end


return TreasureToadRespinView
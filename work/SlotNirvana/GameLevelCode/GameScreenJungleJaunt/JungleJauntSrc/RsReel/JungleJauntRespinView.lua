
local PBC = require "JungleJauntPublicConfig"
local JungleJauntRespinView = class("JungleJauntRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

function JungleJauntRespinView:initRsBg()
      self.m_rsBg = {}
      for i=1,#self.m_respinNodes do
            local colorNode = util_createAnimation("JungleJaunt_respin_qipandi.csb")
            colorNode:setPosition(self.m_respinNodes[i]:getPosition())
            colorNode.p_rowIndex = self.m_respinNodes[i].p_rowIndex
            colorNode.p_colIndex = self.m_respinNodes[i].p_colIndex
            self:addChild(colorNode,-10)
            self.m_rsBg[self.m_machine:getPosReelIdx(colorNode.p_rowIndex, colorNode.p_colIndex)+1] = colorNode
            colorNode:setVisible(true)
      end
end

function JungleJauntRespinView:initSpecLockFrame(_isNorTri)
      local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {} 
      local specialcase = rsExtraData.specialcase or {}
      self.m_lockFrames ={}
      for i=1,#self.m_respinNodes do
            local lockFrame = util_spineCreate("JungleJaunt_respin_lvsegezi",true,true)
            lockFrame:setPosition(self.m_respinNodes[i]:getPosition())
            lockFrame.p_rowIndex = self.m_respinNodes[i].p_rowIndex
            lockFrame.p_colIndex = self.m_respinNodes[i].p_colIndex
            self:addChild(lockFrame,1 )

            local bg = util_spineCreate("JungleJaunt_respin_lvsegezi_bg",true,true)
            bg:setPosition(self.m_respinNodes[i]:getPosition())
            self:addChild(bg,-1 )
            
            lockFrame.bg = bg

            self.m_lockFrames[self.m_machine:getPosReelIdx(lockFrame.p_rowIndex, lockFrame.p_colIndex)+1] = lockFrame

            lockFrame:setScale(0.5)
            lockFrame.bg:setScale(0.5)

            lockFrame:setVisible(false)
            lockFrame.bg:setVisible(false)

            util_spinePlay(lockFrame,"idle",true)
            util_spinePlay(lockFrame.bg,"idle",true)
      end

      if not _isNorTri then
            for i=1,#specialcase do
                  local index = specialcase[i] + 1
                  self.m_lockFrames[index]:setVisible(true)
                  self.m_lockFrames[index].bg:setVisible(true)
            end   
      end
      
end

function JungleJauntRespinView:playRsViewLockFrameShow(_func)
      local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {} 
      local specialcase = rsExtraData.specialcase or {}
      specialcase = clone(specialcase)
      local cutTime = 15/30
      local playIndex = 0

      for i=1,#specialcase do
            local index = specialcase[i] + 1
            local frame = self.m_lockFrames[index]
            local endFunc = nil
            if i == #specialcase then
                  endFunc = function()
                        if _func then
                              _func()
                        end
                  end
            end
            if not frame:isVisible() then

                  performWithDelay(frame,function()
                        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_49)   
                        self.m_machine.m_rsTopWheelNor:playShowLockFrames(index,function()
                              frame:setVisible(true) 
                              frame.bg:setVisible(true)
                              util_spinePlay(frame,"start")
                              util_spineEndCallFunc(frame,"start",function()
                                    util_spinePlay(frame,"idle",true)  
                              end)
                              util_spinePlay(frame.bg,"start")
                              util_spineEndCallFunc(frame.bg,"start",function()
                                    util_spinePlay(frame.bg,"idle",true)  
                              end)
                              local fixPos = self.m_machine:getRowAndColByPos(index - 1)
                              local iCol = fixPos.iY
                              local iRow = fixPos.iX
                              local repsinNode = self:getRespinNode(iRow, iCol)
                              local lastNode = repsinNode:getLastNode()
                              if not tolua.isnull(lastNode) then
                                    lastNode:runAnim("hide") 
                              end
                              
                              self:playLockFrameShowTx(index,endFunc)    
                        end)
                  end,cutTime*playIndex) 
                  playIndex = playIndex + 1
            else
                 if endFunc then
                        endFunc()
                        endFunc= nil
                 end 
            end
            
      end   

end

function JungleJauntRespinView:playLockFrameShowTx(_posIndex,_endfunc)
      if not self.m_lockFramesTx then
            self.m_lockFramesTx ={}   
      end

      if not self.m_lockFramesTx[_posIndex] then
            local fixPos = self.m_machine:getRowAndColByPos(_posIndex - 1)
            local iCol = fixPos.iY
            local iRow = fixPos.iX
            local respinNode = self:getRespinNode(iRow, iCol)
            self.m_lockFramesTx[_posIndex] = util_spineCreate("JungleJaunt_yuanpan_tx_2",true,true)
            self.m_lockFramesTx[_posIndex]:setPosition(respinNode:getPosition())
            self.m_lockFramesTx[_posIndex].p_rowIndex = respinNode.p_rowIndex
            self.m_lockFramesTx[_posIndex].p_colIndex = respinNode.p_cloumnIndex
            self:addChild(self.m_lockFramesTx[_posIndex],REEL_SYMBOL_ORDER.REEL_ORDER_2 )
      end
      
      self.m_lockFramesTx[_posIndex]:setVisible(true)
      util_spinePlay(self.m_lockFramesTx[_posIndex],"shouji")
      util_spineEndCallFunc(self.m_lockFramesTx[_posIndex],"shouji",function()
            self.m_lockFramesTx[_posIndex]:setVisible(false)
            if _endfunc then
                  _endfunc()
            end
      end)
end

function JungleJauntRespinView:playSpecBuff2ShowTx(_posIndex,_endfunc)
      if not self.m_specBuff2Tx then
            self.m_specBuff2Tx ={}   
      end

      if not self.m_specBuff2Tx[_posIndex] then
            local fixPos = self.m_machine:getRowAndColByPos(_posIndex - 1)
            local iCol = fixPos.iY
            local iRow = fixPos.iX
            local respinNode = self:getRespinNode(iRow, iCol)
            self.m_specBuff2Tx[_posIndex] = util_spineCreate("JungleJaunt_yuanpan_tx_3",true,true)
            self.m_specBuff2Tx[_posIndex]:setPosition(respinNode:getPosition())
            self.m_specBuff2Tx[_posIndex].p_rowIndex = respinNode.p_rowIndex
            self.m_specBuff2Tx[_posIndex].p_colIndex = respinNode.p_cloumnIndex
            self:addChild(self.m_specBuff2Tx[_posIndex],REEL_SYMBOL_ORDER.REEL_ORDER_4 * 3 )
      end
      
      self.m_specBuff2Tx[_posIndex]:setVisible(true)
      util_spinePlay(self.m_specBuff2Tx[_posIndex],"shouji")
      util_spineEndCallFunc(self.m_specBuff2Tx[_posIndex],"shouji",function()
            self.m_specBuff2Tx[_posIndex]:setVisible(false)
            if _endfunc then
                  _endfunc()
            end
      end)
end

function JungleJauntRespinView:getRsClipType()
      return RESPIN_CLIPTYPE.SINGLE
end

function JungleJauntRespinView:initRsViwePos()
      local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData or {} 
      local rows = rsExtraData.rows or 4
      
      self:setPositionY((rows - self.m_machine.m_iReelRowNum ) * (self.m_slotNodeHeight + 1))
      if rows > 4 then
            self.m_machine:runCsbAction("qipan".. (rsExtraData.rows - 3))
      end
      
      for i=1,#self.m_respinNodes do
            local respinNode = self.m_respinNodes[i]
            respinNode:setVisible(respinNode.p_rowIndex > (self.m_machine.m_iReelRowNum - rows))   
            respinNode.m_clipNode:setVisible(respinNode.p_rowIndex > (self.m_machine.m_iReelRowNum - rows))      
            local bg = self.m_rsBg[self.m_machine:getPosReelIdx(respinNode.p_rowIndex, respinNode.p_colIndex)+1]
            bg:setVisible(respinNode.p_rowIndex > (self.m_machine.m_iReelRowNum - rows)) 
      end
end


function JungleJauntRespinView:isTriggerBuffCell(_iCol, _iRow)
      local posIndex = self.m_machine:getPosReelIdx(_iRow, _iCol)
      local rsExtraData = self.m_machine.m_runSpinResultData.p_rsExtraData
  
      local bTrigger = false
      -- buff转盘玩法-普通
      if not bTrigger then
          local buffBonusList = rsExtraData.wheelkinds or {}
          for i,v in ipairs(buffBonusList) do
              if posIndex == v[1] then
                  bTrigger = true
                  break
              end
          end
      end
      -- buff转盘玩法-特殊
      if not bTrigger then
          local specialBuffBonusList = rsExtraData.specialwheelkinds or {}
          for i,v in ipairs(specialBuffBonusList) do
              if posIndex == v[1] then
                  bTrigger = true
                  break
              end
          end
      end
      
      
      return bTrigger
  end

function JungleJauntRespinView:runNodeEnd(endNode)
      local zorder = self.m_machine:getBounsScatterDataZorder(endNode.p_symbolType)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            endNode:setLocalZOrder(zorder - endNode.p_rowIndex + endNode.p_cloumnIndex * self.m_machine.m_iReelRowNum)
            self.m_bulingIndex = self.m_bulingIndex + 1 
            local animName = info.runEndAnimaName
            local isTrigger = self:isTriggerBuffCell( endNode.p_cloumnIndex,endNode.p_rowIndex)
            if isTrigger then
                  animName = "buling2"
                  local posIndex = self.m_machine:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex) + 1
                  local frame = self.m_lockFrames[posIndex]
                  frame:setVisible(true) 
                  frame.bg:setVisible(true)
                  util_spinePlay(frame,"idle2",true)  
                  util_spinePlay(frame.bg,"idle2",true)  

                  local rod = math.random(1,2)
                  if rod == 1 and endNode.p_symbolType == self.m_machine.SYMBOL_BONUS_1 then
                        self.m_triSound = gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_86) 
                  elseif rod == 1 and endNode.p_symbolType == self.m_machine.SYMBOL_BONUS_2 then 
                        self.m_triSound = gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_87)
                  end
                  
            end

            self.m_machine:playBulingSymbolSounds(endNode.p_cloumnIndex, PBC.SoundConfig.JUNGLEJAUNT_SOUND_9)

            endNode:runAnim(info.runEndAnimaName, false,function()
                  self.m_bulingIndex = self.m_bulingIndex - 1
                  endNode:runAnim(info.runIdleAnimaName, true)
            end)
      else
            endNode:runAnim("hide")
      end
end

function JungleJauntRespinView:checkAllRunDown()

      self.m_machine:playQuickStopBulingSymbolSound(self.m_machine.m_iReelColumnNum)  

      schedule(self.m_rsBg[1],function()
            if self.m_bulingIndex <= 0 then
                  self.m_rsBg[1]:stopAllActions()
                  self.m_bulingIndex = 0
                  self.super.checkAllRunDown()
            end
      end,1/60)
      
end

function JungleJauntRespinView:oneReelDown(_reelCol)
      if self:getouchStatus() ~= ENUM_TOUCH_STATUS.QUICK_STOP then
            self.m_machine:playReelDownSound(_reelCol,  self.m_machine.m_reelDownSound)

      else
            local reelCol = _reelCol
            
      end  
      
      
end

function JungleJauntRespinView:quicklyStop()
      self.super.quicklyStop(self)
      gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_4)      
end



function JungleJauntRespinView:getAllCleaningNode()
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
function JungleJauntRespinView:startMove()
      self.m_bulingIndex = 0
      self.m_machine:resetreelDownSoundArray()
      self.m_machine:resetsymbolBulingSoundArray()
      self.super.startMove(self)
end

return JungleJauntRespinView
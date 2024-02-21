local RespinView = util_require("Levels.RespinView")
local PharaohRespinView = class("PharaohRespinView",RespinView )

PharaohRespinView.m_getSpinResultReelsType = nil
PharaohRespinView.m_getIDCompares = nil
PharaohRespinView.m_animaNameNode = nil

PharaohRespinView.m_storeIcons = nil
local ANIMA_TAG = 20000

function PharaohRespinView:setStoreIcons(storeIcons)
      self.m_storeIcons = storeIcons
end

function PharaohRespinView:setMachine(machine)
      self.m_machine = machine
end

function PharaohRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
      RespinView.initRespinElement(self,machineElement, machineRow, machineColmn, startCallFun)
      self:changeClipRowNode(1,cc.p(0,-0.5))
      self:changeClipRowNode(3,cc.p(0,0.2))
end

function PharaohRespinView:getStoreIconsScore(iX, iY)
      for i=1,#self.m_storeIcons do
           local data = self.m_storeIcons[i]
           if data.iX == iX and data.iY == iY then
                 return data.score
           end
      end
end

function PharaohRespinView:setCallFun(getSpinResultReelsType, getIDCompares)
      self.m_getSpinResultReelsType = getSpinResultReelsType
      self.m_getIDCompares = getIDCompares
end

function PharaohRespinView:readyMove()

      self:addAnimaNode( )

      performWithDelay(self,function( ... )
            for i=1,#self.m_animaNameNode do
                  local node = self.m_animaNameNode[i]
                  node:removeFromParent()
            end
            self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_startCallFunc then
                  self.m_startCallFunc()
            end
      end ,4)

end

function PharaohRespinView:runNodeEnd(endNode)

      local symbolId = self.m_getSpinResultReelsType(endNode.p_cloumnIndex, endNode.p_rowIndex)
      local specialNodeInfo = nil
      if specialNodeInfo == nil then
            return
      end
      local score = specialNodeInfo.value
      local animaName = nil

      if type(score) ~= "string" then
            animaName = "idleframe_actionframe"
        else
            if score == "MINI" then
                  animaName = "jackpot_1_actionframe"
            elseif score == "MINOR" then
                  animaName = "jackpot_2_actionframe"
            elseif score == "MAJOR" then
                  animaName = "jackpot_3_actionframe"
            else
                  animaName = "jackpot_4_actionframe"
            end
        end
        if animaName ~= nil then
            endNode:runAnim(animaName, false)
        end
end

function PharaohRespinView:getBigSymbolAnimaName(endNode)


      local iCol = endNode.p_cloumnIndex
      local iRow = endNode.p_rowIndex

      local symbolId = self.m_getSpinResultReelsType(endNode.p_cloumnIndex, endNode.p_rowIndex)      
      --获取分数
      local specialNodeInfo = nil

      local animaName = nil
      if specialNodeInfo ~= nil then
          local score = specialNodeInfo.value
          if type(score) ~= "string" then
               animaName = "action10"
          else
              if score == "MINI" then
                  animaName = "action12"
              elseif score == "MINOR" then
                  animaName = "action13"
              elseif score == "MAJOR" then
                  animaName = "action14"
              else
                  animaName = "action15"
              end
          end
      end
      return animaName
end

function PharaohRespinView:oneReelDown()
      gLobalSoundManager:playSound("PharaohSounds/music_Pharaoh_reel_stop.mp3")
end


function PharaohRespinView:addAnimaNode(  )

      local childs = self:getChildren()
      self.m_animaNameNode = {}
      for i=1,#childs do
            local node = childs[i]
            local tag =  node:getTag() 
            local visible = node:isVisible()
            if tag == self.REPIN_NODE_TAG  and visible then

                  if node.p_symbolType < 1000 then
                        local score =  self:getStoreIconsScore(node.p_rowIndex, node.p_cloumnIndex)
                        local type = nil
                        local animaName = "buling2"
                        if score == 10 then
                              type = 108
                        elseif score == 20 then
                              type = 107
                        elseif score == 100 then
                              type = 106
                        else
                              type = 101
                        end

                        local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, type)
                        local animaNode = util_createAnimation(ccbName..".csb")--self.getSlotNodeBySymbolType(type,node.p_rowIndex,node.p_cloumnIndex )
                        animaNode:runCsbAction(animaName, true)
                        animaNode:setPosition(cc.p(node:getPositionX(), node:getPositionY()))
                        self:addChild(animaNode, REEL_SYMBOL_ORDER.REEL_ORDER_3, ANIMA_TAG)

                        self.m_animaNameNode[#self.m_animaNameNode + 1] = animaNode

                        if type == 101 then
                              local lineBet =  globalData.slotRunData:getCurTotalBet()
                              local scoreTmp = score * lineBet
                              scoreTmp = util_formatCoins(scoreTmp, 3)
                              animaNode:findChild("score_lab"):setString(scoreTmp)
                        end
                  else
                        local score =  self:getStoreIconsScore(node.p_rowIndex, node.p_cloumnIndex)
                        node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_4)
                        local animID = 10
                        if score == 10 then
                              animID = 12
                          elseif score == 20 then
                              animID = 13
                          elseif score == 100 then
                              animID = 14
                          elseif score == 1000 then
                              animID = 15
                          end
                        -- node:runAnim("action"..animID.."_actionframe1")
                        
                                    performWithDelay(node,function( ... )
                                          node:runAnim("action"..animID.."_actionframe1", false,function(  )
                                                node:runAnim("action"..animID)
                                          end)
                              end ,1)
                  end
            end
      end
end
return PharaohRespinView
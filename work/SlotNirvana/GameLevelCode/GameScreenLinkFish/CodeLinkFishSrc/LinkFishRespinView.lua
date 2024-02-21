

local LinkFishRespinView = class("LinkFishRespinView", 
                                    util_require("Levels.RespinView"))
LinkFishRespinView.m_updateFeatureNodeFun = nil                                    
LinkFishRespinView.m_updateRespinNum = nil

      -- LinkFishRespinView.m_getSpinResultReelsType = nil
      -- LinkFishRespinView.m_getIDCompares = nil
      -- LinkFishRespinView.m_animaNameNode = nil

      -- function LinkFishRespinView:getSymbolType(symbolType)
      -- end

      -- function LinkFishRespinView:getSymbolType(symbolType)
      --       if symbolType == 94 then
      --           return nil
      --       elseif symbolType == 95 then
      --             return nil
      --       elseif symbolType == 100 then
      --             return
      --       end
      -- end

      -- local ANIMA_TAG = 20000

      -- function LinkFishRespinView:setCallFun(getSpinResultReelsType, getIDCompares)
      --       self.m_getSpinResultReelsType = getSpinResultReelsType
      --       self.m_getIDCompares = getIDCompares
      -- end
function LinkFishRespinView:setUpdateCallFun(updateCallFun)
      self.m_updateFeatureNodeFun = updateCallFun
end

function LinkFishRespinView:setUpdateRespinNum(updateCallFun)
      self.m_updateRespinNum = updateCallFun
end

function LinkFishRespinView:readyMove()

      performWithDelay(self,function()
            local fixNode =  self:getFixSlotsNode()
            for k = 1, #fixNode do        
                  local childNode = fixNode[k]
                  childNode:runAnim("lighting",false, function()
                        childNode:runAnim("link_tip",true)  
                  end)  
            end 
      end, 0.5)


      performWithDelay(self,function()
            self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_startCallFunc then
                  self.m_startCallFunc()
            end

      end, 1.5)
end

function LinkFishRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil  then
            -- gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_fall_" .. endNode.p_cloumnIndex ..".mp3") 
            gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_bonuslight_inRespin.mp3") 
            if self.m_updateRespinNum ~= nil then
                  self.m_updateRespinNum()
            end
            endNode:runAnim("begin",false,function(  )
                  endNode:runAnim("link_tip",true)   
                  if self.m_updateFeatureNodeFun ~= nil then
                        self.m_updateFeatureNodeFun()
                  end
            end)   
            
      end    
end

--       LinkFishRespinView.m_reelDownCallBack = nil
-- function LinkFishRespinView:oneReelDownCallBack(callFun )
--       self.m_reelDownCallBack = callFun
-- end
-- function LinkFishRespinView:runNodeEnd(endNode)
--       self.m_reelDownCallBack()
-- end

-- function LinkFishRespinView:runNodeEnd(endNode)

--       local symbolId = self.m_getSpinResultReelsType(endNode.p_cloumnIndex, endNode.p_rowIndex)
--       local specialNodeInfo = self.m_getIDCompares(symbolId)
--       if specialNodeInfo == nil then
--             return
--       end
--       local score = specialNodeInfo.value
--       local animaName = nil

--       if type(score) ~= "string" then
--             animaName = "idleframe_actionframe"
--         else
--             if score == "MINI" then
--                   animaName = "jackpot_1_actionframe"
--             elseif score == "MINOR" then
--                   animaName = "jackpot_2_actionframe"
--             elseif score == "MAJOR" then
--                   animaName = "jackpot_3_actionframe"
--             else
--                   animaName = "jackpot_4_actionframe"
--             end
--         end
--         if animaName ~= nil then
--             endNode:runAnim(animaName, false)
--         end
-- end

function LinkFishRespinView:oneReelDown()
      gLobalSoundManager:playSound("LinkFishSounds/music_LinkFish_reel_stop.mp3")
end

---获取所有参与结算节点
function LinkFishRespinView:getAllCleaningNode()
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
-- function LinkFishRespinView:addAnimaNode(  )
--       local childs = self:getChildren()
--       self.m_animaNameNode = {}
--       for i=1,#childs do
--             local node = childs[i]
--             local tag =  node:getTag() 
--             local visible = node:isVisible()
--             if tag == self.REPIN_NODE_TAG  and visible then
--                   if node.p_symbolType == 101 then
--                         local symbolType = nil
--                         local animaName = nil
--                         local animaNode = nil
--                         local symbolId = self.m_getSpinResultReelsType(node.p_cloumnIndex, node.p_rowIndex)
--                         local specialNodeInfo = self.m_getIDCompares(symbolId)
--                         local score = specialNodeInfo.value

--                         if type(score) ~= "string" then
--                               symbolType =  100
--                               animaName = "buling2"
--                           else
--                               if score == "MINI" then
--                                     symbolType =  99
--                                     animaNode = self.getSlotNodeBySymbolType(symbolType)
--                                     animaName = "buling2"
--                               elseif score == "MINOR" then
--                                     symbolType =  98
--                                     animaNode = self.getSlotNodeBySymbolType(symbolType)
--                                     animaName = "buling2"
--                               elseif score == "MAJOR" then
--                                     symbolType =  97
--                                     animaNode = self.getSlotNodeBySymbolType(symbolType)
--                                     animaName = "buling2"
--                               else
--                                     symbolType =  96
--                                     animaNode = self.getSlotNodeBySymbolType(symbolType)
--                                     animaName = "buling2"
--                               end
--                           end
                          
--                           animaNode = self.getSlotNodeBySymbolType(symbolType)
--                           animaNode.m_isLastSymbol = true
              
--                           animaNode.p_cloumnIndex = node.p_cloumnIndex
--                           animaNode.p_rowIndex =  node.p_rowIndex
--                           node:addChild(animaNode, 1, ANIMA_TAG)
--                           performWithDelay(animaNode,function( ... )
--                               animaNode:runAnim(animaName, true)
--                         end ,0.2)
--                         self.m_animaNameNode[#self.m_animaNameNode + 1] = animaNode
--                   elseif  node.p_symbolType == 94 then
--                         node:runAnim("action10", true)
--                         performWithDelay(node,function( ... )
--                               node:runAnim("action10_actionframe2", true)
--                         end ,0.2)

--                         performWithDelay(node,function( ... )
--                               node:runAnim("action10", true)
--                         end ,4)
--                   end
--             end
--       end

-- end
return LinkFishRespinView
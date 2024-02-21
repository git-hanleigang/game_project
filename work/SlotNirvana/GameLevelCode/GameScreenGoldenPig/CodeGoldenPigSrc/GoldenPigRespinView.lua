

local GoldenPigRespinView = class("GoldenPigRespinView", 
                                    util_require("Levels.RespinView"))
GoldenPigRespinView.m_updateFeatureNodeFun = nil                                    


      -- GoldenPigRespinView.m_getSpinResultReelsType = nil
      -- GoldenPigRespinView.m_getIDCompares = nil
      -- GoldenPigRespinView.m_animaNameNode = nil

      -- function GoldenPigRespinView:getSymbolType(symbolType)
      -- end

      -- function GoldenPigRespinView:getSymbolType(symbolType)
      --       if symbolType == 94 then
      --           return nil
      --       elseif symbolType == 95 then
      --             return nil
      --       elseif symbolType == 100 then
      --             return
      --       end
      -- end

      -- local ANIMA_TAG = 20000

      -- function GoldenPigRespinView:setCallFun(getSpinResultReelsType, getIDCompares)
      --       self.m_getSpinResultReelsType = getSpinResultReelsType
      --       self.m_getIDCompares = getIDCompares
      -- end
function GoldenPigRespinView:setUpdateCallFun(updateCallFun)
      self.m_updateFeatureNodeFun = updateCallFun
end

function GoldenPigRespinView:readyMove()

      self:createGoldenPigWangGe()

      performWithDelay(self,function()
            local fixNode =  self:getFixSlotsNode()
            for k = 1, #fixNode do        
                  local childNode = fixNode[k]
                  childNode:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + childNode.p_cloumnIndex)
                  childNode:runAnim("actionframe",false, function()
                        childNode:runAnim("idleframe",true)  
                  end)  
            end 
      end, 0.5)

      local fDelayTime = 3.5
      if self:getParent().m_choiceTriggerRespin then
            fDelayTime = 0.5
      end
      performWithDelay(self,function()
            self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_startCallFunc then
                  self.m_startCallFunc()
            end

      end, fDelayTime)
end

function GoldenPigRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil  then
            endNode:runAnim("idleframe",true)   
            endNode:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + endNode.p_cloumnIndex)
            gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_bonus_auto.mp3") 

            if self.m_updateFeatureNodeFun ~= nil then
                  self.m_updateFeatureNodeFun()
            end
      end    
end

--       GoldenPigRespinView.m_reelDownCallBack = nil
-- function GoldenPigRespinView:oneReelDownCallBack(callFun )
--       self.m_reelDownCallBack = callFun
-- end
-- function GoldenPigRespinView:runNodeEnd(endNode)
--       self.m_reelDownCallBack()
-- end

-- function GoldenPigRespinView:runNodeEnd(endNode)

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

function GoldenPigRespinView:oneReelDown()
      gLobalSoundManager:playSound("GoldenPigSounds/music_GoldenPig_reel_stop.mp3")
end


-- function GoldenPigRespinView:addAnimaNode(  )
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


function GoldenPigRespinView:createGoldenPigWangGe( )
      
     self.m_WangGeBg = util_createView("CodeGoldenPigSrc.GoldenPigWangGe")  

      self:addChild(self.m_WangGeBg,10)
      self.m_WangGeBg:setPositionY(-10)
end
return GoldenPigRespinView
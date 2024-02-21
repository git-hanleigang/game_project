

local HallowinRespinView = class("HallowinRespinView", 
                                    util_require("Levels.RespinView"))

HallowinRespinView.SYMBOL_FIX_TYPE = 95

function HallowinRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0

      gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_trigger_rs.mp3")
      for i = 1, #fixNode, 1 do
            local symbolNode = fixNode[i]
            symbolNode:runAnim("idleframe")
            local lab = symbolNode:getCcbProperty("m_lb_index")
            if lab then
                  lab:setString("")
            end
            local parent = symbolNode:getCcbProperty("Bonus")
            local node = parent:getChildByName("nangua")
            if node == nil then
                  node = util_spineCreate("Socre_Hallowin_NanGua", true, true)
                  parent:addChild(node)
                  node:setName("nangua")
            end
            node:setVisible(true)
            util_spinePlay(node, "actionframe")
            util_spineEndCallFunc(node, "actionframe", function()
                  util_spinePlay(node, "daiji", true)
            end)
      end
      performWithDelay(self, function()
            self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_startCallFunc then
                  self.m_startCallFunc()
            end
      end, 3.4)

end

function HallowinRespinView:runNodeEnd(endNode)

      if endNode.p_symbolType == self.SYMBOL_FIX_TYPE then
            gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_fall_" .. endNode.p_cloumnIndex ..".mp3") 
            endNode:runAnim("idleframe")
            local parent = endNode:getCcbProperty("Bonus")
            local lab = endNode:getCcbProperty("m_lb_index")
            if lab then
                  lab:setString("")
            end
            local node = parent:getChildByName("nangua")
            if node == nil then
                  node = util_spineCreate("Socre_Hallowin_NanGua", true, true)
                  parent:addChild(node)
                  node:setName("nangua")
            end
            node:setVisible(true)
            util_spinePlay(node, "buling")
            util_spineEndCallFunc(node, "buling", function()
                  util_spinePlay(node, "daiji", true)
            end)
      end
      

end

function HallowinRespinView:oneReelDown()
      gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_reel_down.mp3")
end

---获取所有参与结算节点
function HallowinRespinView:getAllCleaningNode()
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
return HallowinRespinView
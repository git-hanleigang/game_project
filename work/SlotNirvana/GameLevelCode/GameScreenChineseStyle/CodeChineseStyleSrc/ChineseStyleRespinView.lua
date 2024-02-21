

local ChineseStyleRespinView = class("ChineseStyleRespinView", 
                                    util_require("Levels.RespinView"))

ChineseStyleRespinView.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13
ChineseStyleRespinView.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
ChineseStyleRespinView.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
ChineseStyleRespinView.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
ChineseStyleRespinView.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

function ChineseStyleRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0
      performWithDelay(self,function()
            for k = 1, #fixNode do        
                  local childNode = fixNode[k]
                  childNode:runAnim("begin")  
                  nBeginAnimTime = childNode:getAniamDurationByName("begin")                        
            end 
        
              performWithDelay(self,function()
                    for k = 1, #fixNode do        
                          local childNode = fixNode[k]
                          childNode:runAnim("link_tip",true)  
                    end 
              end,nBeginAnimTime)
        
              performWithDelay(self,function()
                    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
                    if self.m_startCallFunc then
                          self.m_startCallFunc()
                    end
        
              end,nBeginAnimTime + 1)
      end,0.2)
     
end

function ChineseStyleRespinView:runNodeEnd(endNode)

      if endNode.p_symbolType == self.SYMBOL_FIX_SYMBOL
       or endNode.p_symbolType == self.SYMBOL_FIX_MINI       
        or endNode.p_symbolType == self.SYMBOL_FIX_MINOR 
         or endNode.p_symbolType == self.SYMBOL_FIX_MAJOR
          or endNode.p_symbolType == self.SYMBOL_FIX_GRAND then
            local waitTime = 0
            endNode:runAnim("begin")  
            waitTime = endNode:getAniamDurationByName("begin")
            if not waitTime then
                  waitTime = 0
            end
            performWithDelay(self,function()
                  endNode:runAnim("link_tip",true)  
            end,waitTime)
            
      end
      

end

function ChineseStyleRespinView:oneReelDown()
      gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_reel_stop.mp3")
end

---获取所有参与结算节点
function ChineseStyleRespinView:getAllCleaningNode()
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
return ChineseStyleRespinView
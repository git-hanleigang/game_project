

local PepperBlastRespinView = class("PepperBlastRespinView", 
                                    util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 10,
}


function PepperBlastRespinView:setOneReelDownCallback(func)
      self.m_oneReelDownCallback = func
  end
  
--小块滚动（包含回弹）完毕，判断类型执行动画 
function PepperBlastRespinView:runNodeEnd(endNode)
      
      -- if(endNode and endNode.p_symbolType == self.m_machine.m_reSpinSymbolType)then
      --       --scatter落地音效,wild
      --       local soundName = string.format("PepperBlastSounds/music_PepperBlast_Wild_Down_%d.mp3", endNode.p_cloumnIndex)  
      --       gLobalSoundManager:playSound(soundName)
      --       endNode:runAnim("buling",false,function(  )
      --             endNode:runAnim("idleframe", true)
      --       end)
      -- end
end

function PepperBlastRespinView:oneReelDown(iCol, lastCol)
      if(nil ~= self.m_oneReelDownCallback)then
            self.m_oneReelDownCallback(iCol, lastCol)
      end
      gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_reel_stop.mp3")
end

---获取所有参与结算节点
function PepperBlastRespinView:getAllCleaningNode()
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


function PepperBlastRespinView:playAllWildIdleAnim()
      local wildList = self:getAllCleaningNode()
      for _index,_node in ipairs(wildList) do
            _node:runAnim("idleframe1",true)
      end
end


--===============重写父类接口
--node滚动停止
function PepperBlastRespinView:respinNodeEndBeforeResCallBack(endNode)
      --判断是否是该列最后一个格子滚动结束
      local lastColNodeRow = endNode.p_rowIndex 
      local lastCol = 1

      for i=1,#self.m_respinNodes do
            local respinNode = self.m_respinNodes[i]
            if respinNode.p_colIndex == endNode.p_cloumnIndex and respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  if respinNode.p_rowIndex < lastColNodeRow  then
                        lastColNodeRow = respinNode.p_rowIndex 
                  end
            end

            if(respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK and lastCol < respinNode.p_colIndex)then
                  lastCol = respinNode.p_colIndex
            end
      end
      if endNode.p_rowIndex  == lastColNodeRow then
            self:oneReelDown(endNode.p_cloumnIndex, lastCol)
      end
end

return PepperBlastRespinView

local RespinView = util_require("Levels.RespinView")
local LightCherryRespinView = class("LightCherryRespinView",RespinView)
LightCherryRespinView.m_updateFeatureNodeFun = nil  
LightCherryRespinView.m_vecExpressSound = {false, false, false, false, false}                                  


function LightCherryRespinView:setUpdateCallFun(updateCallFun)
      self.m_updateFeatureNodeFun = updateCallFun
end

function LightCherryRespinView:readyMove()

      performWithDelay(self,function()
            self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_startCallFunc then
                  self.m_startCallFunc()
            end

      end, 0.5)
end

function LightCherryRespinView:runNodeEnd(endNode)
      if tolua.isnull(endNode) then
            return
      end
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil  then
            
            self.m_machine:playBonusAni(endNode,"buling",false,function()
                  -- self.m_machine:playBonusAni(endNode,"idleframe2",true)
            end)
            if self.m_isQuicklyRun then
                  if self.m_isFirstPlaySound then
                        return 
                  end
            end
            self.m_isFirstPlaySound = true
            if self.m_vecExpressSound[endNode.p_cloumnIndex] == false then
                  gLobalSoundManager:playSound("LightCherrySounds/sound_LightCherry_bonus_buling.mp3")
                  self.m_vecExpressSound[endNode.p_cloumnIndex] = true
            end
            
      end    
end


function LightCherryRespinView:oneReelDown()
      self.m_vecExpressSound = {false, false, false, false, false}
      if self.m_isQuicklyRun then
            return
      end
      gLobalSoundManager:playSound("LightCherrySounds/sound_Lightcherry_reel_down.mp3")
end

---获取所有参与结算节点
function LightCherryRespinView:getAllCleaningNode()
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

function LightCherryRespinView:quicklyStop()
      self.m_isQuicklyRun = true
      LightCherryRespinView.super.quicklyStop(self)

      gLobalSoundManager:playSound("LightCherrySounds/sound_Lightcherry_reel_down_quick.mp3")

end

--组织滚动信息 开始滚动
function LightCherryRespinView:startMove()
      self.m_isQuicklyRun = false
      self.m_isFirstPlaySound = false
      LightCherryRespinView.super.startMove(self)
end

return LightCherryRespinView
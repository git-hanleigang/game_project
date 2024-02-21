------
---
---
------
local CandyBingoRespinView = class("CandyBingoRespinView", util_require("Levels.BaseRespin"))

CandyBingoRespinView.REPIN_NODE_TAG = 1000

CandyBingoRespinView.m_respinNodeName = nil

--滚动状态
GD.ENUM_TOUCH_STATUS = {
      UNDO = 1,       ---等待状态 不允许点击
      ALLOW = 2,      ---允许点击
      WATING = 3, --等待滚动
      RUN = 4,        ---滚动状态
      QUICK_STOP = 5, ---快滚状态
}

CandyBingoRespinView.m_respinTouchStatus = nil

local VIEW_ZORDER = 
{
      NORMAL = 100,
      REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 15 --20
local BASE_ROW_ADD_NUM = 11 --2

local BASE_COL_INTERVAL = 6



CandyBingoRespinView.m_baseRunNum = nil
CandyBingoRespinView.m_machineElementData = nil  --初始化repsin盘面时信息

CandyBingoRespinView.m_respinNodes = nil  --初始化repsin盘面时信息

--m_respinNodeRunCount == m_respinNodeStopCount轮盘停止了 滚动
CandyBingoRespinView.m_respinNodeRunCount = nil     --respinNode滚动个数
CandyBingoRespinView.m_respinNodeStopCount = nil    --repsinNode停止滚动个数 
CandyBingoRespinView.m_machineRow = nil             --关卡轮盘行数
CandyBingoRespinView.m_machineColmn = nil           --关卡轮盘列数
CandyBingoRespinView.m_startCallFunc = nil           --开始转动喊数

CandyBingoRespinView.m_Machine = nil           --开始转动喊数


function CandyBingoRespinView:initUI(respinNodeName,machine)
   self.m_respinNodeName = respinNodeName 
   self.m_baseRunNum = BASE_RUN_NUM
   self.m_Machine = machine
   self.m_isPlayedSound = false
end

--初始化变量
function CandyBingoRespinView:initData()
   self.m_respinTouchStatus = ENUM_TOUCH_STATUS.UNDO
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function CandyBingoRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
      -- ,{
      --       clipOffsetPos = cc.p(0,-10),
      --       clipOffsetSize = cc.size(0,10)
      -- })
      self.m_machineElementData = machineElement
      for i=1,#machineElement do
            local nodeInfo = machineElement[i]
            local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

            local pos = self:convertToNodeSpace(nodeInfo.Pos)
            machineNode:setPosition(pos)
            self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
            machineNode:setVisible(nodeInfo.isVisible)
            if nodeInfo.isVisible then
                  print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end

            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end

      self:readyMove()
end

--将CandyBingoRespinView元素放入respinNode做移动准备工作
--可以重写播放进入respin时动画
function CandyBingoRespinView:readyMove()


    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_startCallFunc then
            self.m_startCallFunc()
    end
end

function CandyBingoRespinView:createRespinNode(symbolNode, status)

    local respinNode = util_createView(self.m_respinNodeName,self)
    respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
    respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
    respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
    respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)
    --滚动速度
    respinNode:setRunSpeed(self.m_Machine.m_configData.p_reelMoveSpeed)

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
    
    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex))
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    respinNode:setFirstSlotNode(symbolNode)

    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

end

--node滚动停止
function CandyBingoRespinView:respinNodeEndBeforeResCallBack(endNode)
      --判断是否是该列最后一个格子滚动结束
      local lastColNodeRow = endNode.p_rowIndex 
      for i=1,#self.m_respinNodes do
            local respinNode = self.m_respinNodes[i]
            if respinNode.p_colIndex == endNode.p_cloumnIndex then
                  if respinNode.p_rowIndex < lastColNodeRow  then
                        lastColNodeRow = respinNode.p_rowIndex 
                  end
            end
      end
      if endNode.p_rowIndex  == lastColNodeRow then
            self:oneReelDown(endNode.p_cloumnIndex)
      end
end

--repsinNode滚动完毕后 置换层级
function CandyBingoRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

-- function CandyBingoRespinView:getRespinEndNode(iX, iY)
--       local childs = self:getChildren()

--       for i=1,#childs do
--             local node = childs[i]

--             if node:getTag() == self.REPIN_NODE_TAG and node.p_rowIndex == iX  and node.p_cloumnIndex == iY then
--                   return node
--             end
--       end
--       print("RESPINNODE NOT END!!!")
--       return nil
-- end

function CandyBingoRespinView:oneReelDown(iCol)
      self.m_Machine:slotLocalOneReelDown(iCol)  
end

function CandyBingoRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            endNode:runAnim(info.runEndAnimaName, false)
      end
      -- body
end

--组织滚动信息 开始滚动
function CandyBingoRespinView:startMove()
      self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
      self.m_respinNodeRunCount = 0
      self.m_respinNodeStopCount = 0
      for i=1,#self.m_respinNodes do
            if self.m_respinNodes[i].p_rowIndex == 3 and self.m_respinNodes[i].p_colIndex == 3  then
                  print("中间的wild不用滚")
            else
                  self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                  self.m_respinNodes[i]:startMove()
            end
            

      end
end

function CandyBingoRespinView:getBaseRunNum()
      return self.m_baseRunNum
end

function CandyBingoRespinView:setBaseRunNum(num)
      self.m_baseRunNum = num
end

function CandyBingoRespinView:setBaseColInterVal(num)
      BASE_COL_INTERVAL = num
end

function CandyBingoRespinView:getPosReelIdx(iRow, iCol)
      local index = (5 - iRow) * 5 + (iCol - 1)
      -- print(index .. "  ------------")
      return index + 1
end

function CandyBingoRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
      for j=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[j]
            local bFix = false 

            -- local runInfo =  {0,4,8,12,16,
            --                   1,5,9,13,17,
            --                   2,6,10,14,18,
            --                   3,7,11,15,19,
            --                   4,8,12,16,20}
            -- local index = self:getPosReelIdx(repsinNode.p_rowIndex,repsinNode.p_colIndex)
            -- local runLong = self.m_baseRunNum + runInfo[index]  * BASE_ROW_ADD_NUM 
            
            -- 每格间隔 -> 每列间隔
            --正常滚动时 起始滚动长度 15 列递增 5
            local runLong = self.m_baseRunNum + (repsinNode.p_colIndex - 1)  * BASE_ROW_ADD_NUM 
            for i=1, #storedNodeInfo do
                  local runDatelong =  runLong 
                  local stored = storedNodeInfo[i]
                  if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                        repsinNode:setRunInfo(runDatelong, stored.type)
                        bFix = true
                  end
            end
            
            for i=1,#unStoredReels do
                  local data = unStoredReels[i]
                  local runDatelong =  runLong 
                  if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                        repsinNode:setRunInfo(runDatelong, data.type)
                  end
            end
      end
end

--坐标获取RepsinNode
function CandyBingoRespinView:getRespinNode(iX, iY)
      for i=1,#self.m_respinNodes do
            local respinNode = self.m_respinNodes[i]
            if respinNode.p_rowIndex == iX and respinNode.p_colIndex == iY then
                  return respinNode
            end
      end
      return nil
end

--是否参与结算
function CandyBingoRespinView:getPartCleaningNode(iX, iY)
      for i=1,#self.m_machineElementData do
            local data = self.m_machineElementData[i]
            if data.ArrayPos.iX == iX and data.ArrayPos.iY == iY and data.bCleaning then
                  local respinNode = self:getRespinNode(iX, iY)
                  if respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
                        return true
                  end
            end
      end
      return false
end

---获取所有参与结算节点
function CandyBingoRespinView:getAllCleaningNode()
      --从左到右排序 从上到下
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
      for iRow = self.m_machineRow , 1, -1 do
            
            local sameRowNode = {}
            for i = 1, #cleaningNodes do
                  local  node = cleaningNodes[i]
                  if node.p_rowIndex == iRow then
                        sameRowNode[#sameRowNode + 1] = node
                  end   
            end 
            table.sort( sameRowNode, function(a, b)
                  return a.p_cloumnIndex < b.p_cloumnIndex 
            end)

            for i=1,#sameRowNode do
                  sortNode[#sortNode + 1] = sameRowNode[i]
            end
      end
      cleaningNodes = sortNode
      return cleaningNodes
end

--获取所有固定信号
function CandyBingoRespinView:getFixSlotsNode()
      local fixSlotNode = {}
      local childs = self:getChildren()

      for i=1,#childs do
            local node = childs[i]
            if node:getTag() == self.REPIN_NODE_TAG  then
                  fixSlotNode[#fixSlotNode + 1] =  node
            end
      end
      return fixSlotNode
end

function CandyBingoRespinView:getRespinEndNode(iX, iY)
      local childs = self:getFixSlotsNode()

      for i=1,#childs do
            local node = childs[i]

            if node.p_rowIndex == iX  and node.p_cloumnIndex == iY then
                  return node
            end
      end
      print("RESPINNODE NOT END!!!")
      return nil
end

--获取所有最终停止信号
function CandyBingoRespinView:getAllEndSlotsNode()
      local endSlotNode = {}
      local childs = self:getChildren()

      for i=1,#childs do
            local node = childs[i]
            if node:getTag() == self.REPIN_NODE_TAG  then
                  endSlotNode[#endSlotNode + 1] =  node
            end
      end
      for i=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[i]
            if repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                  endSlotNode[#endSlotNode + 1] =  repsinNode:getLastNode()
            end
      end
      return endSlotNode
end


function CandyBingoRespinView:quicklyStop()
      self.m_isPlayedSound = false

      for i=1,#self.m_respinNodes do
            local repsinNode = self.m_respinNodes[i]
            if repsinNode:getNodeRunning() then
               repsinNode:quicklyStop()
            end
      end

      self:changeTouchStatus(ENUM_TOUCH_STATUS.QUICK_STOP)
end

function CandyBingoRespinView:changeTouchStatus(touchStatus)
   self.m_respinTouchStatus = touchStatus
end

function CandyBingoRespinView:getouchStatus()
   return self.m_respinTouchStatus
end
   
function CandyBingoRespinView:onEnter()
end

function CandyBingoRespinView:onExit()

end

return CandyBingoRespinView
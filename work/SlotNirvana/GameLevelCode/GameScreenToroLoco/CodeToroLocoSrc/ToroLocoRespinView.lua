
local ToroLocoPublicConfig = require "ToroLocoPublicConfig"
local ToroLocoRespinView = class("ToroLocoRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
    NORMAL = 100,
    REPSINNODE = 1,
}

function ToroLocoRespinView:ctor()
      ToroLocoRespinView.super.ctor(self)
      self.m_isQuickRun = false
      self.m_quickRunNode = nil
      self.SYMBOL_BONUS = 94
  end

function ToroLocoRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            endNode:runAnim(info.runEndAnimaName, false, function()
                  endNode:runAnim("idleframe2", true)
            end)
            if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
                  self.m_machine:setGameSpinStage(QUICK_RUN)
            end
            self.m_machine:playRespinViewJiManEffect()
            self.m_machine:checkPlayBonusDownSound(endNode)
      end
end

function ToroLocoRespinView:oneReelDown(colIndex)
      self.m_machine:respinOneReelDown(colIndex,self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP)
  end

function ToroLocoRespinView:createRespinNode(symbolNode, status)

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

      local colorNode = util_createAnimation("ToroLoco_Black.csb")
      colorNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
      self:addChild(colorNode, VIEW_ZORDER.REPSINNODE - 100)

      self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)

      respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex),130)
      respinNode.p_rowIndex = symbolNode.p_rowIndex
      respinNode.p_colIndex = symbolNode.p_cloumnIndex
      respinNode:initConfigData()
      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
            respinNode.m_baseFirstNode = symbolNode
            symbolNode:runAnim("idleframe2",true)
      else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end

      if symbolNode.p_symbolType == self.SYMBOL_BONUS then
            util_changeNodeParent(self,symbolNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex)
      end
      respinNode.m_runLastNodeType = symbolNode.p_symbolType
            
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function ToroLocoRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
      self.m_machineRow = machineRow 
      self.m_machineColmn = machineColmn
      self.m_startCallFunc = startCallFun
      self.m_respinNodes = {}
      self:setMachineType(machineColmn, machineRow)
      self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
      self.m_machineElementData = machineElement
      for i=1,#machineElement do
            local nodeInfo = machineElement[i]
            local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)
  
            local pos = self:convertToNodeSpace(nodeInfo.Pos)
            machineNode:setPosition(pos)
            self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
            machineNode:setVisible(nodeInfo.isVisible)
            if nodeInfo.isVisible then
                  -- print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end
  
            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end
  
      local linesNode = util_createAnimation("ToroLoco_RespinLins.csb")
      linesNode:setPosition(util_convertToNodeSpace(self.m_machine.m_respinNodeView:findChild("Node_respinlines"), self))
      self:addChild(linesNode, REEL_SYMBOL_ORDER.REEL_ORDER_2 + 100)
  
      self:readyMove()
end

--repsinNode滚动完毕后 置换层级
function ToroLocoRespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - endNode.p_rowIndex + endNode.p_cloumnIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

return ToroLocoRespinView
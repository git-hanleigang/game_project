
local VIEW_ZORDER =
{
      NORMAL = 100,
      REPSINNODE = 1,
}
local RespinView = util_require("Levels.RespinView")
local Christmas2021RespinView = class("Christmas2021RespinView", RespinView)
Christmas2021RespinView.m_updateFeatureNodeFun = nil
Christmas2021RespinView.m_WheelTipNode = nil

function Christmas2021RespinView:setUpdateCallFun(updateCallFun)
      self.m_updateFeatureNodeFun = updateCallFun
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function Christmas2021RespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

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
                  print("initRespinElement "..machineNode.p_cloumnIndex.." "..machineNode.p_rowIndex)
            end
            local status = nodeInfo.status
            self:createRespinNode(machineNode, status)
      end


      self.m_WheelTipNode = nil


      -- 添加转盘信号动画
      self:readyMove()
end

function Christmas2021RespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      for k = 1, #fixNode do
            local childNode = fixNode[k]
            childNode:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + self:getPosByColRow(childNode.p_cloumnIndex, childNode.p_rowIndex))
            childNode:runAnim("idleframe",true)
            if self:getClipNode(childNode.p_cloumnIndex,childNode.p_rowIndex) then
                  self:showClipXueHuaBg(self:getClipNode(childNode.p_cloumnIndex,childNode.p_rowIndex))
            end
      end
      
      performWithDelay(self,function()
            self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_startCallFunc then
                  self.m_startCallFunc()
            end

      end, 0.1)
end

function Christmas2021RespinView:showClipXueHuaBg(_clipNode)
      local xuehuaNode = util_createAnimation("Socre_Christmas2021_xuehua.csb")
      xuehuaNode:setPosition(cc.p(0 , 0))
      _clipNode:addChild(xuehuaNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
end

-- 根据行列得到自定义的 pos位置
function Christmas2021RespinView:getPosByColRow(col, row )
      if row == 1 then
          row = 3
      elseif row == 3 then
          row = 1
      end
      return (row - 1) * 5 + col
  end

function Christmas2021RespinView:initCrazyBombMachine(machine)
      self.m_machine = machine
end

function Christmas2021RespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil  then
            if self:getClipNode(endNode.p_cloumnIndex,endNode.p_rowIndex) then
                  self:showClipXueHuaBg(self:getClipNode(endNode.p_cloumnIndex,endNode.p_rowIndex))
            end
            endNode:runAnim("buling",false, function()
                  endNode:runAnim("idleframe",true)
                  
            end)
            endNode:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + self:getPosByColRow(endNode.p_cloumnIndex, endNode.p_rowIndex))
            gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_bonus_down.mp3")
      end
end

function Christmas2021RespinView:oneReelDown()
      gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_ReelDown.mp3")
end

function Christmas2021RespinView:createRespinNode(symbolNode, status)

      local respinNode = util_createView(self.m_respinNodeName)
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

      self:addChild(respinNode,VIEW_ZORDER.REPSINNODE)

      respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),200)
      respinNode.p_rowIndex = symbolNode.p_rowIndex
      respinNode.p_colIndex = symbolNode.p_cloumnIndex
      respinNode:initConfigData()
      if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
            self:createRespinNodeBg(symbolNode,cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()),2)

      else
            respinNode:setFirstSlotNode(symbolNode)
            respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
      end
      self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

end

--创建respinNodeBg
function Christmas2021RespinView:createRespinNodeBg(respinNode,pos,order)

      if respinNode:getChildByName("bg") then
            return
      end

      local info = {}
      info.width = 180
      info.height = 160
      info.shape = "1x1"
      local bg = util_createView("Christmas2021Src.Christmas2021BombBg")
      bg:changeImage(info)
      bg:setPosition(pos)
      local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2
      if order then
            zorder = order
      end
      bg:runCsbAction("start",false)
      self:addChild(bg,zorder)
      bg:setName("bg".. (respinNode.p_cloumnIndex + 5 * (respinNode.p_rowIndex-1)))

end

--repsinNode滚动完毕后 置换层级
function Christmas2021RespinView:respinNodeEndCallBack(endNode, status)
      --层级调换
      self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

      if status == RESPIN_NODE_STATUS.LOCK then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
            local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
            endNode:setPosition(pos)
            self:createRespinNodeBg(endNode,pos)
      end
      self:runNodeEnd(endNode)

      if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
      end
end

return Christmas2021RespinView
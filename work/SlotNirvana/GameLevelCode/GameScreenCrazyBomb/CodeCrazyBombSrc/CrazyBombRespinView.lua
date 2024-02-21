
local VIEW_ZORDER =
{
      NORMAL = 100,
      REPSINNODE = 1,
}

local CrazyBombRespinView = class("CrazyBombRespinView",
                                    util_require("Levels.RespinView"))
CrazyBombRespinView.m_updateFeatureNodeFun = nil
CrazyBombRespinView.m_WheelTipNode = nil

function CrazyBombRespinView:setUpdateCallFun(updateCallFun)
      self.m_updateFeatureNodeFun = updateCallFun
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function CrazyBombRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

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
      local data = self.m_machine.m_runSpinResultData.p_rsExtraData
      if data and data.wheel  then
            local pos =  self.m_machine:getTarSpPos(data.wheel )
            self:createWheelTip(pos,function()
                  self:readyMove()
            end)
      else
            self:readyMove()
      end

end



function CrazyBombRespinView:readyMove()

      -- self.m_WheelTipNode = nil

      -- self:createCrazyBombWangGe()

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

function CrazyBombRespinView:initCrazyBombMachine(machine)
      self.m_machine = machine
end


function CrazyBombRespinView:runNodeEnd(endNode)
      local info = self:getEndTypeInfo(endNode.p_symbolType)
      if info ~= nil  then
            endNode:runAnim("buling2",false, function()
                  endNode:runAnim("idleframe",true)
            end)
            endNode:setZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + endNode.p_cloumnIndex)
            gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_bonus_auto.mp3")


            -- 添加转盘信号动画
            local data = self.m_machine.m_runSpinResultData.p_rsExtraData
            if data and data.wheel  then
                  local pos =  self.m_machine:getTarSpPos(data.wheel )
                  self:createWheelTip(pos)
            end



      end
end


function CrazyBombRespinView:createWheelTip(pos,func)

      if self.m_WheelTipNode then
           -- print("已经创建了--- m_WheelTipNode")
            if func then
                  func()
            end
      else

            self.m_WheelTipNode = util_createView("CodeCrazyBombSrc.CrazyBombWheelSymbolTip")

            self.m_WheelTipNode:runCsbAction("luanpan_chuxian",false,function()
                  self.m_WheelTipNode:runCsbAction("lunpan_idle",true)

                  if func then
                        func()
                  end
            end)

            self:addChild(self.m_WheelTipNode,9999)
            self.m_machine:setWheelTipNode(self.m_WheelTipNode)
            gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_little_wheel_appear.mp3")
      end



      -- local wordPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
      -- local curPos = cc.p(self:convertToNodeSpace(wordPos))

      self.m_WheelTipNode:setPosition(pos)
end


function CrazyBombRespinView:oneReelDown()
      gLobalSoundManager:playSound("CrazyBombSounds/music_CrazyBomb_reel_stop.mp3")
end


function CrazyBombRespinView:createCrazyBombWangGe( )

     self.m_WangGeBg = util_createView("CodeCrazyBombSrc.CrazyBombWangGe")

      self:addChild(self.m_WangGeBg,10)
end

function CrazyBombRespinView:createRespinNode(symbolNode, status)

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
function CrazyBombRespinView:createRespinNodeBg(respinNode,pos,order)

      if respinNode:getChildByName("bg") then
            return
      end

      local info = {}
      info.width = 194
      info.height = 158
      info.shape = "1x1"
      local bg = util_createView("CodeCrazyBombSrc.CrazyBombBombBg")
      bg:changeImage(info)
      bg:setPosition(pos)
      local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2
      if order then
            zorder = order
      end

      self:addChild(bg,zorder)
      bg:setName("bg")

end


--repsinNode滚动完毕后 置换层级
function CrazyBombRespinView:respinNodeEndCallBack(endNode, status)
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

return CrazyBombRespinView
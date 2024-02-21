
local PublicConfig = require "AChristmasCarolPublicConfig"
local AChristmasCarolRespinView = class("AChristmasCarolRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = 
{
    NORMAL = 100,
    REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3

function AChristmasCarolRespinView:ctor()
    AChristmasCarolRespinView.super.ctor(self)
    self.SYMBOL_RESPIN_BONUS1 = 97
    self.SYMBOL_RESPIN_BONUS2 = 98
end

function AChristmasCarolRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
        endNode:runAnim(info.runEndAnimaName, false,function(  )
            endNode:runAnim("idleframe1", true)
        end)

        if endNode then
            if self.m_machine.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_machine.m_isPlayUpdateRespinNums then
                self.m_machine:changeReSpinUpdateUI(self.m_machine.m_runSpinResultData.p_reSpinCurCount)
                self.m_machine.m_isPlayUpdateRespinNums = false
            end

            if self.m_machine.m_isMiniMachine then
                if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
                    self.m_machine.m_parent:setGameSpinStage(QUICK_RUN)
                end
            else
                if self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
                    self.m_machine:setGameSpinStage(QUICK_RUN)
                end
            end
            
            self.m_machine:checkPlayBonusDownSound(endNode)
            --添加集满光效
            self:addRespinJiManLightEffect(endNode)
        end
    end
end

function AChristmasCarolRespinView:addRespinJiManLightEffect(_endNode)
    --判断是否是该列最后一个格子滚动结束
    local lastColNodeRow = _endNode.p_rowIndex 
    for i=1,#self.m_respinNodes do
          local respinNode = self.m_respinNodes[i]
          if respinNode.p_colIndex == _endNode.p_cloumnIndex and respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                if respinNode.p_rowIndex ~= lastColNodeRow  then
                      lastColNodeRow = respinNode.p_rowIndex 
                end
          end
    end
    if _endNode.p_rowIndex == lastColNodeRow then
        self.m_machine:showJiManEffect(self.m_machine.m_isMiniMachine, _endNode.p_cloumnIndex)
    end
end

---获取所有参与结算节点
function AChristmasCarolRespinView:getAllCleaningNode()
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

function AChristmasCarolRespinView:createRespinNode(symbolNode, status)
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

    -- local colorNode = util_createAnimation("AChristmasCarol_respin_diban.csb")
    -- colorNode:setPosition(cc.p(symbolNode:getPositionX(),symbolNode:getPositionY()))
    -- self:addChild(colorNode, VIEW_ZORDER.REPSINNODE - 100)

    self:addChild(respinNode, VIEW_ZORDER.REPSINNODE)
    
    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or (self:getTypeIsEndType(symbolNode.p_symbolType) == true and not self:getCollectStatus(symbolNode)) then
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
        respinNode.m_baseFirstNode = symbolNode
        symbolNode:runAnim("idleframe1",true)
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    if symbolNode.p_symbolType == self.SYMBOL_RESPIN_BONUS1 or symbolNode.p_symbolType == self.SYMBOL_RESPIN_BONUS2 then
        util_changeNodeParent(self,symbolNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex)
    end

    respinNode.m_runLastNodeType = symbolNode.p_symbolType
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

function AChristmasCarolRespinView:getCollectStatus(_symbolNode)
    if self.m_machine.m_isMiniMachine then
        if self.m_machine.m_runSpinResultData.p_rsExtraData.collect_up and #self.m_machine.m_runSpinResultData.p_rsExtraData.collect_up > 0 then
            for _, _data in ipairs(self.m_machine.m_runSpinResultData.p_rsExtraData.collect_up) do
                local fixPos = self.m_machine:getRowAndColByPos(_data[1])
                if fixPos.iX == _symbolNode.p_rowIndex and fixPos.iY == _symbolNode.p_cloumnIndex then
                    return true
                end
            end
        end
        return false
    else
        if self.m_machine.m_runSpinResultData.p_rsExtraData.collect and #self.m_machine.m_runSpinResultData.p_rsExtraData.collect > 0 then
            for _, _data in ipairs(self.m_machine.m_runSpinResultData.p_rsExtraData.collect) do
                local fixPos = self.m_machine:getRowAndColByPos(_data[1])
                if fixPos.iX == _symbolNode.p_rowIndex and fixPos.iY == _symbolNode.p_cloumnIndex then
                    return true
                end
            end
        end
        return false
    end
end

--repsinNode滚动完毕后 置换层级
function AChristmasCarolRespinView:respinNodeEndCallBack(endNode, status)
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
        self.m_machine:reSpinReelDown()
    end
end

function AChristmasCarolRespinView:oneReelDown(colIndex)
    self.m_machine:respinOneReelDown(colIndex,self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP)
end

return AChristmasCarolRespinView
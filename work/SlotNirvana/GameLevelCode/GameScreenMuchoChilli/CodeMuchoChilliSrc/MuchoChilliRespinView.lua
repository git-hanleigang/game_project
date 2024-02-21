---
--xcyy
--2018年5月23日
--MuchoChilliRespinView.lua
local MuchoChilliRespinView = class("MuchoChilliRespinView",util_require("Levels.RespinView"))
local PublicConfig = require "MuchoChilliPublicConfig"

local VIEW_ZORDER = 
{
    NORMAL = 100,
    REPSINNODE = 1,
}

--滚动参数
local BASE_RUN_NUM = 20

local BASE_COL_INTERVAL = 3


function MuchoChilliRespinView:ctor()
    MuchoChilliRespinView.super.ctor(self)
    self.m_isQuickRun = false
    self.m_quickRunNode = nil
    self.SYMBOL_BONUS = 94
    self.SYMBOL_SPECIAL_BONUS = 95
end

function MuchoChilliRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
        endNode:runAnim(info.runEndAnimaName, false,function(  )
            endNode:runAnim("idleframe2", true)
        end)

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

        if endNode then
            if self.m_machine.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_machine.m_isPlayUpdateRespinNums then
                self.m_machine:changeReSpinUpdateUI(self.m_machine.m_runSpinResultData.p_reSpinCurCount)
                self.m_machine.m_isPlayUpdateRespinNums = false
            end
        end
    end
end

---获取所有参与结算节点
function MuchoChilliRespinView:getAllCleaningNode()
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

function MuchoChilliRespinView:createRespinNode(symbolNode, status)

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

    local colorNode = util_createAnimation("Socre_MuchoChilli_Empty.csb")
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
    if self.m_machine.m_isMiniMachine then
        if self.m_machine.m_parent:getIsPlayEffect() or self.m_machine.m_parent:isTriggerBonus() then
            if symbolNode.p_symbolType == self.SYMBOL_BONUS or symbolNode.p_symbolType == self.SYMBOL_SPECIAL_BONUS then
                symbolNode:setVisible(false)
            end
        end
    end
    if symbolNode.p_symbolType == self.SYMBOL_BONUS or symbolNode.p_symbolType == self.SYMBOL_SPECIAL_BONUS then
        util_changeNodeParent(self,symbolNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - symbolNode.p_rowIndex + symbolNode.p_cloumnIndex)
    end
    respinNode.m_runLastNodeType = symbolNode.p_symbolType
      
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

--repsinNode滚动完毕后 置换层级
function MuchoChilliRespinView:respinNodeEndCallBack(endNode, status)
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

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function MuchoChilliRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
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

    local linesNode = util_createAnimation("MuchoChilli_respinLines.csb")
    linesNode:setPosition(util_convertToNodeSpace(self.m_machine:findChild("Node_respinlines"), self))
    self:addChild(linesNode, REEL_SYMBOL_ORDER.REEL_ORDER_2 + 100)

    self:readyMove()
end

function MuchoChilliRespinView:oneReelDown(colIndex)
    self.m_machine:respinOneReelDown(colIndex,self:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP)
end

return MuchoChilliRespinView
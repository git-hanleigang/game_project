local MagicLadyRespinView = class("MagicLadyRespinView", util_require("Levels.RespinView"))

MagicLadyRespinView.m_animaState = 1

function MagicLadyRespinView:ctor()
    MagicLadyRespinView.super.ctor(self)
    self.m_wheelIndex = 0--轮盘编号
    self.m_isHaveNewLightingTab = {}--存储每一列是否有新的lighitng图标出现
    self.m_lightingNum = 0--本轮盘已经有lighting图标个数
end

function MagicLadyRespinView:initUI(respinNodeName)
    self.m_respinNodeName = respinNodeName 
    self.m_baseRunNum = 20--基础滚动数量
    self:setBaseColInterVal(7)--列之间滚动数量差
 end

--增加lighting图标计数，并监测改变背景音乐
function MagicLadyRespinView:addLightingNum()
    self.m_lightingNum = self.m_lightingNum + 1
    if self.m_lightingNum == 12 then
        gLobalNoticManager:postNotification("CodeGameScreenMagicLadyMachine_changeRespinBg")
    end
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function MagicLadyRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    self.m_machineRow = machineRow 
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    self:setMachineType(machineColmn, machineRow)
    self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE,{
        clipOffsetSize = cc.size(0,1),
        -- clipOffsetPos = cc.p(0,-0.5)
    })
    -- self:changeClipRowNode(1,cc.p(0,-1)) --修正位置
    -- self:changeClipRowNode(3,cc.p(0,1)) --修正位置
    self.m_machineElementData = machineElement
    for i=1,#machineElement do
          local nodeInfo = machineElement[i]
          local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

          local pos = self:convertToNodeSpace(nodeInfo.Pos)
          machineNode:setPosition(pos)
          self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
          machineNode:setVisible(nodeInfo.isVisible)

          local status = nodeInfo.status
          self:createRespinNode(machineNode, status)
    end

    self:readyMove()
end

function MagicLadyRespinView:setAnimaState(state)
    self.m_animaState = state
    if self.m_respinNodes then
        for i = 1, #self.m_respinNodes do
            self.m_respinNodes[i]:setAnimaState(state)
        end
    end
end
function MagicLadyRespinView:createRespinNode(symbolNode, status)
    local respinNode = util_createView(self.m_respinNodeName)

    respinNode:setAnimaState(self.m_animaState)

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

    self:addChild(respinNode,1)

    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex),180)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
        self.m_lightingNum = self.m_lightingNum + 1
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

end
function MagicLadyRespinView:readyMove()
    local fixNode = self:getFixSlotsNode()
    local nBeginAnimTime = 0
    local tipTime = 0

    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_startCallFunc then
        self.m_startCallFunc()
    end
end

--开始滚动
function MagicLadyRespinView:startMove()
    self.m_isHaveNewLightingTab = {}
    MagicLadyRespinView.super.startMove(self)
end
--一个滚轴滚动结束
function MagicLadyRespinView:runNodeEnd(endNode)
    if endNode then
        local info = self:getEndTypeInfo(endNode.p_symbolType)
        if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
            endNode:runAnim(info.runEndAnimaName, false,function ()
                endNode:runAnim("idleframe",true)
            end)
        end
    end
end
--判断轮盘是否停止滚动
function MagicLadyRespinView:wheelIsAllStop()
    --当前轮滚动的滚轴个数等于了滚动停止的滚轴个数，说明本轮盘完全停止了
    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
        return true
    end
    return false
end

--一个node落地 未反弹前
function MagicLadyRespinView:respinNodeEndBeforeResCallBack(endNode)
    --判断是否是该列最后一个格子滚动结束
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info then
        for i=1,#self.m_respinNodes do
            local respinNode = self.m_respinNodes[i]
            if respinNode.p_colIndex == endNode.p_cloumnIndex and respinNode.p_rowIndex == endNode.p_rowIndex and respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                self.m_isHaveNewLightingTab[endNode.p_cloumnIndex] = true
                self:addLightingNum()
            end
        end
    end

    MagicLadyRespinView.super.respinNodeEndBeforeResCallBack(self,endNode)
end
function MagicLadyRespinView:oneReelDown(col)
    gLobalNoticManager:postNotification("CodeGameScreenMagicLadyMachine_reSpinOneWheelOneReelDown",{col,self.m_wheelIndex})
end
--计算本轮盘某一列是否有可滚动的滚轴（在一列滚轴落地、滚轴状态未改变前时调用，）
function MagicLadyRespinView:isHaveNoLockRespinNode(col)
    for i=1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[i]
        if respinNode.p_colIndex == col and respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            return true
        end
    end
    return false
end
---获取所有参与结算节点
function MagicLadyRespinView:getAllCleaningNode()
    --从 从上到下 左到右排序
    local cleaningNodes = {}
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
            cleaningNodes[#cleaningNodes + 1] = node
        end
    end

    --排序
    local sortNode = {}
    for iCol = 1, self.m_machineColmn do
        local sameRowNode = {}
        for i = 1, #cleaningNodes do
            local node = cleaningNodes[i]
            if node.p_cloumnIndex == iCol then
                sameRowNode[#sameRowNode + 1] = node
            end
        end
        table.sort(
            sameRowNode,
            function(a, b)
                return b.p_rowIndex < a.p_rowIndex
            end
        )

        for i = 1, #sameRowNode do
            sortNode[#sortNode + 1] = sameRowNode[i]
        end
    end
    cleaningNodes = sortNode
    return cleaningNodes
end

--根据行列获取世界坐标
function MagicLadyRespinView:getWorldPosByColRow(col,row)
    local respinNode = self:getRespinNode(row,col)
    local worldPos = respinNode:getParent():convertToWorldSpace(cc.p(respinNode:getPosition()))
    return worldPos
end
return MagicLadyRespinView

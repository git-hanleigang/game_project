------
---
---
------
local FortuneCatsRespinView = class("FortuneCatsRespinView", util_require("Levels.BaseRespin"))

FortuneCatsRespinView.REPIN_NODE_TAG = 1000

FortuneCatsRespinView.m_respinNodeName = nil
FortuneCatsRespinView.SYMBOL_ReSpin_CAT = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

--滚动状态
GD.ENUM_TOUCH_STATUS = {
    UNDO = 1, ---等待状态 不允许点击
    ALLOW = 2, ---允许点击
    WATING = 3, --等待滚动
    RUN = 4, ---滚动状态
    QUICK_STOP = 5 ---快滚状态
}

FortuneCatsRespinView.m_respinTouchStatus = nil

local VIEW_ZORDER = {
    NORMAL = 100,
    REPSINNODE = 1
}

--滚动参数
local BASE_RUN_NUM = 17

local BASE_COL_INTERVAL = 6

local BASE_ROW_ADD_NUM = 3

FortuneCatsRespinView.m_baseRunNum = nil
FortuneCatsRespinView.m_machineElementData = nil --初始化repsin盘面时信息

FortuneCatsRespinView.m_respinNodes = nil --初始化repsin盘面时信息

--m_respinNodeRunCount == m_respinNodeStopCount轮盘停止了 滚动
FortuneCatsRespinView.m_respinNodeRunCount = nil --respinNode滚动个数
FortuneCatsRespinView.m_respinNodeStopCount = nil --repsinNode停止滚动个数
FortuneCatsRespinView.m_machineRow = nil --关卡轮盘行数
FortuneCatsRespinView.m_machineColmn = nil --关卡轮盘列数
FortuneCatsRespinView.m_startCallFunc = nil --开始转动喊数

FortuneCatsRespinView.m_Machine = nil --开始转动喊数

function FortuneCatsRespinView:initUI(respinNodeName, machine)
    self.m_respinNodeName = respinNodeName
    self.m_baseRunNum = BASE_RUN_NUM
    self.m_Machine = machine
    self.m_isPlayedSound = false

end

--初始化变量
function FortuneCatsRespinView:initData()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.UNDO
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function FortuneCatsRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    self.m_machineRow = machineRow
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    self:setMachineType(machineColmn, machineRow)
    -- self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE) --招财猫暂时弃用新裁切
    self.m_machineElementData = machineElement
    for i = 1, #machineElement do
        local nodeInfo = machineElement[i]
        local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)

        local pos = self:convertToNodeSpace(nodeInfo.Pos)
        machineNode:setPosition(pos)
        self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
        machineNode:setVisible(nodeInfo.isVisible)
        -- if nodeInfo.isVisible then
        --     print("initRespinElement " .. machineNode.p_cloumnIndex .. " " .. machineNode.p_rowIndex)
        -- end

        local status = nodeInfo.status
        self:createRespinNode(machineNode, status)
    end
    self:readyMove()
end

--将FortuneCatsRespinView元素放入respinNode做移动准备工作
--可以重写播放进入respin时动画
function FortuneCatsRespinView:readyMove()
    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_startCallFunc then
        self.m_startCallFunc()
    end
end

function FortuneCatsRespinView:createRespinNode(symbolNode, status)
    local respinNode = util_createView(self.m_respinNodeName, self)
    respinNode:setCreateAndPushSymbolFun(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
    respinNode:setEndSymbolType(self.m_symbolTypeEnd, self.m_symbolRandomType)
    respinNode:initRespinSize(self.m_slotNodeWidth, self.m_slotNodeHeight, self.m_slotReelWidth, self.m_slotReelHeight)
    respinNode:setMachineType(self.m_machineColmn, self.m_machineRow)

    respinNode:setPosition(cc.p(symbolNode:getPositionX(), symbolNode:getPositionY()))
    respinNode:setReelDownCallBack(
        function(symbolType, status)
            if self.respinNodeEndCallBack ~= nil then
                self:respinNodeEndCallBack(symbolType, status)
            end
        end,
        function(symbolType)
            if self.respinNodeEndBeforeResCallBack ~= nil then
                self:respinNodeEndBeforeResCallBack(symbolType)
            end
        end
    )

    self:addChild(respinNode, VIEW_ZORDER.REPSINNODE)
    
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initClipNode()--招财猫暂时弃用新裁切
    respinNode:initConfigData()
    respinNode:setFirstSlotNode(symbolNode)
    respinNode.b_addReel = bAddReel
    respinNode.b_addNode = bAddReel
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

--node滚动停止
function FortuneCatsRespinView:respinNodeEndBeforeResCallBack(endNode)
    --判断是否是该列最后一个格子滚动结束
    local lastRow = endNode.p_rowIndex
    local lastCol = endNode.p_cloumnIndex
    self:oneReelDown(lastCol,lastRow)
end

--repsinNode滚动完毕后 置换层级
function FortuneCatsRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    if status == RESPIN_NODE_STATUS.LOCK then
        local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
        local pos = self:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
            endNode:setTag(self.REPIN_NODE_TAG)
        endNode:setPosition(pos)
    end
    self:runNodeEnd(endNode)
    if self.m_respinNodeStopCount == self.m_respinNodeRunCount then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
    end
end

-- function FortuneCatsRespinView:getRespinEndNode(iX, iY)
--     local childs = self:getChildren()

--     for i = 1, #childs do
--         local node = childs[i]

--         if node:getTag() == self.REPIN_NODE_TAG and node.p_rowIndex == iX and node.p_cloumnIndex == iY then
--             return node
--         end
--     end
--     -- print("RESPINNODE NOT END!!!")
--     return nil
-- end

function FortuneCatsRespinView:oneReelDown(iCol,iRow)
    self.m_Machine:slotLocalOneReelDown(iCol,iRow)

end

function FortuneCatsRespinView:runNodeEnd(endNode)
    
    self.m_Machine:createOneActionSymbol(endNode)

end

--组织滚动信息 开始滚动
function FortuneCatsRespinView:startMove()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    for i = 1, #self.m_respinNodes do
        if self.m_Machine.m_bProduceSlots_InFreeSpin then
            if (self.m_respinNodes[i].p_rowIndex == 3 and self.m_respinNodes[i].p_colIndex == 1)
            or (self.m_respinNodes[i].p_rowIndex == 2 and self.m_respinNodes[i].p_colIndex == 2)
            or (self.m_respinNodes[i].p_rowIndex == 1 and self.m_respinNodes[i].p_colIndex == 3)  then
                print("1,5,9固定不滚动")
            else
                if  self.m_Machine.m_addRepin then
                    local isMove = true
                    for j=1,#self.m_Machine.m_RespinSymbol do
                        local data = self.m_Machine.m_RespinSymbol[j]
                        if self.m_respinNodes[i].p_colIndex == data.icol and self.m_respinNodes[i].p_rowIndex == data.irow then
                            isMove = false
                            break
                        end
                    end
                    if isMove then
                        self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                        self.m_respinNodes[i]:startMove()
                    end
                else
                    self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                    self.m_respinNodes[i]:startMove()
                end

            end
        elseif  self.m_Machine.m_addRepin then
            local isMove = true
            for j=1,#self.m_Machine.m_RespinSymbol do
                local data = self.m_Machine.m_RespinSymbol[j]
                if self.m_respinNodes[i].p_colIndex == data.icol and self.m_respinNodes[i].p_rowIndex == data.irow then
                    isMove = false
                    break
                end
            end
            if isMove then
                self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                self.m_respinNodes[i]:startMove()
            end
        else
            self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
            self.m_respinNodes[i]:startMove()
        end
    end
end

--将1，5，9 变为scatter
function FortuneCatsRespinView:getChangeFreeSpinSlotsNode()
    local endSlotNode = {}
    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        if (self.m_respinNodes[i].p_rowIndex == 3 and self.m_respinNodes[i].p_colIndex == 1)
        or (self.m_respinNodes[i].p_rowIndex == 2 and self.m_respinNodes[i].p_colIndex == 2)
        or (self.m_respinNodes[i].p_rowIndex == 1 and self.m_respinNodes[i].p_colIndex == 3)  then
            local node  = repsinNode:getLastNode()
            if node then
                endSlotNode[#endSlotNode + 1] = node
            end
        end

    end
    return endSlotNode
end

function FortuneCatsRespinView:getBaseRunNum()
    return self.m_baseRunNum
end

function FortuneCatsRespinView:setBaseRunNum(num)
    self.m_baseRunNum = num
end

function FortuneCatsRespinView:setBaseColInterVal(num)
    BASE_COL_INTERVAL = num
end

function FortuneCatsRespinView:getPosReelIdx(iRow, iCol)
  
    local   index = (self.m_Machine.m_iReelRowNum - iRow) * self.m_Machine.m_iReelColumnNum + (iCol - 1)
    
    return index + 1
end

function FortuneCatsRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    for j = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local bFix = false
        local runInfo = {
            0,1,2,
            3,4,5,
            6,7,8}
        local index = self:getPosReelIdx(repsinNode.p_rowIndex, repsinNode.p_colIndex)
        local runLong = self.m_baseRunNum + runInfo[index] * BASE_ROW_ADD_NUM
        for i = 1, #storedNodeInfo do
            local runDatelong = runLong
            local stored = storedNodeInfo[i]
            if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                repsinNode:setRunInfo(runDatelong, stored.type)
                bFix = true
            end
        end

        for i = 1, #unStoredReels do
            local data = unStoredReels[i]
            local runDatelong = runLong
            if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then
                repsinNode:setRunInfo(runDatelong, data.type)
            end
        end
    end
end

function FortuneCatsRespinView:setRunRespinNodeLong(longNum)
    for j = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        repsinNode:setRunLongNum(longNum)
    end
end
--坐标获取RepsinNode
function FortuneCatsRespinView:getRespinNode(iX, iY)
    for i = 1, #self.m_respinNodes do
        local respinNode = self.m_respinNodes[i]
        if respinNode.p_rowIndex == iX and respinNode.p_colIndex == iY then
            return respinNode
        end
    end
    return nil
end

--获取所有固定信号
function FortuneCatsRespinView:getFixSlotsNode()
    local fixSlotNode = {}
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG then
            fixSlotNode[#fixSlotNode + 1] = node
        end
    end
    return fixSlotNode
end

function FortuneCatsRespinView:getRespinEndNode(iX, iY)
    local childs = self:getFixSlotsNode()

    for i = 1, #childs do
        local node = childs[i]

        if node.p_rowIndex == iX and node.p_cloumnIndex == iY then
            return node
        end
    end
    -- print("RESPINNODE NOT END!!!")
    return nil
end

--获取所有最终停止信号
function FortuneCatsRespinView:getAllEndSlotsNode()
    local endSlotNode = {}
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG then
            endSlotNode[#endSlotNode + 1] = node
        end
    end
    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        -- if repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
        endSlotNode[#endSlotNode + 1] = repsinNode:getLastNode()
        -- end
    end
    return endSlotNode
end

function FortuneCatsRespinView:playFreespinCatIdle()

    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        local node  = repsinNode:getLastNode()
        if node.p_symbolType == self.SYMBOL_ReSpin_CAT then
            node:runAnim("idle2")
        else
            node:runAnim("idleframe")
        end
    end
    
end


function FortuneCatsRespinView:playReSpinCatIdle()

    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        local node  = repsinNode:getLastNode()
        if node.p_symbolType == self.SYMBOL_ReSpin_CAT then
            node:runAnim("idle2",true)
        end
    end
    
end

function FortuneCatsRespinView:changeImage()

    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        local node  = repsinNode:getLastNode()
        if node then
            node:changeImage()
        end
    end
    
end

function FortuneCatsRespinView:removeAllSlotsNodeMark()
    local endSlotNode = {}
    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        local node  = repsinNode:getLastNode()
        if node.m_icon then
            node.m_icon:stopAllActions()
            node.m_icon:removeFromParent()
            node.m_icon = nil
        end
    end
end

function FortuneCatsRespinView:shopPos()
    local endSlotNode = {}
    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        local node  = repsinNode:getLastNode()
        if node then
            local slotParent = node:getParent()
            local posWorld = slotParent:convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
            local iRow = node.p_rowIndex 
            local iCol =  node.p_cloumnIndex
            print("Respin轮盘 " .. iCol .."列" .. iRow .. "行" .."posWorld.x ===" .. posWorld.x  .. "posWorld.y ==="  .. posWorld.y)
        end
    end
end

function FortuneCatsRespinView:quicklyStop()
    self.m_isPlayedSound = false

    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        if repsinNode:getNodeRunning() then
            repsinNode:quicklyStop()
        end
    end

    self:changeTouchStatus(ENUM_TOUCH_STATUS.QUICK_STOP)
end

function FortuneCatsRespinView:changeTouchStatus(touchStatus)
    self.m_respinTouchStatus = touchStatus
end

function FortuneCatsRespinView:getouchStatus()
    return self.m_respinTouchStatus
end

function FortuneCatsRespinView:onEnter()
end

function FortuneCatsRespinView:onExit()

end

return FortuneCatsRespinView

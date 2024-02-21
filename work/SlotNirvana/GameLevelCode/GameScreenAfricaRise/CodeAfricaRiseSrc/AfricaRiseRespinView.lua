------
---
---
------
local AfricaRiseRespinView = class("AfricaRiseRespinView", util_require("Levels.BaseRespin"))

AfricaRiseRespinView.REPIN_NODE_TAG = 1000

AfricaRiseRespinView.m_respinNodeName = nil
AfricaRiseRespinView.SYMBOL_WILD_X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 107
AfricaRiseRespinView.SYMBOL_SPIN_ADD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 108
--滚动状态
GD.ENUM_TOUCH_STATUS = {
    UNDO = 1, ---等待状态 不允许点击
    ALLOW = 2, ---允许点击
    WATING = 3, --等待滚动
    RUN = 4, ---滚动状态
    QUICK_STOP = 5 ---快滚状态
}

AfricaRiseRespinView.m_respinTouchStatus = nil

local VIEW_ZORDER = {
    NORMAL = 100,
    REPSINNODE = 1
}

--滚动参数
local BASE_RUN_NUM = 15

local BASE_COL_INTERVAL = 6

local BASE_ROW_ADD_NUM = 2

AfricaRiseRespinView.m_baseRunNum = nil
AfricaRiseRespinView.m_machineElementData = nil --初始化repsin盘面时信息

AfricaRiseRespinView.m_respinNodes = nil --初始化repsin盘面时信息

--m_respinNodeRunCount == m_respinNodeStopCount轮盘停止了 滚动
AfricaRiseRespinView.m_respinNodeRunCount = nil --respinNode滚动个数
AfricaRiseRespinView.m_respinNodeStopCount = nil --repsinNode停止滚动个数
AfricaRiseRespinView.m_machineRow = nil --关卡轮盘行数
AfricaRiseRespinView.m_machineColmn = nil --关卡轮盘列数
AfricaRiseRespinView.m_startCallFunc = nil --开始转动喊数

AfricaRiseRespinView.m_Machine = nil --开始转动喊数

function AfricaRiseRespinView:initUI(respinNodeName, machine)
    self.m_respinNodeName = respinNodeName
    self.m_baseRunNum = BASE_RUN_NUM
    self.m_Machine = machine
    self.m_isPlayedSound = false
    self.m_bFirstMove = true
end

--初始化变量
function AfricaRiseRespinView:initData()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.UNDO
end

--将machine盘面放入repsin中
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
--{ status = RESPIN_NODE_STATUS.IDLE, bCleaning = true , isVisible = true , Type = symbolType, Zorder = zorder, Tag = tag, Pos = pos, ArrayPos = arrayPos}
function AfricaRiseRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    self.m_machineRow = machineRow
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    self:setMachineType(machineColmn, machineRow)
    self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
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
        self:createRespinNode(machineNode, status, false)
    end
    self.m_bFirstMove = true
    self:readyMove()
end

--将machine盘面放入repsin中
function AfricaRiseRespinView:initAddReelRespinElement(machineElement, machineRow, machineColmn, startCallFun)
    local addNodeList = {}
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
        local node = self:createRespinNode(machineNode, status, true)
        table.insert(addNodeList, node)
    end

    self:changeAddReelLength(addNodeList)
    self.m_bFirstMove = false
    self:readyMove()
end

function AfricaRiseRespinView:removeAddReelRespinElement()
    for i = 1, #self.m_respinNodes do
        local respinNode = self.m_respinNodes[i]
        if respinNode.b_addNode == true then
            respinNode:removeFromParent()
            self.m_respinNodes[i] = nil
        end
    end
    self.m_bFirstMove = true
end

--将AfricaRiseRespinView元素放入respinNode做移动准备工作
--可以重写播放进入respin时动画
function AfricaRiseRespinView:readyMove()
    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_startCallFunc then
        self.m_startCallFunc()
    end
end

function AfricaRiseRespinView:createRespinNode(symbolNode, status, bAddReel)
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

    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex,symbolNode.p_rowIndex))
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    respinNode:setFirstSlotNode(symbolNode)
    respinNode.b_addReel = bAddReel
    respinNode.b_addNode = bAddReel
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode

    if bAddReel then
        local rect = respinNode.m_clipNode:getClippingRegion()
        respinNode.m_clipNode:setClippingRegion(
            {
                x = rect.x,
                y = rect.y,
                width = rect.width,
                height = 0
            }
        )
    end
    return respinNode
end

--设置基础轮盘 长度
function AfricaRiseRespinView:changeAddReelLength(respinNodeList)
    local NowHeight = 0
    local endHeight = self.m_slotNodeHeight
    local moveSpeed = endHeight / 20
    local scheduleDelayTime = 0.016
    self.m_updateReelHeightID =
        scheduler.scheduleGlobal(
        function(delayTime)
            local distance = 0
            if NowHeight + moveSpeed >= endHeight then
                distance = endHeight
                scheduler.unscheduleGlobal(self.m_updateReelHeightID)
                self.m_updateReelHeightID = nil
            else
                distance = NowHeight + moveSpeed
                NowHeight = NowHeight + moveSpeed
            end
            for i, v in ipairs(respinNodeList) do
                local respinNode = v
                local rect = respinNode.m_clipNode:getClippingRegion()
                respinNode.m_clipNode:setClippingRegion(
                    {
                        x = rect.x,
                        y = rect.y,
                        width = rect.width,
                        height = NowHeight
                    }
                )
            end
        end,
        scheduleDelayTime
    )
end

--node滚动停止
function AfricaRiseRespinView:respinNodeEndBeforeResCallBack(endNode)
    local lastRow = endNode.p_rowIndex
    local lastCol = endNode.p_cloumnIndex
    self:oneReelDown(lastCol, lastRow)
end

--repsinNode滚动完毕后 置换层级
function AfricaRiseRespinView:respinNodeEndCallBack(endNode, status)
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
        if self.m_brespinAddReel == false then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
        else
            self.m_Machine:playNextAddReel()
            for i = 1, #self.m_respinNodes do
                self.m_respinNodes[i].b_addReel = false
            end
        end
    end
end

-- function AfricaRiseRespinView:getRespinEndNode(iX, iY)
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

function AfricaRiseRespinView:oneReelDown(iCol, iRow)
    self.m_Machine:slotLocalOneReelDown(iCol, iRow)
end

function AfricaRiseRespinView:runNodeEnd(endNode)
    if endNode.p_symbolType == self.SYMBOL_WILD_X then
        self.m_Machine:createOneActionSymbol(endNode)
        endNode:setVisible(false)
    end
end

--组织滚动信息 开始滚动
function AfricaRiseRespinView:startMove()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_brespinAddReel = false
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    for i = 1, #self.m_respinNodes do
        self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
        self.m_respinNodes[i]:startMove()
    end
end
--组织滚动信息 开始滚动
function AfricaRiseRespinView:startAddReelMove()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_brespinAddReel = true
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    for i = 1, #self.m_respinNodes do
        if self.m_respinNodes[i].b_addReel then
            self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
            self.m_respinNodes[i]:startMove()
        end
    end
end

function AfricaRiseRespinView:getBaseRunNum()
    return self.m_baseRunNum
end

function AfricaRiseRespinView:setBaseRunNum(num)
    self.m_baseRunNum = num
end

function AfricaRiseRespinView:setBaseColInterVal(num)
    BASE_COL_INTERVAL = num
end

function AfricaRiseRespinView:getPosReelIdx(iRow, iCol)
    local index = 1
    if self.m_bFirstMove == true then
        index = (self.m_Machine.m_iReelRowNum - iRow) * self.m_Machine.m_iReelColumnNum + (iCol - 1)
    else
        index = (self.m_Machine.m_iAddReelRowNum - iRow) * self.m_Machine.m_iReelColumnNum + (iCol - 1)
    end

    return index + 1
end

function AfricaRiseRespinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    for j = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local runInfo = {
            0,
            3,
            6,
            9,
            12,
            1,
            4,
            7,
            10,
            13,
            2,
            5,
            8,
            11,
            14
        }
        local index = self:getPosReelIdx(repsinNode.p_rowIndex, repsinNode.p_colIndex)
        local runLong = 20
        if index > 15 then
            runInfo = {0, 1, 2, 3, 4}
            index = index % 5
            if index == 0 then
                index = 5
            end
            runLong =  self.m_baseRunNum + runInfo[index] --* BASE_ROW_ADD_NUM
        else
            runLong = self.m_baseRunNum + runInfo[index] * BASE_ROW_ADD_NUM
        end

        for i = 1, #storedNodeInfo do
            local runDatelong = runLong
            local stored = storedNodeInfo[i]
            if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                repsinNode:setRunInfo(runDatelong, stored.type)
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

--坐标获取RepsinNode
function AfricaRiseRespinView:getRespinNode(iX, iY)
    for i = 1, #self.m_respinNodes do
        local respinNode = self.m_respinNodes[i]
        if respinNode.p_rowIndex == iX and respinNode.p_colIndex == iY then
            return respinNode
        end
    end
    return nil
end

--获取所有固定信号
function AfricaRiseRespinView:getFixSlotsNode()
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

function AfricaRiseRespinView:getRespinEndNode(iX, iY)
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
function AfricaRiseRespinView:getAllEndSlotsNode()
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
        endSlotNode[#endSlotNode + 1] = repsinNode:getLastNode()
    end
    return endSlotNode
end

function AfricaRiseRespinView:getAllWildXSlotsNode()
    local endSlotNode = {}
    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        local node = repsinNode:getLastNode()
        if node.p_symbolType == self.SYMBOL_WILD_X then
            endSlotNode[#endSlotNode + 1] = node
        end
    end
    return endSlotNode
end

function AfricaRiseRespinView:setAllSymbolSlotsNodeVisible()

    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        local node = repsinNode:getLastNode()
        if node then
            node:setVisible(true)
        end
    end
   
end

function AfricaRiseRespinView:playAllSpinAddNodeIdle(iCol,iRow)
    local endSlotNode = {}
    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        local node = repsinNode:getLastNode()
        if node.p_symbolType == self.SYMBOL_SPIN_ADD and repsinNode.p_rowIndex == iRow and repsinNode.p_colIndex == iCol  then
            node:runAnim("idleframe2")
        end
    end
    return endSlotNode
end

function AfricaRiseRespinView:removeAllSlotsNodeMark()
    local endSlotNode = {}
    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        local node = repsinNode:getLastNode()
        if node.m_icon then
            node.m_icon:stopAllActions()
            node.m_icon:removeFromParent()
            node.m_icon = nil
        end
    end
end

function AfricaRiseRespinView:quicklyStop()
    self.m_isPlayedSound = false

    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        if repsinNode:getNodeRunning() then
            repsinNode:quicklyStop()
        end
    end

    self:changeTouchStatus(ENUM_TOUCH_STATUS.QUICK_STOP)
end

function AfricaRiseRespinView:changeTouchStatus(touchStatus)
    self.m_respinTouchStatus = touchStatus
end

function AfricaRiseRespinView:getouchStatus()
    return self.m_respinTouchStatus
end

function AfricaRiseRespinView:onEnter()
end

function AfricaRiseRespinView:onExit()
    if self.m_updateReelHeightID then
        scheduler.unscheduleGlobal(self.m_updateReelHeightID)
        self.m_updateReelHeightID = nil
    end
end

return AfricaRiseRespinView

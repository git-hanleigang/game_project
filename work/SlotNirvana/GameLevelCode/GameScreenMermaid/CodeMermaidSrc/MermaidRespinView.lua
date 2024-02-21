local MermaidRespinView = class("MermaidRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = {
    NORMAL = 100,
    REPSINNODE = 1
}

function MermaidRespinView:readyMove()
    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_startCallFunc then
        self.m_startCallFunc()
    end
end

--获取所有参与结算节点
function MermaidRespinView:getAllCleaningNode()
    --从 从上到下 左到右排序
    local cleaningNodes = {}
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG and self:getPartCleaningNode(node.lightNode.p_rowIndex, node.lightNode.p_cloumnIndex) then
            local MermaidRespinView = self.m_machine.m_runSpinResultData.p_rsExtraData.unlock -- 服务器已经解锁的个数
            if node.lightNode.p_rowIndex <= MermaidRespinView then
                cleaningNodes[#cleaningNodes + 1] = node.lightNode
            end
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

function MermaidRespinView:initMachine(machine)
    self.m_machine = machine
end

-- 根据服务器数据获得有效固定信号
function MermaidRespinView:getUsefulFixSlotsNode()
    local UsefulNode = {}
    local MermaidRespinView = self.m_machine.m_runSpinResultData.p_rsExtraData.unlock -- 服务器已经解锁的个数

    for i = 1, #self.m_respinNodes do
        local respinNode = self.m_respinNodes[i]
        if respinNode.p_rowIndex <= MermaidRespinView and respinNode:getRespinNodeStatus() == RESPIN_NODE_STATUS.LOCK then
            table.insert(UsefulNode, respinNode)
        end
    end

    return UsefulNode
end

function MermaidRespinView:oneReelLocalDown(cloumn,bLastNode)
    gLobalSoundManager:playSound("MermaidSounds/Mermaid_reelstop.mp3")
    if bLastNode then
        self:updataLockNodes()
    end
end

function MermaidRespinView:updataLockNodes()
    local lcokNode = self:getUsefulFixSlotsNode()
    -- print("lcokNode  数量 ================#lcokNode "..#lcokNode.."cloumn  "..cloumn)
    local lightNum = 0
    local MermaidRespinView = self.m_machine.m_runSpinResultData.p_rsExtraData.unlock -- 服务器已经解锁的个数
    local lockedSymbols = #lcokNode -- self.m_machine.m_runSpinResultData.p_rsExtraData.totalRewardSignals -- 服务器已经锁住的信号数

    local lightNum = lockedSymbols

    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(
        waitNode,
        function()
            for k, v in pairs(self.m_machine.m_lockNodeArray) do
                v:updateLockLeftNum(self.m_machine.m_lockNumArray[k] - lightNum)
            end

            local lightNum_1 = lightNum
            -- performWithDelay(self,function( )
            if lightNum_1 >= self.m_machine.m_lockNumArray[1] and lightNum_1 < self.m_machine.m_lockNumArray[2] then
                self.m_machine:unlockedOneNode(1)
            elseif lightNum_1 >= self.m_machine.m_lockNumArray[2] and lightNum_1 < self.m_machine.m_lockNumArray[3] then
                self.m_machine:unlockedOneNode(1)
                self.m_machine:unlockedOneNode(2)
            elseif lightNum_1 >= self.m_machine.m_lockNumArray[3] and lightNum_1 < self.m_machine.m_lockNumArray[4] then
                self.m_machine:unlockedOneNode(1)
                self.m_machine:unlockedOneNode(2)
                self.m_machine:unlockedOneNode(3)
            elseif lightNum_1 >= self.m_machine.m_lockNumArray[4] then
                self.m_machine:unlockedOneNode(1)
                self.m_machine:unlockedOneNode(2)
                self.m_machine:unlockedOneNode(3)
                self.m_machine:unlockedOneNode(4)
            end

            -- end,  0.1 * （5- cloumn） )

            waitNode:removeFromParent()
        end,
        0.2
    )
end

--repsinNode滚动完毕后 置换层级
function MermaidRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    if status == RESPIN_NODE_STATUS.LOCK then
        local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
        local pos = self:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))

        local clipNode = self:initLockBonusClipNode(endNode)
        self:addChild(clipNode, REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex, self.REPIN_NODE_TAG)
        clipNode:setPosition(pos)

        local MermaidRespinView = self.m_machine.m_runSpinResultData.p_rsExtraData.unlock -- 服务器已经解锁的个数
        if endNode.p_rowIndex <= MermaidRespinView then
        -- gLobalSoundManager:playSound("HowlingMoonSounds/music_HowlingMoon_spin_light_down.mp3")
        end
    end
    self:runNodeEnd(endNode)

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
    end

    local lastColNodeRow = endNode.p_rowIndex
    local lastNodeCol = endNode.p_cloumnIndex
    local maxCol = 1
    for i = 1, #self.m_respinNodes do
        local respinNode = self.m_respinNodes[i]
        if respinNode.p_colIndex == endNode.p_cloumnIndex and respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            if respinNode.p_rowIndex < lastColNodeRow then
                lastColNodeRow = respinNode.p_rowIndex
            end
        end
        if respinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            if respinNode.p_colIndex >= lastNodeCol then
                maxCol = respinNode.p_colIndex
            end
        end
    end
    local isLastNode = false
    if maxCol == lastNodeCol then
        isLastNode = true
    end
    if endNode.p_rowIndex == lastColNodeRow then
        self:oneReelLocalDown(endNode.p_cloumnIndex,isLastNode)
    end
end

function MermaidRespinView:createRespinNode(symbolNode, status)
    local respinNode = util_createView(self.m_respinNodeName)
    respinNode:setMachine(self.m_machine)
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

    respinNode:initClipNode(self:getClipNode(symbolNode.p_cloumnIndex, symbolNode.p_rowIndex), 130)
    respinNode.p_rowIndex = symbolNode.p_rowIndex
    respinNode.p_colIndex = symbolNode.p_cloumnIndex
    respinNode:initConfigData()
    if status == RESPIN_NODE_STATUS.LOCK or self:getTypeIsEndType(symbolNode.p_symbolType) == true then
        local pos = cc.p(symbolNode:getPosition())
        local clipNode = self:initLockBonusClipNode(symbolNode)
        self:addChild(clipNode, symbolNode:getLocalZOrder(), self.REPIN_NODE_TAG)
        clipNode:setPosition(pos)
        -- clipNode.lightNode:runAnim("actionframe",true)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

function MermaidRespinView:initLockBonusClipNode(symbolNode)
    local nodeHeight = self.m_slotReelHeight / self.m_machineRow
    local clipNode = cc.ClippingRectangleNode:create({x = -math.ceil(self.m_slotNodeWidth / 2), y = -nodeHeight / 2, width = self.m_slotNodeWidth, height = nodeHeight + 1})
    symbolNode:removeFromParent()
    clipNode:addChild(symbolNode, self.REPIN_NODE_TAG)
    symbolNode:setPosition(cc.p(0, 0))
    clipNode.lightNode = symbolNode

    return clipNode
end

--获取所有最终停止信号
function MermaidRespinView:getAllEndSlotsNode()
    local endSlotNode = {}
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG then
            endSlotNode[#endSlotNode + 1] = node.lightNode
        end
    end
    for i = 1, #self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        if repsinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            endSlotNode[#endSlotNode + 1] = repsinNode:getLastNode()
        end
    end
    return endSlotNode
end

function MermaidRespinView:getRespinEndNode(iX, iY)
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]

        if node:getTag() == self.REPIN_NODE_TAG and node.lightNode.p_rowIndex == iX and node.lightNode.p_cloumnIndex == iY then
            return node
        end
    end
    print("RESPINNODE NOT END!!!")
    return nil
end

--获取所有固定信号
function MermaidRespinView:getFixSlotsNode()
    local fixSlotNode = {}
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG then
            fixSlotNode[#fixSlotNode + 1] = node.lightNode
        end
    end
    return fixSlotNode
end

function MermaidRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then
        local MermaidRespinView = self.m_machine.m_runSpinResultData.p_rsExtraData.unlock -- 服务器已经解锁的个数
        if endNode.p_rowIndex <= MermaidRespinView then
            if endNode.p_symbolType == self.m_machine.SYMBOL_SMALL_FIX_BONUS then
                gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_FixBonus_down.mp3")
            else
                gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_JpBonus_down.mp3")
            end
        end

        endNode:runAnim(
            info.runEndAnimaName,
            false,
            function()
                -- endNode:runAnim("actionframe",true)
            end
        )

        self:createOneActionSymbol(endNode, "buling")
    end
end

function MermaidRespinView:createOneActionSymbol(endNode, actionName)
    if not endNode or not endNode.m_ccbName then
        return
    end

    local fatherNode = endNode

    local MermaidRespinView = self.m_machine.m_runSpinResultData.p_rsExtraData.unlock -- 服务器已经解锁的个数
    if endNode.p_rowIndex <= MermaidRespinView then
        endNode:setVisible(true)

        local node = util_createAnimation(endNode.m_ccbName .. ".csb")
        local func = function()
            if fatherNode then
                fatherNode:setVisible(true)
            end
            if node then
                node:removeFromParent()
            end
        end
        node:playAction(actionName, false, func)

        local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
        local pos = self:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        self:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - endNode.p_rowIndex + 10000)
        node:setPosition(pos)

        if endNode.p_symbolType == self.m_machine.SYMBOL_SMALL_FIX_GRAND then
            node:findChild("node_grand"):setVisible(self.m_machine.m_jackpot_status == "Normal")
            node:findChild("node_mega"):setVisible(self.m_machine.m_jackpot_status == "Mega")
            node:findChild("node_super"):setVisible(self.m_machine.m_jackpot_status == "Super")
        end

        

        self:setSpecialShowActionNodeScore(fatherNode, node)
    end
end

-- 设置respin分数
function MermaidRespinView:setSpecialShowActionNodeScore(fathernode, node)
    local symbolNode = fathernode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_machine.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --获取分数
        local score = self.m_machine:getReSpinSymbolScore(self.m_machine:getPosReelIdx(iRow, iCol))
        if score then
            local index = 0
            if score and type(score) ~= "string" then
                local lineBet = globalData.slotRunData:getCurTotalBet()

                local labRed = node:findChild("m_lb_score_0")
                local labBlue = node:findChild("m_lb_score")
                if labBlue then
                    labBlue:setVisible(false)
                end

                if labRed then
                    labRed:setVisible(false)
                end

                if score >= self.m_machine.m_respinCollectBet then
                    if labRed then
                        labRed:setVisible(true)
                    end
                else
                    if labBlue then
                        labBlue:setVisible(true)
                    end
                end

                score = score * lineBet
                score = util_formatCoins(score, 3)

                if labRed then
                    labRed:setString(score)
                end

                if labBlue then
                    labBlue:setString(score)
                end
            end
        end
    else
        local score = self.m_machine:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        if score and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()

            local labRed = node:findChild("m_lb_score_0")
            local labBlue = node:findChild("m_lb_score")
            if labBlue then
                labBlue:setVisible(false)
            end

            if labRed then
                labRed:setVisible(false)
            end

            if score >= self.m_machine.m_respinCollectBet then
                if labRed then
                    labRed:setVisible(true)
                end
            else
                if labBlue then
                    labBlue:setVisible(true)
                end
            end

            score = score * lineBet
            score = util_formatCoins(score, 3)

            if labRed then
                labRed:setString(score)
            end

            if labBlue then
                labBlue:setString(score)
            end
        end
    end
end

return MermaidRespinView

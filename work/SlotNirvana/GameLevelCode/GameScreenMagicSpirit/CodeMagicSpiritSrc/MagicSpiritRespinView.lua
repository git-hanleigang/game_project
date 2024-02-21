local MagicSpiritRespinView = class("MagicSpiritRespinView", util_require("Levels.RespinView"))

local VIEW_ZORDER = {
    NORMAL = 100,
    REPSINNODE = 1
}

--重写解决 快滚问题
function MagicSpiritRespinView:startMove()
    self.m_respinTouchStatus = ENUM_TOUCH_STATUS.RUN
    self.m_respinNodeRunCount = 0
    self.m_respinNodeStopCount = 0
    --!!!插入代码
    local blank_list = {}

    for i=1,#self.m_respinNodes do
          if self.m_respinNodes[i]:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
                self.m_respinNodeRunCount = self.m_respinNodeRunCount + 1
                table.insert(blank_list, self.m_respinNodes[i])
          end
    end
    --!!!插入代码
    for _index,_blankNode in ipairs(blank_list) do
        blank_list[1]:changeRunSpeed( 1 == self.m_respinNodeRunCount )
        blank_list[1]:changeResDis( 1 == self.m_respinNodeRunCount )

        _blankNode:startMove()
    end
    --!!!插入代码
    self:playLastOneAnimTip()

    self:playBonusIdleframe()
    
    --重置reSpin的音效索引
    self.m_machine.m_respinSoundId = 0
end

--结束滚动播放落地
function MagicSpiritRespinView:runNodeEnd(endNode)

    local isBonus = nil ~= self.m_machine.m_classicIndexLis[endNode.p_symbolType]
    if  isBonus  then
        --区分金色 和 其他颜色
        if endNode.p_symbolType == self.m_machine.SYMBOL_CLASSIC3 then
            gLobalNoticManager:postNotification("MagicSpirit_playRespinSound", {1})
        else
            gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_bonus_down.mp3")
        end
        
        endNode:runAnim("buling")
    end
    -- body
end

function MagicSpiritRespinView:oneReelDown()
    gLobalSoundManager:playSound("MagicSpiritSounds/sound_MagicSpirit_reel_stop.mp3")
end

function MagicSpiritRespinView:createRespinNode(symbolNode, status)
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
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
    else
        respinNode:setFirstSlotNode(symbolNode)
        respinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
    end
    self.m_respinNodes[#self.m_respinNodes + 1] = respinNode
end

---获取所有参与结算节点
function MagicSpiritRespinView:getAllCleaningNode()
    --从 从上到下 左到右排序 -> 绿色-粉色-金色
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
        for i = 1, #sameRowNode do
            sortNode[#sortNode + 1] = sameRowNode[i]
        end
    end
    

    cleaningNodes = sortNode
    return cleaningNodes
end

--获取可收集的bonus节点
function MagicSpiritRespinView:getAllCollectNode()
    --从 从上到下 左到右排序
    local cleaningNodes = {}
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]
        if node.m_lastNode then
            if node.m_lastNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                cleaningNodes[#cleaningNodes + 1] = node
            end
        end
    end

    --排序
    local sortNode = {}
    for iCol = 1, self.m_machineColmn do
        local sameRowNode = {}
        for i = 1, #cleaningNodes do
            local node = cleaningNodes[i]
            if node.p_colIndex == iCol then
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





--修改所有固定小块的层级显示 和 遮罩相比
function MagicSpiritRespinView:changeAllCollectNodeOrder(isMask)
    --默认高亮
    local order = isMask and -1  or REEL_SYMBOL_ORDER.REEL_ORDER_2
    local nodes = self:getAllCleaningNode()
    for _index,_node in ipairs(nodes) do
        _node:setLocalZOrder(order - _node.p_rowIndex)
    end
end

--reSpin结束时随机打乱盘面
function MagicSpiritRespinView:reSpinOverRandomShow(  )
    for _index,_node in ipairs(self.m_respinNodes) do
        local symbol = _node.m_baseFirstNode
        if symbol then

            local cloumnIndex = _node.p_cloumnIndex
            local reelDatas = self.m_machine.m_configData:getNormalReelDatasByColumnIndex( cloumnIndex )
            local symbolType = self.m_machine:getRandomReelType(cloumnIndex, reelDatas)
            _node:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine, symbolType), symbolType)

        end
    end
end
--==所有回弹结束 检测数量触发展示 只在滚动结束和reSpin开始时调用
function MagicSpiritRespinView:checkBonusCount()
    -- self:playLastOneAnimTip()
    self:playAllMultipleAnim()

    self:reSetReSpinNodeOrder()
end

function MagicSpiritRespinView:playBonusIdleframe()
    --播放reSpin固定小块的 idleframe
    local bonusList = self:getAllCleaningNode()
    for _index,_bonus in ipairs(bonusList) do
        _bonus:runAnim("idleframe",true)
    end
end
--空白格子的层级
function MagicSpiritRespinView:reSetReSpinNodeOrder()
    for _index,_node in ipairs(self.m_respinNodes) do
        local order = 0
        local symbol = _node.m_baseFirstNode

        if(symbol and 
            symbol.p_symbolType~=self.m_machine.SYMBOL_CLASSIC1 and 
            symbol.p_symbolType~=self.m_machine.SYMBOL_CLASSIC2 and
            symbol.p_symbolType~=self.m_machine.SYMBOL_CLASSIC3)then

            order = self.m_machine:getBounsScatterDataZorder(symbol.p_symbolType)
        end

        _node:setLocalZOrder(order)
    end
end
--所有非固定小块
function MagicSpiritRespinView:getBlankList()
    local blank_list = {}
    for _index,_node in ipairs(self.m_respinNodes) do
        local symbol = _node.m_baseFirstNode
        --初始化reSpin棋盘时，只有非锁定节点 才有这个节点
        if(symbol and 
            symbol.p_symbolType~=self.m_machine.SYMBOL_CLASSIC1 and 
            symbol.p_symbolType~=self.m_machine.SYMBOL_CLASSIC2 and
            symbol.p_symbolType~=self.m_machine.SYMBOL_CLASSIC3)then

            blank_list[#blank_list + 1] = _node
        end
    end

    return blank_list
end
--播放 差一个bonus全满的动画提示 
function MagicSpiritRespinView:playLastOneAnimTip()
    local blank_list = self:getBlankList()
    if(not self.m_lastOneTip)then
        if(1 == #blank_list or _visible)then
            local blank_symbol = blank_list[1]

            self.m_lastOneTip = util_createAnimation("MagicSpirit_respin_run.csb")
            self:addChild(self.m_lastOneTip, VIEW_ZORDER.REPSINNODE+1)
    
            local wordPos = blank_symbol:getParent():convertToWorldSpace(cc.p(blank_symbol:getPosition()))
            self.m_lastOneTip:setPosition(self.m_lastOneTip:getParent():convertToNodeSpace(wordPos))
            self.m_lastOneTip:runCsbAction("actionframe", true)
        end
    else
        local visible = 1 == #blank_list
        self.m_lastOneTip:setVisible(visible)
    end
end
function MagicSpiritRespinView:changeLastOneAnimTipVisible(_visible)
    if(self.m_lastOneTip)then
        self.m_lastOneTip:setVisible(_visible)
    end
end
--播放 全满时小块成倍固定在主棋盘左上角
function MagicSpiritRespinView:playAllMultipleAnim()
    local blank_list = self:getBlankList()
    if(0 == #blank_list)then
        self.m_machine:playAllMultipleAnim()
    end
end
return MagicSpiritRespinView

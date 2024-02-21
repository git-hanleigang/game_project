--[[
    右边条节点 不需要csb
]]
local RightFrameLayer = class("RightFrameLayer", util_require("base.BaseView"))

function RightFrameLayer:initUI(worldPos)
    self:initExtraNodeConfig()
    self:createCsbNode("RightFrame/RightFrameNodeV2.csb")
    -- 创建一个基准 baseNode
    
    self.m_firstExtraNodePos = {x = 0, y = 0} -- 第一个  extraNode 的坐标 之后依次根据 extraNode 的大小进行排序
    self.m_csbNode = {}
    self.m_realExtraNodeInfo = {}
    self.m_maxSize = {widht = 0, height = 0} -- 九宫格大小
    self.m_nodeDis = 15 -- 每个 entry 之间的间隔
    self.m_fSacle = 0.8
    self.m_activityExtraNode = {}

    self.m_openDrag = false -- 是否开启拖拽
    self.m_oldZOrder = nil

    self.m_baseNode = self:findChild("node_cell")
    self.m_scrlView = self:findChild("ScrollView_1")
	self.m_scrlView:setScrollBarEnabled(false)
    self.m_scrlView:onScroll(function()
		self:updateCellVisible()
	end)
    self.m_bg = self:findChild("Image_1")
    self.m_panel = self:findChild("Panel_1")
    self.m_node_btn = self:findChild("node_btn")
    self.m_btn_up = self:findChild("Button_up")
    self.m_btn_down = self:findChild("Button_down")
    self.m_panel:setSwallowTouches(false)
    self:addClick(self.m_panel)

    -------------------
	local nodeClipRef = self:findChild("node_clip")
	self._layoutClip = self:findChild("Panel_4")
	self._scrlVParent = self:findChild("Panel_3")
	local clipPos = cc.p(nodeClipRef:getPosition())
	-- 创建裁剪层
	local nodeClipping = cc.ClippingNode:create()
	nodeClipping:setInverted(false)
	nodeClipping:setAlphaThreshold(0)
	self._scrlVParent:addChild(nodeClipping)
	nodeClipping:move(clipPos.x, clipPos.y)
	-- 设置 stencil node对象
    local refImgV = self:findChild("Image_1")
    local refImgVSize = refImgV:getContentSize()
	self.m_nodeStencil = ccui.Scale9Sprite:create(refImgV:getCapInsets(), "RightFrame/ui/rightframe_bg_clip.png")
	self.m_nodeStencil:setAnchorPoint(cc.p(0.5, 0))
	self.m_nodeStencil:setContentSize(cc.size(1000, refImgVSize.height-12))
    self.m_nodeStencil:setPositionY(5)
	nodeClipping:setStencil(self.m_nodeStencil)
	-- 裁剪scrlView
	util_changeNodeParent(nodeClipping, nodeClipRef)
	nodeClipRef:move(0, 0)

    -- nodeClipping:addChild(util_newMaskLayer())
	-------------------

    -- 计算坐标
    local pos_x = 0
    local pos_y = 0
    local offset = {x = 0, y = 0}
    if globalData.slotRunData.isPortrait == true then
        pos_x = display.width - offset.x
        pos_y = worldPos.y + 150 - offset.y
    else
        pos_x = display.width - offset.x - util_getBangScreenHeight()
        pos_y = worldPos.y - offset.y
        self.m_node_btn:setVisible(false)
    end
    self:setPosition(pos_x, pos_y)

    self:updateNode()
    if table.nums(self.m_realExtraNodeInfo) > 0 then
        self.m_btn_down:setVisible(false)
        self:runCsbAction(
            "show",
            false,
            function()
                self.m_isCanTouch = true
                self:runCsbAction("idle")
            end,
            60
        )
    else
        self.m_isCanTouch = true
    end

    -- 当前关卡 右边条缩放值
	local scale = gLobalActivityManager:getSlotFloatLayerRight() or math.min(util_getAdaptDesignScale(), 1)
	self:setScale(scale)
end

-- 把节点添加到这里面来

function RightFrameLayer:createExtraNode(createFunc, viewName, viewParam, viewNode, sizeInfo)
    if viewNode == nil then
        viewNode = createFunc(viewName, viewParam)
    end
    if viewNode ~= nil then
        self.m_baseNode:addChild(viewNode)
        if not sizeInfo then
            sizeInfo = {widht = 100, height = 80}
        end

        --添加大小提示
        -- if DEBUG == 2 then
        --     local layout = cc.LayerColor:create(cc.c3b(192, 192, 192 ))
        --     layout:setSwallowsTouches(false)
        --     layout:setOpacity( 128 )
        --     layout:setContentSize(sizeInfo.widht,sizeInfo.height)
        --     layout:setPosition(-sizeInfo.widht / 2, -sizeInfo.height / 2)
        --     viewNode:addChild(layout, -1)
        -- end
        

        -- if viewNode.getPanelSize then
        --     sizeInfo = viewNode:getPanelSize()
        -- end

        local data = {
            -- node = clone(viewNode),
            node = viewNode,
            size = sizeInfo,
            name = self.m_currViewName
        }
        if viewParam and viewParam.baseScale then
            data.baseScale = viewParam.baseScale
        end
        self.m_realExtraNodeInfo[#self.m_realExtraNodeInfo + 1] = data
        -- 获取最大
        if self.m_maxSize.widht < sizeInfo.widht then
            self.m_maxSize.widht = sizeInfo.widht
        end
    end
    return viewNode
end

function RightFrameLayer:removeExtraNode(extraNode)
    local index = nil
    for i = 1, table.nums(self.m_realExtraNodeInfo) do
        if self.m_realExtraNodeInfo[i].node == extraNode then 
            index = i
            break
        end
    end
    if index then
        table.remove(self.m_realExtraNodeInfo, index)
    end
    extraNode:removeFromParent()
end

function RightFrameLayer:removeExtraNodeByName(extraName)
    extraName = extraName or ""
    if extraName == "" then
        return
    end

    local index = nil
    for i = 1, table.nums(self.m_realExtraNodeInfo) do
        if self.m_realExtraNodeInfo[i].name == extraName then 
            index = i
            break
        end
    end

    if index then
        table.remove(self.m_realExtraNodeInfo, index)
    end

    self.m_baseNode:removeChildByName(extraName)
end

function RightFrameLayer:updateNode()
    self.m_maxSize.height = 0

    -- 刷新一遍所有的绑定节点信息 添加到node上
    for i = 1, table.nums(self.eventList) do
        local eventData = self.eventList[i]
        if eventData and #eventData >= 1 then
            local eventFunc = eventData[1] -- 函数
            self.m_currViewName = eventData[2] -- 名称
            if eventFunc then
                eventFunc()
            end
        end
    end

    -- 计算一下排序
    self:changeNodePos()
end

function RightFrameLayer:changeNodePos()
    -- 先获取第一个的位置
    if table.nums(self.m_realExtraNodeInfo) > 0 then
        self:setVisible(true)
        local sizeInfo = self.m_realExtraNodeInfo[1].size
        self.m_firstExtraNodePos.x = 0
        -- self.m_firstExtraNodePos.x = -(self.m_maxSize.widht / 2)
        self.m_firstExtraNodePos.y = sizeInfo.height / 2 * self.m_fSacle

        local lastNodePos = nil
        local height = self.m_maxSize.height
        for i = 1, table.nums(self.m_realExtraNodeInfo) do
            local size = self.m_realExtraNodeInfo[i].size
            local node = self.m_realExtraNodeInfo[i].node
            local baseScale = self.m_realExtraNodeInfo[i].baseScale
            local newPos = cc.p(self.m_firstExtraNodePos.x, self.m_firstExtraNodePos.y)
            if i == 1 then
                node:setPosition(newPos)
            else
                local lastSize = self.m_realExtraNodeInfo[i - 1].size
                local yPos = (lastNodePos.y + (lastSize.height / 2 + self.m_nodeDis + size.height / 2) * self.m_fSacle)
                newPos = cc.p(self.m_firstExtraNodePos.x, yPos)
                node:setPosition(newPos)
            end
            lastNodePos = cc.p(node:getPosition())
            -- node:stopAllActions()
            node:setScale(self.m_fSacle)
            if baseScale then
                node:setScale(self.m_fSacle*baseScale)
            end
            node:setVisible(true)
            node:setZOrder(10000 - i)
            self.m_maxSize.height = (self.m_maxSize.height + size.height + self.m_nodeDis)
        end
        self.m_maxSize.height = self.m_maxSize.height * self.m_fSacle
        self:updateScrollViewSize(self.m_maxSize)
        self:updateBGPanel(self.m_maxSize)
    else
        self:setVisible(false)
    end
end

function RightFrameLayer:updateScrollViewSize(_size)
    local scrlViewSize = self.m_scrlView:getContentSize()
    local size = cc.size(scrlViewSize.width, _size.height)
    self.m_scrlView:setInnerContainerSize(size)
    local limitH = 500
    if size.height > limitH then
        size.height = limitH
        self:buttonSwallowTouches(self.m_baseNode)
        self._layoutClip:setClippingEnabled(true)
    else
        self._layoutClip:setClippingEnabled(false)
    end
    self.m_scrlView:setContentSize(size)

    self:updateCellVisible()
end
function RightFrameLayer:updateCellVisible()
	local aabbW = self.m_scrlView:getWordAabb()
    if table.nums(self.m_realExtraNodeInfo) > 0 then
        for i = 1, table.nums(self.m_realExtraNodeInfo) do
            local size = self.m_realExtraNodeInfo[i].size
            local node = self.m_realExtraNodeInfo[i].node
            local posItem = node:convertToWorldSpace(cc.p(-size.widht*0.5, -size.height*0.5))
            local bShow = cc.rectIntersectsRect(aabbW, cc.rect(posItem.x, posItem.y, size.widht, size.height))
            node:setVisible(bShow)
        end
    end
end
function RightFrameLayer:buttonSwallowTouches(_node)
    if not _node then
        return
    end

    --绑定按钮监听
    if tolua.type(_node) == "ccui.Button" or tolua.type(_node) == "ccui.Layout" then
        _node:setSwallowTouches(false)
    end
    for _, node in pairs(_node:getChildren()) do
        self:buttonSwallowTouches(node)
    end
end

function RightFrameLayer:updateBGPanel()
    local size = self.m_scrlView:getContentSize()

    self.m_bg:setContentSize(110,size.height + 30)
    self.m_panel:setContentSize(110,size.height + 30)
    self.m_node_btn:setPositionY((size.height + 30)/2)
    self.m_nodeStencil:setContentSize(1000, size.height + 18)
    self._scrlVParent:setContentSize(800,size.height + 24)
    self._layoutClip:setContentSize(800,size.height + 24)
    util_setCascadeOpacityEnabledRescursion(self.m_baseNode, true)
end

function RightFrameLayer:getIsSpecialScale()
    local currViewDire = globalData.slotRunData.isPortrait
    if globalData.slotRunData.machineData then
        currViewDire = globalData.slotRunData.machineData.p_portraitFlag
    end
    local glView = cc.Director:getInstance():getOpenGLView()
    local frameSize = glView:getFrameSize()
    local ratio = frameSize.width / frameSize.height
    --  竖屏
    if currViewDire then
        ratio = frameSize.height / frameSize.width
    end
    if ratio <= 1.34 then
        return true
    end
    return false
end

--每日奖励事件添加(目前只有每日轮盘)
function RightFrameLayer:initExtraNodeConfig()
    self.eventList = {}
    self.eventList[#self.eventList + 1] = {handler(self, self.addCashBackNode), "CashBack"}
    self.eventList[#self.eventList + 1] = {handler(self, self.addActivityNode), "Activity"}
    self.eventList[#self.eventList + 1] = {handler(self, self.addAdsChallengeIconNode), "AdsChallenge"}
    --视频放到最上面
    self.eventList[#self.eventList + 1] = {handler(self, self.addRewardVideoNode), "RewardVideo"}
end

function RightFrameLayer:addRewardVideoNode()
    --激励视频
    local isShow = globalData.adsRunData.p_isNull == false and globalData.adsRunData:isPlayRewardForPos(PushViewPosType.GamePos)
    if self.m_vedioNode then
        if not isShow then
            self:removeExtraNode(self.m_vedioNode)
            self.m_vedioNode = nil
        end
    else
        if isShow then
            self.m_videoInit = true
            local viewParam = {scene = "Game", init = self.m_videoInit}
            local videoNode = self:createExtraNode(util_createView, "views.lobby.AdsRewardIcon", viewParam, nil, {widht = 110, height = 100})
            self.m_vedioNode = videoNode
        end
    end
end

function RightFrameLayer:addAdsChallengeIconNode()
    local isShow = globalData.AdChallengeData:isHasAdChallengeActivity() and gLobalAdChallengeManager:checkOpenLevel()
    if self.m_adsChallengNode then
        if not isShow then
            self:removeExtraNode(self.m_adsChallengNode)
            self.m_adsChallengNode = nil
        end
    else
        if not isShow then
            return
        end
        local adsChallegeNode = self:createExtraNode(util_createView, "views.Ad_Challenge.AdsChallengeLobbyIconNode", {baseScale = 1}, nil, {widht = 110, height = 100})
        self.m_adsChallengNode = adsChallegeNode
    end
end

function RightFrameLayer:addCashBackNode()
    --boostme
    local boostMeConfig = G_GetMgr(ACTIVITY_REF.CashBack):getRightFrameRunningData()
    if self.m_boostMeNode then
        if boostMeConfig then
            if self.m_boostMeNode.getIsCanShow then
                if not self.m_boostMeNode:getIsCanShow() then
                    self:removeExtraNode(self.m_boostMeNode)
                    self.m_boostMeNode = nil
                end
            end
        else
            self:removeExtraNode(self.m_boostMeNode)
            self.m_boostMeNode = nil
        end
    else
        if boostMeConfig then
            local doShowAction = false
            local boostNode = self:createExtraNode(util_createView, "GameModule.Shop.BoostMeEntryNode", {doShowAction = doShowAction}, nil, {widht = 110, height = 100})
            boostNode:setName("BoostMeEntryNode")
            if boostNode.getIsCanShow then
                if boostNode:getIsCanShow() then
                    self.m_boostMeNode = boostNode
                else
                    self:removeExtraNode(boostNode)
                    self.m_boostMeNode = nil
                end
            end
        end
    end
end

-- 活动相关右侧入口
function RightFrameLayer:addActivityNode()
    -- 先清理已经有的点活动点
    for refName, nodeData in pairs(self.m_activityExtraNode) do
        if nodeData.type == "Activity" and refName then
            local runingData
            local _mgr = G_GetMgr(refName)
            if _mgr then
                runingData = _mgr:getRightFrameRunningData()
            else
                runingData = G_GetActivityDataByRef(refName)
            end

            if not runingData then
                self:removeExtraNode(self.m_activityExtraNode[refName].node)
                self.m_activityExtraNode[refName] = nil
            end
        end
    end

    -- 添加 活动入口
    local tableActivityExtra = gLobalActivityManager:InitMachineRightNode()
    for i = 1, table.nums(tableActivityExtra) do
        local entryInfo = tableActivityExtra[i]
        local name = entryInfo.name
        if not self.m_activityExtraNode[name] then
            local entryNode = gLobalActivityManager:createEntryNode(entryInfo.info)
            if entryNode then
                local extraSize = entryInfo.size
                if entryNode.getRightFrameSize then
                    extraSize = entryNode:getRightFrameSize()
                else
                    extraSize = entryInfo.size
                end
                entryNode:setName(entryInfo.name)
                local nodeData = {
                    node = self:createExtraNode(nil, nil, "", entryNode, extraSize),
                    name = entryInfo.name,
                    type = "Activity"
                }
                self.m_activityExtraNode[name] = nodeData
            end
        end
    end
end

function RightFrameLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_isCanTouch then
        return
    end
    
    if name == "Button_up" then
        self.m_isCanTouch = false
        self.m_panel:setSwallowTouches(true)
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        self:runCsbAction(
        "over",
        false,
        function()
            self.m_isCanTouch = true
            self.m_btn_up:setVisible(false)
            self.m_btn_down:setVisible(true)
            self:runCsbAction("idle2")
        end,
        60
    )
    elseif name == "Button_down" then
        self.m_isCanTouch = false
        self.m_panel:setSwallowTouches(true)
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        self:runCsbAction(
        "show",
        false,
        function()
            self.m_isCanTouch = true
            self.m_btn_up:setVisible(true)
            self.m_btn_down:setVisible(false)
            self.m_panel:setSwallowTouches(false)
            self:runCsbAction("idle")
        end,
        60
    )
    elseif name == "Panel_1" then
    end
end

function RightFrameLayer:onEnter()
    self.m_oldZOrder = self:getZOrder()

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateNode()
        end,
        ViewEventType.NOTIFY_LC_LEVELUP_OPEN
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateNode()
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params[1] == PushViewPosType.GamePos then
                self:updateNode()
            end
        end,
        ViewEventType.NOTIFY_ADS_REWARDS_END
    )
    
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateNode()
        end,
        ViewEventType.NOTIFY_AFTER_REQUEST_ZERO_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateNode()
        end,
        ViewEventType.NOTIFY_ACTIVITY_BIGWIN_ANIMATE
    )

    -- 次日礼物
    local TomorrowGiftConfig = util_require("GameModule.TomorrowGift.config.TomorrowGiftConfig")
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateNode()
        end,
        TomorrowGiftConfig.EVENT_NAME.NOTICE_REMOVE_TOMORROW_GIFT_MACHINE_ENTRY --移除入口
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.m_btn_down:isVisible() then
                self:clickFunc(self.m_btn_down)
            end
        end,
        TomorrowGiftConfig.EVENT_NAME.NOTICE_SHOW_TOMORROW_GIFT_MACHINE_ENTRY --可领奖后 右边条隐藏 把它显示出来
    )
end

-- function RightFrameLayer:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

--[[
    拖拽条调用返回事件
]]
function RightFrameLayer:getOldZOrder()
    if self.m_oldZOrder then
        return self.m_oldZOrder
    end
    return GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5
end

function RightFrameLayer:changePanleSwallow(status)
    self.m_layout:setSwallowTouches(status)
    if status then
        performWithDelay(
            self,
            function()
                self.m_layout:setSwallowTouches(false)
            end,
            0.2
        )
    end
end

function RightFrameLayer:changeStopDirection(direction)
    -- 遍历字节点是否有需要改变ui
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_CHANGE_STOP_DIRECTION_RIGHTFRAME, direction)
end

function RightFrameLayer:checkOpenProgressResult(oldPos)
end

return RightFrameLayer

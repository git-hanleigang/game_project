--[[--
    集卡小游戏引导
]]
local PuzzleGuideManager = class("PuzzleGuideManager") 

-- 集卡小游戏引导配置
local NOVICE_CONFIG = {
    {id = 1, bubble = {0, 38}},
    {id = 2, bubble = {0, -40}, preId = 1, nextId = 3},
    {id = 3, bubble = {0, 30}, preId = 2, finger = {0, 0}},
    {id = 4, bubble = {190, 0}, preId = 3, nextId = 5},
    {id = 5, bubble = {0, 80}, preId = 4},
    {id = 6, bubble = {-110, 0}, preId = 5},
    {id = 7, bubble = {0, -120}, preId = 6}
}

function PuzzleGuideManager:ctor()
end

function PuzzleGuideManager:getCurStepId()
    return globalData.puzzleGuideStepId ~= nil and tonumber(globalData.puzzleGuideStepId) or 0
end

function PuzzleGuideManager:isPickOne()
    -- 添加补丁判断条件：如果玩家有打开的宝箱，不引导
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    if data then
        local boxData = data.box
        for i = 1, #boxData do
            if boxData[i].pick then
                return true
            end
        end
    end
    return false
end

function PuzzleGuideManager:isFinish(stepId)
    if globalNoviceGuideManager:getIsFinish(stepId + 400) then -- 补丁，因为第一版是按照新手引导逻辑做的，热更后走过引导的就别提示了
        return true
    end
    local curStepId = self:getCurStepId()
    if stepId <= curStepId then
        return true
    end
    return false
end

function PuzzleGuideManager:stopGuide(stepId)
    if stepId == 1 then
        if self:isPickOne() then -- 补丁：如果玩家已经打开了宝箱不走引导
            return
        end
    end
    if NOVICE_CONFIG[stepId] and NOVICE_CONFIG[stepId].preId then
        if not self:isFinish(NOVICE_CONFIG[stepId].preId) then
            return
        end
    end
    if not self:isFinish(stepId) then
        globalData.puzzleGuideStepId = stepId
        self:sendExtraRequest(stepId)
    end
    -- 删除遮罩
    if self.m_newbieMask ~= nil then
        self.m_newbieMask:removeFromParent()
        self.m_newbieMask = nil
    end
    -- 删除气泡
    self:delBubble(stepId)
    -- 还原按钮层级
    self:resetHighLightNode(stepId)
    -- 移除手指
    if NOVICE_CONFIG[stepId].finger then
        self:delFinger()
    end

    -- 结束当前引导直接开始下一个引导
    if NOVICE_CONFIG[stepId].nextId then
        -- self:startGuide(NOVICE_CONFIG[stepId].nextId)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASHPUZZLE_GUIDE, {stepId = NOVICE_CONFIG[stepId].nextId})
    end
end

function PuzzleGuideManager:startGuide(stepId, highNode, rootScale)
    if NOVICE_CONFIG[stepId] and NOVICE_CONFIG[stepId].preId then
        if not self:isFinish(NOVICE_CONFIG[stepId].preId) then
            return
        end
    end
    if self:isFinish(stepId) then
        return
    end

    if stepId == 1 then
        if self:isPickOne() then
            return
        end
        self:addMaskLayer(true, true, nil, nil)
    elseif stepId == 2 or stepId == 4 or stepId == 5 then
        self:addMaskLayer(
            true,
            true,
            function()
                -- 集卡小游戏引导：本次结束
                self:stopGuide(stepId)
            end
        )
    elseif stepId == 3 then
        self:addMaskLayer(true, true, nil, nil)
    elseif stepId == 6 or stepId == 7 then
        self:addMaskLayer(
            true,
            false,
            function()
                -- 集卡小游戏引导：本次结束
                self:stopGuide(stepId)
            end,
            0
        )
    end

    -- 提高按钮的层级
    local pos = self:highLightNode(stepId, highNode, gLobalViewManager:getViewLayer(), stepId == 6, rootScale)
    -- 添加气泡
    if NOVICE_CONFIG[stepId].bubble then
        self:addBubble(pos, NOVICE_CONFIG[stepId].bubble, stepId)
    end
    -- 添加手指
    if NOVICE_CONFIG[stepId].finger then
        self:addFinger(pos, NOVICE_CONFIG[stepId].finger)
    end
end

function PuzzleGuideManager:sendExtraRequest(stepId)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.puzzleGuideStepId] = stepId
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
end

function PuzzleGuideManager:addMaskLayer(isTouch, isTouchSwallow, touchCallFunc, opacityValue)
    if self.m_newbieMask ~= nil then
        self.m_newbieMask:removeFromParent()
        self.m_newbieMask = nil
    end

    self.m_newbieMask = cc.LayerColor:create(cc.c3b(0, 0, 0), display.width, display.height)
    gLobalViewManager:getViewLayer():addChild(self.m_newbieMask, ViewZorder.ZORDER_GUIDE - 1)

    opacityValue = opacityValue or 190
    self.m_newbieMask:setOpacity(opacityValue)

    if isTouch then
        local function onTouchBegan(touch, event)
            return true
        end
        local function onTouchEnded(touch, event)
            if touchCallFunc then
                touchCallFunc()
            end
        end
        local listener1 = cc.EventListenerTouchOneByOne:create()
        if isTouchSwallow then
            listener1:setSwallowTouches(true)
        else
            listener1:setSwallowTouches(false)
        end
        listener1:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
        listener1:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
        local eventDispatcher = self.m_newbieMask:getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, self.m_newbieMask)
    end
end

function PuzzleGuideManager:highLightNode(index, node, maskLayer, noHigh, rootScale)
    local highKey = "step_" .. index
    if not noHigh then
        if not self.m_hideLishtList then
            self.m_hideLishtList = {}
        end
        if not self.m_hideLishtList[highKey] then
            self.m_hideLishtList[highKey] = {highKey = highKey, highNode = node, lastParent = node:getParent(), lastZOrder = node:getLocalZOrder()}
        end
    end

    -- 提高node的层级到遮罩层之上
    local pos = cc.p(node:getPosition())
    local worldPos = node:getParent():convertToWorldSpace(cc.p(pos.x, pos.y))
    local localPos = maskLayer:convertToNodeSpace(worldPos)
    if not noHigh then
        self.m_hideLishtList[highKey].localPos = localPos
        util_changeNodeParent(maskLayer, node, ViewZorder.ZORDER_GUIDE + 1)
        node:setPosition(localPos)
        node:setScale(rootScale)
    end
    return localPos
end

function PuzzleGuideManager:resetHighLightNode(index)
    local highKey = "step_" .. index
    if self.m_hideLishtList and self.m_hideLishtList[highKey] then
        local nodeInfo = self.m_hideLishtList[highKey]
        local highNode = nodeInfo.highNode
        local lastParent = nodeInfo.lastParent
        local lastZOrder = nodeInfo.lastZOrder
        if lastParent then
            local worldPos = highNode:getParent():convertToWorldSpace(cc.p(highNode:getPosition()))
            local localPos = lastParent:convertToNodeSpace(worldPos)
            util_changeNodeParent(lastParent, highNode, lastZOrder)
            highNode:setPosition(localPos)
            highNode:setScale(1)
        end
        self.m_hideLishtList[highKey] = nil
    end
end

function PuzzleGuideManager:addBubble(pos, offset, index)
    if not self.m_guideBubble then
        self.m_guideBubble = {}
    end
    if not self.m_guideBubble[index] then
        local view = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGuideView")
        gLobalViewManager:getViewLayer():addChild(view, ViewZorder.ZORDER_GUIDE + 1) -- 注意层级

        local x, y = pos.x, pos.y
        if offset then
            x = x + offset[1]
            y = y + offset[2]
        end
        view:setPosition(cc.p(x, y))

        local data = CardSysRuntimeMgr:getPuzzleGameData()
        if data then
            local text = nil
            if index == 2 then
                text = data.pickLeft
            elseif index == 7 then
                text = data.purchasePicksLimit
            end
            view:updateUI(index, text)
            self.m_guideBubble[index] = view
        end
    end
end

function PuzzleGuideManager:delBubble(index)
    if self.m_guideBubble and self.m_guideBubble[index] then
        if self.m_guideBubble[index].closeUI then
            self.m_guideBubble[index]:closeUI()
        else
            self.m_guideBubble[index]:removeFromParent()
        end
        self.m_guideBubble[index] = nil
    end
end

--显示finger
function PuzzleGuideManager:addFinger(pos, offset)
    if not self.m_spineFinger then
        self.m_spineFinger = util_spineCreate("CardRes/season201904/CashPuzzle/other/DailyBonusGuide", true, true, 1)
        gLobalViewManager:getViewLayer():addChild(self.m_spineFinger, ViewZorder.ZORDER_GUIDE + 1) -- 注意层级
        self.m_spineFinger:setPosition(cc.p(pos.x, pos.y))
        util_spinePlay(self.m_spineFinger, "idleframe", true)
    end
end

--隐藏finger
function PuzzleGuideManager:delFinger()
    if self.m_spineFinger ~= nil then
        self.m_spineFinger:removeFromParent()
        self.m_spineFinger = nil
    end
end

return PuzzleGuideManager

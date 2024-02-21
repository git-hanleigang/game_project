--[[
    主逻辑
]]
-- local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local LSGameLogic = class("LSGameLogic", BaseLayer)

function LSGameLogic:setStatus(_logicKey, _status)
    self["logicStatus_" .. _logicKey] = _status
end

function LSGameLogic:getStatusByKey(_logicKey)
    return self["logicStatus_" .. _logicKey]
end

function LSGameLogic:nextTriggerLogic(_key)
    local eventList = nil
    if _key == "stamp" then
        eventList = self.m_stampEventList
    elseif _key == "onceStamp" then
        eventList = self.m_onceStampEventList
    elseif _key == "roll" then
        eventList = self.m_rollEventList
    elseif _key == "reconnectCollect" then
        eventList = self.m_reconnectCollectEventList
    end
    if not eventList or #eventList <= 0 then
        self:setStatus(_key, false)
        return
    end
    local eventData = table.remove(eventList, 1)
    local func = eventData[1]
    func(eventData[2], eventData[3])
end
--
-----------------------------------------------------------------------------------------
--[[--
    盖单戳流程
        盖戳 [→ 格子升级] → 金币上升
    盖多戳流程
        开始 → 盖单戳流程 xN → 结束
    抽奖流程
        点击按钮 → 开始滚动
    抽奖结算流程
        结算界面 → 重置金币
    
    流程组合：
        只盖戳： 盖多戳流程 → 界面关闭
        盖戳+玩游戏： 盖多戳流程 → 抽奖流程 → 界面关闭
        盖戳+玩游戏+盖戳： 盖多戳流程 → 抽奖流程 → 盖多戳流程 → 界面关闭
    总结为一个流程
        盖戳+玩游戏+盖戳： 盖多戳流程 [→ 界面关闭] → 抽奖流程 [→ 界面关闭] → 盖多戳流程 → 界面关闭
    
    优化：先盖戳，然后格子数值上涨，盖戳处飞出粒子飞至变色格子处,格子播放变化动效
    
    断线重连
        付费后没有弹出盖戳，断线从盖戳开始
        没有抽奖的，开始抽奖，
        盖戳后没有领奖的，开始领奖
--]]
function LSGameLogic:initStampLogic()
    self.m_stampEventList = {}
    table.insert(self.m_stampEventList, {handler(self, self.onceStamp_start)})
    table.insert(self.m_stampEventList, {handler(self, self.onceStamp_playStamp)})
    table.insert(self.m_stampEventList, {handler(self, self.onceStamp_upCoin)})
    table.insert(self.m_stampEventList, {handler(self, self.onceStamp_flyLizi)})
    -- table.insert(self.m_stampEventList, {handler(self, self.onceStamp_upFireCoins)})
    table.insert(self.m_stampEventList, {handler(self, self.onceStamp_upBox)})
    table.insert(self.m_stampEventList, {handler(self, self.onceStamp_over)})
end

function LSGameLogic:initRollLogic()
    local key = "roll"
    self.m_rollEventList = {}
    table.insert(self.m_rollEventList, {handler(self, self.startRoll)})
    table.insert(self.m_rollEventList, {handler(self, self.overRoll)})
    table.insert(self.m_rollEventList, {handler(self, self.playWinEffect)})
    table.insert(self.m_rollEventList, {handler(self, self.showRewardUI), key})
    table.insert(self.m_rollEventList, {handler(self, self.resetBox), key})
    table.insert(self.m_rollEventList, {handler(self, self.switch2Stamp), key})
end

function LSGameLogic:initReconnectCollectLogic()
    local key = "reconnectCollect"
    self.m_reconnectCollectEventList = {}
    table.insert(self.m_reconnectCollectEventList, {handler(self, self.showRewardUI), key})
    table.insert(self.m_reconnectCollectEventList, {handler(self, self.resetBox), key})
    table.insert(self.m_reconnectCollectEventList, {handler(self, self.switch2Stamp), key})
end

function LSGameLogic:doStampLogic()
    local key = "stamp"
    self:setStatus(key, true)
    self:initStampLogic()
    self:nextTriggerLogic(key)
end

function LSGameLogic:doRollLogic()
    local key = "roll"
    self:setStatus(key, true)
    self:initRollLogic()
    self:nextTriggerLogic(key)
end

function LSGameLogic:doReconnectCollectLogic()
    local key = "reconnectCollect"
    self:setStatus(key, true)
    self:initReconnectCollectLogic()
    self:nextTriggerLogic(key)
end

-----------------------------------------------------------------------------------------

function LSGameLogic:onceStamp_start()
    local key = "stamp"
    local needStampCount = self:getNeedStampNum()
    print("--- onceStamp_start ---", needStampCount)
    if needStampCount < 1 then
        self:setStatus(key, false)
        return
    end
    -- 处理数据
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processIdx = data:getProcessIndex()
        local nextIdx = processIdx + 1
        data:setProcessIndex(nextIdx)
        data:setLocalCacheProcess(nextIdx)
    end
    self:nextTriggerLogic(key)
end

function LSGameLogic:onceStamp_playStamp()
    local key = "stamp"
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processIdx = data:getProcessIndex()
        local processData = data:getProcessDataByIndex(processIdx)
        if processData then
            -- 播放盖戳动效
            gLobalSoundManager:playSound(LuckyStampCfg.otherPath .. "music/Stamp.mp3")
            local stampIndex = processData:getIndex()
            local stampType = processData:getStampType()
            self.m_stamp:showStampEffect(
                stampIndex,
                stampType,
                function()
                    if not tolua.isnull(self) then
                        self:nextTriggerLogic(key)
                    end
                end
            )
            -- 刷新戳
            local function updateStamp()
                if not tolua.isnull(self) then
                    self.m_stamp:updateStamps()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATA_LUCKYSTAMP)
                end
            end
            util_performWithDelay(self, updateStamp, 10 / 30)
        end
    end
end

-- 涨金币
function LSGameLogic:onceStamp_upCoin()
    local key = "stamp"
    gLobalSoundManager:playSound(LuckyStampCfg.otherPath .. "music/increase.mp3")
    local costTime = 0
    for i = 1, #self.m_boxes do
        costTime = self.m_boxes[i]:upCoin()
    end
    local time = self.m_topReward:upCoin()
    -- 回调
    local function callFunc()
        if not tolua.isnull(self) then
            self:nextTriggerLogic(key)
        end
    end
    util_performWithDelay(self, callFunc, math.max(costTime, time))
end

-- --更新新金币显示
-- function LSGameLogic:onceStamp_upFireCoins()
--     local key = "stamp"
--     for i = 1, #self.m_boxes do
--         self.m_boxes[i]:updateGoldenCoin()
--     end
--     self:nextTriggerLogic(key)
-- end

-- 飞粒子
function LSGameLogic:onceStamp_flyLizi()
    local key = "stamp"
    if self:isUpBoxType() then
        local data = G_GetMgr(G_REF.LuckyStamp):getData()
        if data then
            -- 获取目标位置
            local targetIndex = data:getNewGoldenLatticeIndex()
            print("getNewGoldenLatticeIndex targetIndex == ", targetIndex)
            if targetIndex ~= nil then
                local processIdx = data:getProcessIndex()
                local lizi = G_GetMgr(G_REF.LuckyStamp):showFlyLizi()
                if lizi then
                    local wPos = self.m_stamp:getStampWorldPos(processIdx)
                    local lPos = lizi:getParent():convertToNodeSpace(wPos)
                    -- 设置当前位置
                    lizi:setPosition(lPos)
                    gLobalSoundManager:playSound(LuckyStampCfg.otherPath .. "music/fly.mp3")
                    local boxWorldPos = self:getBoxWorldPos(targetIndex)
                    local targetPos = lizi:getParent():convertToNodeSpace(boxWorldPos)
                    -- 动作
                    local actionList = {}
                    actionList[#actionList + 1] = cc.MoveTo:create(0.3, targetPos)
                    actionList[#actionList + 1] =
                        cc.CallFunc:create(
                        function()
                            if not tolua.isnull(self) then
                                self:nextTriggerLogic(key)
                                util_performWithDelay(
                                    self,
                                    function()
                                        local lizi = gLobalViewManager:getViewByName("LSFlyLizi")
                                        if not tolua.isnull(lizi) then
                                            lizi:removeFromParent()
                                        end
                                    end,
                                    0.1
                                )
                            end
                        end
                    )
                    lizi:runAction(cc.Sequence:create(actionList))
                else
                    self:nextTriggerLogic(key)
                end
            else
                self:nextTriggerLogic(key)
            end
        end
    else
        self:nextTriggerLogic(key)
    end
end

function LSGameLogic:onceStamp_upBox()
    local key = "stamp"
    if self:isUpBoxType() then
        local costTime = 0
        for i = 1, #self.m_boxes do
            local upTime = self.m_boxes[i]:upBox()
            costTime = math.max(upTime, costTime)
        end
        local function callFunc()
            if not tolua.isnull(self) then
                self:nextTriggerLogic(key)
            end
        end
        util_performWithDelay(self, callFunc, costTime)
    else
        self:nextTriggerLogic(key)
    end
end

function LSGameLogic:onceStamp_over()
    local key = "stamp"
    -- 判断逻辑
    if self:isActiveGame() then
        self.m_stamp:switch2Roll(
            function()
                if not tolua.isnull(self) then
                    self:nextTriggerLogic(key)
                end
            end
        )
    else
        self:nextTriggerLogic(key)
        local needStampCount = self:getNeedStampNum()
        if needStampCount > 0 then
            self:doStampLogic()
        end
    end
end

-- 滚动开始
function LSGameLogic:startRoll()
    local key = "roll"
    local winIndex = self:getWinIndex()
    if winIndex and winIndex >= 0 then
        self.m_rollCtrl:setStopIndex(winIndex)
        self.m_rollCtrl:startRoll(
            function(_index, _count)
                if not tolua.isnull(self) then
                    self:changeRollEffectPosition(_index)
                end
            end,
            function()
                if not tolua.isnull(self) then
                    self:nextTriggerLogic(key)
                end
            end
        )
    else
        if DEBUG == 2 then
            assert("error, winIndex = nil")
        end
        self:setStatus(key, false)
    end
end

function LSGameLogic:overRoll()
    local key = "roll"
    self:nextTriggerLogic(key)
end

function LSGameLogic:playWinEffect()
    local key = "roll"
    gLobalSoundManager:playSound(LuckyStampCfg.otherPath .. "music/win.mp3")
    self.m_rollEffect:playWin(
        function()
            if not tolua.isnull(self) then
                self:nextTriggerLogic(key)
            end
        end
    )
end

function LSGameLogic:showRewardUI(key)
    G_GetMgr(G_REF.LuckyStamp):showRewardLayer(
        function()
            if not tolua.isnull(self) then
                self:nextTriggerLogic(key)
            end
        end
    )
end

-- 重置奖励
function LSGameLogic:resetBox(key)
    for i = 1, #self.m_boxes do
        self.m_boxes[i]:resetBoxType()
        self.m_boxes[i]:resetCoin()
    end
    self:changeRollEffectPosition(1)
    self.m_rollEffect:playIdle()
    local function callFunc()
        if not tolua.isnull(self) then
            self:nextTriggerLogic(key)
        end
    end
    util_performWithDelay(self, callFunc, 0.5)
end

-- 重新盖戳
function LSGameLogic:switch2Stamp(key)
    local needStampCount = self:getNeedStampNum()
    if needStampCount > 0 then
        self:setStatus(key, false)
        -- 重置界面到盖戳状态
        self.m_stamp:switch2Stamp(
            function()
                if not tolua.isnull(self) then
                    -- 执行盖戳逻辑
                    self:doStampLogic()
                end
            end
        )
    else
        self:nextTriggerLogic(key)
        self:closeUI()
    end
end

function LSGameLogic:isActiveGame()
    if LuckyStampCfg.TEST_MODE == true then
        return true
    end
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processData = data:getCurProcessData()
        if processData then
            if processData:getWinIndex() >= 0 and processData:isSpin() == false then
                return true
            end
        end
    end
    return false
end

function LSGameLogic:isUpBoxType()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processData = data:getCurProcessData()
        if processData and processData:getStampType() == LuckyStampCfg.StampType.Golden then
            return true
        end
    end
    return false
end

return LSGameLogic

--[[
    主逻辑
    一共15轮，每轮结束都可以中途带走奖励，
    每轮如果没有开出鲨鱼要展示其他宝箱奖励，
    如果开出鲨鱼其他宝箱不打开同时弹框提示开出鲨鱼， 如果放弃游戏结束，如果不放弃本轮继续等待开启剩余宝箱。【如果四个宝箱都是鲨鱼，这是什么逻辑，holyshit】
    宝箱开出非鲨鱼奖励后，奖励入库，并且进入下一轮
    最后一轮，开完宝箱后，自动弹出最终结算界面
]]
local CSMainTouchControl = import(".CSMainTouchControl")
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local CSMainLogic = class("CSMainLogic", BaseActivityMainLayer)

function CSMainLogic:initDatas()
    CSMainLogic.super.initDatas(self)
end

function CSMainLogic:onEnter()
    CSMainLogic.super.onEnter(self)
end

function CSMainLogic:registerListener()
    CSMainLogic.super.registerListener(self)
end

function CSMainLogic:setStatus(_logicKey, _status)
    self["logicStatus_" .. _logicKey] = _status
end

function CSMainLogic:getStatusByKey(_logicKey)
    return self["logicStatus_" .. _logicKey]
end

function CSMainLogic:nextTriggerLogic(_key)
    local eventList = nil
    if _key == "start_monster" then
        eventList = self.m_startEventList
    elseif _key == "seek_monster" then
        eventList = self.m_seekMonsterEventList
    elseif _key == "seek_prize" then
        eventList = self.m_seekPrizeEventList
    end
    if not eventList or #eventList <= 0 then
        self:setStatus(_key, false)
        return
    end
    local eventData = table.remove(eventList, 1)
    local func = eventData[1]
    func(eventData[2], eventData[3])
end
-----------------------------------------------------------------------------------------
function CSMainLogic:initStartMonsterLogic()
    self.m_startEventList = {}
    -- 之前开出鲨鱼并且没有选择放弃或者付费
    table.insert(self.m_startEventList, {handler(self, self.seekMonster_hideWidget), "start_monster"})
    table.insert(self.m_startEventList, {handler(self, self.seekMonster_hideMonsterBox), "start_monster"})
    table.insert(self.m_startEventList, {handler(self, self.seekMonster_showMonsterUI), "start_monster"}) -- 如果选择放弃，停止逻辑，关闭界面后结束游戏 【断线重连】
    table.insert(self.m_startEventList, {handler(self, self.seekMonster_showWidget), "start_monster"}) -- 花钻石后，回到当前轮次，进入等待开宝箱
end

function CSMainLogic:initSeekMonsterLogic()
    self.m_seekMonsterEventList = {}
    table.insert(self.m_seekMonsterEventList, {handler(self, self.resetBtnTake), false, "seek_monster"})
    table.insert(self.m_seekMonsterEventList, {handler(self, self.openSelectBox), "seek_monster"})
    table.insert(self.m_seekMonsterEventList, {handler(self, self.seekMonster_hideWidget), "seek_monster"})
    table.insert(self.m_seekMonsterEventList, {handler(self, self.seekMonster_hideMonsterBox), "seek_monster"})
    table.insert(self.m_seekMonsterEventList, {handler(self, self.seekMonster_showMonsterUI), "seek_monster"}) -- 如果选择放弃，停止逻辑，关闭界面后结束游戏 【断线重连】
    table.insert(self.m_seekMonsterEventList, {handler(self, self.seekMonster_showWidget), "seek_monster"}) -- 花钻石后，回到当前轮次，进入等待开宝箱
    table.insert(self.m_seekMonsterEventList, {handler(self, self.resetBtnTake), true, "seek_monster"}) -- 本轮结束，进入等待开宝箱
    table.insert(self.m_seekMonsterEventList, {handler(self, self.seekMonsterOver)})
end

function CSMainLogic:initSeekPrizeLogic()
    self.m_seekPrizeEventList = {}
    table.insert(self.m_seekPrizeEventList, {handler(self, self.resetBtnTake), false, "seek_prize"})
    table.insert(self.m_seekPrizeEventList, {handler(self, self.openSelectBox), "seek_prize"})
    table.insert(self.m_seekPrizeEventList, {handler(self, self.seekPrize_openOtherBox)})
    table.insert(self.m_seekPrizeEventList, {handler(self, self.seekPrize_playSelectBoxRewardDisappear)})
    table.insert(self.m_seekPrizeEventList, {handler(self, self.seekPrize_playAddReward)})
    table.insert(self.m_seekPrizeEventList, {handler(self, self.seekPrize_showRoundReward)}) -- 最后一轮，关闭界面后结束游戏 【断线重连】
    table.insert(self.m_seekPrizeEventList, {handler(self, self.seekPrize_playProgressMove)})
    table.insert(self.m_seekPrizeEventList, {handler(self, self.seekPrize_playNpcBubble), "seek_prize"})
    table.insert(self.m_seekPrizeEventList, {handler(self, self.resetBtnTake), true, "seek_prize"}) -- 本轮结束，进入等待开宝箱
    table.insert(self.m_seekPrizeEventList, {handler(self, self.seekPrizeOver)})
end

function CSMainLogic:doStartMonsterLogic()
    local key = "start_monster"
    self:setStatus(key, true)
    self:initStartMonsterLogic()
    self:nextTriggerLogic(key)
end

function CSMainLogic:doSeekMonsterLogic()
    local key = "seek_monster"
    self:setStatus(key, true)
    self:initSeekMonsterLogic()
    self:nextTriggerLogic(key)
end

function CSMainLogic:doSeekPrizeLogic()
    local key = "seek_prize"
    self:setStatus(key, true)
    self:initSeekPrizeLogic()
    self:nextTriggerLogic(key)
end

-----------------------------------------------------------------------------------------
function CSMainLogic:resetBtnTake(_status, _logicKey)
    self:setBtnGoClickStatus(_status)
    self:nextTriggerLogic(_logicKey)
end

function CSMainLogic:openSelectBox(_key)
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local levelData = GameData:getLevelDataByIndex(self.m_cacheLevelIndex)
    local willBoxData = levelData:getWillOpenBoxRewardData()
    local box = self.m_boxList[self.m_selectBoxIndex]
    if box then
        -- 箱子打开
        box:playOpen()
        util_performWithDelay(
            self,
            function()
                if tolua.isnull(self) then
                    return
                end
                -- 添加宝箱奖励或者鲨鱼
                print("____self.m_selectBoxIndex____", self.m_selectBoxIndex)
                -- gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/box_click.mp3")
                if _key == "seek_monster" then
                    gLobalSoundManager:playSound(CardSeekerCfg.otherPath .. "music/openMonster.mp3")
                end
                local boxReward = self:createBoxReward(self.m_selectBoxIndex, willBoxData, false)
                boxReward:playStart(
                    function()
                        if not tolua.isnull(self) then
                            self:nextTriggerLogic(_key)
                        end
                    end
                )
            end,
            40 / 60
        )
    end
end

function CSMainLogic:seekMonster_hideWidget(_key)
    self:showWidget(false)
    self:nextTriggerLogic(_key)
end

function CSMainLogic:seekMonster_hideMonsterBox(_key)
    local box = self.m_boxList[self.m_selectBoxIndex]
    local boxWater = self.m_boxWaters[self.m_selectBoxIndex]
    if box then
        box:playHide(
            function()
                if not tolua.isnull(self) and not tolua.isnull(box) then
                    box:playHideIdle()
                    boxWater:setWaterShow(false)
                    self:clearBoxRewardByIndex(self.m_selectBoxIndex)
                end
            end
        )
    end
    self:nextTriggerLogic(_key)
end

function CSMainLogic:seekMonster_showMonsterUI(_key)
    G_GetMgr(G_REF.CardSeeker):showDefeatLayer(
        self.m_cacheLevelIndex,
        function()
            if not tolua.isnull(self) then
                self:nextTriggerLogic(_key)
            end
        end
    )
end

function CSMainLogic:seekMonster_showWidget(_key)
    self:showWidget(true)
    self:nextTriggerLogic(_key)
end

function CSMainLogic:seekMonsterOver()
    -- 晃动宝箱计时开始
    CSMainTouchControl:getInstance():startTiming()
    self:nextTriggerLogic("seek_monster")
end

-----------------------------------------------------------------------------------------
function CSMainLogic:seekPrize_openOtherBox()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    -- 打开其他箱子
    local levelData = GameData:getLevelDataByIndex(self.m_cacheLevelIndex)
    local otherBoxRewardDatas = levelData:getUnOpenedBoxRewardData()
    randomShuffle(otherBoxRewardDatas)
    local otherBoxIndex = 0
    for i = 1, CardSeekerCfg.BoxTotalCount do
        local box = self.m_boxList[i]
        local isOpened = levelData:isBoxOpened(i)
        if not isOpened then -- 未打开的箱子做动作
            box:playHide()
            otherBoxIndex = otherBoxIndex + 1
            local boxData = otherBoxRewardDatas[otherBoxIndex]
            print("____i____", i)
            local boxReward = self:createBoxReward(i, boxData, true)
            boxReward:playOtherStart()
        end
    end

    self:nextTriggerLogic("seek_prize")
    -- util_performWithDelay(
    --     self,
    --     function()
    --         if not tolua.isnull(self) then
    --             self:nextTriggerLogic("seek_prize")
    --         end
    --     end,
    --     1
    -- )
end

function CSMainLogic:seekPrize_playSelectBoxRewardDisappear()
    local boxReward = self:getBoxRewardByIndex(self.m_selectBoxIndex)
    if boxReward then
        boxReward:playDisappear(
            function()
                if not tolua.isnull(self) then
                    self:clearBoxRewardByIndex(self.m_selectBoxIndex)
                    self:nextTriggerLogic("seek_prize")
                end
            end
        )
        local boxWater = self.m_boxWaters[self.m_selectBoxIndex]
        if boxWater then
            boxWater:setWaterShow(false)
        end
    else
        self:nextTriggerLogic("seek_prize")
    end
end

function CSMainLogic:seekPrize_playAddReward()
    -- local GameData = self:getTSGameData()
    -- if not GameData then
    --     return
    -- end
    -- local levelData = GameData:getLevelDataByIndex(self.m_cacheLevelIndex)
    -- local boxData = levelData:getWillOpenBoxRewardData()
    -- local boxType = boxData:getType()
    -- local iconName = nil
    -- if boxType == CardSeekerCfg.BoxType.coin then
    --     iconName = "Coins"
    -- elseif boxType == CardSeekerCfg.BoxType.gem then
    --     iconName = "Gem"
    -- elseif boxType == CardSeekerCfg.BoxType.item then
    --     local itemDatas = boxData:getItems()
    --     if itemDatas and #itemDatas > 0 then
    --         for i = 1, #itemDatas do
    --             iconName = itemDatas[i].p_icon
    --         end
    --     end
    -- end
    self.m_reward:winReward(self.m_cacheLevelIndex)
    util_performWithDelay(
        self,
        function()
            if not tolua.isnull(self) then
                self:nextTriggerLogic("seek_prize")
            end
        end,
        1
    )
end

function CSMainLogic:seekPrize_showRoundReward()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local curLevelData = GameData:getCurLevelData()
    local openedIndexs = curLevelData:getOpenedClientPos()
    local cur = GameData:getCurLevelIndex()
    local max = GameData:getLevelCount()
    if cur == max and (openedIndexs and #openedIndexs > 0) then
        G_GetMgr(G_REF.CardSeeker):showRewardLayer(true) -- 结束游戏
    else
        self:nextTriggerLogic("seek_prize")
    end
end

function CSMainLogic:seekPrize_playProgressMove()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    -- 关卡球移动
    self.m_progress:moveBalls()
    local callFuncList = {}
    callFuncList[#callFuncList + 1] =
        cc.CallFunc:create(
        function()
            if tolua.isnull(self) then
                return
            end
            local levelData = GameData:getLevelDataByIndex(self.m_cacheLevelIndex)
            for i = 1, CardSeekerCfg.BoxTotalCount do
                local isOpened = levelData:isBoxOpened(i)
                if not isOpened then -- 未打开的箱子奖励做动作
                    local boxReward = self:getBoxRewardByIndex(i)
                    if boxReward then
                        boxReward:playOtherDisappear(
                            i,
                            function(_index)
                                if not tolua.isnull(self) then
                                    self:clearBoxRewardByIndex(_index)
                                end
                            end
                        )
                    end
                end
            end
        end
    )
    callFuncList[#callFuncList + 1] = cc.DelayTime:create(20 / 60)
    callFuncList[#callFuncList + 1] =
        cc.CallFunc:create(
        function()
            if tolua.isnull(self) then
                return
            end
            local curLevelConfig = GameData:getCurLevelConfig()
            if not curLevelConfig then
                return
            end
            for i = 1, CardSeekerCfg.BoxTotalCount do
                -- 重置宝箱
                local box = self.m_boxList[i]
                local special = curLevelConfig:getSpecial()
                box:resetIcon(special)
                box:playStart(
                    function()
                        if not tolua.isnull(box) and not tolua.isnull(self) then
                            box:resetView()
                        end
                    end
                )
                -- 重置水波纹
                local boxWater = self.m_boxWaters[i]
                boxWater:setWaterShow(true)
            end
        end
    )
    callFuncList[#callFuncList + 1] = cc.DelayTime:create(80 / 60)
    callFuncList[#callFuncList + 1] =
        cc.CallFunc:create(
        function()
            if not tolua.isnull(self) then
                self:nextTriggerLogic("seek_prize")
            end
        end
    )

    self:runAction(cc.Sequence:create(callFuncList))
    -- self:openCG(
    --     function()
    --         if not tolua.isnull(self) then
    --             self:nextTriggerLogic("seek_prize")
    --         end
    --     end
    -- )
    -- util_performWithDelay(
    --     self,
    --     function()
    --         -- 重置宝箱
    --         self:resetBoxes()
    --         self.m_progress:moveBalls()
    --     end,
    --     1
    -- )
end

-- function CSMainLogic:seekPrize_resetBoxes()
--     local GameData = self:getTSGameData()
--     if not GameData then
--         return
--     end
--     local curLevelConfig = GameData:getCurLevelConfig()
--     if not curLevelConfig then
--         return
--     end
--     local special = curLevelConfig:getSpecial()
--     if self.m_boxList and #self.m_boxList > 0 then
--         for i = 1, #self.m_boxList do
--             self.m_boxList[i]:resetView(special)
--         end
--     end
--     self:nextTriggerLogic("seek_prize")
-- end

-- function CSMainLogic:seekPrize_closeCG()
--     self:closeCG(
--         function()
--             self:nextTriggerLogic("seek_prize")
--         end
--     )
--     self:nextTriggerLogic("seek_prize")
-- end

function CSMainLogic:seekPrize_playNpcBubble(_key)
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local levelIndex = GameData:getCurLevelIndex()
    -- local texts = CardSeekerCfg.getBubbleTextByLevelType(levelIndex)
    local levelBubbleType = GameData:getLevelBubbleType(levelIndex)
    local texts = CardSeekerCfg.getBubbleTextByLevelType(levelBubbleType)
    if texts and #texts > 0 then
        self.m_bubble:setVisible(true)
        self.m_bubble:showBubble(
            texts,
            function()
                if not tolua.isnull(self) and self.m_bubble then
                    self.m_bubble:setVisible(false)
                end
            end
        )
    end
    if _key then
        self:nextTriggerLogic(_key)
    end
end

function CSMainLogic:seekPrizeOver()
    -- 晃动宝箱计时开始
    CSMainTouchControl:getInstance():startTiming()
    self:nextTriggerLogic("seek_prize")
end

return CSMainLogic

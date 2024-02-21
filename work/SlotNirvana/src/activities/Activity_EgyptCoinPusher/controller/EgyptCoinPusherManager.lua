--[[
    EgyptCoinPusherManager
    tm - -
]]
-- FIX IOS 
local EgyptCoinPusherNet = require("activities.Activity_EgyptCoinPusher.net.EgyptCoinPusherNet")
local EgyptCoinPusherGuideMgr = require("activities.Activity_EgyptCoinPusher.controller.EgyptCoinPusherGuideMgr")
local EgyptCoinPusherManager = class("EgyptCoinPusherManager", BaseActivityControl)
local Config = require("activities.Activity_EgyptCoinPusher.config.EgyptCoinPusherConfig")
-- ctor
function EgyptCoinPusherManager:ctor()
    EgyptCoinPusherManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.EgyptCoinPusher)
    self._InLevel = nil --进入推币机等级
    self._LeaveLevel = nil --退出d
    self._Init = false

    self.m_rankExpireTime = 5 -- 过期时间
    self.m_getRankDataTime = 0 -- 获得排行榜数据的时间

    --自维数据 运行时数据
    self._PlayList = {} -- 玩法列表
    self._PlaySlotList = {} -- 玩法列表 老虎机吐币 列表

    self._RunningData = nil -- 运行中数据 以UI展示位标准
    self._PassStage = false -- 是否已经过关
    self._Round = nil -- 当前轮数
    self._Stage = nil -- 当前章节
    self.m_net = EgyptCoinPusherNet:create()
    self.m_guide = EgyptCoinPusherGuideMgr:getInstance()
    self:setSaveDirtyFlag(false)
end

function EgyptCoinPusherManager:getGuide()
    return self.m_guide
end

function EgyptCoinPusherManager:onStart()
    gLobalNoticManager:removeAllObservers(self)
    self._StageBuffOpen = self:checkHasStageCoinBuff()

    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData then
        self:initConfig()
        self:registerObserver()
        self:initEgyptCoinPusherData()
        self._Init = true
    else
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if params.name == ACTIVITY_REF.EgyptCoinPusher then
                    local coinPusherData = self:getEgyptCoinPusherData()
                    if not self._Init and coinPusherData then
                        self:initConfig()
                        self:registerObserver()
                        self:initEgyptCoinPusherData()
                        self._Init = true
                    end
                end
            end,
            ViewEventType.NOTIFY_REFRESH_ACTIVITY_DATA
        )
    end
end

function EgyptCoinPusherManager:registerObserver()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.EgyptCoinPusher then
                self:updateEgyptCoinPusherData()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_BUFF_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateEgyptCoinPusherData()
        end,
        ViewEventType.NOTIFY_BUYCOINS_SUCCESS
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateEgyptCoinPusherData()
        end,
        ViewEventType.NOTIFY_REFESH_COINPUSHER_SAVE_DATA
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params[1] == true then
                local spinData = params[2]
                if spinData.action == "SPIN" and spinData.extend and spinData.extend.coinPusherV3 and spinData.extend.coinPusherV3.rewardPushes and spinData.extend.coinPusherV3.rewardPushes > 0 then
                    self:updateEgyptCoinPusherDataInSpin(spinData.extend.coinPusherV3.totalPushes)
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.EgyptCoinPusher then
                self._Init = false
                gLobalNoticManager:removeAllObservers(self)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params == Config.PopCsbPath.Collect.Type then
                if self._CollectCallBack then
                    self._CollectCallBack()
                    self._CollectCallBack = nil
                end
            end
        end,
        Config.Event.EgyptCoinPusherEffectEnd
    )
end

function EgyptCoinPusherManager:initEgyptCoinPusherData()
    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData then
        self._EntitySaveKey = "EgyptCoinPusherEntity_" .. Config.Version .. "_" .. globalData.userRunData.userUdid .. tostring(coinPusherData.p_start)
        self._DataSaveKey = "EgyptCoinPusherData_" .. Config.Version .. "_" .. globalData.userRunData.userUdid .. tostring(coinPusherData.p_start)
        --self:clearEgyptCoinPusherData()
        self:InitSaveData()
    end

    if self.checkBufferTimer ~= nil then
        scheduler.unscheduleGlobal(self.checkBufferTimer)
        self.checkBufferTimer = nil
    end
    self.checkBufferTimer =
        scheduler.scheduleGlobal(
        function()
            if self:checkHasStageCoinBuff() then
                if not self._StageBuffOpen then
                    self._StageBuffOpen = true
                    --post
                    gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherStageBuffOpen)
                end
            else
                if self._StageBuffOpen then
                    self._StageBuffOpen = false
                    --post
                    gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherStageBuffClose)
                end
            end
        end,
        1
    )
end

-- 初始化 Config 配置
function EgyptCoinPusherManager:initConfig()
    local configPath = self:getConfigPath()
    Config = require(configPath)
end

-- 根据主题获取 Config 配置 路径
function EgyptCoinPusherManager:getConfigPath()
    local path = "activities.Activity_EgyptCoinPusher.config.EgyptCoinPusherConfig"
    local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.EgyptCoinPusher)
    if not config then
        return path
    end
    local theme = config:getThemeName()
    local pathList = {
        Activity_EgyptCoinPusher = "activities.Activity_EgyptCoinPusher.config.EgyptCoinPusherConfig"
    }
    return pathList[theme] or path
end

-- 获取 Config 配置
function EgyptCoinPusherManager:getConfig()
    return Config
end
----------------------------------------------- Game Data S ---------------------------------------------
--物理数据
function EgyptCoinPusherManager:saveEntityData(_EntityInfo)
    --过关数据发来 不再接收消息
    local attJson = cjson.encode(_EntityInfo)
    gLobalDataManager:setStringByField(self._EntitySaveKey, attJson)
end

--内存数据
function EgyptCoinPusherManager:saveRunningData()
    local runningData = {}
    runningData.PlayList = {}
    runningData.PlaySlotList = {} --老虎机吐币 单独记录
    --动画List
    for i, v in ipairs(self._PlayList) do
        local data = v:getRunningData()
        if not v:checkAllStateDone() then
            table.insert(runningData.PlayList, data)
        end
    end
    for i, v in ipairs(self._PlaySlotList) do
        local data = v:getRunningData()
        if not v:checkAllStateDone() then
            table.insert(runningData.PlaySlotList, data)
        end
    end
    --数据data
    if self._RunningData then
        runningData.RunningData = self._RunningData:getRunningData()
    end

    --判断是否过关  过关需要清空数据
    local attJson = cjson.encode(runningData)
    gLobalDataManager:setStringByField(self._DataSaveKey, attJson)
end

function EgyptCoinPusherManager:loadEntityData()
    --判断是否过关  过关需要清空数据
    local attJson = gLobalDataManager:getStringByField(self._EntitySaveKey, "{}")
    local entityAttList = cjson.decode(attJson)
    return entityAttList
end

function EgyptCoinPusherManager:loadRunningData()
    --判断是否过关  过关需要清空数据
    local attJson = gLobalDataManager:getStringByField(self._DataSaveKey, "{}")
    local attJson = cjson.decode(attJson)
    return attJson
end

--清除数据
function EgyptCoinPusherManager:clearEgyptCoinPusherData()
    gLobalDataManager:setStringByField(self._EntitySaveKey, "{}")
    gLobalDataManager:setStringByField(self._DataSaveKey, "{}")
end

--盘面初始数据
function EgyptCoinPusherManager:saveEgyptCoinPusherDeskstopData(Stage)
    local loadData = self:loadEgyptCoinPusherDeskstopData()
    local entityAttList = self._coinPushMain:getSceneEntityData()
    loadData[Stage] = entityAttList.Entity
    local attJson = cjson.encode(loadData)
    local path = cc.FileUtils:getInstance():getWritablePath()
    local f = io.open(path .. "tengdanb.json", "w+")
    f:write(attJson)
    f:close()
end

function EgyptCoinPusherManager:loadEgyptCoinPusherDeskstopData()
    local path = cc.FileUtils:getInstance():getWritablePath()
    local entityAttList = {}
    local f = io.open(path .. "tengdanb.json", "r")
    if f then
        entityAttList = f:read("*all")
        entityAttList = cjson.decode(entityAttList)
        f:close()
    end
    return entityAttList
end

function EgyptCoinPusherManager:loadCoingInitDisk()
    local pathConfig = "Activity/EgyptCoinPusherGame/EgyptCoinPusherInitDiskConfig.json"
    if not cc.FileUtils:getInstance():isFileExist(pathConfig) then
        return false
    end
    local jsonDatas = cc.FileUtils:getInstance():getStringFromFile(pathConfig)

    if jsonDatas then
        local diskDatas = cjson.decode(jsonDatas)
        if diskDatas and diskDatas[tostring(self._Stage)] then
            return true, diskDatas[tostring(self._Stage)]
        end
    end

    return false
end
----------------------------------------------- Game Data E ---------------------------------------------

----------------------------------------------- Net Work S ----------------------------------------------
-- 申请掉落道具 --
function EgyptCoinPusherManager:getItem(data, extraData, event)
    --数据二次组装
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local coinPusherData = self:getEgyptCoinPusherData()
    if not coinPusherData then
        return
    end
    if (not self._RunningData or coinPusherData:getStageDataStateById(self._RunningData:getStage()) ~= "PLAY" or self._RunningData:getRound() ~= coinPusherData:getRound()) then
        return
    end

    local successFunc = function(resultData)
        if resultData then
            local coinPusherData = self:getEgyptCoinPusherData()
            if coinPusherData then
                self._RunningData = self:updateRunningDataFromNet()
                self:saveRunningData()
                self:updataPlayList("Drop", {resultData.coins, extraData})
                --抛事件 成功回调后的事件 有掉落数据
                gLobalNoticManager:postNotification(event, true)
            end
        else
            --抛事件 成功回调后的事件 无掉落数据
            gLobalNoticManager:postNotification(event, false)
        end
    end

    local failedCallFun = function()
        -- gLobalViewManager:showReConnect()
    end

    self.m_net:requestGetItem(data, successFunc, failedCallFun)
end

-- 道具被退出台子后 申请奖励 --
function EgyptCoinPusherManager:dropItemReward(data, extraData, event)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successFunc = function(resData)
        local coinPusherData = self:getEgyptCoinPusherData()
        if coinPusherData then
            self:updataPlayList("PushOut", {resData, extraData})
        end
    end

    local failedCallFun = function()
        -- gLobalViewManager:showReConnect()
    end

    self.m_net:requestDropItemReward(data, successFunc, failedCallFun)
end

-- 掉入框内 记录老虎机 次数 --
function EgyptCoinPusherManager:requestRememberSlots(bug_ID)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successFunc = function(resData)
        local coinPusherData = self:getEgyptCoinPusherData()
        if coinPusherData then
        --self:updataPlayList("SLOTS", {resData,})
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EGYPTCOINPUSHER_REMEMBERSLOT, true)
    end

    local failedCallFun = function()
        -- gLobalViewManager:showReConnect()
    end

    self.m_net:requestRememberSlots(bug_ID,successFunc, failedCallFun)
end

-- 请求老虎机数据 --
function EgyptCoinPusherManager:requestSlots(data, extraData, event)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successFunc = function(resData)
        local coinPusherData = self:getEgyptCoinPusherData()
        if coinPusherData then
            self:updataPlayList("SLOTS", resData)
            coinPusherData:parseGameSoltData(resData)
            if resData.initCoins then
                coinPusherData:setLongPusherResetCoins(resData.initCoins)
            end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EGYPTCOINPUSHER_SLOTRESULT, true)
    end

    local failedCallFun = function()
        -- gLobalViewManager:showReConnect()
    end

    self.m_net:requestSlots(data, successFunc, failedCallFun)
end

-- DeBug 清除引导缓存
function EgyptCoinPusherManager:clearGuideRecord()
    self.m_guide:clearGuideRecord()
end

-- 获取排行榜信息
function EgyptCoinPusherManager:sendActionRank(_callFunc)
    -- 数据没有过期
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if curTime - self.m_getRankDataTime <= self.m_rankExpireTime then
        if _callFunc then
            _callFunc()
        end
        return
    end

    local successFunc = function(rankData)
        gLobalViewManager:removeLoadingAnima()

        if _callFunc then
            _callFunc()
        end

        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        self.m_getRankDataTime = curTime

        local gameData = self:getEgyptCoinPusherData()
        if gameData and rankData and rankData.myRank then
            gameData:setRankJackpotCoins(0)
            gameData:parseRankData(rankData)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.EgyptCoinPusher})
    end

    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        -- gLobalViewManager:showReConnect()
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    self.m_net:requestActionRank(successFunc, failedCallFun)
end

function EgyptCoinPusherManager:requestCollectReward(_params, succFunc, failedFunc)
    gLobalViewManager:addLoadingAnima(false, 1)

    local successFunc = function(resData)
        gLobalViewManager:removeLoadingAnima()
        if succFunc then
            succFunc(_params)
        end
        gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherGetDropCoinsReward, {isSuc = true, data = _params})
    end

    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if failedFunc then
            failedFunc()
        end
        gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherGetDropCoinsReward, {isSuc = false})
    end

    self.m_net:requestCollectReward(successFunc, failedCallFun)
end

----------------------------------------------- 自持数据维护 S -----------------------------------
--取服务器必要数据
function EgyptCoinPusherManager:getPlayData()
    local coinPusherData = self:getEgyptCoinPusherData()
    if not coinPusherData then
        return {}
    end

    local userData = coinPusherData:getRuningUserData()
    return userData
end

function EgyptCoinPusherManager:getEgyptCoinPusherData()
    return self:getRunningData()
end

--动画列表
--更新动画列表
function EgyptCoinPusherManager:updataPlayList(type, data)
    --过关数据发来 不再接收消息
    if self._PassStage then
        return
    end

    --type "PushOut"推下去 "Drop"落下
    if type == "PushOut" then
        local coinsData = data[1]
        local pos = nil
        if coinsData then
            if coinsData.coins then
                for i = 1, #coinsData.coins do
                    local coinsData = coinsData.coins[i]
                    local userData = self:getPlayData()
                    userData.Round = self._Round
                    userData.Stage = self._Stage
                    local playData = self:createPlayData(coinsData.type, coinsData)
                    self._PlayList[table_nums(self._PlayList) + 1] = playData
                end
            end

            if coinsData.stage then
                self._PassStage = true
                self._PlayList[1]:setStageData(coinsData.stage)
            end

            if coinsData.round then
                self._PassStage = true
                self._PlayList[1]:setRoundData(coinsData.round)
            end
        end
    elseif type == "Drop" then
        --暂时这样做 全部都加到动画list 中防止数据显示问题
        if data then
            local playData = self:createPlayData("DROP", data)
            self._PlayList[table_nums(self._PlayList) + 1] = playData
        -- gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherTriggerEffect, {"DROP", playData})
        end
    elseif type == "SLOTS" then
        if data then
            local playData = self:createPlayData("SLOTS", data)
            self._PlaySlotList[table_nums(self._PlaySlotList) + 1] = playData
        end
    end

    --动画更新后存档
    self:setSaveDirtyFlag(true)
end

--断线重连
function EgyptCoinPusherManager:reconnectionPlay()
    if table_nums(self._PlayList) < 1 and table_nums(self._PlaySlotList) < 1 then
        self._PassStage = false
        return
    end

    -- 去除金币和加成重连弹窗
    for i = #self._PlayList, 1, -1 do
        local data = self._PlayList[i]
        local actionType = data:getActionType() or ""
        if actionType == "COINS" or actionType == "STAGE_COINS" then
            table.remove(self._PlayList, i)
        end
    end

    for i = #self._PlayList, 1, -1 do
        local data = self._PlayList[i]
        if data:getActionState() == Config.PlayState.DONE then
            self:checkPlayEffectEnd(data, i)
            return
        elseif data:getActionState() == Config.PlayState.PLAYING then
            self:triggerPlay(i)
            return
        end
    end

    for i = #self._PlaySlotList, 1, -1 do
        local data = self._PlaySlotList[i]
        if data:getActionState() == Config.PlayState.DONE then
            self:checkPlayEffectEnd(data, i, true)
            return
        elseif data:getActionState() == Config.PlayState.PLAYING or data:getActionState() == Config.PlayState.IDLE then
            self:triggerPlaySlotEffet(i, true)
            return
        end
    end

    self:saveRunningData()
end

--刷帧监听动画
function EgyptCoinPusherManager:playTick(dt)
    local hasPlaying = false
    if table_nums(self._PlayList) < 1 then
    else
        for i = #self._PlayList, 1, -1 do
            local data = self._PlayList[i]
            local playState = data:getActionState()

            if playState == Config.PlayState.DONE then
                self:checkPlayEffectEnd(data, i)
            elseif playState == Config.PlayState.PLAYING then
                hasPlaying = true
                break
            end
        end

        --顺序播放 所以这里是从1开始
        if not hasPlaying and table_nums(self._PlayList) > 0 then
            self:triggerPlay(1)
        end
    end
end

function EgyptCoinPusherManager:checkSlotEffect()
    local hasPlaying = false
    local result = false
    if table_nums(self._PlaySlotList) < 1 then
    else
        for i = #self._PlaySlotList, 1, -1 do
            local data = self._PlaySlotList[i]
            local playState = data:getActionState()

            if playState == Config.PlayState.DONE then
                self:checkPlayEffectEnd(data, i, true)
            elseif playState == Config.PlayState.PLAYING then
                hasPlaying = true
                break
            end
        end
        if not hasPlaying and table_nums(self._PlaySlotList) > 0 then
            result = true
            self:triggerPlaySlotEffet(1)
        end
    end
    return result
end

--触发玩法
function EgyptCoinPusherManager:triggerPlay(index)
    local data = self:getPlayListData(index)
    local playType = data:getActionType()
    data:setActionState(Config.PlayState.PLAYING)

    gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherTriggerEffect, {playType, data})
end

--触发玩法
function EgyptCoinPusherManager:triggerPlaySlotEffet(index, isReConnect)
    self._PlaySlotList = self:checkPlayListEnd(self._PlaySlotList) --检查PlaySlotList是否有完成
    if self:getPlaySlotListCount() <= 0 then
        return false
    end
    local data = self:getPlaySlotListData(index)
    local playType = data:getActionType()
    if data:getActionState() == Config.PlayState.PLAYING and not isReConnect then
        if self:getPlaySlotListCount() > 1 then
            return true
        end
        return false
    end
    data:setActionState(Config.PlayState.PLAYING)
    gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherTriggerEffect, {playType, data})
    return true
end

--动画播完
function EgyptCoinPusherManager:checkPlayEffectEnd(data, i, isSlotList)
    --阻断播放领奖弹板
    if data:checkStagePass() then
        gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherStageLayer, data)
        self._PlayList = {}
        self._PlaySlotList = {}
        return
    elseif data:checkRoundPass() then
        gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherRoundLayer, data)
        self._PlayList = {}
        self._PlaySlotList = {}
        return
    else
        local newData = data:getUserData()
        local coinPusherData = self:getEgyptCoinPusherData()
        if not coinPusherData then
            return
        end

        if coinPusherData:getStageDataStateById(self._Stage) == "COMPLETED" or self._Stage ~= newData:getStage() then
            -- self:updateMaxScore(coinPusherData:getPushes())
            -- self._RunningData.Pushes = newData.Pushes
        else
            --更新数据
            if (not self._RunningData or coinPusherData:getStageDataStateById(self._RunningData:getStage()) ~= "PLAY" or self._RunningData:getRound() ~= coinPusherData:getRound()) then
            else
                data:updateUserData()
                self._RunningData = data:getUserData()
            end
            gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherUpdateMainUI)
        end
        if isSlotList then
            table.remove(self._PlaySlotList, i)
        else
            table.remove(self._PlayList, i)
        end
        self:setSaveDirtyFlag(true)
    end
end

function EgyptCoinPusherManager:getPlayListData(index)
    return self._PlayList[index]
end

function EgyptCoinPusherManager:getPlayListCount()
    return table.nums(self._PlayList)
end

function EgyptCoinPusherManager:getPlaySlotListData(index)
    return self._PlaySlotList[index]
end

function EgyptCoinPusherManager:getPlaySlotListCount()
    local result = 0
    for i = #self._PlaySlotList, 1, -1 do
        local data = self._PlaySlotList[i]
        local playState = data:getActionState()
        if playState ~= Config.PlayState.DONE then
            result = result + 1
            break
        end
    end
    return result
end

function EgyptCoinPusherManager:isPlaySlotListWorking()
    local result = false
    for i = #self._PlaySlotList, 1, -1 do
        local data = self._PlaySlotList[i]
        local playState = data:getActionState()
        if playState ~= Config.PlayState.DONE then
            result = true
            break
        end
    end
    if result then
        self:checkSlotEffect()
    end
    return result
end

function EgyptCoinPusherManager:setPlayEnd(data)
    data:setActionState(Config.PlayState.DONE)
    self:setSaveDirtyFlag(true)
end

---创建动画数据
function EgyptCoinPusherManager:createPlayData(type, data)
    local actionData = self:createActionData(type)
    --获取最新的数据
    actionData:setActionType(type)
    actionData:setActionData(data)
    actionData:updateUserData()
    return actionData
end

--各种动画数据
function EgyptCoinPusherManager:createActionData(type)
    local actionData = nil
    local _dataModule = nil
    if type == Config.CoinEffectRefer.NORMAL or type == Config.CoinEffectRefer.BIG then
        _dataModule = require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherBaseActionData")
    elseif type == Config.CoinEffectRefer.DROP then
        _dataModule = require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherDropCoinData")
    elseif type == Config.CoinEffectRefer.COINS then
        _dataModule = require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherPopCoinViewData")
    elseif type == Config.CoinEffectRefer.STAGE_COINS then
        _dataModule = require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherPopStageCoinViewData")
    elseif type == Config.CoinEffectRefer.CARD then
        _dataModule = require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherPopCardViewData")
    elseif type == Config.CoinEffectRefer.SLOTS then
        _dataModule = require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherSlotData")
    end
    actionData = _dataModule:create()
    if not actionData then
        assert(false, "Cant find this Type Data! Please check your data!")
    end
    return actionData
end

----------------------------------------------- 自持数据维护 E -----------------------------------

----------------------------------------------- 加载存档数据 S -----------------------------------
function EgyptCoinPusherManager:InitSaveData()
    self._PassStage = false
    --存档读数据
    self:loadSaveData()
    self:loadDataUpdateRunningData()
end

--读取数据
function EgyptCoinPusherManager:loadSaveData()
    self._EntityData = self:loadEntityData() or {}
    self._RunningLoadData = self:loadRunningData() or {}
end

function EgyptCoinPusherManager:getSaveData()
    return self._RunningLoadData, self._EntityData
end

--加载数据判断是否过关
function EgyptCoinPusherManager:loadDataUpdateRunningData()
    local coinPusherData = self:getEgyptCoinPusherData()
    if not coinPusherData then
        return
    end

    local runningData = self._RunningLoadData.RunningData
    local playList = self._RunningLoadData.PlayList
    local playSlotList = self._RunningLoadData.PlaySlotList

    --判断是否已经过关 过关存档数据清空
    if runningData and table.nums(runningData) > 0 and (coinPusherData:getStageDataStateById(runningData.Stage) ~= "PLAY" or runningData.Round ~= coinPusherData:getRound()) then
        --清除存档
        self:clearEgyptCoinPusherData()
        self._RunningData = {}
        self._PlayList = {}
        self._PlaySlotList = {}
        runningData = nil
        playList = nil
        playSlotList = nil
    end

    local hasLocalData = false
    --更新播放列表
    if runningData and playSlotList then
        hasLocalData = true
        self._PlaySlotList = {}
        for i, v in ipairs(playSlotList) do
            local actionData = self:createActionData(v.ActionType)
            actionData:setRunningData(v)
            table.insert(self._PlaySlotList, i, actionData)
        end
    end
    --更新播放列表
    if runningData and playList then
        hasLocalData = true
        self._PlayList = {}
        for i, v in ipairs(playList) do
            local actionData = self:createActionData(v.ActionType)
            actionData:setRunningData(v)
            table.insert(self._PlayList, i, actionData)
        end
    end

    if hasLocalData then
        self._RunningData = self:createRunningData(runningData)
        --同步服务器币个数
        local data = self:getEgyptCoinPusherData()
        if data then
            self:updateEgyptCoinPusherDataInSpin(data:getPushes())
        end
    else
        self._RunningData = self:updateRunningDataFromNet()
    end

    self._Stage = self._RunningData:getStage()
    self._Round = self._RunningData:getRound()
    self:saveRunningData()
end

--进入关卡前检查是否过关
function EgyptCoinPusherManager:checkRunningDataPassStage()
    --判断是否已经过关 过关存档数据清空
    local coinPusherData = self:getEgyptCoinPusherData()
    if not coinPusherData then
        return
    end

    if (not self._RunningData or coinPusherData:getStageDataStateById(self._RunningData:getStage()) ~= "PLAY" or self._RunningData:getRound() ~= coinPusherData:getRound()) then
        self._RunningData = {}
        self._PlayList = {}
        self._PlaySlotList = {}
        --清除存档
        self:clearEgyptCoinPusherData()
    end
    --充值内存数据
    self._RunningData = self:updateRunningDataFromNet()
    self._Stage = self._RunningData:getStage()
    self._Round = self._RunningData:getRound()
    self:saveRunningData()
end

function EgyptCoinPusherManager:updateRunningDataFromNet()
    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData then
        return self:createRunningData(coinPusherData:getRuningData())
    else
        return {}
    end
end

function EgyptCoinPusherManager:createRunningData(runningData)
    local _dataModule = require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherRunningData")
    local runingUserDate = _dataModule:create()
    runingUserDate:setRunningData(runningData)
    return runingUserDate
end

function EgyptCoinPusherManager:leaveEgyptCoinPusherUpdateData()
    local coinPusherData = self:getEgyptCoinPusherData()
    if not coinPusherData then
        return
    end

    if self._PassStage then
        -- self:setShowSelectView(true)
        --如果过关 清空数据
        self:clearEgyptCoinPusherData()
        --充值内存数据
        self._RunningData = self:updateRunningDataFromNet()
        self._Stage = self._RunningData:getStage()
        self._Round = self._RunningData:getRound()
        self._PassStage = false
        self._PlayList = {}
        self._PlaySlotList = {}
        self._EntityData.Entity = nil
        self:setSaveDirtyFlag(false)
    end
end

function EgyptCoinPusherManager:getStagePushCoin()
    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData then
        return coinPusherData:getStagePushCoinsData(self._Stage)
    else
        return {}
    end
end

function EgyptCoinPusherManager:getLongPusherCoins()
    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData then
        return coinPusherData:getStageLongPusherResetCoinsData(self._Stage)
    else
        return {}
    end
end

function EgyptCoinPusherManager:getLeftSlotCount()
    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData then
        return coinPusherData:getLeftSlotCount(self._Stage)
    else
        return 0
    end
end
----------------------------------------------- 加载存档数据 E -----------------------------------

----------------------------------------------- buff处理 S ----------------------------------
function EgyptCoinPusherManager:updateEgyptCoinPusherData()
    local coinPusherData = self:getEgyptCoinPusherData()
    if not coinPusherData then
        return
    end

    --更新playlist 和 runningData 回调
    if table.nums(self._PlayList) > 0 then
        local addPushesCount = coinPusherData:getPushes() - self._PlayList[#self._PlayList]:getUserDataPushes()
        if addPushesCount > 0 then
            for i = 1, #self._PlayList do
                local playEffect = self._PlayList[i]
                playEffect:addUserDataPushesCount(addPushesCount)
            end
            self._RunningData:setPushes(self._RunningData:getPushes() + addPushesCount)
            gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherUpdateMainUI)
        end
    else
        if table.nums(self._PlaySlotList) > 0 then
            local addPushesCount = coinPusherData:getPushes() - self._PlaySlotList[#self._PlaySlotList]:getUserDataPushes()
            if addPushesCount > 0 then
                for i = 1, #self._PlaySlotList do
                    local playEffect = self._PlaySlotList[i]
                    playEffect:addUserDataPushesCount(addPushesCount)
                end
                self._RunningData:setPushes(self._RunningData:getPushes() + addPushesCount)
                gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherUpdateMainUI)
            end
        elseif self._RunningData:getPushes() ~= coinPusherData:getPushes() then
            self._RunningData:setPushes(coinPusherData:getPushes())
            gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherUpdateMainUI)
        end
    end
end

function EgyptCoinPusherManager:updateEgyptCoinPusherDataInSpin(_totlePusherCount)
    --更新playlist 和 runningData 回调
    if table.nums(self._PlayList) > 0 then
        local addPushesCount = _totlePusherCount - self._PlayList[#self._PlayList]:getUserDataPushes()
        if addPushesCount > 0 then
            for i = 1, #self._PlayList do
                local playEffect = self._PlayList[i]
                playEffect:addUserDataPushesCount(addPushesCount)
            end
            self._RunningData:setPushes(self._RunningData:getPushes() + addPushesCount)
            gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherUpdateMainUI)
        end
    else
        if table.nums(self._PlaySlotList) > 0 then
            local addPushesCount = _totlePusherCount - self._PlaySlotList[#self._PlaySlotList]:getUserDataPushes()
            if addPushesCount > 0 then
                for i = 1, #self._PlaySlotList do
                    local playEffect = self._PlaySlotList[i]
                    playEffect:addUserDataPushesCount(addPushesCount)
                end
                self._RunningData:setPushes(self._RunningData:getPushes() + addPushesCount)
                gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherUpdateMainUI)
            end
        elseif self._RunningData:getPushes() ~= _totlePusherCount then
            self._RunningData:setPushes(_totlePusherCount)
            gLobalNoticManager:postNotification(Config.Event.EgyptCoinPusherUpdateMainUI)
        end
    end
end

function EgyptCoinPusherManager:checkHasStageCoinBuff()
    local coinPusherData = self:getEgyptCoinPusherData()
    if not coinPusherData then
        return false
    end

    local leftTime = coinPusherData:getBuffPrizeLT()
    return leftTime > 0
end

--检测Playlist是否有完成
function EgyptCoinPusherManager:checkPlayListEnd(_playList)
    local playList = {}
    for i, v in ipairs(_playList) do
        local data = v:getRunningData()
        if not v:checkAllStateDone() then
            table.insert(playList, v)
        end
    end
    return playList
end

----------------------------------------------- buff处理   E ----------------------------------

----------------------------------------------- 一些get方法 S -----------------------------------

function EgyptCoinPusherManager:getRuningData()
    return self._RunningData
end

function EgyptCoinPusherManager:getPushes()
    if self._RunningData then
        return self._RunningData:getPushes()
    end
    return 0
end

function EgyptCoinPusherManager:getStageDataById(index)
    local coinPusherData = self:getEgyptCoinPusherData()
    if not coinPusherData then
        return {}
    end

    return coinPusherData:getStageDataById(index)
end

function EgyptCoinPusherManager:getEgyptCoinPusherPlayListCount()
    return table.nums(self._PlayList)
end

function EgyptCoinPusherManager:getStage()
    return self._Stage
end

function EgyptCoinPusherManager:isPassStage()
    return self._PassStage
end

function EgyptCoinPusherManager:getPlaneCoins()
    return self._RunningData:getPlaneCoins() + self:getRunStageAddCoins()
end

function EgyptCoinPusherManager:getPlaneCoinsPercent()
    local planeCoins = self._RunningData:getPlaneCoins()
    local pCoins = clone(planeCoins)
    if iskindof(planeCoins, "LongNumber") then
        pCoins = tonumber(planeCoins.lNum)
    end
    local baseCoins = self._RunningData:getPlaneBaseCoins()
    local bCoins = clone(baseCoins)
    if iskindof(baseCoins, "LongNumber") then
        bCoins = tonumber(baseCoins.lNum)
    end
    local percent = (pCoins - bCoins) * 100 / bCoins
    percent = math.floor(percent + 0.5)
    if self:getStageBuffState() then
        percent = percent + 100
    end
    return percent
end

function EgyptCoinPusherManager:getRunStageAddCoins()
    if self._StageBuffOpen then
        return self._RunningData:getPlaneBaseCoins()
    else
        return toLongNumber(0)
    end
end

function EgyptCoinPusherManager:getStageAddCoins(_Stage)
    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData and self._StageBuffOpen then
        return coinPusherData:getStageDataBaseCoinsById(_Stage)
    else
        return toLongNumber(0)
    end
end

function EgyptCoinPusherManager:getStageBuffState()
    return self._StageBuffOpen
end
----------------------------------------------- 一些get方法 S -----------------------------------

----------------------------------------------- 对外接口 S --------------------------------------
function EgyptCoinPusherManager:showMainLayer()
    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData then
        local time = coinPusherData:getExpireAt()
        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        local tempTime = time - curTime
        if tempTime > 5 then
            gLobalViewManager:gotoSceneByType(SceneType.Scene_EgyptCoinPusher)
        end
    end
end

function EgyptCoinPusherManager:showCollectRewardLayer(_callback)
    self._CollectCallBack = _callback
    local data = self:getEgyptCoinPusherData()
    if data then
        local allItems = data:getAllCollectItem()
        if #allItems > 0 then
            local cloneItems = clone(allItems)
            local succFunc = function(data)
                self:showRewardLayer(nil, data.items, 0, self:getStage(), Config.PopCsbPath.Collect)
            end
            self:requestCollectReward({items = cloneItems}, succFunc, _callback)
            return
        end
    end
    if _callback then
        _callback()
    end
end

--创建并且进入推币机scene
function EgyptCoinPusherManager:GoToEgyptCoinPusher(preMachineData)
    self:checkRunningDataPassStage()
    self._EntityData = self:loadEntityData() --重新加载实体存档
    self._PlayList = self:checkPlayListEnd(self._PlayList) --检查PlayList是否有完成
    self._PlaySlotList = self:checkPlayListEnd(self._PlaySlotList) --检查PlaySlotList是否有完成

    if preMachineData then
        globalData.slotRunData.gameRunPause = true
        self._entryLevelData = preMachineData
    else
        self._entryLevelData = nil
    end
    self:setOpenEgyptCoinPusherFlag()
    -- local newScene = cc.Scene:createWithPhysics()
    self._coinPushMain = util_createView("Activity.EgyptCoinPusherGame.EgyptCoinPusherMain", true)
    -- newScene:addChild(self._coinPushMain)
    self._ShowSelect = false

    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData then
        self._InLevel = coinPusherData:getStage()
    else
        self._InLevel = nil
    end

    --飞金币定位
    util_afterDrawCallBack(
        function()
            local winSize = cc.Director:getInstance():getWinSize()
            local endPos = {
                x = winSize.width * 0.1,
                y = winSize.height - util_getBangScreenHeight() - 30
            }
            globalData.recordHorizontalEndPos = endPos
        end
    )
    -- return newScene
    return self._coinPushMain
end

function EgyptCoinPusherManager:getCoinPushMain()
    return self._coinPushMain
end
-- 点击关闭退出
function EgyptCoinPusherManager:onClickLeaveCoinPusher()
    if not self:isPassStage() then
        self:showCollectRewardLayer(handler(self, self.LeaveEgyptCoinPusher))
    end
end

--退出推币机
function EgyptCoinPusherManager:LeaveEgyptCoinPusher()
    if self.m_isLeaving then
        return
    end

    self.m_isLeaving = true
    if not tolua.isnull(self._coinPushMain) then
        self._coinPushMain:leaveCoinPusher()
    end

    util_sendToSplunkMsg("LevelEgypt", "5--leaveEgyptCoinPusherUpdateData")
    self:leaveEgyptCoinPusherUpdateData()
    self:refreshLeaveLevel()
    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        _mgr:removeCollectNodeInfo("EgyptCoinPusherTop")
    end
    if self._entryLevelData then
        util_removeSearchPath("GameScreen")
        util_sendToSplunkMsg("LevelEgypt", "6--enterLevel")
        local isSucc = self:enterLevel(self._entryLevelData)
        if isSucc then
            util_sendToSplunkMsg("LevelEgypt", "7--enterLevel success!!")
            globalData.slotRunData.gameRunPause = nil
            globalData.slotRunData.gameResumeFunc = nil
            self._entryLevelData = nil
        end
    else
        globalData.leaveFromCoinPuhser = true
        release_print("EgyptCoinPusher back to lobby!!!")
        util_sendToSplunkMsg("LevelEgypt", "6--enterLobby")
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        util_sendToSplunkMsg("LevelEgypt", "7--enterLobby success!!")
    end
    self.m_isLeaving = false
end

-- 刷新退出推币机 leaveLevel
function EgyptCoinPusherManager:refreshLeaveLevel()
    local coinPusherData = self:getEgyptCoinPusherData()
    if coinPusherData then
        self._LeaveLevel = coinPusherData:getStage()
    else
        self._LeaveLevel = nil
    end
end

function EgyptCoinPusherManager:isCoinPusherEnterLevel()
    return self._isCoinPusher
end

function EgyptCoinPusherManager:removeEnterLevelFlag()
    self._isCoinPusher = false
end

--推币机退出后进入关卡
function EgyptCoinPusherManager:enterLevel(info)
    self._isCoinPusher = true
    return gLobalViewManager:gotoSlotsScene(info, nil, globalData.slotRunData.iLastBetIdx)
end

--检测是否过关 并且返回前一关卡,后一关卡 用于选择界面播放动画
function EgyptCoinPusherManager:checkPassStage()
    return self._InLevel ~= self._LeaveLevel and self._InLevel ~= nil and self._LeaveLevel ~= nil, self._InLevel, self._LeaveLevel
end

function EgyptCoinPusherManager:clearPassStageInfo()
    self._InLevel = nil
    self._LeaveLevel = nil
end

function EgyptCoinPusherManager:getShowSelectView()
    return self._ShowSelect
end

function EgyptCoinPusherManager:setShowSelectView(state)
    self._ShowSelect = state
end

function EgyptCoinPusherManager:setOpenEgyptCoinPusherFlag()
    self.m_levelToEgyptCoinPusher = nil
    if self._entryLevelData then
        self.m_levelToEgyptCoinPusher = self._entryLevelData.p_id
    end
end

function EgyptCoinPusherManager:getEgyptCoinPusherToLevelID()
    local flag = self.m_levelToEgyptCoinPusher
    self.m_levelToEgyptCoinPusher = nil
    return flag
end

function EgyptCoinPusherManager:showRankMainLayer()
    if not gLobalViewManager:getViewByExtendData("EgyptCoinPusherRankMainLayer") then
        local view = util_createView("Activity.EgyptCoinPusherGame.CoinPusherRank.EgyptCoinPusherRankMainLayer")
        if view then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end
end

function EgyptCoinPusherManager:setSaveDirtyFlag(flag)
    self.saveDirtyFlag = flag
end

function EgyptCoinPusherManager:getSaveDirtyFlag()
    return self.saveDirtyFlag
end

function EgyptCoinPusherManager:showRuleLayer(_bCoinSceneOpen)
    if not self:isCanShowLayer() then
        return nil
    end
    local ruleLayer = gLobalViewManager:getViewByExtendData("EgyptCoinPusherGamePromtView")
    if ruleLayer then
        return ruleLayer
    end
    local view = util_createView("Activity/EgyptCoinPusherGame/EgyptCoinPusherGamePromtView")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

----------------------------------------------- 对外接口 E ----------------------------------------------
function EgyptCoinPusherManager:showSelectLayer(_bCoinSceneOpen)
    if not self:isCanShowLayer() then
        return nil
    end

    self.m_guide:onRegist(ACTIVITY_REF.EgyptCoinPusher)

    local selectUI = gLobalViewManager:getViewByExtendData("EgyptCoinPusherSelectUI")
    if selectUI then
        return selectUI
    end

    if _bCoinSceneOpen then
        self:refreshLeaveLevel()
    end

    local view = util_createView("Activity/EgyptCoinPusherGame/EgyptCoinPusherSelectUI")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function EgyptCoinPusherManager:showPopLayer(popInfo, callback)
    if popInfo and type(popInfo) == "table" and popInfo.clickFlag then
        return self:showSelectLayer()
    else
        return EgyptCoinPusherManager.super.showPopLayer(self, popInfo, callback)
    end
end

function EgyptCoinPusherManager:showRewardLayer(data, item, rewardCoins, stage, path)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity.EgyptCoinPusherGame.EgyptCoinPusherCardLayer", data, item, rewardCoins, stage, path)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function EgyptCoinPusherManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function EgyptCoinPusherManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function EgyptCoinPusherManager:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function EgyptCoinPusherManager:getWildBuff()
    local activityData = self:getEgyptCoinPusherData()
    local leftTimes = 0
    if activityData then
        leftTimes = activityData:getLeftWildLock()
    end
    return leftTimes and leftTimes > 0
end

function EgyptCoinPusherManager:checkDebugModleType(debugType)
    return self._debugType == debugType
end

function EgyptCoinPusherManager:setDebugModleType(debugType)
    self._debugType = debugType
end

function EgyptCoinPusherManager:checkDebugSlotModleType(debugType)
    if not self._debugSlotType then
        self._debugSlotType = 1
    end
    return self._debugSlotType == debugType
end

function EgyptCoinPusherManager:setDebugSlotModleType(debugType)
    self._debugSlotType = debugType
end

function EgyptCoinPusherManager:doDebugSlotGame()
    local resData = {coins = {}}
    if G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):checkDebugSlotModleType(1) then
        resData.coins.NORMAL = 5
    elseif G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):checkDebugSlotModleType(2) then
        resData.coins.NORMAL = 30
    elseif G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):checkDebugSlotModleType(3) then
        resData.coins.NORMAL = 5
        resData.coins.BIG_COINS = 1
    else
        resData.coins.NORMAL = 5
        resData.symbol = "SYMBOL_HUGE_COINS"
    end
    self:updataPlayList("SLOTS", resData)
end

return EgyptCoinPusherManager

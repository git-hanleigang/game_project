--[[
    CoinPusherManager
    tm - -
]]
-- FIX IOS 139
local CoinPusherNet = require("activities.Activity_CoinPusher.net.CoinPusherNet")
local CoinPusherManager = class("CoinPusherManager", BaseActivityControl)
local Config = require("activities.Activity_CoinPusher.config.CoinPusherConfig")
-- ctor
function CoinPusherManager:ctor()
    CoinPusherManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CoinPusher)
    self._InLevel = nil --进入推币机等级
    self._LeaveLevel = nil --退出d
    self._Init = false

    self.m_rankExpireTime = 5 -- 过期时间
    self.m_getRankDataTime = 0 -- 获得排行榜数据的时间

    --自维数据 运行时数据
    self._PlayList = {} -- 玩法列表
    self._RunningData = nil -- 运行中数据 以UI展示位标准
    self._PassStage = false -- 是否已经过关
    self._Round = nil -- 当前轮数
    self._Stage = nil -- 当前章节
    self.m_net = CoinPusherNet:create()
    self:setSaveDirtyFlag(false)

    self:addExtendResList("Activity_CoinPusherCode")
end

function CoinPusherManager:onStart()
    gLobalNoticManager:removeAllObservers(self)
    self._StageBuffOpen = self:checkHasStageCoinBuff()

    local coinPusherData = self:getCoinPusherData()
    if coinPusherData then
        self:initConfig()
        self:registerObserver()
        self:initCoinPusherData()
        self._Init = true
    else
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if params.name == ACTIVITY_REF.CoinPusher then
                    local coinPusherData = self:getCoinPusherData()
                    if not self._Init and coinPusherData then
                        self:initConfig()
                        self:registerObserver()
                        self:initCoinPusherData()
                        self._Init = true
                    end
                end
            end,
            ViewEventType.NOTIFY_REFRESH_ACTIVITY_DATA
        )
    end
end

function CoinPusherManager:registerObserver()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.CoinPusher then
                self:updateCoinPusherData()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_BUFF_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateCoinPusherData()
        end,
        ViewEventType.NOTIFY_BUYCOINS_SUCCESS
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateCoinPusherData()
        end,
        ViewEventType.NOTIFY_REFESH_COINPUSHER_SAVE_DATA
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params[1] == true then
                local spinData = params[2]
                if spinData.action == "SPIN" and spinData.extend and spinData.extend.coinPusher and spinData.extend.coinPusher.rewardPushes and spinData.extend.coinPusher.rewardPushes > 0 then
                    self:updateCoinPusherDataInSpin(spinData.extend.coinPusher.totalPushes)
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.CoinPusher then
                self._Init = false
                gLobalNoticManager:removeAllObservers(self)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
    -- 无限促销
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateCoinPusherData()
        end,
        ViewEventType.NOTIFY_INFINITE_SALE_COLLECT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateCoinPusherData()
        end,
        ViewEventType.NOTIFY_INFINITE_SALE_BUY
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateCoinPusherData()
        end,
        ViewEventType.NOTIFY_FUNCTION_SALE_PASS_COLLECT
    )
end

-- get Instance --
-- function CoinPusherManager:getInstance()
--     if not self._instance then
--         self._instance = CoinPusherManager.new()
--     end
--     return self._instance
-- end

function CoinPusherManager:getExtraDataKey()
    return "CoinPusherGuide"
end

function CoinPusherManager:initCoinPusherData()
    local coinPusherData = self:getCoinPusherData()
    if coinPusherData then
        self._EntitySaveKey = "CoinPusherEntity_" .. Config.Version .. "_" .. globalData.userRunData.userUdid .. tostring(coinPusherData.p_start)
        self._DataSaveKey = "CoinPusherData_" .. Config.Version .. "_" .. globalData.userRunData.userUdid .. tostring(coinPusherData.p_start)
        self:InitSaveData()
    end

    if self.checkBufferTimer ~= nil then
        scheduler.unscheduleGlobal(self.checkBufferTimer)
        self.checkBufferTimer = nil
    end
    self.checkBufferTimer = scheduler.scheduleGlobal(
        function()
            if self:checkHasStageCoinBuff() then
                if not self._StageBuffOpen then
                    self._StageBuffOpen = true
                    --post
                    gLobalNoticManager:postNotification(Config.Event.CoinPuserStageBuffOpen)
                end
            else
                if self._StageBuffOpen then
                    self._StageBuffOpen = false
                    --post
                    gLobalNoticManager:postNotification(Config.Event.CoinPuserStageBuffClose)
                end
            end
        end,
        1
    )
end

-- 初始化 Config 配置
function CoinPusherManager:initConfig()
    local configPath = self:getConfigPath()
    Config = require(configPath)
end

-- 根据主题获取 Config 配置 路径
function CoinPusherManager:getConfigPath()
    local path = "activities.Activity_CoinPusher.config.CoinPusherConfig"
    local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.CoinPusher)
    if not config then
        return path
    end
    local theme = config:getThemeName()
    local pathList = {
        Activity_CoinPusher = "activities.Activity_CoinPusher.config.CoinPusherConfig",
        Activity_CoinPusher_Easter = "activities.Activity_CoinPusher.config.CoinPusherConfigEaster",
        Activity_CoinPusher_Liberty = "activities.Activity_CoinPusher.config.CoinPusherConfigLiberty"
    }
    return  pathList[theme] or path
end
-- 获取 Config 配置
function CoinPusherManager:getConfig()
    return Config
end
----------------------------------------------- Game Data S ---------------------------------------------
--物理数据
function CoinPusherManager:saveEntityData(_EntityInfo)
    --过关数据发来 不再接收消息
    local attJson = cjson.encode(_EntityInfo)

    gLobalDataManager:setStringByField(self._EntitySaveKey, attJson)
end

--内存数据
function CoinPusherManager:saveRunningData()
    local runningData = {}
    runningData.PlayList = {}
    --动画List
    for i, v in ipairs(self._PlayList) do
        local data = v:getRunningData()
        if not v:checkAllStateDone() then
            table.insert(runningData.PlayList, data)
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

function CoinPusherManager:loadEntityData()
    --判断是否过关  过关需要清空数据
    local attJson = gLobalDataManager:getStringByField(self._EntitySaveKey, "{}")
    local entityAttList = cjson.decode(attJson)
    return entityAttList
end

function CoinPusherManager:loadRunningData()
    --判断是否过关  过关需要清空数据
    local attJson = gLobalDataManager:getStringByField(self._DataSaveKey, "{}")
    local attJson = cjson.decode(attJson)
    return attJson
end

--清除数据
function CoinPusherManager:clearCoinPusherData()
    gLobalDataManager:delValueByField(self._EntitySaveKey)
    gLobalDataManager:delValueByField(self._DataSaveKey)
end

--盘面初始数据
function CoinPusherManager:saveCoinPusherDeskstopData(Stage)
    local loadData = self:loadCoinPusherDeskstopData()

    local entityAttList = self._coinPushMain:getSceneEntityData()
    loadData[Stage] = entityAttList.Entity
    local attJson = cjson.encode(loadData)
    local path = cc.FileUtils:getInstance():getWritablePath()
    local f = io.open(path .. "tengdanb.lua", "w+")
    f:write(attJson)
    f:close()
end

function CoinPusherManager:loadCoinPusherDeskstopData()
    local path = cc.FileUtils:getInstance():getWritablePath()
    local entityAttList = {}
    local f = io.open(path .. "tengdanb.lua", "r")
    if f then
        entityAttList = f:read("*all")
        entityAttList = cjson.decode(entityAttList)
        f:close()
    end
    return entityAttList
end

function CoinPusherManager:loadCoingInitDisk()
    local pathConfig = "Activity/CoinPusherGame/CoinPusherInitDiskConfig.json"
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
function CoinPusherManager:getItem(data, extraData, event)
    --数据二次组装
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successFunc = function(resultData)
        if resultData then
            local coinPusherData = self:getCoinPusherData()
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
        gLobalViewManager:showReConnect()
    end

    self.m_net:requestGetItem(data, successFunc, failedCallFun)
end

-- 道具被退出台子后 申请奖励 --
function CoinPusherManager:dropItemReward(data, extraData, event)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successFunc = function(resData)
        local coinPusherData = self:getCoinPusherData()
        if coinPusherData then
            self:updataPlayList("PushOut", {resData, extraData})
        end
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end

    self.m_net:requestDropItemReward(data, successFunc, failedCallFun)
end

function CoinPusherManager:sendGuideDataRequest(iStep)
    local coinPusherData = self:getCoinPusherData()
    if coinPusherData then
        local data = coinPusherData:getCoinPusherGuideData()
        data[table.nums(data) + 1] = iStep
        coinPusherData:initCoinPusherGuideData(data)
        self.m_net:requestSaveUserExtraData(data)
    end
end

-- 获取排行榜信息
function CoinPusherManager:sendActionRank(_success)
    -- 数据没有过期
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if curTime - self.m_getRankDataTime <= self.m_rankExpireTime then
        if _success then
            _success()
        end        
        return
    end

    local successFunc = function(rankData)
        gLobalViewManager:removeLoadingAnima()

        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        self.m_getRankDataTime = curTime

        local gameData = self:getCoinPusherData()
        if gameData and rankData and rankData.myRank then
            gameData:setRankJackpotCoins(0)
            gameData:parseRankData(rankData)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.CoinPusher})
        if _success then
            _success()
        end           
    end

    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    self.m_net:requestActionRank(successFunc, failedCallFun)
end

----------------------------------------------- 自持数据维护 S -----------------------------------
--取服务器必要数据
function CoinPusherManager:getPlayData()
    local coinPusherData = self:getCoinPusherData()
    if not coinPusherData then
        return {}
    end

    local userData = coinPusherData:getRuningUserData()
    return userData
end

function CoinPusherManager:getCoinPusherData()
    return G_GetMgr(ACTIVITY_REF.CoinPusher):getRunningData()
end

--动画列表
--更新动画列表
function CoinPusherManager:updataPlayList(type, data)
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
                self._PlayList[table.nums(self._PlayList)]:setStageData(coinsData.stage)
            end

            if coinsData.round then
                self._PassStage = true
                self._PlayList[table.nums(self._PlayList)]:setRoundData(coinsData.round)
            end
        end
    elseif type == "Drop" then
        --暂时这样做 全部都加到动画list 中防止数据显示问题
        if data then
            local playData = self:createPlayData("DROP", data)
            self._PlayList[table_nums(self._PlayList) + 1] = playData
        end
    end

    --动画更新后存档
    self:setSaveDirtyFlag(true)
end

--断线重连
function CoinPusherManager:reconnectionPlay()
    if table_nums(self._PlayList) < 1 then
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
    self:saveRunningData()
end

--刷帧监听动画
function CoinPusherManager:playTick(dt)
    if table_nums(self._PlayList) < 1 then
        return
    end

    local hasPlaying = false
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

--触发玩法
function CoinPusherManager:triggerPlay(index)
    local data = self:getPlayListData(index)

    data:setActionState(Config.PlayState.PLAYING)
    local playType = data:getActionType()

    gLobalNoticManager:postNotification(Config.Event.CoinPuserTriggerEffect, {playType, data})
end

--动画播完
function CoinPusherManager:checkPlayEffectEnd(data, i)
    --阻断播放领奖弹板
    if data:checkStagePass() then
        gLobalNoticManager:postNotification(Config.Event.CoinPuserStageLayer, data)
        self._PlayList = {}
        return
    elseif data:checkRoundPass() then
        gLobalNoticManager:postNotification(Config.Event.CoinPuserRoundLayer, data)
        self._PlayList = {}
        return
    else
        local newData = data:getUserData()
        local coinPusherData = self:getCoinPusherData()
        if not coinPusherData then
            return
        end

        if coinPusherData:getStageDataStateById(self._Stage) == "COMPLETED" or self._Stage ~= newData:getStage() then
            -- self:updateMaxScore(coinPusherData:getPushes())
            -- self._RunningData.Pushes = newData.Pushes
        else
            --更新数据
            data:updateUserData()
            self._RunningData = data:getUserData()
            gLobalNoticManager:postNotification(Config.Event.CoinPuserUpdateMainUI)
        end
        table.remove(self._PlayList, i)
        self:setSaveDirtyFlag(true)
    end
end

function CoinPusherManager:getPlayListData(index)
    return self._PlayList[index]
end

function CoinPusherManager:getPlayListCount()
    return table.nums(self._PlayList)
end

function CoinPusherManager:setPlayEnd(data)
    data:setActionState(Config.PlayState.DONE)
    self:setSaveDirtyFlag(true)
end

---创建动画数据
function CoinPusherManager:createPlayData(type, data)
    local actionData = self:createActionData(type)
    --获取最新的数据
    actionData:setActionType(type)
    actionData:setActionData(data)
    actionData:updateUserData()
    return actionData
end

--各种动画数据
function CoinPusherManager:createActionData(type)
    local actionData = nil
    local _dataModule = nil
    if type == Config.CoinEffectRefer.NORMAL or type == Config.CoinEffectRefer.BIG then
        _dataModule = require("activities.Activity_CoinPusher.model.data.CoinPusherBaseActionData")
    elseif type == Config.CoinEffectRefer.DROP then
        _dataModule = require("activities.Activity_CoinPusher.model.data.CoinPusherDropCoinData")
    elseif type == Config.CoinEffectRefer.COINS then
        _dataModule = require("activities.Activity_CoinPusher.model.data.CoinPusherPopCoinViewData")
    elseif type == Config.CoinEffectRefer.STAGE_COINS then
        _dataModule = require("activities.Activity_CoinPusher.model.data.CoinPusherPopStageCoinViewData")
    elseif type == Config.CoinEffectRefer.CARD then
        _dataModule = require("activities.Activity_CoinPusher.model.data.CoinPusherPopCardViewData")
    elseif type == Config.CoinEffectRefer.SLOTS then
        _dataModule = require("activities.Activity_CoinPusher.model.data.CoinPusherSlotData")
    elseif type == Config.CoinEffectRefer.EASTER then
        _dataModule = require("activities.Activity_CoinPusher.model.data.CoinPusherEasterEggData")
    end
    actionData = _dataModule:create()
    if not actionData then
        assert(false, "Cant find this Type Data! Please check your data!")
    end
    return actionData
end

----------------------------------------------- 自持数据维护 E -----------------------------------

----------------------------------------------- 加载存档数据 S -----------------------------------
function CoinPusherManager:InitSaveData()
    self._PassStage = false
    --存档读数据
    self:loadSaveData()
    self:loadDataUpdateRunningData()
end

--读取数据
function CoinPusherManager:loadSaveData()
    self._EntityData = self:loadEntityData() or {}
    self._RunningLoadData = self:loadRunningData() or {}
end

function CoinPusherManager:getSaveData()
    return self._RunningLoadData, self._EntityData
end

--加载数据判断是否过关
function CoinPusherManager:loadDataUpdateRunningData()
    local coinPusherData = self:getCoinPusherData()
    if not coinPusherData then
        return
    end

    local runningData = self._RunningLoadData.RunningData
    local playList = self._RunningLoadData.PlayList

    --判断是否已经过关 过关存档数据清空
    if runningData and table.nums(runningData) > 0 and (coinPusherData:getStageDataStateById(runningData.Stage) ~= "PLAY" or runningData.Round ~= coinPusherData:getRound()) then
        --清除存档
        self:clearCoinPusherData()
        self._RunningData = {}
        self._PlayList = {}
        runningData = nil
        playList = nil
    end

    --更新播放列表
    if runningData and table.nums(playList) > 0 then
        self._PlayList = {}
        for i, v in ipairs(playList) do
            local actionData = self:createActionData(v.ActionType)
            actionData:setRunningData(v)
            table.insert(self._PlayList, i, actionData)
        end
        self._RunningData = self:createRunningData(runningData)

        --同步服务器币个数
        local data = self:getCoinPusherData()
        if data then
            self:updateCoinPusherDataInSpin(data:getPushes())
        end
    else
        self._RunningData = self:updateRunningDataFromNet()
    end

    self._Stage = self._RunningData:getStage()
    self._Round = self._RunningData:getRound()
    self:saveRunningData()
end

--进入关卡前检查是否过关
function CoinPusherManager:checkRunningDataPassStage()
    --判断是否已经过关 过关存档数据清空
    local coinPusherData = self:getCoinPusherData()
    if not coinPusherData then
        return
    end

    if (not self._RunningData or coinPusherData:getStageDataStateById(self._RunningData:getStage()) ~= "PLAY" or self._RunningData:getRound() ~= coinPusherData:getRound()) then
        self._RunningData = {}
        self._PlayList = {}
        --清除存档
        self:clearCoinPusherData()
    end
    --充值内存数据
    self._RunningData = self:updateRunningDataFromNet()
    self._Stage = self._RunningData:getStage()
    self._Round = self._RunningData:getRound()
    self:saveRunningData()
end

function CoinPusherManager:updateRunningDataFromNet()
    local coinPusherData = self:getCoinPusherData()
    if coinPusherData then
        return self:createRunningData(coinPusherData:getRuningData())
    else
        return {}
    end
end

function CoinPusherManager:createRunningData(runningData)
    local _dataModule = require("activities.Activity_CoinPusher.model.data.CoinPusherRunningData")
    local runingUserDate = _dataModule:create()
    runingUserDate:setRunningData(runningData)
    return runingUserDate
end

function CoinPusherManager:leaveCoinPusherUpdateData()
    local coinPusherData = self:getCoinPusherData()
    if not coinPusherData then
        return
    end

    if self._PassStage then
        -- self:setShowSelectView(true)
        --如果过关 清空数据
        self:clearCoinPusherData()
        --充值内存数据
        self._RunningData = self:updateRunningDataFromNet()
        self._Stage = self._RunningData:getStage()
        self._Round = self._RunningData:getRound()
        self._PassStage = false
        self._PlayList = {}
        self._EntityData.Entity = nil
    end
end

function CoinPusherManager:getStagePushCoin()
    local coinPusherData = self:getCoinPusherData()
    if coinPusherData then
        return coinPusherData:getStagePushCoinsData(self._Stage)
    else
        return {}
    end
end
----------------------------------------------- 加载存档数据 E -----------------------------------

----------------------------------------------- buff处理 S ----------------------------------
function CoinPusherManager:updateCoinPusherData()
    local coinPusherData = self:getCoinPusherData()
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
            gLobalNoticManager:postNotification(Config.Event.CoinPuserUpdateMainUI)
        end
    else
        if self._RunningData:getPushes() ~= coinPusherData:getPushes() then
            self._RunningData:setPushes(coinPusherData:getPushes())
            gLobalNoticManager:postNotification(Config.Event.CoinPuserUpdateMainUI)
        end
    end
end

function CoinPusherManager:updateCoinPusherDataInSpin(_totlePusherCount)
    --更新playlist 和 runningData 回调
    if table.nums(self._PlayList) > 0 then
        local addPushesCount = _totlePusherCount - self._PlayList[#self._PlayList]:getUserDataPushes()
        if addPushesCount > 0 then
            for i = 1, #self._PlayList do
                local playEffect = self._PlayList[i]
                playEffect:addUserDataPushesCount(addPushesCount)
            end
            self._RunningData:setPushes(self._RunningData:getPushes() + addPushesCount)
            gLobalNoticManager:postNotification(Config.Event.CoinPuserUpdateMainUI)
        end
    else
        if self._RunningData:getPushes() ~= _totlePusherCount then
            self._RunningData:setPushes(_totlePusherCount)
            gLobalNoticManager:postNotification(Config.Event.CoinPuserUpdateMainUI)
        end
    end
end

function CoinPusherManager:checkHasStageCoinBuff()
    local coinPusherData = self:getCoinPusherData()
    if not coinPusherData then
        return false
    end

    local leftTime = coinPusherData:getBuffPrizeLT()
    return leftTime > 0
end

--检测Playlist是否有完成
function CoinPusherManager:checkPlayListEnd(_playList)
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

function CoinPusherManager:getRuningData()
    return self._RunningData
end

function CoinPusherManager:getPushes()
    if self._RunningData then
        return self._RunningData:getPushes()
    end
    return 0
end

function CoinPusherManager:getLobbyBottomNum()
    return self:getPushes()
end

function CoinPusherManager:getStageDataById(index)
    local coinPusherData = self:getCoinPusherData()
    if not coinPusherData then
        return {}
    end

    return coinPusherData:getStageDataById(index)
end

function CoinPusherManager:getCoinPusherPlayListCount()
    return table.nums(self._PlayList)
end

function CoinPusherManager:getStage()
    return self._Stage
end

function CoinPusherManager:getPlaneCoins()
    return self._RunningData:getPlaneCoins() + self:getRunStageAddCoins()
end

function CoinPusherManager:getPlaneCoinsPercent()
    local percent = (self._RunningData:getPlaneCoins() - self._RunningData:getPlaneBaseCoins()) / self._RunningData:getPlaneBaseCoins() * 100
    percent = math.floor(percent + 0.5000000001)
    if self:getStageBuffState() then
        percent = percent + 100
    end
    return percent
end

function CoinPusherManager:getRunStageAddCoins()
    if self._StageBuffOpen then
        return self._RunningData:getPlaneBaseCoins()
    else
        return 0
    end
end

function CoinPusherManager:getStageAddCoins(_Stage)
    local coinPusherData = self:getCoinPusherData()
    if coinPusherData and self._StageBuffOpen then
        return coinPusherData:getStageDataBaseCoinsById(_Stage)
    else
        return 0
    end
end

function CoinPusherManager:getStageBuffState()
    return self._StageBuffOpen
end
----------------------------------------------- 一些get方法 S -----------------------------------

----------------------------------------------- 对外接口 S --------------------------------------
function CoinPusherManager:showMainLayer()
    local coinPusherData = self:getCoinPusherData()
    if coinPusherData then
        local time = coinPusherData:getExpireAt()
        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        local tempTime = time - curTime
        if tempTime > 5 then
            gLobalViewManager:gotoSceneByType(SceneType.Scene_CoinPusher)
        end
    end
end

--创建并且进入推币机scene
function CoinPusherManager:GoToCoinPusher(preMachineData)
    self:checkRunningDataPassStage()
    self._EntityData = self:loadEntityData() --重新加载实体存档
    self._PlayList = self:checkPlayListEnd(self._PlayList) --检查PlayList是否有完成

    if preMachineData then
        globalData.slotRunData.gameRunPause = true
        self._entryLevelData = preMachineData
    else
        self._entryLevelData = nil
    end
    self:setOpenCoinPusherFlag()
    -- local newScene = cc.Scene:createWithPhysics()
    self._coinPushMain = util_createView("Activity.CoinPusherGame.CoinPusherMain", true)
    -- newScene:addChild(self._coinPushMain)
    self._ShowSelect = false

    local coinPusherData = self:getCoinPusherData()
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

--退出推币机
function CoinPusherManager:LeaveCoinPusher()
    if self.m_isLeaving then
        return
    end

    self.m_isLeaving = true

    if not tolua.isnull(self._coinPushMain) then
        self._coinPushMain:leaveCoinPusher()
    end
    self:leaveCoinPusherUpdateData()
    self:refreshLeaveLevel()
    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        _mgr:removeCollectNodeInfo("CoinPusherTop")
    end
    if self._entryLevelData then
        util_removeSearchPath("GameScreen")
        
        local isSucc = self:enterLevel(self._entryLevelData)
        if isSucc then
            globalData.slotRunData.gameRunPause = nil
            globalData.slotRunData.gameResumeFunc = nil
            self._entryLevelData = nil
        end
    else
        globalData.leaveFromCoinPuhser = true
        release_print("CoinPusher back to lobby!!!")
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
    end
    self.m_isLeaving = false
end

-- 刷新退出推币机 leaveLevel
function CoinPusherManager:refreshLeaveLevel()
    local coinPusherData = self:getCoinPusherData()
    if coinPusherData then
        self._LeaveLevel = coinPusherData:getStage()
    else
        self._LeaveLevel = nil
    end
end

function CoinPusherManager:isCoinPusherEnterLevel()
    return self._isCoinPusher
end

function CoinPusherManager:removeEnterLevelFlag()
    self._isCoinPusher = false
end

--推币机退出后进入关卡
function CoinPusherManager:enterLevel(info)
    self._isCoinPusher = true
    
    return gLobalViewManager:gotoSlotsScene(info, nil, globalData.slotRunData.iLastBetIdx)
end

--检测是否过关 并且返回前一关卡,后一关卡 用于选择界面播放动画
function CoinPusherManager:checkPassStage()
    return self._InLevel ~= self._LeaveLevel and self._InLevel ~= nil and self._LeaveLevel ~= nil, self._InLevel, self._LeaveLevel
end

function CoinPusherManager:clearPassStageInfo()
    self._InLevel = nil
    self._LeaveLevel = nil
end

function CoinPusherManager:getShowSelectView()
    return self._ShowSelect
end

function CoinPusherManager:setShowSelectView(state)
    self._ShowSelect = state
end

function CoinPusherManager:checkAutoDrop()
    return self._Auto or false
end

function CoinPusherManager:setAutoDrop(isAuto)
    self._Auto = isAuto
end

function CoinPusherManager:setOpenCoinPusherFlag()
    self.m_levelToCoinPusher = nil
    if self._entryLevelData then
        self.m_levelToCoinPusher = self._entryLevelData.p_id
    end
end

function CoinPusherManager:getCoinPusherToLevelID()
    local flag = self.m_levelToCoinPusher
    self.m_levelToCoinPusher = nil
    return flag
end

function CoinPusherManager:showRankMainLayer()
    if not gLobalViewManager:getViewByExtendData("CoinPusherRankMainLayer") then
        local view = util_createView("Activity.CoinPusherRank.CoinPusherRankMainLayer")
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
end

function CoinPusherManager:setSaveDirtyFlag(flag)
    self.saveDirtyFlag = flag
end

function CoinPusherManager:getSaveDirtyFlag()
    return self.saveDirtyFlag
end

----------------------------------------------- 对外接口 E ----------------------------------------------
function CoinPusherManager:showSelectLayer(_bCoinSceneOpen)
    if not self:isCanShowLayer() then
        return nil
    end

    local CoinPusherSelectUI = nil
    if gLobalViewManager:getViewByExtendData("CoinPusherSelectUI") == nil then
        if _bCoinSceneOpen then
            self:refreshLeaveLevel()
        end
        CoinPusherSelectUI = util_createFindView("Activity/CoinPusherGame/CoinPusherSelectUI")
        if CoinPusherSelectUI ~= nil then
            gLobalViewManager:showUI(CoinPusherSelectUI, ViewZorder.ZORDER_UI - 1)
        end
    end

    return CoinPusherSelectUI
end

----------------------------------------------- PASS模块 ----------------------------------------------
-- 创建 pass 入口
function CoinPusherManager:createPassEntryNode()
    local coinPusherData = self:getCoinPusherData()
    if not coinPusherData then
        return
    end
    
    local passData = coinPusherData:getCoinPusherPassData()
    if not passData or not passData:checkPassOpen() then
        return
    end

    local view = util_createView("Activity.CoinPusherPass.CoinPusherPassEntry")
    return view
end

function CoinPusherManager:showPassMainLayer()
    if gLobalViewManager:getViewByExtendData("CoinPusherPassMainLayer") then 
        return
    end
    local view = util_createView("Activity.CoinPusherPass.CoinPusherPassMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CoinPusherManager:showPassRuleLayer()
    local view = util_createView("Activity.CoinPusherPass.CoinPusherPassRule")
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function CoinPusherManager:showPassRewardLayer(rewad)
    local view = util_createView("Activity.CoinPusherPass.CoinPusherPassReward", rewad)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

-- PASS请求领取奖励 --
function CoinPusherManager:requestGetReward(data, event)
    local successFunc = function()
        local coinPusherData = self:getCoinPusherData()
        if coinPusherData then
            --抛事件 成功回调后的事件 有掉落数据
            gLobalNoticManager:postNotification(event, {index = data.index,reward = data.reward})
        end
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end

    self.m_net:requestGetReward(data.index, successFunc, failedCallFun)
end
----------------------------------------------- PASS模块 ----------------------------------------------

function CoinPusherManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function CoinPusherManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function CoinPusherManager:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end


return CoinPusherManager

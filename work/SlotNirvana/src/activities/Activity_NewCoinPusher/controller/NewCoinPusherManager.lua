--[[
    NewCoinPusherManager
    tm - -
]]
-- FIX IOS 139
local NewCoinPusherNet = require("activities.Activity_NewCoinPusher.net.NewCoinPusherNet")
local NewCoinPusherManager = class("NewCoinPusherManager", BaseActivityControl)
local Config = require("activities.Activity_NewCoinPusher.config.NewCoinPusherConfig")
-- ctor
function NewCoinPusherManager:ctor()
    NewCoinPusherManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewCoinPusher)
    self._InLevel = nil --进入推币机等级
    self._LeaveLevel = nil --退出d
    self._Init = false
    self._DebugSpinCar = false

    self.m_rankExpireTime = 5 -- 过期时间
    self.m_getRankDataTime = 0 -- 获得排行榜数据的时间
    self.m_fruitNums = 0 -- 剩余水果机次数
    self.m_insertPos = 1 -- 弹板插入位置

    --自维数据 运行时数据
    self._PlayList = {} -- 玩法列表
    self._RunningData = nil -- 运行中数据 以UI展示位标准
    self._PassStage = false -- 是否已经过关
    self._Round = nil -- 当前轮数
    self._Stage = nil -- 当前章节
    self.m_net = NewCoinPusherNet:create()
    self:setSaveDirtyFlag(false)
end

function NewCoinPusherManager:onStart()
    gLobalNoticManager:removeAllObservers(self)
    self._StageBuffOpen = self:checkHasStageCoinBuff()

    local coinPusherData = self:getNewCoinPusherData()
    if coinPusherData then
        self:initConfig()
        self:registerObserver()
        self:initNewCoinPusherData()
        self._Init = true
    else
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if params.name == ACTIVITY_REF.NewCoinPusher then
                    local coinPusherData = self:getNewCoinPusherData()
                    if not self._Init and coinPusherData then
                        self:initConfig()
                        self:registerObserver()
                        self:initNewCoinPusherData()
                        self._Init = true
                    end
                end
            end,
            ViewEventType.NOTIFY_REFRESH_ACTIVITY_DATA
        )
    end
end

function NewCoinPusherManager:registerObserver()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params.name == ACTIVITY_REF.NewCoinPusher then
                self:updateNewCoinPusherData()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_BUFF_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateNewCoinPusherData()
        end,
        ViewEventType.NOTIFY_BUYCOINS_SUCCESS
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateNewCoinPusherData()
        end,
        ViewEventType.NOTIFY_REFESH_COINPUSHER_SAVE_DATA
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params[1] == true then
                local spinData = params[2]
                if spinData.action == "SPIN" and spinData.extend and spinData.extend.coinPusher and spinData.extend.coinPusher.rewardPushes and spinData.extend.coinPusher.rewardPushes > 0 then
                    self:updateNewCoinPusherDataInSpin(spinData.extend.coinPusher.totalPushes)
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.NewCoinPusher then
                self._Init = false
                gLobalNoticManager:removeAllObservers(self)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

-- get Instance --
-- function NewCoinPusherManager:getInstance()
--     if not self._instance then
--         self._instance = NewCoinPusherManager.new()
--     end
--     return self._instance
-- end

function NewCoinPusherManager:getExtraDataKey()
    return "NewCoinPusherGuide"
end

function NewCoinPusherManager:initNewCoinPusherData()
    local coinPusherData = self:getNewCoinPusherData()
    if coinPusherData then
        self._EntitySaveKey = "NewCoinPusherEntity_" .. Config.Version .. "_" .. globalData.userRunData.userUdid .. tostring(coinPusherData.p_start)
        self._DataSaveKey = "NewCoinPusherData_" .. Config.Version .. "_" .. globalData.userRunData.userUdid .. tostring(coinPusherData.p_start)
        self:InitSaveData()
    end

    -- if self.checkBufferTimer ~= nil then
    --     scheduler.unscheduleGlobal(self.checkBufferTimer)
    --     self.checkBufferTimer = nil
    -- end
    -- self.checkBufferTimer = scheduler.scheduleGlobal(
    --     function()
    --         if self:checkHasStageCoinBuff() then
    --             if not self._StageBuffOpen then
    --                 self._StageBuffOpen = true
    --                 --post
    --                 gLobalNoticManager:postNotification(Config.Event.NewCoinPuserStageBuffOpen)
    --             end
    --         else
    --             if self._StageBuffOpen then
    --                 self._StageBuffOpen = false
    --                 --post
    --                 gLobalNoticManager:postNotification(Config.Event.NewCoinPuserStageBuffClose)
    --             end
    --         end
    --     end,
    --     1
    -- )
end

-- 初始化 Config 配置
function NewCoinPusherManager:initConfig()
    local configPath = self:getConfigPath()
    Config = require(configPath)
end

-- 根据主题获取 Config 配置 路径
function NewCoinPusherManager:getConfigPath()
    local path = "activities.Activity_NewCoinPusher.config.NewCoinPusherConfig"
    local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.NewCoinPusher)
    if not config then
        return path
    end
    local theme = config:getThemeName()
    local pathList = {
        Activity_NewCoinPusher = "activities.Activity_NewCoinPusher.config.NewCoinPusherConfig",
        Activity_NewCoinPusher_Easter = "activities.Activity_NewCoinPusher.config.NewCoinPusherConfigEaster",
        Activity_NewCoinPusher_Liberty = "activities.Activity_NewCoinPusher.config.NewCoinPusherConfigLiberty"
    }
    return  pathList[theme] or path
end
-- 获取 Config 配置
function NewCoinPusherManager:getConfig()
    return Config
end
----------------------------------------------- Game Data S ---------------------------------------------
--物理数据
function NewCoinPusherManager:saveEntityData(_EntityInfo)
    --过关数据发来 不再接收消息
    local attJson = cjson.encode(_EntityInfo)

    gLobalDataManager:setStringByField(self._EntitySaveKey, attJson)
end

--内存数据
function NewCoinPusherManager:saveRunningData()
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

function NewCoinPusherManager:loadEntityData()
    --判断是否过关  过关需要清空数据
    local attJson = gLobalDataManager:getStringByField(self._EntitySaveKey, "{}")
    local entityAttList = cjson.decode(attJson)
    return entityAttList
end

function NewCoinPusherManager:loadRunningData()
    --判断是否过关  过关需要清空数据
    local attJson = gLobalDataManager:getStringByField(self._DataSaveKey, "{}")
    local attJson = cjson.decode(attJson)
    return attJson
end

--清除数据
function NewCoinPusherManager:clearNewCoinPusherData()
    gLobalDataManager:delValueByField(self._EntitySaveKey)
    gLobalDataManager:delValueByField(self._DataSaveKey)
end

--盘面初始数据
function NewCoinPusherManager:saveNewCoinPusherDeskstopData(Stage)
    local loadData = self:loadNewCoinPusherDeskstopData()

    local entityAttList = self._coinPushMain:getSceneEntityData()
    loadData[Stage] = entityAttList.Entity
    local attJson = cjson.encode(loadData)
    local path = cc.FileUtils:getInstance():getWritablePath()
    local f = io.open(path .. "tengdanb.lua", "w+")
    f:write(attJson)
    f:close()
end

function NewCoinPusherManager:loadNewCoinPusherDeskstopData()
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

function NewCoinPusherManager:loadCoingInitDisk()
    local pathConfig = "Activity/NewCoinPusherGame/NewCoinPusherInitDiskConfig.json"
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
function NewCoinPusherManager:getItem(data, extraData, event)
    --数据二次组装
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local coinPusherData = self:getNewCoinPusherData()
    if not coinPusherData then
        return
    end
    if (not self._RunningData or coinPusherData:getStageDataStateById(self._RunningData:getStage()) ~= "PLAY" or self._RunningData:getRound() ~= coinPusherData:getRound()) then
        return
    end

    local successFunc = function(resultData)
        if resultData then
            local coinPusherData = self:getNewCoinPusherData()
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
function NewCoinPusherManager:dropItemReward(data, extraData, event)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successFunc = function(resData)
        local coinPusherData = self:getNewCoinPusherData()
        if coinPusherData then
            self:updataPlayList("PushOut", {resData, extraData})
        end
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end

    self.m_net:requestDropItemReward(data, successFunc, failedCallFun)
end

function NewCoinPusherManager:sendGuideDataRequest(iStep)
    local coinPusherData = self:getNewCoinPusherData()
    if coinPusherData then
        local data = coinPusherData:getNewCoinPusherGuideData()
        data[table.nums(data) + 1] = iStep
        coinPusherData:initNewCoinPusherGuideData(data)
        self.m_net:requestSaveUserExtraData(data)
    end
end

function NewCoinPusherManager:sendGuideDataRequestTest()
    local coinPusherData = self:getNewCoinPusherData()
    if coinPusherData then
       local data = {}
        self.m_net:requestSaveUserExtraData(data)
    end
end

-- 获取排行榜信息
function NewCoinPusherManager:sendActionRank()
    -- 数据没有过期
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if curTime - self.m_getRankDataTime <= self.m_rankExpireTime then
        return
    end

    local successFunc = function(rankData)
        gLobalViewManager:removeLoadingAnima()

        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        self.m_getRankDataTime = curTime

        local gameData = self:getNewCoinPusherData()
        if gameData and rankData and rankData.myRank then
            gameData:setRankJackpotCoins(0)
            gameData:parseRankData(rankData)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.NewCoinPusher})
    end

    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    self.m_net:requestActionRank(successFunc, failedCallFun)
end

-- 获取水果机信息
function NewCoinPusherManager:requestFruitMachine()
    local successFunc = function(resData)
        local coinPusherData = self:getNewCoinPusherData()
        if coinPusherData then
            if self._DebugSpinCar then
                resData.type = "CAR"
                resData.value = 1
            end
            self:updataPlayList("FruitMachine", resData)
            -- self:addFruitNums(1)
        end
        gLobalNoticManager:postNotification(Config.Event.NewCoinPuserRequestFruitMachineFinish)
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    self.m_net:requestFruitMachine(successFunc, failedCallFun)
end

----------------------------------------------- 自持数据维护 S -----------------------------------
--取服务器必要数据
function NewCoinPusherManager:getPlayData()
    local coinPusherData = self:getNewCoinPusherData()
    if not coinPusherData then
        return {}
    end

    local userData = coinPusherData:getRuningUserData()
    return userData
end

function NewCoinPusherManager:getNewCoinPusherData()
    return G_GetMgr(ACTIVITY_REF.NewCoinPusher):getRunningData()
end

--动画列表
--更新动画列表
function NewCoinPusherManager:updataPlayList(type, data)
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

                    table.insert(self._PlayList, self.m_insertPos, playData)
                    self.m_insertPos = math.min(self.m_insertPos + 1, table_nums(self._PlayList))
                    -- self._PlayList[table_nums(self._PlayList) + 1] = playData
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
            -- self._PlayList[table_nums(self._PlayList) + 1] = playData
            gLobalNoticManager:postNotification(Config.Event.NewCoinPuserTriggerEffect, {"DROP", playData})
        end
    elseif type == "FruitMachine" then
        if data then
            local playData = self:createPlayData("FRUITMACHINE", data)
            self._PlayList[table_nums(self._PlayList) + 1] = playData
        end
    end

    --动画更新后存档
    self:setSaveDirtyFlag(true)
end

--断线重连
function NewCoinPusherManager:reconnectionPlay()
    if table_nums(self._PlayList) < 1 then
        self._PassStage = false
        self.m_fruitNums = 0
        return
    end
    self:initFruitNums()
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
function NewCoinPusherManager:playTick(dt)
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
function NewCoinPusherManager:triggerPlay(index)
    local data = self:getPlayListData(index)

    data:setActionState(Config.PlayState.PLAYING)
    local playType = data:getActionType()

    gLobalNoticManager:postNotification(Config.Event.NewCoinPuserTriggerEffect, {playType, data})
end

--动画播完
function NewCoinPusherManager:checkPlayEffectEnd(data, i)
    --阻断播放领奖弹板
    if data:checkStagePass() then
        gLobalNoticManager:postNotification(Config.Event.NewCoinPuserStageLayer, data)
        self.m_insertPos = 1
        self._PlayList = {}
        return
    elseif data:checkRoundPass() then
        gLobalNoticManager:postNotification(Config.Event.NewCoinPuserRoundLayer, data)
        self.m_insertPos = 1
        self._PlayList = {}
        return
    else
        local newData = data:getUserData()
        local coinPusherData = self:getNewCoinPusherData()
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
            gLobalNoticManager:postNotification(Config.Event.NewCoinPuserUpdateMainUI)
        end
        table.remove(self._PlayList, i)
        self:setSaveDirtyFlag(true)
    end
end

function NewCoinPusherManager:getPlayListData(index)
    return self._PlayList[index]
end

function NewCoinPusherManager:getPlayListCount()
    return table.nums(self._PlayList)
end

function NewCoinPusherManager:setPlayEnd(data)
    data:setActionState(Config.PlayState.DONE)
    self:setSaveDirtyFlag(true)
end

---创建动画数据
function NewCoinPusherManager:createPlayData(type, data)
    local actionData = self:createActionData(type)
    --获取最新的数据
    actionData:setActionType(type)
    actionData:setActionData(data)
    actionData:updateUserData()
    return actionData
end

--各种动画数据
function NewCoinPusherManager:createActionData(type)
    local actionData = nil
    local _dataModule = nil
    if type == Config.CoinEffectRefer.NORMAL or type == Config.CoinEffectRefer.BIG then
        _dataModule = require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherBaseActionData")
    elseif type == Config.CoinEffectRefer.DROP then
        _dataModule = require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherDropCoinData")
    elseif type == Config.CoinEffectRefer.COINS then
        _dataModule = require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherPopCoinViewData")
    elseif type == Config.CoinEffectRefer.STAGE_COINS then
        _dataModule = require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherPopStageCoinViewData")
    elseif type == Config.CoinEffectRefer.CARD then
        _dataModule = require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherPopCardViewData")
    elseif type == Config.CoinEffectRefer.SLOTS then
        _dataModule = require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherSlotData")
    elseif type == Config.CoinEffectRefer.EASTER then
        _dataModule = require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherEasterEggData")
    elseif type == Config.CoinEffectRefer.FRUITMACHINE then
        _dataModule = require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherFruitData")
    end
    actionData = _dataModule:create()
    if not actionData then
        assert(false, "Cant find this Type Data! Please check your data!")
    end
    return actionData
end

----------------------------------------------- 自持数据维护 E -----------------------------------

----------------------------------------------- 加载存档数据 S -----------------------------------
function NewCoinPusherManager:InitSaveData()
    self._PassStage = false
    --存档读数据
    self:loadSaveData()
    self:loadDataUpdateRunningData()
end

--读取数据
function NewCoinPusherManager:loadSaveData()
    self._EntityData = self:loadEntityData() or {}
    self._RunningLoadData = self:loadRunningData() or {}
end

function NewCoinPusherManager:getSaveData()
    return self._RunningLoadData, self._EntityData
end

--加载数据判断是否过关
function NewCoinPusherManager:loadDataUpdateRunningData()
    local coinPusherData = self:getNewCoinPusherData()
    if not coinPusherData then
        return
    end

    local runningData = self._RunningLoadData.RunningData
    local playList = self._RunningLoadData.PlayList

    --判断是否已经过关 过关存档数据清空
    if runningData and table.nums(runningData) > 0 and (coinPusherData:getStageDataStateById(runningData.Stage) ~= "PLAY" or runningData.Round ~= coinPusherData:getRound()) then
        --清除存档
        self:clearNewCoinPusherData()
        self._RunningData = {}
        self._PlayList = {}
        self.m_fruitNums = 0
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
        local data = self:getNewCoinPusherData()
        if data then
            self:updateNewCoinPusherDataInSpin(data:getPushes())
        end
    else
        self._RunningData = self:updateRunningDataFromNet()
    end

    self._Stage = self._RunningData:getStage()
    self._Round = self._RunningData:getRound()
    self:saveRunningData()
end

--进入关卡前检查是否过关
function NewCoinPusherManager:checkRunningDataPassStage()
    --判断是否已经过关 过关存档数据清空
    local coinPusherData = self:getNewCoinPusherData()
    if not coinPusherData then
        return
    end

    if (not self._RunningData or coinPusherData:getStageDataStateById(self._RunningData:getStage()) ~= "PLAY" or self._RunningData:getRound() ~= coinPusherData:getRound()) then
        self._RunningData = {}
        self._PlayList = {}
        self.m_insertPos = 1
        --清除存档
        self:clearNewCoinPusherData()
    end
    --充值内存数据
    self._RunningData = self:updateRunningDataFromNet()
    self._Stage = self._RunningData:getStage()
    self._Round = self._RunningData:getRound()
    self:saveRunningData()
end

function NewCoinPusherManager:updateRunningDataFromNet()
    local coinPusherData = self:getNewCoinPusherData()
    if coinPusherData then
        return self:createRunningData(coinPusherData:getRuningData())
    else
        return {}
    end
end

function NewCoinPusherManager:createRunningData(runningData)
    local _dataModule = require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherRunningData")
    local runingUserDate = _dataModule:create()
    runingUserDate:setRunningData(runningData)
    return runingUserDate
end

function NewCoinPusherManager:leaveNewCoinPusherUpdateData()
    local coinPusherData = self:getNewCoinPusherData()
    if not coinPusherData then
        return
    end

    if self._PassStage then
        -- self:setShowSelectView(true)
        --如果过关 清空数据
        self:clearNewCoinPusherData()
        --充值内存数据
        self._RunningData = self:updateRunningDataFromNet()
        self._Stage = self._RunningData:getStage()
        self._Round = self._RunningData:getRound()
        self._PassStage = false
        self._PlayList = {}
        self.m_insertPos = 1
        self._EntityData.Entity = nil
        self:setSaveDirtyFlag(false)
    end
end

function NewCoinPusherManager:getStagePushCoin()
    local coinPusherData = self:getNewCoinPusherData()
    if coinPusherData then
        return coinPusherData:getStagePushCoinsData(self._Stage)
    else
        return {}
    end
end
----------------------------------------------- 加载存档数据 E -----------------------------------

----------------------------------------------- buff处理 S ----------------------------------
function NewCoinPusherManager:updateNewCoinPusherData()
    local coinPusherData = self:getNewCoinPusherData()
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
            gLobalNoticManager:postNotification(Config.Event.NewCoinPuserUpdateMainUI)
        end
    else
        if self._RunningData:getPushes() ~= coinPusherData:getPushes() then
            self._RunningData:setPushes(coinPusherData:getPushes())
            gLobalNoticManager:postNotification(Config.Event.NewCoinPuserUpdateMainUI)
        end
    end
end

function NewCoinPusherManager:updateNewCoinPusherDataInSpin(_totlePusherCount)
    --更新playlist 和 runningData 回调
    if table.nums(self._PlayList) > 0 then
        local addPushesCount = _totlePusherCount - self._PlayList[#self._PlayList]:getUserDataPushes()
        if addPushesCount > 0 then
            for i = 1, #self._PlayList do
                local playEffect = self._PlayList[i]
                playEffect:addUserDataPushesCount(addPushesCount)
            end
            self._RunningData:setPushes(self._RunningData:getPushes() + addPushesCount)
            gLobalNoticManager:postNotification(Config.Event.NewCoinPuserUpdateMainUI)
        end
    else
        if self._RunningData:getPushes() ~= _totlePusherCount then
            self._RunningData:setPushes(_totlePusherCount)
            gLobalNoticManager:postNotification(Config.Event.NewCoinPuserUpdateMainUI)
        end
    end
end

function NewCoinPusherManager:checkHasStageCoinBuff()
    -- local coinPusherData = self:getNewCoinPusherData()
    -- if not coinPusherData then
    --     return false
    -- end

    -- local leftTime = coinPusherData:getBuffPrizeLT()
    -- return leftTime > 0
    return false
end

--检测Playlist是否有完成
function NewCoinPusherManager:checkPlayListEnd(_playList)
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

function NewCoinPusherManager:getRuningData()
    return self._RunningData
end

function NewCoinPusherManager:getPushes()
    return self._RunningData:getPushes()
end



function NewCoinPusherManager:getStageDataById(index)
    local coinPusherData = self:getNewCoinPusherData()
    if not coinPusherData then
        return {}
    end

    return coinPusherData:getStageDataById(index)
end

function NewCoinPusherManager:getNewCoinPusherPlayListCount()
    return table.nums(self._PlayList)
end

function NewCoinPusherManager:getStage()
    return self._Stage
end

function NewCoinPusherManager:getPlaneCoins()
    return self._RunningData:getPlaneCoins() + self:getRunStageAddCoins()
end

function NewCoinPusherManager:getPlaneCoinsPercent()
    local percent = (self._RunningData:getPlaneCoins() - self._RunningData:getPlaneBaseCoins()) / self._RunningData:getPlaneBaseCoins() * 100
    percent = math.floor(percent + 0.5000000001)
    -- if self:getStageBuffState() then
    --     percent = percent + 100
    -- end
    return percent
end

function NewCoinPusherManager:getRunStageAddCoins()
    -- if self._StageBuffOpen then
    --     return self._RunningData:getPlaneBaseCoins()
    -- else
    --     return 0
    -- end
    return 0
end

function NewCoinPusherManager:getStageAddCoins(_Stage)
    -- local coinPusherData = self:getNewCoinPusherData()
    -- if coinPusherData and self._StageBuffOpen then
    --     return coinPusherData:getStageDataBaseCoinsById(_Stage)
    -- else
    --     return 0
    -- end
    return 0
end

function NewCoinPusherManager:getStageBuffState()
    return self._StageBuffOpen
end
----------------------------------------------- 一些get方法 S -----------------------------------

----------------------------------------------- 对外接口 S --------------------------------------
function NewCoinPusherManager:showMainLayer()
    local coinPusherData = self:getNewCoinPusherData()
    if coinPusherData then
        local time = coinPusherData:getExpireAt()
        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        local tempTime = time - curTime
        if tempTime > 5 then
            gLobalViewManager:gotoSceneByType(SceneType.Scene_NewCoinPusher)
        end
    end
end

--创建并且进入推币机scene
function NewCoinPusherManager:GoToNewCoinPusher(preMachineData)
    self:checkRunningDataPassStage()
    self._EntityData = self:loadEntityData() --重新加载实体存档
    self._PlayList = self:checkPlayListEnd(self._PlayList) --检查PlayList是否有完成

    if preMachineData then
        globalData.slotRunData.gameRunPause = true
        self._entryLevelData = preMachineData
    else
        self._entryLevelData = nil
    end
    self:setOpenNewCoinPusherFlag()
    -- local newScene = cc.Scene:createWithPhysics()
    self._coinPushMain = util_createView("Activity.NewCoinPusherGame.NewCoinPusherMain", true)
    -- newScene:addChild(self._coinPushMain)
    self._ShowSelect = false

    local coinPusherData = self:getNewCoinPusherData()
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
function NewCoinPusherManager:LeaveNewCoinPusher()
    self:leaveNewCoinPusherUpdateData()
    self:refreshLeaveLevel()
    local _mgr = G_GetMgr(G_REF.Currency)
    if _mgr then
        _mgr:removeCollectNodeInfo("NewCoinPusherTop")
    end
    if self._entryLevelData then
        util_removeSearchPath("GameScreen")
        globalData.slotRunData.gameRunPause = nil
        globalData.slotRunData.gameResumeFunc = nil
        self:enterLevel(self._entryLevelData)

        self._entryLevelData = nil
    else
        globalData.leaveFromCoinPuhser = true
        release_print("NewCoinPusher back to lobby!!!")
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
    end
end

-- 刷新退出推币机 leaveLevel
function NewCoinPusherManager:refreshLeaveLevel()
    local coinPusherData = self:getNewCoinPusherData()
    if coinPusherData then
        self._LeaveLevel = coinPusherData:getStage()
    else
        self._LeaveLevel = nil
    end
end

--推币机退出后进入关卡
function NewCoinPusherManager:enterLevel(info)
    gLobalViewManager:gotoSlotsScene(info)
end

--检测是否过关 并且返回前一关卡,后一关卡 用于选择界面播放动画
function NewCoinPusherManager:checkPassStage()
    return self._InLevel ~= self._LeaveLevel and self._InLevel ~= nil and self._LeaveLevel ~= nil, self._InLevel, self._LeaveLevel
end

function NewCoinPusherManager:clearPassStageInfo()
    self._InLevel = nil
    self._LeaveLevel = nil
end

function NewCoinPusherManager:getShowSelectView()
    return self._ShowSelect
end

function NewCoinPusherManager:setShowSelectView(state)
    self._ShowSelect = state
end

function NewCoinPusherManager:checkAutoDrop()
    return self._Auto or false
end

function NewCoinPusherManager:setAutoDrop(isAuto)
    self._Auto = isAuto
end

function NewCoinPusherManager:setOpenNewCoinPusherFlag()
    self.m_levelToNewCoinPusher = nil
    if self._entryLevelData then
        self.m_levelToNewCoinPusher = self._entryLevelData.p_id
    end
end

function NewCoinPusherManager:getNewCoinPusherToLevelID()
    local flag = self.m_levelToNewCoinPusher
    self.m_levelToNewCoinPusher = nil
    return flag
end

function NewCoinPusherManager:showRankMainLayer()
    if not gLobalViewManager:getViewByExtendData("NewCoinPusherRankMainLayer") then
        local view = util_createView("Activity.NewCoinPusherGame.NewCoinPusherRankMainLayer")
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
end

function NewCoinPusherManager:setSaveDirtyFlag(flag)
    self.saveDirtyFlag = flag
end

function NewCoinPusherManager:getSaveDirtyFlag()
    return self.saveDirtyFlag
end

----------------------------------------------- 对外接口 E ----------------------------------------------
function NewCoinPusherManager:showSelectLayer(_bCoinSceneOpen)
    if not self:isCanShowLayer() then
        return nil
    end

    local NewCoinPusherSelectUI = nil
    if gLobalViewManager:getViewByExtendData("NewCoinPusherSelectUI") == nil then
        if _bCoinSceneOpen then
            self:refreshLeaveLevel()
        end
        NewCoinPusherSelectUI = util_createFindView("Activity/NewCoinPusherGame/NewCoinPusherSelectUI")
        if NewCoinPusherSelectUI ~= nil then
            gLobalViewManager:showUI(NewCoinPusherSelectUI, ViewZorder.ZORDER_UI - 1)
        end
    end

    return NewCoinPusherSelectUI
end

----------------------------------------------- PASS模块 ----------------------------------------------
-- 创建 pass 入口
function NewCoinPusherManager:createPassEntryNode()
    local coinPusherData = self:getNewCoinPusherData()
    if not coinPusherData then
        return
    end
    
    local passData = coinPusherData:getNewCoinPusherPassData()
    if not passData or not passData:checkPassOpen() then
        return
    end

    local view = util_createView("Activity.NewCoinPusherPass.NewCoinPusherPassEntry")
    return view
end

function NewCoinPusherManager:showPassMainLayer()
    if gLobalViewManager:getViewByExtendData("NewCoinPusherPassMainLayer") then 
        return
    end
    local view = util_createView("Activity.NewCoinPusherPass.NewCoinPusherPassMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function NewCoinPusherManager:showPassRuleLayer()
    local view = util_createView("Activity.NewCoinPusherPass.NewCoinPusherPassRule")
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function NewCoinPusherManager:showPassRewardLayer(rewad)
    local view = util_createView("Activity.NewCoinPusherPass.NewCoinPusherPassReward", rewad)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

-- PASS请求领取奖励 --
function NewCoinPusherManager:requestGetReward(data, event)
    local successFunc = function()
        local coinPusherData = self:getNewCoinPusherData()
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

function NewCoinPusherManager:setDebugSpinCar(bool)
    self._DebugSpinCar = bool
end

function NewCoinPusherManager:initFruitNums()
    self.m_fruitNums = 0
    -- 金币加成，获得金币，获得卡片三种重连去掉, 小车倒过金币后也去掉
    for i = #self._PlayList, 1, -1 do
        local data = self._PlayList[i]
        -- if data:getActionType() == Config.CoinEffectRefer.COINS or data:getActionType() == Config.CoinEffectRefer.CARD 
        -- or data:getActionType() == Config.CoinEffectRefer.STAGE_COINS then
        --     table.remove(self._PlayList, i)
        -- end
        if data:getActionType() == Config.CoinEffectRefer.FRUITMACHINE then
            if data:getIsPourCoins() then
                table.remove(self._PlayList, i)
            end
            self.m_fruitNums = self.m_fruitNums + 1
        end
    end
end

function NewCoinPusherManager:updateFruitNums()
    self.m_fruitNums = 0
    -- 金币加成，获得金币，获得卡片三种重连去掉, 小车倒过金币后也去掉
    for i = #self._PlayList, 1, -1 do
        local data = self._PlayList[i]
        if data:getActionType() == Config.CoinEffectRefer.FRUITMACHINE then
            self.m_fruitNums = self.m_fruitNums + 1
        end
    end
end

function NewCoinPusherManager:addFruitNums(value)
    self.m_fruitNums = self.m_fruitNums + value
end

function NewCoinPusherManager:getFruitNums()
    return self.m_fruitNums or 0
end

function NewCoinPusherManager:reduceInsertPos()
    self.m_insertPos = math.max(self.m_insertPos - 1, 1)
end

return NewCoinPusherManager

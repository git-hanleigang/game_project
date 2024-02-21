local LevelRushManager = class("LevelRushManager", util_require("baseActivity.BaseActivityManager"))
LevelRushManager.m_instance = nil

-- ctor --
function LevelRushManager:ctor()
    LevelRushManager.super.ctor(self)

    self.m_hadPopPanelList = {} -- 关卡内弹出的 活动开启进度弹板

    self:registerObserve()
end

-- instance --
function LevelRushManager:getInstance()
    if not self.m_instance then
        self.m_instance = LevelRushManager.new()
    end

    return self.m_instance
end

function LevelRushManager:initBaseData()
    self:initCountTime()
end

function LevelRushManager:initCountTime()
    -- self:stopCountTime()
    -- self.m_loaclLastTime = socket.gettime()
    -- self.m_levelRushTimer = scheduler.scheduleGlobal(function()
    --     --获取真实倒计时
    --     local delayTime = 1
    --     if self.m_loaclLastTime then
    --         local spanTime = socket.gettime()-self.m_loaclLastTime
    --         self.m_loaclLastTime = socket.gettime()
    --         if spanTime>0 then
    --             delayTime = spanTime
    --         end
    --     end
    -- end, 1)
end

function LevelRushManager:stopCountTime()
    -- if self.m_levelRushTimer then
    --     scheduler.unscheduleGlobal(self.m_levelRushTimer)
    --     self.m_levelRushTimer = nil
    -- end
end

function LevelRushManager:addHadPopList(_key, _val)
    self.m_hadPopPanelList[_key] = _val
end

function LevelRushManager:clearHadPopList()
    self.m_hadPopPanelList = {}
end

--------------------------------- observe S--------------------------------------
-- 注册消息 --
function LevelRushManager:registerObserve()
    -- 下载结束发送通知
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 活动资源下载完成
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_RUSH_REFRESH_EXP_BUFF)
        end,
        "DL_Complete" .. "Activity_LevelRush"
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 邮件资源下载完成
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        end,
        "DL_Complete" .. "Activity_LevelRushInbox"
    )

    -- 活动结束删除 已经存的 本地邮件
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.LevelRush then
                local collectData = G_GetMgr(G_REF.Inbox):getSysRunData()
                if collectData then
                    collectData:removeLevelRushMail()
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_RUSH_REFRESH_INBOX)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end
--------------------------------- observe E--------------------------------------

--------------------------------- 下载逻辑 S --------------------------------------
-- 下载完代码
function LevelRushManager:isDownloadCode()
    -- if globalDynamicDLControl:checkDownloading("Activity_LevelRush_Code") then
    --     return false
    -- else
    --     return true
    -- end
    return globalDynamicDLControl:checkDownloaded("Activity_LevelLink_Code")
end
-- 下载完资源
function LevelRushManager:isDownloadRes()
    -- if globalDynamicDLControl:checkDownloading("Activity_LevelRush") then
    --     return false
    -- else
    --     return true
    -- end
    if globalDynamicDLControl:checkDownloaded("Activity_LevelLink_Code") and globalDynamicDLControl:checkDownloaded("Activity_LevelLink") then
        return true
    else
        return false
    end
end
-- 下载完邮箱
function LevelRushManager:isDownloadInbox()
    -- if globalDynamicDLControl:checkDownloading("Activity_LevelRushInbox") then
    --     return false
    -- else
    --     return true
    -- end
    return globalDynamicDLControl:checkDownloaded("Activity_LevelRushInbox")
end

--------------------------------- 下载逻辑 E --------------------------------------

--------------------------------- ui      S--------------------------------------
--------------------------------- ui      E--------------------------------------

--------------------------------- netWork S--------------------------------------
-- 请求游戏数据 --
function LevelRushManager:requestGameData(_nIndex, _successFunc)
    local funcSuccess = function(data)
        gLobalViewManager:removeLoadingAnima()
        if _successFunc then
            _successFunc()
        end
    end

    local funcFailed = function()
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    gLobalViewManager:addLoadingAnima()
    local actionType = ActionType.LevelRushGameData

    local params = {
        index = _nIndex
    }
    self:sendMsgBaseFunc(actionType, nil, params, funcSuccess, funcFailed)
end

-- 点击play _nIndex 游戏index  _nStartIndex 掉球的位置 --
function LevelRushManager:requestGamePlayData(_nStartIndex)
    local funcSuccess = function(resData)
        if resData.result and resData.result ~= "" then
            local data = cjson.decode(resData.result)
            --抛消息
            gLobalViewManager:removeLoadingAnima()
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_RUSH_GAME_PLAY, {path = data.routes, dis = data.fishTankDis})
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_RUSH_LAUNCH_BALLS, {path = data.routes, dis = data.fishTankDis})
        else
            gLobalViewManager:removeLoadingAnima()
        end
    end

    local funcFailed = function()
        --抛消息
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end
    gLobalViewManager:addLoadingAnimaDelay(2)
    local actionType = ActionType.LevelRushGamePlay

    local gameData = self:getRunningGameData()

    local params = {
        index = gameData:getGameIndex(),
        startPos = _nStartIndex,
        source = gameData:getSource()
    }

    self:sendMsgBaseFunc(actionType, nil, params, funcSuccess, funcFailed)
end

-- 收集游戏奖励 --
function LevelRushManager:requestGameCollect()
    local funcSuccess = function(resData)
        if resData.result then
            -- -- 收集完成切换付费 LevelRush
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_RUSH_CHANGE_PAY_FACE)
            local data = cjson.decode(resData.result)
            -- 抛消息
            gLobalViewManager:removeLoadingAnima()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_RUSH_COLLECT_OVER)
        else
            local a = 1
        end
    end

    local funcFailed = function()
        --抛消息
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end
    gLobalViewManager:addLoadingAnima()

    local actionType = ActionType.LevelRushGameCollect
    local gameData = self:getRunningGameData()
    local params = {
        index = gameData:getGameIndex(),
        source = gameData:getSource()
    }

    self:sendMsgBaseFunc(actionType, nil, params, funcSuccess, funcFailed)
end

-- LevelRush 小游戏删除 (玩家确认不购买后 删除该活动数据)
function LevelRushManager:requestDelRunningGameData()
    local funcSuccess = function(resData)
        print("del levelRush game data success")
        gLobalViewManager:removeLoadingAnima()
    end

    local funcFailed = function()
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end
    gLobalViewManager:addLoadingAnima()

    local actionType = ActionType.LevelRushGameRemove
    local gameData = self:getRunningGameData()
    local params = {
        index = gameData:getGameIndex(),
        source = gameData:getSource()
    }

    self:sendMsgBaseFunc(actionType, nil, params, funcSuccess, funcFailed)
end
--------------------------------- netWork E--------------------------------------

--------------------------------- inner interface S------------------------------
-- 当前游戏Index --
function LevelRushManager:setGameIndex(_nIndex)
    self.m_nGameIndex = _nIndex
end

function LevelRushManager:getGameIndex()
    return self.m_nGameIndex
end

-- 获取活动数据 --
function LevelRushManager:getLevelRushData()
    local bIgnoreRunning = self.m_source and self.m_source == "LevelRushInbox"

    --注意这里上线去挑 true参数
    return G_GetActivityDataByRef(ACTIVITY_REF.LevelRush, bIgnoreRunning)
end

-- 获取id为index 游戏数据 --
function LevelRushManager:getGameData(_nIndex)
    -- 获取数据的地方需要判断来源
    local gameData = nil
    if self.m_source and self.m_source == "MiniGame" then
        gameData = gLobalMiniGameManager:getLevelFishGameDataForIdx(_nIndex)
        return gameData
    else
        -- cxc 2021年09月08日17:03:35 改活动结束也可以完小游戏
        local levelRushData = G_GetActivityDataByRef(ACTIVITY_REF.LevelRush, true)
        if levelRushData then
            local gameData = levelRushData:getGameData(_nIndex)
            return gameData
        end
    end

    return nil
end

function LevelRushManager:checkGameInit(_nIndex)
    local gameData = self:getGameData(_nIndex)
    if gameData then
        return gameData:checkHasRewards()
    end
    return false
end

-- 获取最后一个游戏数据 --
function LevelRushManager:getLastGameData()
    local levelRushData = G_GetActivityDataByRef(ACTIVITY_REF.LevelRush)
    if levelRushData then
        local gameData = levelRushData:getLastGameData()
        return gameData
    end
    return nil
end

-- 获取当前玩的游戏数据 --
function LevelRushManager:getRunningGameData()
    return self:getGameData(self.m_nGameIndex)
end

function LevelRushManager:checkLevelRushEnterGame()
    local activityData = self:getLevelRushData()
    if not activityData then
        return false
    end
    if not activityData:getActivityOpen() then
        return false
    end
    if not self:isDownloadRes() then
        return false
    end
    if not G_GetMgr(G_REF.LeveDashLinko):getIsGames() then
        return false
    end
    local endLv = activityData:getEndLevel()
    if globalData.userRunData.levelNum == endLv and self:checkFirstPopByCurLevel(2, endLv) then
        self:clearHadPopList()
        return true
    else
        return false
    end
end

-- 就执行之前的逻辑 (开启 和 half 时才 弹出)
function LevelRushManager:checkLevelRushTriggerOld(_bUpLv)
    local activityData = self:getLevelRushData()
    if not activityData then
        return false
    end
    local startLv = activityData:getStartLevel()
    local bStart = startLv == globalData.userRunData.levelNum
    if bStart then
        return self:checkFirstPopByCurLevel(1, globalData.userRunData.levelNum)
    end

    if not _bUpLv then
        return false
    end

    return globalData.userRunData.levelNum == activityData:getMidlleLevel() and self:checkFirstPopByCurLevel(1, globalData.userRunData.levelNum)
end

function LevelRushManager:checkLevelRushTrigger(_bUpLv)
    local activityData = self:getLevelRushData()
    if not activityData then
        return false
    end
    if not activityData:getActivityOpen() then
        return false
    end
    if not self:isDownloadRes() then
        return false
    end

    -- cxc 2021年06月25日11:45:42  LevelRush阶段奖励 开启新手期功能 才显示
    if not globalData.GameConfig:checkUseNewNoviceFeatures() then
        -- 没有 就执行之前的逻辑 (开启 和 half 时才 弹出)
        return self:checkLevelRushTriggerOld(_bUpLv)
    end

    if not _bUpLv and not self:checkFirstPopByCurLevel(1, globalData.userRunData.levelNum) then
        return false
    end

    local phaseDataLsit = activityData:getPhaseRewardList()
    if #phaseDataLsit <= 0 then
        return false
    end

    local startLv = activityData:getStartLevel()
    local bInPahse = startLv == globalData.userRunData.levelNum
    if not bInPahse and _bUpLv then
        for i, data in ipairs(phaseDataLsit) do
            local lv = data:getLevel()
            if lv == globalData.userRunData.levelNum then
                bInPahse = true
                break
            end

            if lv > globalData.userRunData.levelNum then
                break
            end
        end
    end
    if bInPahse and self:checkFirstPopByCurLevel(1, globalData.userRunData.levelNum) then
        return true
    else
        return false
    end
end

-- 第一次 触发该等级对应的 弹板
function LevelRushManager:checkFirstPopByCurLevel(_type, _lv)
    _lv = _lv or globalData.userRunData.levelNum
    local key = ""
    if _type == 1 then
        -- trigger
        key = "trigger_" .. _lv
    elseif _type == 2 then
        -- endlv openGame
        key = "end_" .. _lv
    else
        return false
    end

    return not self.m_hadPopPanelList[key]
end

-- 弹出leverush升级弹板 --
function LevelRushManager:showGameStartView(_overFunc)
    local levelRushData = self:getLevelRushData()
    if levelRushData then
        if globalData.userRunData.levelNum == levelRushData:getEndLevel() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_RUSH_REFRESH_EXP_BUFF)
            return self:pubRequestNewOpenGameData(_overFunc)
        end
    end
end

function LevelRushManager:showUpView(_half, _overCall, _bSpinTrigger,_bFirstAct)
    if not self:isDownloadRes() then
        return
    end

    local levelRushData = self:getLevelRushData()
    if levelRushData ~= nil and levelRushData:getActivityOpen() then
        gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "levelRush")
        local view = nil
        local group = globalData.GameConfig:getABtestGroup("LevelDash")
        if _bFirstAct then
            view = util_createFindView("Activity/LevelLinkSrc/LevelRush_UpTwo", _half, _overCall, _bSpinTrigger,_bFirstAct)
        else
            view = util_createFindView("Activity/LevelLinkSrc/LevelRush_UpView", _half, _overCall, _bSpinTrigger,_bFirstAct)
        end
        if view == nil then
            return
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_RUSH_REFRESH_EXP_BUFF)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        self:addHadPopList("trigger_" .. globalData.userRunData.levelNum, true)
        return view
    end
end

function LevelRushManager:showDoubleBuffView(_overCall)
    _overCall = _overCall or function()
        end
    if not self:isDownloadRes() then
        _overCall()
        return
    end

    local levelRushData = self:getLevelRushData()
    if levelRushData ~= nil and levelRushData:getActivityOpen() and levelRushData:isOpenDoubleBuff() then
        local view = util_createFindView("Activity/LevelLinkSrc/LevelRush_DoubleBuffView", levelRushData, _overCall)
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            return view
        end
    end

    _overCall()
end

-- 弹出leverush开启弹板 --
function LevelRushManager:showGameOpenTipView(_overFunc)
    local view
    if self:isDownloadRes() then
        local levelRushData = self:getLevelRushData()
        if levelRushData and levelRushData:getActivityOpen() then
            view = util_createFindView("Activity/LevelLinkSrc/LevelRush_OpenTipView", _overFunc)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

            self:addHadPopList("end_" .. globalData.userRunData.levelNum, true)
        end
    else
        view = gLobalViewManager:showDownloadTip(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end,
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end
        )
    end
    return view
end

-- 请求游戏数据 返回后弹出游戏主界面 --
function LevelRushManager:showLevelRushRequest()
    local gameData = self:getRunningGameData()
    if gameData then
        self:showLevelRushView()
    end
end

-- 通过index打开游戏主界面 --
function LevelRushManager:showLevelRushIndex(_nIndex)
    -- 记录当前游戏index --
    self:setGameIndex(_nIndex)
    local gameData = self:getGameData(_nIndex)
    if gameData then
        self:showLevelRushView()
    end
end

-- 打开游戏主界面 --
function LevelRushManager:showLevelRushView(_overCall)
    local gameData = self:getRunningGameData()
    -- 未下载时弹框提示
    if self:isDownloadRes() then
        --先组织数据，然后进入游戏
        -- local info = globalData.slotRunData:getLevelInfoById(10208)
        -- globalData.slotRunData.machineData = info
        -- if globalData.slotRunData.isPortrait == false then
        --     globalData.slotRunData.isChangeScreenOrientation = true
        --     globalData.slotRunData:changeScreenOrientation(true)
        -- end
        -- local view = util_createView("Activity.LevelDashLink.LevelDashLinkGame")
        -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        G_GetMgr(G_REF.LeveDashLinko):enterGame(self:getGameIndex())
    else
        gLobalViewManager:showDialog("Dialog/LevelDashIndexIf.csb", _overCall, nil, nil, nil)
    end
end

-- 打开游戏结算界面 --
function LevelRushManager:showLevelRushResultView()
    local gameData = self:getRunningGameData()
    if gameData and not gLobalViewManager:getViewByExtendData("LevelRush_ResultView") then
        local view = util_createFindView("Activity/LevelRushSrc/LevelRush_ResultView")
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
end

-- 打开游戏支付界面 --
function LevelRushManager:showPayView()
    local gameData = self:getRunningGameData()
    if gameData and not gLobalViewManager:getViewByExtendData("LevelRush_PayView") then
        local view = util_createFindView("Activity/LevelRushSrc/LevelRush_PayView")
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
end

-- 打开游戏支付二次弹窗
function LevelRushManager:showPayConfirmView()
    local gameData = self:getRunningGameData()
    if gameData and not gLobalViewManager:getViewByExtendData("LevelRush_PayConfirmView") then
        local view = util_createFindView("Activity/LevelRushSrc/LevelRush_PayConfirmView")
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
end

function LevelRushManager:showExpTipView(_flag)
    if self:isDownloadRes() then
        local view = util_createFindView("Activity/LevelLinkSrc/LevelRush_ExpTip", _flag)
        return view
    end
    return nil
end

-- 是当前游戏否全部完成 --
function LevelRushManager:getRunningGameOver()
    local gameData = self:getRunningGameData()
    if gameData then
        local bPurchase = gameData:getHasPurchase()
        local bCollected = gameData:getRewardIsCollect()
        local nLeftBall = gameData:getLeftBallsCount()
        local isClickXInPayConfirm = gameData:getClickXInPayConfirm()
        local activityData = self:getLevelRushData()

        -- cxc 2021年09月08日17:26:53 游戏到期使用本身游戏数据的时间判断，不用活动时间
        -- local activityData = self:getLevelRushData()
        -- if not activityData then
        --     return true
        -- else
        -- local strTime, isOver = activityData:getTodayLeftTime()
        local strTime, isOver = gameData:getTodayLeftTime()
        if isOver then -- 如果活动到期直接认为游戏结束，不需要再判断是否玩过
            return true
        end
        -- end

        if nLeftBall == 0 and bCollected and (bPurchase or isClickXInPayConfirm) then
            return true
        else
            return false
        end
    end

    return true
end

-- 是index否全部完成 --
function LevelRushManager:getGameOverByIndex(_nIndex)
    local gameData = self:getGameData(_nIndex)
    if gameData then
        local bPurchase = gameData:getHasPurchase()
        local bCollected = gameData:getRewardIsCollect()
        local nLeftBall = gameData:getLeftBallsCount()
        local isClickXInPayConfirm = gameData:getClickXInPayConfirm()

        local rewardCfg = gameData:getRewardConfig()
        if rewardCfg == nil then
            return true
        end

        -- cxc 2021年09月08日17:26:53 游戏到期使用本身游戏数据的时间判断，不用活动时间
        -- local activityData = self:getLevelRushData()
        -- if not activityData then
        --     return true
        -- else
        -- local strTime, isOver = activityData:getTodayLeftTime()
        local strTime, isOver = gameData:getTodayLeftTime()
        if isOver then -- 如果活动到期直接认为游戏结束，不需要再判断是否玩过
            return true
        end
        -- end

        if nLeftBall == 0 and bCollected and (bPurchase or isClickXInPayConfirm) then
            return true
        else
            return false
        end
    end

    return true
end

function LevelRushManager:getShowPayView()
    local gameData = self:getRunningGameData()
    if not gameData then
        return false
    end
    local bPurchase = gameData:getHasPurchase()
    local bCollected = gameData:getRewardIsCollect()
    local nLeftBall = gameData:getLeftBallsCount()
    local isClickXInPayConfirm = gameData:getClickXInPayConfirm()
    if bCollected == true and nLeftBall == 0 and (bPurchase == false and not isClickXInPayConfirm) then
        return true
    end
    return false
end

--------------------------------- inner interface E------------------------------

--------------------------------- external interface S---------------------------
-- network请求 --
-- 请求游戏数据 --
function LevelRushManager:pubRequestGameData(_nIndex)
    self:setGameIndex(_nIndex)
    self:requestGameData(
        _nIndex,
        function()
            self:showLevelRushRequest()
        end
    )
end

-- 收集奖励
function LevelRushManager:pubRequestGameCollect()
    local gameData = self:getRunningGameData()

    if gameData and not gameData:getRewardIsCollect() then
        self:requestGameCollect()
    end
end

-- 请求新开启游戏的数据 --
function LevelRushManager:pubRequestNewOpenGameData(_overFunc)
    local activityData = self:getLevelRushData()
    if not activityData then
        return
    end
    if not G_GetMgr(G_REF.LeveDashLinko):getIsGames() then
        return false
    end
    -- 记录当前游戏index --
    local nGameIndex = G_GetMgr(G_REF.LeveDashLinko):getEnterGameData()
    if nGameIndex == nil then
        return false
    end
    self:setGameIndex(nGameIndex)
    -- self:requestGameData(
    --     nGameIndex,
    --     function()
    --         self:showGameOpenTipView(_overFunc)
    --     end
    -- )
    local view = self:showGameOpenTipView(_overFunc)
    return view
end

-- 获取活动数据 --
function LevelRushManager:pubGetLevelRushData(_bIgnoreRunning)
    return self:getLevelRushData(_bIgnoreRunning)
end

-- 判断活动是否开启 --
function LevelRushManager:pubGetLevelRushOpen()
    local levelRushData = self:getLevelRushData()
    if levelRushData and levelRushData:getActivityOpen() then
        return true
    end
    return false
end

-- 判断buff是否开启 --
function LevelRushManager:pubGetLevelRushBuffOpen()
    local levelRushData = self:getLevelRushData()
    if levelRushData and levelRushData:getBuffOpen() then
        return true
    end
    return false
end

-- 检查游戏是否初始化 --
function LevelRushManager:pubCheckGameInit(_nIndex)
    return self:checkGameInit(_nIndex)
end

-- 获取当前进行游戏的数据 --
function LevelRushManager:pubGetRunningGameData()
    return self:getRunningGameData()
end

--  游戏开始弹窗 --
function LevelRushManager:pubShowGameStartView(_overFunc)
    return self:showGameStartView(_overFunc)
end

--  升级弹窗 --
function LevelRushManager:pubShowUpView(half, _overFunc, _bSpinTrigger, bFirstAct, _isAutoClose)
    -- 关卡spin 激活弹窗
    self.m_bFirstActiveUpView = _bSpinTrigger and bFirstAct
    local view  = self:showUpView(half, _overFunc, _bSpinTrigger,bFirstAct)
    return view
end

--  双倍buff弹窗 --
function LevelRushManager:pubShowDoubleBuffView(_overFunc)
    self:showDoubleBuffView(_overFunc)
end

-- 是否是付费rush --
function LevelRushManager:pubGetInPayView()
    local gameData = self:getRunningGameData()

    local bPurchase = gameData:getHasPurchase()
    local bCollected = gameData:getRewardIsCollect()
    local nLeftBall = gameData:getLeftBallsCount()

    if bPurchase == true or (bCollected == true and nLeftBall == 0 and bPurchase == false) then
        return true
    end
    return false
end

-- 当前游戏是否全部完成 --
function LevelRushManager:pubGetRunningGameOver()
    return self:getRunningGameOver()
end

-- 当前游戏是否全部完成 --
function LevelRushManager:pubGetGameOverByIndex(_nIndex)
    return self:getGameOverByIndex(_nIndex)
end

--  购买弹窗 --
function LevelRushManager:pubShowPayView()
    if self:getShowPayView() then
        self:showPayView()
    end
end

--弹出购买弹窗条件 --
function LevelRushManager:pubGetShowPayView()
    return self:getShowPayView()
end

--  购买二次确认弹窗 --
function LevelRushManager:pubShowPayConfirmView()
    self:showPayConfirmView()
end

-- 打开收集弹窗 --
function LevelRushManager:pubShowLevelRushResultView()
    local gameData = self:getRunningGameData()

    local bCollected = gameData:getRewardIsCollect()
    local nLeftBall = gameData:getLeftBallsCount()

    if not bCollected and nLeftBall == 0 then
        self:showLevelRushResultView()
    end
end

--  打开游戏界面 --
function LevelRushManager:pubShowLevelRush(_nIndex)
    self:showLevelRushIndex(_nIndex)
end

-- 关闭游戏回调 --
function LevelRushManager:pubCloseLevelDash()
    self:setGameIndex(nil)
end

function LevelRushManager:isShowFinger()
    return gLobalDataManager:getBoolByField("FirstLevelRushGuide_" .. globalData.userRunData.uid, false) == false
end

--添加finger
function LevelRushManager:addFigner(_fingerNode, _x, _y)
    self.m_spineFinger = util_spineCreate("Activity/LevelLinkSrc/extra/DailyBonusGuide", true, true, 1)
    self.m_spineFinger:setPosition(cc.p(_x, _y))
    _fingerNode:addChild(self.m_spineFinger)
    util_spinePlay(self.m_spineFinger, "idleframe", true)
    gLobalDataManager:setBoolByField("FirstLevelRushGuide_" .. globalData.userRunData.uid, true)
end

--隐藏finger
function LevelRushManager:delFinger()
    if self.m_spineFinger ~= nil then
        self.m_spineFinger:removeFromParent()
        self.m_spineFinger = nil
    end
end

--------------------------------- external interface E---------------------------

-- 本次 play 触发的特殊钉子
function LevelRushManager:setCurGameIdxTriggerType(_triggerType)
    self.m_triggerType = _triggerType
end
function LevelRushManager:getCurGameIdxTriggerType()
    return self.m_triggerType
end
function LevelRushManager:resetCurGameIdxTriggerType()
    self.m_triggerType = nil
end

-- 设置鱼缸的位置 world
function LevelRushManager:setBowDingPosYW(_posYW)
    self.m_bowDingPosYW = _posYW
end
function LevelRushManager:getBowDingPosYW()
    return self.m_bowDingPosYW or 0
end

function LevelRushManager:reParseLevelRushPhaseReward(_rewardData)
    local activityData = self:getLevelRushData()
    if not activityData then
        return false
    end
    if not activityData:getActivityOpen() then
        return false
    end

    local rewardList = activityData:getPhaseRewardList()
    if not rewardList or #rewardList <= 0 then
        return
    end

    for i, phaseData in ipairs(rewardList) do
        phaseData:reParseCollectType()
    end
end

function LevelRushManager:getRewardT(_index)
    local activityData = self:getLevelRushData()
    if not activityData then
        return false
    end
    if not activityData:getActivityOpen() then
        return false
    end

    local rewardList = activityData:getPhaseRewardList()
    if not rewardList or #rewardList <= 0 then
        return
    end
    local rewad = rewardList[_index-1]
    local rewad1 = rewardList[_index]
    local flag = false
    if rewad then
        if rewad:getCollectType(true) == 0 and rewad1:getCollectType(true) == 2 then
            flag = true
        end
    else
        if rewad1:getCollectType(true) == 2 then
            flag = true
        end
    end
    return flag
end

----------------------- 适配小游戏接口 ----------------------
function LevelRushManager:setLevelRushSource(_source)
    self.m_source = _source
end

function LevelRushManager:getLevelRushSource()
    return self.m_source
end

function LevelRushManager:setIsEnterGameView(_enter)
    self.m_isEnterGameView = _enter
end

function LevelRushManager:getIsEnterGameView()
    return self.m_isEnterGameView
end

-- 是否是 spin 第一次激活弹出的 UpView
function LevelRushManager:isSpinActiveUpView()
    return self.m_bFirstActiveUpView
end
function LevelRushManager:resetSpinActiveUpView()
    self.m_bFirstActiveUpView = false
end

-----------------------  道具掉落相关 ---------------
function LevelRushManager:setPopLevelRushTempList(_list)
    self.m_shopItemList = _list
end
function LevelRushManager:getPopLevelRushTempList(_list)
    return self.m_shopItemList
end
function LevelRushManager:resetLevelRushTempList()
    self.m_shopItemList = {}
end

return LevelRushManager

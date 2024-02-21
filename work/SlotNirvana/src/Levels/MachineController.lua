--
-- Slots的处理逻辑
-- Date: 2020-07-14 11:39:57
-- FIX IOS 139
local MachineController = class("MachineController")
MachineController.__DELAY_HANDLE_NAME = "delay_handler_name"

function MachineController:ctor()
    self.systemUICor = nil

    self.m_isEffectPlaying = true
    self.m_machine = nil

    --固定弹版函数列表（按顺序显示）
    -- self:createPopList()
end

function MachineController:getInstance()
    if MachineController.m_instance == nil then
        MachineController.m_instance = MachineController.new()
    end
    return MachineController.m_instance
end

-- Spin推送关卡
function MachineController:setPushGameId(slotId)
    if slotId and slotId ~= "" then
        self.m_pushSlotId = slotId
    end
end

function MachineController:clearPushGameId()
    self.m_pushSlotId = nil
end

function MachineController:getPushGameId()
    return self.m_pushSlotId
end

-- 关卡spin结束后 是否需要忽略系统 弹板
function MachineController:setIgnorePopCorEnabled(_bEabled)
    self._bIgnorePopCorEnabled = _bEabled
end

function MachineController:getIgnorePopCorEnabled()
    return self._bIgnorePopCorEnabled or false
end

-- 显示当前 协程挂起的 系统 弹板名称
function MachineController:showDebugPopName(_popUpName, _bWhite)
    if DEBUG == 0 then
        return
    end

    local lbPopName = gLobalViewManager.p_ViewLayer:getChildByName("Lb_Slot_Spin_Over_Layer")
    if not lbPopName then
        lbPopName = cc.LabelTTF:create("", "Arial", 36)
        lbPopName:setName("Lb_Slot_Spin_Over_Layer")
        lbPopName:addTo(gLobalViewManager.p_ViewLayer, 99999999)
        lbPopName:move(20, display.height - 40)
        lbPopName:setColor(cc.RED)
        lbPopName:setHorizontalAlignment(0)
        lbPopName:setAnchorPoint(cc.p(0, 1)) 
    end

    local str = ""
    if type(_popUpName) == "string" then
        str = string.format("spinOver忽略弹板开关:%s\n弹板:%s\n白名单:%s", tostring(self:getIgnorePopCorEnabled()), _popUpName, tostring(_bWhite or false))
    end
    lbPopName:setString(str)
end

function MachineController:resetPopList(pop_list)
    pop_list = pop_list or {}
    if pop_list and type(pop_list) == "table" then
        self.popupViewFuncList = pop_list
    end
    -- 清空待执行列表
    self.popupExtraFuncList = {}
end

function MachineController:hasPopList()
    return (#self.popupViewFuncList > 0) or (#self.popupExtraFuncList > 0)
end

-- 关卡spin结束后 监测弹出的 系统弹板。 bWhite是否是白名单， 关卡设置忽略弹板也会弹
function MachineController:createPopList()
    self.popupViewFuncList = {
        -- ios att 跳转设置界面
        {popFuncName = "popupAttGotoSettingLayer", bWhite = false},
        {popFuncName = "popupDiyFeaturesTakePartInLayer", bWhite = true},
        {popFuncName = "popupDiyFeaturesSaleLayer", bWhite = true},
        {popFuncName = "popupSpinUpgrade", bWhite = false},
        -- jackpot变化和可能弹出的弹版，要求优先级高
        {popFuncName = "checkFlamingoJackpotGuide", bWhite = true},
        {popFuncName = "popFlamingoJackpotDayFirst", bWhite = true},
        {popFuncName = "checkActiveFlamingoJackpot", bWhite = true},
        {popFuncName = "popupLevelRoadMainLayer", bWhite = true},
        {popFuncName = "popupTimeBackMainLayer", bWhite = false},
        {popFuncName = "popupSuperValueSaleLayer", bWhite = false},
        {popFuncName = "popupHourDealMainLayer", bWhite = false},
        {popFuncName = "popupNewQuestOpenLayer", bWhite = true},
        {popFuncName = "popupDragonChallengeGetWheelLayer", bWhite = false},
        {popFuncName = "popupDragonChallengeBoxRewardLayer", bWhite = false},
        {popFuncName = "popupLeagueMainUI", bWhite = false},
        {popFuncName = "popupLuckyRaceOpenLayer", bWhite = false},
        {popFuncName = "popupLuckyRaceMainLayer", bWhite = false},
        {popFuncName = "popupSpinBonus", bWhite = false},
        {popFuncName = "popupBonusHunt", bWhite = false},
        {popFuncName = "popupGemChallengeLayer", bWhite = false},
        {popFuncName = "popupLevelUpPassLayer", bWhite = false},
        {popFuncName = "checkPickTaskComplete", bWhite = false},
        {popFuncName = "checkReturnSpinTaskComplete", bWhite = false},
        {popFuncName = "checkNewPassUpdateConfig", bWhite = true}, -- 刷新pass配置
        {popFuncName = "popupAutoCollectMission", bWhite = true}, -- 自动收集每日任务
        {popFuncName = "popupAvatarFrameRewardLayer", bWhite = true},
        {popFuncName = "popupAvatarFrameChallengeLayer", bWhite = true},
        {popFuncName = "popupClanBoxLvUp", bWhite = false},
        {popFuncName = "checkLevelDashPlus", bWhite = false},
        ------ levelrush相关 levelRush中掉落道具会更新活动 进度 所以放到 活动解锁前边---
        {popFuncName = "popupLevelRushTrigger", bWhite = false},
        {popFuncName = "popupLevelRushEnterGame", bWhite = false},
        {popFuncName = "popupRippleDashLayer", bWhite = false},
        {popFuncName = "popupDeluxeExCardLayer", bWhite = false},
        ------ levelrush相关 --------
        -- {popFuncName = "popupActivityUnlock", bWhite = false},
        {popFuncName = "popupWildChallengeMainLayer", bWhite = false},
        {popFuncName = "popupCollect", bWhite = false},
        {popFuncName = "popupCollectMax", bWhite = true},
        {popFuncName = "popupBalloonRush", bWhite = false},
        {popFuncName = "luckyChipsDrawShowTick", bWhite = false},
        {popFuncName = "popupHotToday", bWhite = false},
        {popFuncName = "repartUpdatePrizeTips", bWhite = false},
        -- {popFuncName = "popupLeagueUnlock", bWhite = false},
        -- {popFuncName = "popupSlotChallenge", bWhite = false},
        {popFuncName = "popupSlotTrials", bWhite = false},
        {popFuncName = "popupLeagueScoreCollect", bWhite = false},
        {popFuncName = "popupMinzMainLayer", bWhite = true},
        {popFuncName = "popupMinzFirstLayer", bWhite = true},
        {popFuncName = "popupChaseForChips", bWhite = false},
        {popFuncName = "popupTimeLimitExpansion", bWhite = false},
        -- {popFuncName = "popupFBGroup", bWhite = false},
        {popFuncName = "popupQuestTaskDoneView", bWhite = true},
        -- 检测quest活动结束 这个最好放最后 这里要退出关卡
        {popFuncName = "popupQuestEnded", bWhite = true},
        {popFuncName = "missionRushTip", bWhite = false}, --此条放在最后
        {popFuncName = "popupIcebreakerSale", bWhite = false}, --新版破冰促销
        {popFuncName = "configPushZomReward", bWhite = false},--行尸走肉领奖
        {popFuncName = "bigWinChallengeTip", bWhite = false},
        {popFuncName = "cardOpenNoticeLayer", bWhite = false}, -- 普通集卡 18级解锁宣传弹板
        {popFuncName = "popMinBetNoCoinsLayer", bWhite = false},
        {popFuncName = "popColNoviceTrail", bWhite = false}, -- 新手3日任务奖励 有可领取的 弹主界面
        {popFuncName = "popTomorrowGiftMainLayer", bWhite = false}, -- 次日礼物主界面
        {popFuncName = "popColFrostFlameClash", bWhite = false}, --1 v 1 结果
        {popFuncName = "popTrillionChallengeTask", bWhite = false}, -- 亿万赢钱挑战 可领奖
        {popFuncName = "popHolidayPassProcessLayer", bWhite = false}, -- 新版圣诞聚合pass
        {popFuncName = "popWantedMainLayer", bWhite = false}, -- 弹出Wanted界面领奖
        {popFuncName = "popupMegaWinFirstOpenInfoLayer", bWhite = true}, --大赢宝箱说明
    }
    
    -- 播放插屏广告
    table.insert(self.popupViewFuncList, {popFuncName = "popupLevelUpPlayAds", bWhite = true})

    -- 检测比赛聚合
    table.insert(self.popupViewFuncList, {popFuncName = "popupBattleMatch", bWhite = false})

    --这俩放在最后
    table.insert(self.popupViewFuncList, {popFuncName = "popupJackpotPush", bWhite = false})
    table.insert(self.popupViewFuncList, {popFuncName = "popupGameEffectOver", bWhite = false})

    --扩展弹版函数列表
    self.popupExtraFuncList = {}
end

function MachineController:onEnter()
    -- 固定弹版函数列表（按顺序显示）
    self:createPopList()
    self:registerListener()
end

function MachineController:onExit()
    G_GetMgr(ACTIVITY_REF.GemChallenge):resetCheckCount()
    G_GetMgr(ACTIVITY_REF.LevelUpPass):resetCheckCount()
    self:resetPopList()
    scheduler.unschedulesByTargetName(__DELAY_HANDLE_NAME)
    self.systemUICor = nil
    gLobalNoticManager:removeAllObservers(self)
end

-- bet计算 spin时额外消耗bet
function MachineController:calculateBetExtraCost(_betValue)
    _betValue = _betValue or 0
    local extraPercent = G_GetMgr(G_REF.BetExtraCosts):getExtraPercent()
    if extraPercent and extraPercent > 0 then
        _betValue = _betValue + _betValue * extraPercent
    end
    return _betValue
end

--[[
    @desc: 按照一定音量播放bgm ， 之后恢复音量
    time:2020-07-14 11:47:36
    --@bgmName:
	--@bgmTime:
	--@volume:  默认0.4
	--@resumeVolume:   默认  1
    @return:
]]
function MachineController:playBgmAndResume(bgmName, bgmTime, volume, resumeVolume)
    volume = volume or 0.4
    resumeVolume = resumeVolume or 1

    gLobalSoundManager:setBackgroundMusicVolume(volume)
    local soundID = gLobalSoundManager:playSound(bgmName, false)

    local delayHandleId =
        scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:setBackgroundMusicVolume(resumeVolume)
        end,
        bgmTime,
        self.__DELAY_HANDLE_NAME
    )

    return soundID, delayHandleId
end

--放入执行的弹版执行函数队列
function MachineController:pushPopupExtraFunc(_popUpName, _callBack, _param, _bWhite)
    -- 优化：不判断协同是否创建，保证任何时候都可以插入，并且spin结束后可以删除
    if not _callBack then
        return
    end
    if self.popupExtraFuncList ~= nil then
        table.insert(self.popupExtraFuncList, {popUpName = _popUpName, callBack = _callBack, param = _param, bWhite = _bWhite})
    else
        _callBack(_param)
    end
end

function MachineController:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:resumeShowSystemUICor()
        end,
        ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:showLevelDashView(params == true)
        end,
        ViewEventType.NOTIFY_LEVEL_DASH_START
    )
end

function MachineController:checkShowPopUpUI(machine)
    local machineData = globalData.slotRunData.machineData
    if self.systemUICor == nil and machine ~= nil and machineData ~= nil and machineData.p_betsData ~= nil and self:hasPopList() then
        self.systemUICor =
            coroutine.create(
            function()
                globalFireBaseManager:checkFireBaseLog()

                for index, popLayerInfo in ipairs(self.popupViewFuncList) do
                    
                    if not self._bIgnorePopCorEnabled or popLayerInfo.bWhite then
                        -- 没有设置 spin后 忽略 弹板 或者 设置了 但是该弹板在白名单里 监测弹板

                        self.cur_popName = popLayerInfo.popFuncName
                        local func = self[self.cur_popName]
                        local ok, result =
                            pcall(
                            function()
                                return func(self, machine)
                            end
                        )

                        if not ok then
                            local errMsg = "error check show popUpUI = " .. self.cur_popName .. "\n" .. result
                            if DEBUG == 0 then
                                sendBuglyLuaException(errMsg)
                            else
                                assert(false, errMsg)
                            end
                        else
                            if result then
                                release_print("check show popUpUI = " .. self.cur_popName)
                                self:showDebugPopName(self.cur_popName, popLayerInfo.bWhite)
                                coroutine.yield()
                            end
                        end

                    end

                end

                local popupExtraFuncList = self.popupExtraFuncList
                for i = #popupExtraFuncList, 1, -1 do
                    local callBackInfo = popupExtraFuncList[i]

                    if not self._bIgnorePopCorEnabled or callBackInfo.bWhite then
                        -- 没有设置 spin后 忽略 弹板 或者 设置了 但是该弹板在白名单里 监测弹板

                        local func = callBackInfo.callBack
                        local param = callBackInfo.param
                        local isSucc = func(param)
                        if isSucc then
                            table.remove(popupExtraFuncList, i)
                            self:showDebugPopName(callBackInfo.popUpName, callBackInfo.bWhite)
                            coroutine.yield()
                        end

                    end

                end
                release_print("check show popUpUI end!!!")
                self.systemUICor = nil
                self.cur_popName = nil
                self:showDebugPopName()
            end
        )
        self:resumeShowSystemUICor()
    elseif self.systemUICor and self.cur_popName then
        print("--------->  关卡弹窗列表在重新spin前没有重置, 中断序列的弹板名称: " .. self.cur_popName)
        util_sendToSplunkMsg("PopErrorInStage", "关卡弹窗列表在重新spin前没有重置, 中断序列的弹板名称: " .. self.cur_popName)
        self.systemUICor = nil
        self.cur_popName = nil
        self:showDebugPopName()
    end
end


function MachineController:resumeShowSystemUICor()
    util_resumeCoroutine(self.systemUICor)
end

function MachineController:clearSystemUICor()
    self.systemUICor = nil
end

function MachineController:popupSpinUpgrade(machine)
    if machine.m_spinIsUpgrade then
        -- max 按钮 特效
        if globalData.userRunData.levelNum <= 25 and not globalData.slotRunData:checkCurBetIsMaxbet() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GUIDE_MAXBET_EFF)
        end

        -- 升级 更新新手任务进度
        local sysNoviceTaskMgr = G_GetMgr(G_REF.SysNoviceTask)
        if sysNoviceTaskMgr and sysNoviceTaskMgr:checkEnabled() then
            sysNoviceTaskMgr:spinUpgradeLv()
        end

        -- spin 升级后 bet值小于指定bet 弹出气泡
        if G_GetMgr(G_REF.BetUpNotice):checkCurSpinBetUpShow() then
            if not globalData.slotRunData:checkCurBetIsMaxbet() then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POPSPECIAL_NEWGUIDE, GUIDE_LEVEL_POP.BetUpNotice)
            end
            G_GetMgr(G_REF.BetUpNotice):setCurSpinBetUpShow(false)
        end

        if globalData.userRunData.levelNum == 2 then
            --B组2级弹
            if not globalData.GameConfig:checkABtestGroupA("NewUser") then
                if not globalData.slotRunData:checkCurBetIsMaxbet() then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POPSPECIAL_NEWGUIDE, GUIDE_LEVEL_POP.MaxBet)
                end
            end
        elseif globalData.userRunData.levelNum == 3 then
            --A组3级弹
            if globalData.GameConfig:checkABtestGroupA("NewUser") then
                if not globalData.slotRunData:checkCurBetIsMaxbet() then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POPSPECIAL_NEWGUIDE, GUIDE_LEVEL_POP.MaxBet)
                end
            end
        elseif globalData.userRunData.levelNum == 9 then
            -- if not globalData.slotRunData:checkCurBetIsMaxbet() then
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POPSPECIAL_NEWGUIDE,GUIDE_LEVEL_POP.AddBet)
            -- end
        elseif globalData.userRunData.levelNum == 8 then
            local isEnterOtherLevel = gLobalDataManager:getNumberByField("NewPlayerUnlockLevelTip_" .. globalData.userRunData.uid, 0)
            if globalData.slotRunData.machineData.p_levelName == "GameScreenCharms" and isEnterOtherLevel ~= 1 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POPSPECIAL_NEWGUIDE, GUIDE_LEVEL_POP.ReturnLobbyForGame)
            end
        end
    end
end

function MachineController:popupSpinBonus(machine)
    --spinBonus 数据
    if globalData.spinBonusData and globalData.spinBonusData:getCanCollect() then
        local spinBonusResult = util_createFindView("Activity/Activity_SpinBonusResult")
        if spinBonusResult ~= nil then
            gLobalSendDataManager:getLogIap():setEnterOpen("autoOpen", "spinOver")
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():addNodeDot(spinBonusResult, "Push", DotUrlType.UrlName, true, DotEntrySite.SpinPush, DotEntryType.Game)
            end
            gLobalViewManager:showUI(spinBonusResult)
            return spinBonusResult
        end
    end
end

function MachineController:popupBonusHunt(machine)
    local bonusHuntData = G_GetActivityDataByRef(ACTIVITY_REF.BonusHunt) or G_GetActivityDataByRef(ACTIVITY_REF.BonusHuntCoin)
    if bonusHuntData then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUSHUNT_UPDATE)
        if bonusHuntData:isShowResult() then
            bonusHuntData.p_spinComplete = false
            local view =
                util_createView(
                "Activity.BonusHuntResultView",
                function()
                    if CardSysManager:needDropCards("Bonus hunt") == true then
                        -- 正常掉落
                        CardSysManager:doDropCards(
                            "Bonus hunt",
                            function()
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                            end
                        )
                    else
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                    end
                end
            )
            gLobalViewManager:showUI(view)
            return view
        end
    end
end

-- 活动解锁
function MachineController:popupActivityUnlock(machine)
    local EntryNodeConfig = util_getRequireFile("baseActivity/ActivityExtra/EntryNodeConfig")
    if not EntryNodeConfig or not EntryNodeConfig.popup_config then
        return
    end

    for activity_type, config in pairs(EntryNodeConfig.popup_config) do
        if gLobalPushViewControl:isActivityUnlock(activity_type) == true then
            if config.levelUp then
                local activity_data = G_GetActivityDataByRef(activity_type)
                local activityUnlockPopView =
                    util_createFindView(config.levelUp, {name = activity_data.pathCsbName, activityId = activity_data.id, clickFlag = activity_data.clickFlag, isLevelUp = true})
                if activityUnlockPopView then
                    gLobalViewManager:showUI(activityUnlockPopView, ViewZorder.ZORDER_GAMEPOP)
                    -- 这个同时只会弹出一个 所以找到就跳出了
                    return activityUnlockPopView
                end
            else
                assert(false, "---------------> " .. activity_type .. " 活动解锁弹板没配置 去EntryNodeConfig文件配置一下levelUp字段")
            end
        end
    end
end

-- 活动收集
function MachineController:popupCollect(machine)
    local EntryNodeConfig = util_getRequireFile("baseActivity/ActivityExtra/EntryNodeConfig")
    if not EntryNodeConfig or not EntryNodeConfig.popup_config then
        return
    end

    for activity_type, config in pairs(EntryNodeConfig.popup_config) do
        if config.collect then
            local activity_data = G_GetActivityDataByRef(activity_type)
            if activity_data and activity_data:isRunning() and activity_data.state_popupInStage_ShowCollect == true and activity_data.popupInStage_willShowCollect then
                -- 新手blast 特殊处理
                if activity_type == ACTIVITY_REF.Blast and activity_data:getNewUser() then

                    local curLevel = globalData.userRunData.levelNum
                    local lockLevel = globalData.constantData.NOVICE_BLAST_COLLECT_LAYER_LV or 0
                    if curLevel < lockLevel then
                        -- 新手blat50级前不弹  收集弹板
                        return
                    end
                    
                end

                local lua_file = config.collect.lua_file
                if not lua_file then
                    util_sendToSplunkMsg("MachineController", "collect activity_type = " .. activity_type)
                    return
                end

                local activityCollectPopView = util_createFindView(lua_file, activity_type, true)
                if not tolua.isnull(activityCollectPopView) then
                    activity_data.popupInStage_willShowCollect = false
                    gLobalViewManager:showUI(activityCollectPopView, ViewZorder.ZORDER_GAMEPOP)
                    -- 这个同时只会弹出一个 所以找到就跳出了
                    return activityCollectPopView
                end
            end
        end
    end
end

-- 活动集满
function MachineController:popupCollectMax(machine)
    local EntryNodeConfig = util_getRequireFile("baseActivity/ActivityExtra/EntryNodeConfig")
    if not EntryNodeConfig or not EntryNodeConfig.popup_config then
        return
    end

    for activity_type, config in pairs(EntryNodeConfig.popup_config) do
        if config.collect_max then
            local activity_data = G_GetActivityDataByRef(activity_type)
            if activity_data and activity_data:isRunning() and activity_data.state_popupInStage_ShowMax == EntryNodeConfig.COLLECT_MAX_STATE.ON_SHOW and activity_data.popupInStage_willShowMax then
                local lua_file = config.collect_max.lua_file
                if not lua_file then
                    util_sendToSplunkMsg("MachineController", "activity_type = " .. activity_type)
                    return
                end
                local activityCollectMaxPopView = util_createFindView(lua_file, activity_type, true)
                if not tolua.isnull(activityCollectMaxPopView) then
                    activity_data.state_popupInStage_ShowMax = EntryNodeConfig.COLLECT_MAX_STATE.SHOW_OVER
                    activity_data.popupInStage_willShowMax = false
                    gLobalViewManager:showUI(activityCollectMaxPopView, ViewZorder.ZORDER_GAMEPOP)
                    -- 这个同时只会弹出一个 所以找到就跳出了
                    return activityCollectMaxPopView
                end
            end
        end
    end
end

-- 气球收集
function MachineController:popupBalloonRush(machine)
    local EntryNodeConfig = util_getRequireFile("baseActivity/ActivityExtra/EntryNodeConfig")
    if not EntryNodeConfig or not EntryNodeConfig.popup_config then
        return
    end

    local act_data = G_GetMgr(ACTIVITY_REF.BalloonRush):getRunningData()
    if act_data and act_data:isRunning() and act_data.state_popupInStage_ShowCollect == true and act_data.popupInStage_willShowCollect then
        local mainUI = G_GetMgr(ACTIVITY_REF.BalloonRush):getMainLayer()
        if not tolua.isnull(mainUI) then
            act_data.popupInStage_willShowCollect = false
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_GAMEPOP)
            if G_GetMgr(ACTIVITY_REF.BalloonRush):isCanCollect() then
                G_GetMgr(ACTIVITY_REF.BalloonRush):collectRewards(false)
            end
            -- 这个同时只会弹出一个 所以找到就跳出了
            return mainUI
        end
    end
end

--充值抽奖任务完成弹窗
function MachineController:luckyChipsDrawShowTick(machine)
    local mgr = G_GetMgr(ACTIVITY_REF.LuckyChipsDraw)
    local drawData = mgr:getRunningData()
    if drawData and drawData.m_drawTaskData then
        local taskData = drawData.m_drawTaskData
        if taskData.m_tickNum and taskData.m_tickNum > 0 then
            local tickNum = taskData.m_tickNum

            local cfg = mgr:getConfig()
            if cfg then
                local isSuc =
                    mgr:showLuckyChipsDrawDialog(
                    "LuckyChipsDrawReward",
                    cfg.csbPath .. "LuckChipsDrawBuy.csb",
                    true,
                    function(name)
                        if name and name == "btn_open" then
                            gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "LuckyChipsDrawEntryNode")
                            gLobalActivityManager:showActivityMainView("Activity_LuckyChipsDraw", "LuckyChipsDrawMainUI")
                        else
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                        end
                    end,
                    {
                        m_lb_num = string.format("+%d TICKETS", tickNum)
                    }
                )
                if isSuc then
                    taskData.m_tickNum = 0
                    return true
                end
            end
        end
    end
end

function MachineController:checkHotTodayView()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local nowTb = {}
    nowTb.year = tonumber(os.date("%Y", curTime))
    nowTb.month = tonumber(os.date("%m", curTime))
    nowTb.day = tonumber(os.date("%d", curTime))

    local key = "Hot_Today_" .. nowTb.year .. nowTb.month .. nowTb.day
    local curShowTime = gLobalDataManager:getNumberByField(key, 0)
    if curShowTime < 1 then
        self.m_isShowHotToday = true
        gLobalDataManager:setNumberByField(key, 1)
        return true
    end
    self.m_isShowHotToday = true
    return false
end

function MachineController:checkTryPayView()
    --非大弹版不弹
    if globalData.userRunData.levelNum % 5 ~= 0 then
        return
    end

    if not self.m_triggerFlationLevel then --检测是否膨胀
        return false
    end
    self.m_triggerFlationLevel = false
    if not globalData.constantData or not globalData.constantData.TEST_PAY_LEVEL or globalData.userRunData.levelNum < globalData.constantData.TEST_PAY_LEVEL then --等级不足
        return false
    end
    if not globalData.saleRunData:getAttemptData() then --已经购买过
        return false
    end
    if self.m_isShowFlationLevel then --首次膨胀已经展示过了
        if globalData.saleRunData.p_onceBuyAttemps then -- 首次膨胀之后付过费 不弹
            return false
        end
    else
        local showState = gLobalDataManager:getNumberByField("TryPay_FlationLevel_Show", 0)
        if showState == 0 then
            self.m_isShowFlationLevel = true
            gLobalDataManager:setNumberByField("TryPay_FlationLevel_Show", 1)
        else
            if globalData.saleRunData.p_onceBuyAttemps then -- 首次膨胀之后付过费 不弹
                return false
            end
        end
    end

    return true
end

function MachineController:popupHotToday(machine)
    local function showHotToday()
        if not self.m_isShowHotToday and machine.m_totalEndUpGrade and globalData.userRunData.levelNum % 5 == 0 then --hottoday  每次 每次升级时候 弹一次窗
            local temp = globalData.GameConfig:getHotTodayConfigs()
            if temp and self:checkHotTodayView() then
                gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "HotToday")
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ONLY_OPEN_POPUP_VIEW, temp)
            end
        end
        self.m_totalEndUpGrade = nil
    end
    if self:checkTryPayView() then
        local view =
            util_createView(
            "views.TryPay.TryPayView",
            function()
                -- showHotToday()
            end
        )
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(view, "Push", DotUrlType.UrlName, true, DotEntrySite.SpinPush, DotEntryType.Game)
        end
        gLobalViewManager:showUI(view)
    else
        -- showHotToday()
    end
end
--repart活动刷新奖池提示
function MachineController:repartUpdatePrizeTips(machine)
    --jackpot刷新提示
    local repartJackpotData = G_GetMgr(ACTIVITY_REF.RepartJackpot):getRunningData()
    if repartJackpotData and repartJackpotData:isRunning() and repartJackpotData:isUpdatePrizeTips() then
        repartJackpotData:clearPrizeTips()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_REPART_PRIZE, ACTIVITY_REF.RepartJackpot)
    end
    --freespin刷新提示
    local repeatFreeSpinData = G_GetMgr(ACTIVITY_REF.RepeatFreeSpin):getRunningData()
    if repeatFreeSpinData and repeatFreeSpinData:isRunning() and repeatFreeSpinData:isUpdatePrizeTips() then
        repeatFreeSpinData:clearPrizeTips()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_REPART_PRIZE, ACTIVITY_REF.RepeatFreeSpin)
    end
end

function MachineController:popupJackpotPush(machine)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_JACKPOT_PUSH)
end

function MachineController:popupGameEffectOver(machine)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAMEEFFECT_OVER)
end

function MachineController:showLevelDashView(half)
    self:pushPopupExtraFunc(
        "showLevelDashView",
        function(half)
            local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
            if levelDashData ~= nil and levelDashData:getIsExist() == true and levelDashData:getIsOpen() then
                gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "levelDash")
                local view = util_createFindView("Activity/LevelDashSrc/Activity_LevelDashLayer", half)
                if view ~= nil then
                    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                    return true
                end
            end
        end,
        half
    )
end

function MachineController:checkNewPassUpdateConfig()
    if G_GetMgr(ACTIVITY_REF.NewPass):isCanShowLayer() then
        if G_GetMgr(ACTIVITY_REF.NewPass):checkToUpdatePassConfig() then
            gLobalDailyTaskManager:updateConfig()
        end
    end
end

function MachineController:popupLeagueMainUI(machine)
    -- 先检测有没有飞奖杯
    local mgr = G_GetMgr(ACTIVITY_REF.League)
    if mgr:isCanShowLayer() and mgr:isFirstInRank() then
        local showViewCb = function()
            -- 不飞奖杯 直接弹板   优先 弹 开启弹板
            local view = mgr:onShowOpenLayer()
            if not view then
                view = mgr:showMainLayer()
            end
            return view
        end
        local cb = function()
            local view = showViewCb()
            if not view then
                -- 没弹板  恢复协程
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end
            return view
        end

        if mgr:checkToDayFirstLevelUp() then
            -- 第一次 开启活动不飞 奖杯了
            return showViewCb()
        end

        local bFly = mgr:onShowGainCup(cb)
        if not bFly then
            local view = showViewCb()
            bFly = view
        end
        
        return bFly
    end
end

-- spin 完成之后最后调用
function MachineController:popupLevelUpPlayAds(machine)
    -- if globalData.userRunData.levelNum % 5 == 0 and machine.m_spinIsUpgrade == true then
    --     -- 播放插屏广告
    --     if globalData.adsRunData:isPlayAutoForPos(PushViewPosType.LevelUp) then
    --         gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.LevelUp)
    --         gLobalAdsControl:playAutoAds(PushViewPosType.LevelUp)
    --     end
    -- end
end

-- 新关挑战弹窗
-- function MachineController:popupSlotChallenge(machine)
--     local SlotChallengeManager = G_GetMgr(ACTIVITY_REF.SlotChallenge)
--     local canCollect = nil
--     if SlotChallengeManager.checkAnyTaskCompleted and SlotChallengeManager:checkAnyTaskCompleted() then
--         if gLobalActivityManager and gLobalActivityManager.checktActivityOpen and gLobalActivityManager:checktActivityOpen(ACTIVITY_REF.SlotChallenge) then
--             canCollect = true
--         end
--     end
--     if canCollect then
--         SlotChallengeManager:showMainLayer()
--         return true
--     end
-- end

-- 新版新关挑战弹窗
function MachineController:popupSlotTrials()
    local act_data = G_GetMgr(ACTIVITY_REF.SlotTrial):getRunningData()
    if not act_data then
        return
    end
    local id_list = act_data:getStageList()
    if id_list and #id_list <= 0 then
        return
    end
    local id_exit = false
    local level_id = globalData.slotRunData.machineData.p_id
    for i, id in ipairs(id_list) do
        if tonumber(level_id) == tonumber(id) then
            id_exit = true
            break
        end
    end
    if not id_exit then
        return
    end

    local taskId = act_data:getCompleteTaskId()
    if act_data:getWillPlayAnimation() and taskId and taskId > 0 then
        local mainUI = G_GetMgr(ACTIVITY_REF.SlotTrial):showMainLayer()
        if mainUI then
            return mainUI
        end
    end
end

-- 高倍场体验卡面板
function MachineController:popupDeluxeExCardLayer(machine)
    -- csc 修改高倍场体验卡 弹出调用判断
    if globalDeluxeManager:checkPopExperienceCard() then
        local result = globalDeluxeManager:popExperienceLayer()
        if result then
            return result
        end
    end
end

-- levelRush游戏 up 提示面板
function MachineController:popupLevelRushTrigger(machine)
    -- if not machine.m_spinIsUpgrade then
    --     return
    -- end
    if globalData.slotRunData:isDIY() or globalData.slotRunData:isMasterStamp() then
        return nil
    end

    if gLobalLevelRushManager:checkLevelRushTrigger(machine.m_spinIsUpgrade) then
        local activityData = gLobalLevelRushManager:getLevelRushData()
        if not activityData then
            return
        end
        local bHalf = globalData.userRunData.levelNum == activityData:getMidlleLevel()
        if globalData.GameConfig:checkUseNewNoviceFeatures() then
            -- cxc 2021年06月25日11:45:42  有新手期功能 LevelRush阶段奖励 到达阶段就弹出
            -- 没有 就执行之前的逻辑 (开启 和 half 时才 弹出)
            bHalf = false
        end

        local view = gLobalLevelRushManager:pubShowUpView(bHalf, nil, true, globalData.userRunData.levelNum == activityData:getStartLevel(), true)
        if not tolua.isnull(view) then
            return view
        end
    end
end

--levelrushlink小游戏
function MachineController:popupLevelRushEnterGame(machine)
    if not machine.m_spinIsUpgrade then
        return
    end

    if gLobalLevelRushManager:checkLevelRushEnterGame() then
        local bl_success = gLobalLevelRushManager:pubShowGameStartView()
            if bl_success then
                return true
            end
    end
end

-- RippleDash 活动(LevelRush挑战活动)
function MachineController:popupRippleDashLayer(machine)
    --cxc 2021-07-01 15:39:52 不检测升级了 (弹板 改为 进到关卡第一次spin也检测)
    -- if not machine.m_spinIsUpgrade then
    --     return
    -- end

    -- local ActivityRippleDashManager = util_require("activities.Activity_RippleDash.controller.ActivityRippleDashManager"):getInstance()
    local mgr = G_GetMgr(ACTIVITY_REF.RippleDash)
    if mgr and mgr:checkUpatePhase(machine.m_spinIsUpgrade) then
        local view = mgr:popUpMainLayer(nil, {isAutoClose = true})
        if view then
            return view
        end
    end
end

-- 公会 点数 宝箱奖励阶段升级 了
function MachineController:popupClanBoxLvUp()
    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    if ClanManager:checkRewardBoxPop() then
        ClanManager:showRewardBoxPop()
        return true
    end
end

-- 自动收集每日任务
function MachineController:popupAutoCollectMission(machine)
    --spinBonus 数据
    if gLobalDailyTaskManager:getAutoColectFlag() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_AUTOCOLLECT_MSG)
        return true
    end
end

-- 播放effect标志
function MachineController:getEffectPlayStates()
    return self.m_isEffectPlaying
end

function MachineController:popupLeagueScoreCollect(machine)
    if G_GetMgr(ACTIVITY_REF.HolidayChallenge):getLeaguesCollectStatus() then
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):setLeaguesCollectStatus(false)
        -- LEAGUES 任务先废弃 保证 MegaWin  EpicWin  后面再去优化
        local hasFinishTask = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasTaskCompletedByType(G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.MegaWin)
        local taskType = G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.MegaWin
        if not hasFinishTask then
            hasFinishTask = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasTaskCompletedByType(G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.EpicWin)
            if hasFinishTask then
                taskType = G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.EpicWin
            end
        end
        if hasFinishTask then
            local view =
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):chooseCreatePopLayer(
                taskType,
                function()
                    -- 下一帧执行
                    performWithDelay(
                        display:getRunningScene(),
                        function()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                        end,
                        0
                    )
                end,
                {isAutoClose = true}
            )
            if not tolua.isnull(view) then
                return view
            end
        end
    end
end


function MachineController:popupChaseForChips()
    -- 原来是完成任务弹，现在改成完成一个收集再弹 2024-01-10-zzy
    -- if G_GetMgr(ACTIVITY_REF.ChaseForChips):isNewFinishTaskBySpin() then
    --     G_GetMgr(ACTIVITY_REF.ChaseForChips):setNewFinishTaskBySpin(false)
    if G_GetMgr(ACTIVITY_REF.ChaseForChips):isNewFinishCollectCollectBySpin() then
        G_GetMgr(ACTIVITY_REF.ChaseForChips):setNewFinishCollectCollectBySpin(false)
        -- 因为任务都是集卡相关的，需要手动拉取数据
        -- spin触发，打开界面需要拉最新的数据
        G_GetMgr(ACTIVITY_REF.ChaseForChips):enterChaseFroChips(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end,
            2
        )
        return true
    end
end

function MachineController:popupAttGotoSettingLayer()
    if device.platform == "ios" or device.platform == "mac" then
        if globalData.userRunData.levelNum == 28 and gLobalAdsControl:getCheckATTFlag("setting", "1.5.9") then
            -- 需要直接获取一下当前用户的att 授权状态 (防止用户是 2 < x < 8级区间更新的用户)
            release_print("----csc popupAttGotoSettingLayer checkATTrackingStatus")

            if util_isSupportVersion("1.6.4") then
                --新的逻辑 区分当前是要弹哪个界面
                if gLobalAdsControl:isAgainRequestATTracking() then
                    gLobalAdsControl:createATTLayer("levelup")
                else
                    gLobalAdsControl:createATTLayer("setting")
                end
                return true
            else
                globalPlatformManager:checkATTrackingStatus(
                    function(status)
                        if status == "true" then
                            -- 记录当前ATT 弹板已经不用再弹出了
                            gLobalDataManager:setBoolByField("checkATTrackingOver", true)
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                        elseif status == "false" or status == nil then
                            gLobalAdsControl:createATTLayer("setting")
                        end
                    end
                )
                return true
            end
        end
    end
end
-- FB 粉丝页
function MachineController:popupFBGroup()
    if gLobalSendDataManager:getIsFbLogin() == false then
        local FBSignRewardManager = util_require("manager.System.FBSignRewardManager")
        if FBSignRewardManager then
            FBSignRewardManager:getInstance():openGroupView()
        end
    end
end

function MachineController:popupNewQuestOpenLayer()
    if globalNoviceGuideManager:getNewBieTeskReachLevelFlag() then
        -- 添加遮罩
        gLobalViewManager:addLoadingAnima(true)
        -- 暂停轮盘
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
        return true
    end
end

-- 弹出WILD CHALLENGE付费挑战 弹板
function MachineController:popupWildChallengeMainLayer()
    -- print("MachineController:popupWildChallengeMainLayer")
    if not G_GetMgr(ACTIVITY_REF.WildChallenge):checkUncollectedTask() then
        return
    end

    -- 策划反馈 spin 每日任务自动领奖的同时弹了个 wc 弹板， 客户端未复现未查到 先打个补丁
    if gLobalViewManager:getViewLayer():getChildByName("DailyMissionMainLayer") or
    gLobalViewManager:getViewLayer():getChildByName("DailyMissionPassMainLayer") then
        return
    end

    local view = G_GetMgr(ACTIVITY_REF.WildChallenge):showMainLayer()
    if view then
        return view
    end
end

-- 弹出头像框奖励 弹板
function MachineController:popupAvatarFrameRewardLayer()
    if not G_GetMgr(G_REF.AvatarFrame):checkCurTaskComplete() then
        return
    end
    local view = G_GetMgr(G_REF.AvatarFrame):showRewardLayer()
    if view then
        return view
    end
end

-- 弹出头像框挑战 弹板
function MachineController:popupAvatarFrameChallengeLayer()
    if not G_GetMgr(ACTIVITY_REF.FrameChallenge):isShowPrizeLayer() then
        return
    end
    local view = G_GetMgr(ACTIVITY_REF.FrameChallenge):showPrizeLayer()
    if view then
        return view
    end
end

-- questdone 弹板 放到最后一个
function MachineController:popupQuestTaskDoneView()
    local questMgr = G_GetMgr(ACTIVITY_REF.Quest)
    if questMgr and questMgr:isTaskDone() then -- (not questMgr:isNewUserQuest()) and
        -- 普通Quest完成
        local view = questMgr:showTaskDoneView()
        if view then
            return view
        end
    end
    local questNewMgr = G_GetMgr(ACTIVITY_REF.QuestNew)
    if questNewMgr and questNewMgr:getIsShowTaskDoneTip() then
        questNewMgr:setIsShowTaskDoneTip(false)
        local view = questNewMgr:showTaskDoneView()
        if view then
            return view
        end
    end
end

function MachineController:popupQuestEnded()
    if not G_GetMgr(ACTIVITY_REF.Quest):willShowEnded() then
        return
    end

    local view =
        gLobalViewManager:showDialog(
        "Dialog/QuestEnd.csb",
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            if globalData.userRunData:isEnterUpdateFormLevelToLobby() then
                -- 跨天走重登
                globalData.userRunData:saveLeveToLobbyRestartInfo()
                if globalData.slotRunData.isPortrait == true then
                    globalData.slotRunData.isChangeScreenOrientation = true
                    globalData.slotRunData:changeScreenOrientation(false)
                end
        
                util_restartGame()
            else
                gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
            end
        end
    )
    if view then
        return view
    end
end

function MachineController:checkLevelDashPlus()
    if not G_GetMgr(ACTIVITY_REF.LevelDashPlus):canShowMissionRushTip() then
        return
    end

    local view = G_GetMgr(ACTIVITY_REF.LevelDashPlus):showMissionRushTip({isAutoClose = true})

    if view then
        return view
    end
end

function MachineController:missionRushTip()
    if not G_GetMgr(ACTIVITY_REF.ActivityMissionRushNew):canShowMissionRushTip() then
        return
    end
    local view = G_GetMgr(ACTIVITY_REF.ActivityMissionRushNew):showMissionRushTip({isAutoClose = true})
    if view then
        return view
    end
end

--检测bigwin奖励
function MachineController:bigWinChallengeTip(machine)
    if not G_GetMgr(ACTIVITY_REF.BigWin_Challenge):canShowBigWinTip() then
        return
    end
    local view = G_GetMgr(ACTIVITY_REF.BigWin_Challenge):showBigWinTip()
    if view then
        return view
    end
end

-- zombie
function MachineController:configPushZomReward()
    local gameData = G_GetMgr(ACTIVITY_REF.Zombie):getRunningData()
    if not gameData then
        return
    end
    local status = G_GetMgr(ACTIVITY_REF.Zombie):checkZombieLogin(1)
    if status then
        return true
    end
end

function MachineController:checkPickTaskComplete()
    local  flag = G_GetMgr(ACTIVITY_REF.PickTask):checkShowComplete()
    if flag then
        return true
    end
end

function MachineController:checkReturnSpinTaskComplete()
    local data = G_GetMgr(G_REF.Return):getRunningData()
    if data then
        local isComplete = false
        local autoList = {}
        local taskPageIndex = 1
        local spinCompleteIndexs = data:getSpinTaskComplete()
        if spinCompleteIndexs and #spinCompleteIndexs > 0 then
            autoList.autoTaskSpin = spinCompleteIndexs
            isComplete = true
            taskPageIndex = 2
        end
        local questCompleteIndexs = data:getQuestTaskComplete()
        if questCompleteIndexs and #questCompleteIndexs > 0 then
            autoList.autoTaskQuest = questCompleteIndexs
            isComplete = true
            -- 如果没有spin完成
            if taskPageIndex == 1 then
                taskPageIndex = 3
            end
        end

        -- 如果后续有quest完成弹框，回归界面中就不能跳转到Quest
        local noOpenQuest = false
        if G_GetMgr(ACTIVITY_REF.Quest):isTaskDone() or G_GetMgr(ACTIVITY_REF.QuestNew):getIsShowTaskDoneTip() then
            noOpenQuest = true
        end

        if isComplete then
            local view = G_GetMgr(G_REF.Return):showMainLayer(
                3,
                taskPageIndex,
                autoList,
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                end,
                noOpenQuest
            )
            if view then
                return true
            end
        end
    end
    return false
end

-- 比赛聚合弹窗
function MachineController:popupBattleMatch(machine)
    local canCollect = G_GetMgr(ACTIVITY_REF.BattleMatch):doCheckShowActivityLayer(nil, false)
    if canCollect then
        return true
    end
end

-- 新版破冰促销
function MachineController:popupIcebreakerSale(_machine)
    if not _machine.m_spinIsUpgrade then
        return
    end

    -- 40级关闭升级领奖弹板后弹出
    if globalData.userRunData.levelNum ~= 40 then
        return
    end

    local view = G_GetMgr(G_REF.IcebreakerSale):checkPopMainUI("Game")
    if view then
        return view
    end
end

function MachineController:popupHourDealMainLayer()
    local view = G_GetMgr(G_REF.HourDeal):checkHourDealOpen()
    if view then
        return view
    end
end

function MachineController:popupTimeBackMainLayer()
    local view = G_GetMgr(ACTIVITY_REF.TimeBack):checkActivityPopup()
    if view then
        return view
    end
end

-- Minz主界面
function MachineController:popupMinzMainLayer()
    local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    if minzMgr then
        local isPopMainLayer = minzMgr:isPopMainLayer()
        if isPopMainLayer then
            local view = minzMgr:showMainLayer()
            if view then
                return view
            end
        end
    end
end

-- Minz第一次进入掉落minz道具关卡界面
function MachineController:popupMinzFirstLayer()
    local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    if minzMgr then
        local view = minzMgr:popupMinzFirstLayer()
        if view then
            return view
        end
    end
end

function MachineController:popupGemChallengeLayer()
    local view = G_GetMgr(ACTIVITY_REF.GemChallenge):checkMainLayerOpen()
    if view then
        return view
    end
end

function MachineController:popupLevelUpPassLayer()
    if globalData.slotRunData:isDIY() or globalData.slotRunData:isMasterStamp() then
        return nil
    end

    local view = G_GetMgr(ACTIVITY_REF.LevelUpPass):checkMainLayerOpen()
    if view then
        return view
    end
end

function MachineController:popupDragonChallengeGetWheelLayer()
    local view = G_GetMgr(ACTIVITY_REF.DragonChallenge):checkIsGetWheel()
    if view then
        return view
    end
end

function MachineController:popupDragonChallengeBoxRewardLayer()
    local view = G_GetMgr(ACTIVITY_REF.DragonChallenge):checkHasBoxReward()
    if view then
        return view
    end
end

-- 检查flamingo jackpot引导
function MachineController:checkFlamingoJackpotGuide()
    local function callback()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
    end
    if G_GetMgr(ACTIVITY_REF.FlamingoJackpot):checkGuide() then
        G_GetMgr(ACTIVITY_REF.FlamingoJackpot):startGuide(callback)
        return true
    end
end

-- 每天首次进入关卡，弹出参与弹版和二次确认弹版
function MachineController:popFlamingoJackpotDayFirst()
    local function callback()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)        
    end
    local view = G_GetMgr(ACTIVITY_REF.FlamingoJackpot):showDayFirstLayer(callback)
    if not tolua.isnull(view) then
        return view
    end
end

-- spin后触发flamingo jackpot逻辑
function MachineController:checkActiveFlamingoJackpot()
    local function callback()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)        
    end
    if G_GetMgr(ACTIVITY_REF.FlamingoJackpot):checkSpin() then
        G_GetMgr(ACTIVITY_REF.FlamingoJackpot):startSpinAction(callback)
        return true
    end
end

-- 限时膨胀 任务完成
function MachineController:popupTimeLimitExpansion()
    local isComplete = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion):checkIsCompleteActiveTask()
    if isComplete then
        local view = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion):showMainLayer()
        if view then
            return view
        end
    end
end

-- 普通集卡 18级解锁宣传弹板
function MachineController:cardOpenNoticeLayer(_machine)
    if globalData.constantData.NOVICE_NEW_USER_CARD_OPEN or not _machine.m_spinIsUpgrade then
        return
    end
    local openLv = globalData.constantData.CARD_OPEN_LEVEL or 18
    if globalData.userRunData.levelNum < openLv then
        return
    end

    -- 18级解锁宣传弹板
    if globalData.userRunData.levelNum == openLv then
        gLobalDataManager:setBoolByField("CardGuideFirstClanClickEnabled", true)
        gLobalDataManager:setBoolByField("CardGuideFirstClanUDoneCheckEnabled", true)
        gLobalDataManager:setBoolByField("PopNormalCardOpenNoticeEnabled", true)

        local albumId = CardSysRuntimeMgr:getCurAlbumID()
        if not albumId then
            return false
        end
        local tExtraInfo = {["year"] = CardSysRuntimeMgr:getCurrentYear(), ["albumId"] = albumId}
        CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo, function()
            CardSysManager:checkPopNormalOpenNoticeLayer(true)
        end, function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)        
        end)
        return true
    else
        local view = CardSysManager:checkPopNormalOpenNoticeLayer()
        return view
    end
end

-- 等级里程碑
function MachineController:popupLevelRoadMainLayer()
    local isHasReward = G_GetMgr(G_REF.LevelRoad):checkIsCanCollect()
    if isHasReward then
        local view = G_GetMgr(G_REF.LevelRoad):showMainLayer()
        if view then
            view:setOverFunc(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                end
            )
            return view
        end
    end
end
-- 持有金币判断
function MachineController:popMinBetNoCoinsLayer()
    local curCoinsNum = globalData.userRunData.coinNum
    local lackNum = toLongNumber(globalData.constantData.CoinLackNum or 0)
    if (curCoinsNum < lackNum) and globalData.userRunData.levelNum > 1 then
        -- 显示领奖界面
        local _view = util_createView("views.dialogs.LackCoinsLayer")
        if _view then
            _view:setOverFunc(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                end
            )
            gLobalViewManager:showUI(_view, ViewZorder.ZORDER_POPUI)
        end
        return _view
    end
    return nil
end

-- 新手3日任务奖励 有可领取的 弹主界面
function MachineController:popColNoviceTrail()
    local gameData = G_GetMgr(ACTIVITY_REF.NoviceTrail):getRunningData()
    local view
    if gameData and gameData:getCanColCount() > 0 then
        local curSpinDoneTaskData =  gameData:getCurSpinDoneTaskData()
        if not curSpinDoneTaskData then
            -- 本次spin 没有新完成的任务
            return
        end

        view = G_GetMgr(ACTIVITY_REF.NoviceTrail):showPopLayer(nil, function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        end)
    end
   
    return view
end

-- 1v1 比赛 可领取奖励
function MachineController:popColFrostFlameClash()
    local isExecute = false
    local gameData = G_GetMgr(ACTIVITY_REF.FrostFlameClash):getRunningData()
    if gameData and gameData:isWillShowResultLayer() then
        local view = G_GetMgr(ACTIVITY_REF.FrostFlameClash):showBattleResultLayer()
        if view then
            local cb = function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end
            view:setOverFunc(cb)
        end
        isExecute = view ~= nil
    end
    return isExecute
end

-- 开启单人限时比赛活动
function MachineController:popupLuckyRaceOpenLayer()
    local data = G_GetMgr(ACTIVITY_REF.LuckyRace):getRunningData()
    if not data then
        return
    end

    -- spin 后 本轮可玩再检测 弹
    local bCurRoundCanPlay = data:checkCurRoundCanPlay()
    if not bCurRoundCanPlay then
        return
    end

    local isShow = G_GetMgr(ACTIVITY_REF.LuckyRace):showOpenLayer()
    if isShow then
        return true
    end
end

function MachineController:popupLuckyRaceMainLayer()
    local isShow = G_GetMgr(ACTIVITY_REF.LuckyRace):checkOnShowMainLayer()
    if isShow then
        return true
    end
end

-- 次日礼物主界面 4级功能开启弹主界面
function MachineController:popTomorrowGiftMainLayer(_machine)
    if not _machine.m_spinIsUpgrade then
        return
    end

    local mgr = G_GetMgr(G_REF.TomorrowGift)
    if mgr and mgr:checkCanPopOpenLayer() then
        local view = mgr:showMainLayer()
        return view
    end
end

-- 大R高性价比礼包促销
function MachineController:popupSuperValueSaleLayer()
    local view = G_GetMgr(ACTIVITY_REF.SuperValue):showMainLayer(true)
    if view then
        return view
    end
end

-- diy 关卡内首次参与 或者 二次确认 弹板
function MachineController:popupDiyFeaturesTakePartInLayer()
    local view = G_GetMgr(ACTIVITY_REF.DiyFeature):checkShowTakePartInLayer()
    if view then
        return view
    end
end

-- 大赢宝箱
function MachineController:popupMegaWinFirstOpenInfoLayer()
    local view = G_GetMgr(ACTIVITY_REF.MegaWinParty):checkShowFirstOpenInfoLayer()
    if view then
        return view
    end
end

--  diy 活动主界面SPIN次数消耗完毕后，第一次返回关卡时弹出促销主界面 (关闭主界面大厅跳转到关卡，监测下)
function MachineController:popupDiyFeaturesSaleLayer()
    local mgr = G_GetMgr(ACTIVITY_REF.DiyFeature)
    local bCheck = mgr:getNeedcheckMLayerClosePopSaleLayer()
    if not bCheck then
        return
    end

    mgr:setNeedcheckMLayerClosePopSaleLayer(false)
    local bCanPop = mgr:checkMLayerClosePopSaleLayer()
    if not bCanPop then
        return
    end

    local salemgr = G_GetMgr(ACTIVITY_REF.DiyFeatureNormalSale)
    local view = salemgr:showMainLayer()
    if view then
        view:setOverFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end
        )
    end

    return view
end

-- 亿万赢钱挑战 可领奖
function MachineController:popTrillionChallengeTask()
    if not G_GetMgr(G_REF.TrillionChallenge):checkCanAutoPopMaiLayer() then
        return 
    end

    local view = G_GetMgr(G_REF.TrillionChallenge):showMainLayer()
    if view then
        local cb = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        end
        view:setOverFunc(cb)
    end
    return view ~= nil
end

function MachineController:popHolidayPassProcessLayer()
    local _overcall = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
    end
    local view = G_GetMgr(ACTIVITY_REF.HolidayPass):showProgressLayer({isAutoClose = true, overFunc = _overcall})
    return view ~= nil
end

-- 弹出Wanted领奖界面
function MachineController:popWantedMainLayer(_machine)
    if not G_GetMgr(ACTIVITY_REF.Wanted):checkCanAutoPopMaiLayer() then
        return 
    end

    local view = G_GetMgr(ACTIVITY_REF.Wanted):showMainLayer()
    if view then
        local cb = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        end
        view:setOverFunc(cb)
    end
    return view ~= nil
end

return MachineController

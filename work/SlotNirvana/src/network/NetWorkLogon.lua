---
-- 处理Logon 消息
--
-- FIX IOS 139
local LoginMgr = require("GameLogin.LoginMgr")
local NetWorkLogon = class("NetWorkLogon", require "network.NetWorkBase")
NetWorkLogon.m_bLogin = nil
NetWorkLogon.m_fbLoginPos = nil
function NetWorkLogon:ctor()
    -- 玩家默认的 头像列表
    self.m_defaultHeadNameList = {1, 20, 21, 22, 23}
    -- 为不影响线上玩家 增加的判断默认头像时间 (注册事件大于 该时间的 再做判断)
    -- 1623945599000   2021-06-17 23:59:59  单位ms
    self.m_tempRegisterTime = 1623945599000
end

---
--查询服务器时间
--
function NetWorkLogon:requestServerTime(funcSuccess, funcFaild)
    if self.m_bLogin then
        self:updatePlatFormType()
        local request = ExtendProto_pb.GetSysTimeRequest()
        request.udid = globalData.userRunData.userUdid
        request.platform = self.PlatFormType
        request.clientVersion = tostring(util_getUpdateVersionCode(false))
        request.versionCode = tostring(self:getVersionNum())

        local bodyData = request:SerializeToString()

        local httpSender = xcyy.HttpSender:createSender()

        local url = DATA_SEND_URL .. RUI_INFO.SERVER_TIME -- 拼接url 地址
        local success_call_fun = function(responseTable)
            local sysTimeReq = ExtendProto_pb.GetSysTimeResponse()
            local responseStr = self:parseResponseData(responseTable)

            sysTimeReq:ParseFromString(responseStr)
            if sysTimeReq.time ~= nil then
                globalData.userRunData:syncServerTime(tonumber(sysTimeReq.time))
                if funcSuccess then
                    funcSuccess()
                end
            else
                if funcFaild then
                    funcFaild()
                end
            end

            httpSender:release()
        end

        local faild_call_fun = function(errorCode, errorData)
            if funcFaild then
                funcFaild()
            end
            -- 根据errorCode 做处理
            httpSender:release()
        end

        local offset = self:getOffsetValue()
        local token = globalData.userRunData.loginUserData.token
        local serverTime = globalData.userRunData.p_serverTime
        -- httpSender:sendMessage(bodyData,offset,token,url,serverTime,success_call_fun,faild_call_fun)
        httpSender:sendLoginMessage(bodyData, url, serverTime, success_call_fun, faild_call_fun)
    end
end

--服务器额外存储信息 需要根据自定义字段取出
function NetWorkLogon:saveExtraData()
    --初始化数据
    local dailyBonusDays = 0
    local dailyTime = ""
    local bindingFb = false

    local pigLevel = 1
    local pigBuyTimes = 0
    local spinAccumulation = nil
    local taskTime = 0
    local taskInfo = nil
    local rewardTime = 0
    local rewardCount = 0
    local rewardID = 0
    local purchaseSome = false
    local headIdx = util_random(1, 10)
    local operaId = {}
    local questData = nil
    local tasksDailyData = nil
    local tasksDailyTime = 0
    local tasksCollectPoints = 0
    local tasksCollectstate = {0, 0}
    local averageBet = {}
    local shopRewardTime = 0
    local shopLevelBurstEndTime = 0
    local shopCoinsBurstEndTime = 0
    local shopDoubleBurstEndTime = 0
    local userData = globalData.userRunData.loginUserData.user
    local reliefFundsTimes = MAX_RELIEF_FUNDS_TIMES
    local extraData = userData.extra
    local content = nil
    local newPeriod = nil
    local mulReward = nil
    local custTime = ""
    local custDebugData = nil
    local newbieTask = nil
    local NoviceGuideFinishList = {}
    local rateUsData = nil
    local operateGuidePopupSaveData_siteCount = nil
    local operateGuidePopupSaveData_siteCD = nil
    local operateGuidePopupSaveData_PopupCD = nil
    -- local appCode = nil
    -- local fbReward = nil
    local m_signInfo = nil
    local cashMoneyTakeData = nil
    local cashBonus = nil
    local luckyChallengeGuideIndex = nil
    local BingoExtraData = nil
    local _HeadName = nil
    local _lastUpdateNickNameTime = nil -- 用户上次换名的时间戳

    local isPuzzleGameBuyMore = nil
    local CoinPusherGuide = nil
    local puzzleGuideStepId = nil
    local mergeGameGuideStepId = nil
    local NewCoinPusherGuide = nil
    local showVipResetYear = nil

    local PassMissionRefreshGuide = nil
    local PassRewardSafeBoxGuide = nil

    local NewYearGiftSubmit = nil

    local QuestNewGuideId = nil
    local QuestNewGuideData = nil

    local PipeConnectGuideData = nil
    local DiyFeatureGuideData = nil
    local DiyFeatureGuideData_AllOver = nil
    local SidekicksGuideData = nil

    local NewUserBlastPopData = nil
    local MermaidOpNdata = nil
    local MermaidHgData = nil
    local MermaidFirstData = nil
    local ZomBieBordData = nil
    local ZomBieLineData = nil
    local NDCGuideData = nil

    if extraData ~= nil and extraData ~= "" then
        content = cjson.decode(extraData)
    end
    if content ~= nil then
        --------------------------------------------------
        --------------------------------------------------
        --每日登陆
        local signInfo = content[ExtraType.signInfo]
        if signInfo ~= nil then
            -- appCode = signInfo.appCode
            -- fbReward = signInfo.fbReward
            m_signInfo = signInfo.mySignInfo
            if m_signInfo then
                release_print("m_signInfo ---> " .. tostring(m_signInfo.appCode))
            else
                release_print("m_signInfo is nil")
            end
        else
            release_print("signInfo is nil")
        end
        --------------------------------------------------

        --------------------------------------------------
        --fb首登奖励
        local fbConnect = content[ExtraType.fbConnect]
        if fbConnect ~= nil then
            bindingFb = fbConnect["bindingFb"]
            if bindingFb == nil then
                bindingFb = false
            else
                if bindingFb == 0 then
                    bindingFb = false
                else
                    bindingFb = true
                end
            end
        end
        --------------------------------------------------
        --------------------------------------------------
        --小猪银行信息
        if content[ExtraType.pig] ~= nil then
            pigCoin = content[ExtraType.pig]
        end

        -- if content[ExtraType.pigIndex] ~= nil then
        --     pigLevel = content[ExtraType.pigIndex]
        --     if #PIGGYBANK_CONFIG < pigLevel then
        --         pigLevel = #PIGGYBANK_CONFIG
        --     end
        -- end

        if content[ExtraType.pigTimes] ~= nil then
            pigBuyTimes = content[ExtraType.pigTimes]
        end
        if content[ExtraType.spinAccumulation] ~= nil then
            spinAccumulation = content[ExtraType.spinAccumulation]
        else
            spinAccumulation = {["time"] = os.time(), ["amount"] = 0}
        end
        --------------------------------------------------

        --------------------------------------------------
        --任务信息
        if content[ExtraType.taskInfo] ~= nil then
            taskInfo = {}
            for key, var in pairs(content["taskInfo"]) do
                if key == TASK_TIME then
                    taskTime = var
                else
                    taskInfo[key] = var
                end
            end
        end
        --------------------------------------------------

        --------------------------------------------------

        --------------------------------------------------

        -- 商城奖励
        if content[ExtraType.shopBonus] ~= nil then
            if content["shopBonus"]["collectTime"] ~= nil then
                shopRewardTime = content["shopBonus"]["collectTime"]
            end
        end

        --------------------------------------------------
        --------------------------------------------------
        -- -- 商城buff结束时间（升级buff）
        if content[ExtraType.shopLevelBurst] ~= nil then
            if content["shopLevelBurst"]["shopLevelBurstEndTime"] ~= nil then
                shopLevelBurstEndTime = content["shopLevelBurst"]["shopLevelBurstEndTime"]
            end
            if content["shopLevelBurst"]["shopCoinsBurstEndTime"] ~= nil then
                shopCoinsBurstEndTime = content["shopLevelBurst"]["shopCoinsBurstEndTime"]
            end
            if content["shopLevelBurst"]["shopDoubleBurstEndTime"] ~= nil then
                shopDoubleBurstEndTime = content["shopLevelBurst"]["shopDoubleBurstEndTime"]
            end
        end

        --------------------------------------------------

        --------------------------------------------------
        --是否购买过
        if content[ExtraType.purchaseSome] ~= nil then
            if content["purchaseSome"] == 1 then
                purchaseSome = true
            end
        end
        --------------------------------------------------

        --------------------------------------------------

        if content[ExtraType.icon] ~= nil then
            headIdx = content["icon"]
        end
        --------------------------------------------------

        --------------------------------------------------
        --是否购买过
        if content[ExtraType.operaId] ~= nil then
            operaId = content[ExtraType.operaId]
        end

        --------------------------------------------------

        --------------------------------------------------
        --每日任务信息
        if content[ExtraType.tasksDailyData] ~= nil then
            tasksDailyData = content[ExtraType.tasksDailyData]
        end

        -- 每日任务时间
        if content[ExtraType.tasksDailyTime] ~= nil then
            tasksDailyTime = content[ExtraType.tasksDailyTime]
        end
        -- 每日任务收集点数
        if content[ExtraType.tasksCollectPoints] ~= nil then
            tasksCollectPoints = content[ExtraType.tasksCollectPoints]
        end

        -- 每日任务收集状态
        if content[ExtraType.tasksCollectstate] ~= nil then
            tasksCollectstate = content[ExtraType.tasksCollectstate]
        end

        --------------------------------------------------

        --------------------------------------------------
        --quest信息
        if content[ExtraType.questData] ~= nil then
            questData = content[ExtraType.questData]
        end
        --------------------------------------------------

        --------------------------------------------------
        --quest信息
        if content[ExtraType.questData] ~= nil then
            questData = content[ExtraType.questData]
        end

        if content[ExtraType.averageBet] ~= nil then
            averageBet = content[ExtraType.averageBet]
        end
        --------------------------------------------------

        --------------------------------------------------
        --救济金
        if content[ExtraType.reliefTimes] ~= nil then
            reliefFundsTimes = content[ExtraType.reliefTimes]
        end
        --------------------------------------------------
        --新手期存档
        if content[ExtraType.newPeriod] ~= nil then
            newPeriod = content[ExtraType.newPeriod]
        end
        --------------------------------------------------

        --------------------------------------------------
        --多倍奖励信息
        if content[ExtraType.mulReward] ~= nil then
            mulReward = content[ExtraType.mulReward]
        end

        --进入关卡时间
        if content[ExtraType.custTime] ~= nil then
            custTime = content[ExtraType.custTime]
        end

        if content[ExtraType.NoviceGuideFinishList] ~= nil then
            NoviceGuideFinishList = content[ExtraType.NoviceGuideFinishList]
        end

        --关卡内测试数据
        if content[ExtraType.custDebugData] ~= nil then
            custDebugData = content[ExtraType.custDebugData]
        end
        --------------------------------------------------
        --新手任务数据

        if content[ExtraType.newbieTask] ~= nil then
            newbieTask = content[ExtraType.newbieTask]
        end
        --------------------------------------------------
        --引导评价
        if content[ExtraType.rateUsData] ~= nil then
            rateUsData = content[ExtraType.rateUsData]
        end
        -- 运营引导弹板点位数据
        if content[ExtraType.OperateGuidePopup] ~= nil then
            operateGuidePopupSaveData_siteCount = content[ExtraType.OperateGuidePopup]
        end
        if content[ExtraType.OperateGuidePopupSiteCD] ~= nil then
            operateGuidePopupSaveData_siteCD = content[ExtraType.OperateGuidePopupSiteCD]
        end
        if content[ExtraType.OperateGuidePopupCD] ~= nil then
            operateGuidePopupSaveData_PopupCD = content[ExtraType.OperateGuidePopupCD]
        end

        --轮盘钞票小游戏记录是否点击take按钮
        if content[ExtraType.cashMoneyTake] ~= nil then
            cashMoneyTakeData = content[ExtraType.cashMoneyTake]
        end
        --------------------------------------------------
        --第二条任务线引导
        if content[ExtraType.LuckyChallengeGuide] ~= nil then
            luckyChallengeGuideIndex = content[ExtraType.LuckyChallengeGuide]
        end
        --bingo新手引导
        if content[ExtraType.BingoExtra] ~= nil then
            BingoExtraData = content[ExtraType.BingoExtra]
        end

        -- 用户头像
        if content[ExtraType.HeadName] ~= nil then
            _HeadName = content[ExtraType.HeadName]
        elseif globalData.userRunData.createTime and globalData.userRunData.createTime > self.m_tempRegisterTime then
            _HeadName = self:getDefaultHeadName()
            globalData.userRunData.bLoginSaveHead = true -- 登录后保存下头像
        end

        -- 用户头像框
        if content[ExtraType.avatarFrameId] ~= nil then
            if content[ExtraType.avatarFrameId] == "" then
                globalData.userRunData.avatarFrameId = nil
            else
                globalData.userRunData.avatarFrameId = content[ExtraType.avatarFrameId]
                G_GetMgr(G_REF.AvatarFrame):changeSelfAvatarFrameID()
            end
        end

        if content[ExtraType.LastUpdateNickNameTime] ~= nil then
            _lastUpdateNickNameTime = math.floor(content[ExtraType.LastUpdateNickNameTime] * 0.001)
        end

        --集卡小游戏是否打开了，buymore界面
        if content[ExtraType.isPuzzleGameBuyMore] ~= nil then
            isPuzzleGameBuyMore = content[ExtraType.isPuzzleGameBuyMore]
        end

        if content[ExtraType.CoinPusherGuide] ~= nil then
            CoinPusherGuide = content[ExtraType.CoinPusherGuide]
        end

        if content[ExtraType.NewCoinPusherGuide] ~= nil then
            NewCoinPusherGuide = content[ExtraType.NewCoinPusherGuide]
        end

        if content[ExtraType.puzzleGuideStepId] ~= nil then
            puzzleGuideStepId = content[ExtraType.puzzleGuideStepId]
        end

        if content[ExtraType.mergeGameGuideStepId] ~= nil then
            mergeGameGuideStepId = content[ExtraType.mergeGameGuideStepId]
        end

        if content[ExtraType.showVipResetYear] ~= nil then
            G_GetMgr(G_REF.Vip):setShowVipResetYear(content[ExtraType.showVipResetYear])
        end
        
        if content[ExtraType.PassMissionRefreshGuide] ~= nil then
            PassMissionRefreshGuide = content[ExtraType.PassMissionRefreshGuide]
        end

        if content[ExtraType.PassRewardSafeBoxGuide] ~= nil then
            PassRewardSafeBoxGuide = content[ExtraType.PassRewardSafeBoxGuide]
        end

        if content[ExtraType.NewYearGiftSubmit] ~= nil then
            G_GetMgr(ACTIVITY_REF.NewYearGift):setNewYearGiftSubmit(content[ExtraType.NewYearGiftSubmit])
        end
        
        if content[ExtraType.QuestNewGuideId] ~= nil then
            QuestNewGuideId = content[ExtraType.QuestNewGuideId]
        end
        if content[ExtraType.QuestNewGuideData] ~= nil then
            QuestNewGuideData = content[ExtraType.QuestNewGuideData]
        end
        if content[ExtraType.PipeConnectGuideData] ~= nil then
            PipeConnectGuideData = content[ExtraType.PipeConnectGuideData]
        end
        if content[ExtraType.DiyFeatureGuideData] ~= nil then
            DiyFeatureGuideData = content[ExtraType.DiyFeatureGuideData]
        end

        if content[ExtraType.DiyFeatureGuideData_AllOver] ~= nil then
            DiyFeatureGuideData_AllOver = content[ExtraType.DiyFeatureGuideData_AllOver]
        end

        if content[ExtraType.SidekicksGuideData] ~= nil then
            SidekicksGuideData = content[ExtraType.SidekicksGuideData]
        end

        if content[ExtraType.NewUserBlastPop] ~= nil then
            NewUserBlastPopData = content[ExtraType.NewUserBlastPop]
        end
        if content[ExtraType.MermaidOpN] ~= nil then
            MermaidOpNdata = content[ExtraType.MermaidOpN]
        end
        if content[ExtraType.MermaidHg] ~= nil then
            MermaidHgData = content[ExtraType.MermaidHg]
        end
        if content[ExtraType.MermaidFirst] ~= nil then
            MermaidFirstData = content[ExtraType.MermaidFirst]
        end
        if content[ExtraType.ZomBieBord] ~= nil then
            ZomBieBordData = content[ExtraType.ZomBieBord]
        end
        if content[ExtraType.ZomBieLine] ~= nil then
            ZomBieLineData = content[ExtraType.ZomBieLine]
        end
        if content[ExtraType.NDCGuide] ~= nil then
            NDCGuideData = content[ExtraType.NDCGuide]
        end
    else
        -- 玩家注册
        -- 玩家没有设置过头像 随机一个默认头像
        if not globalData.userRunData.isFbLogin then
            _HeadName = self:getDefaultHeadName()
            globalData.userRunData.bLoginSaveHead = true -- 登录后保存下头像
        end
    end

    globalData.shopRunData.shopRewardTime = tonumber(shopRewardTime)

    globalData.shopRunData.shopLevelBurstEndTime = tonumber(shopLevelBurstEndTime)
    globalData.shopRunData.shopCoinsBurstEndTime = tonumber(shopCoinsBurstEndTime)
    globalData.shopRunData.shopDoubleBurstEndTime = tonumber(shopDoubleBurstEndTime)

    globalData.spinAccumulation = spinAccumulation or {["time"] = os.time(), ["amount"] = 0}
    globalData.reliefFundsTimes = tonumber(reliefFundsTimes)

    globalData.taskTime = taskTime
    if taskInfo ~= nil then
        for key, var in pairs(taskInfo) do
            globalData[key] = tonumber(var)
        end
    end

    globalData.rewardTime = tonumber(rewardTime)
    globalData.rewardCount = tonumber(rewardCount)
    globalData.rewardID = rewardID
    globalData.cashBonus = cashBonus
    if nil == globalData.cashBonus then
        globalData.cashBonus = {}
    end
    globalData.cashBonus._b_isNew = true
    globalData.buySomethingOk = purchaseSome
    globalData.dailyDayId = tonumber(dailyBonusDays)
    globalData.dailyDayTime = dailyTime
    globalData.userRunData.isGetFbReward = bindingFb
    globalData.questData = questData
    --globalData.questData = nil
    globalData.userRunData.headIcon = tonumber(headIdx)
    -- globalData.appCode = appCode
    -- globalData.fbReward = fbReward
    globalData.signInfo = m_signInfo
    globalData.operaId = operaId
    globalData.averageBet = averageBet

    globalData.newPeriod = newPeriod

    globalData.custTime = custTime
    globalData.NoviceGuideFinishList = NoviceGuideFinishList
    globalData.custDebugData = custDebugData

    -- fb 登出后 恢复原来保存的头像
    if tonumber(_HeadName) == 0 and not globalData.userRunData.isFbLogin then
        local preHeadName = gLobalDataManager:getStringByField("PreUserHeadName", 0)
        if tonumber(preHeadName) == 0 then
            preHeadName = self:getDefaultHeadName()
        end
        _HeadName = preHeadName
        globalData.userRunData.bLoginSaveHead = true -- 登录后保存下头像
    end

    -- fb 登录 就显示 fb头像， 期间玩家可以选择其他头像 但是重新登录还是 fb 头像
    local bLastTimeGuestLogin = gLobalDataManager:getBoolByField("NoFbAutoLogin", true)
    if bLastTimeGuestLogin and globalData.userRunData.isFbLogin and tonumber(_HeadName) ~= 0 then
        -- 玩家手动登录的 fb， 切换头像
        _HeadName = 0
        globalData.userRunData.bLoginSaveHead = true -- 登录后保存下头像
        if LOG_ENUM_TYPE.BindFB_Login == self.m_fbLoginPos then
            -- 登录界面手动登录的 再置为false
            gLobalDataManager:setBoolByField("NoFbAutoLogin", false)
        end
    end

    globalData.userRunData.HeadName = _HeadName
    --可更换用户名称剩余时间
    globalData.userRunData.lastUpdateNickNameTime = _lastUpdateNickNameTime

    globalNewbieTaskManager:initServerData(newbieTask)

    --保存rateusdata
    if globalData.rateUsData then
        globalData.rateUsData:initRateUsData(rateUsData)
    end
    -- 运营引导弹板 点位次数
    if G_GetMgr(G_REF.OperateGuidePopup) then
        G_GetMgr(G_REF.OperateGuidePopup):initServerExtraSaveData(operateGuidePopupSaveData_siteCount)
    end
    -- 运营引导弹板 点位CD, 弹板CD
    if G_GetMgr(G_REF.OperateGuidePopup) then
        G_GetMgr(G_REF.OperateGuidePopup):initServerExtraSaveData_CD(operateGuidePopupSaveData_siteCD, operateGuidePopupSaveData_PopupCD)
    end
   
    -- 获取extra并保存是否点击take按钮数据
    if cashMoneyTakeData and G_GetMgr(G_REF.CashBonus):getRunningData() then
        G_GetMgr(G_REF.CashBonus):getRunningData():setMegaCashTakeData(cashMoneyTakeData)
    end

    --如果本地数据为空  且服务器有该数据  则服务器数据覆盖掉本地数据
    local guideIndex = gLobalDataManager:getNumberByField("LCGuide" .. globalData.userRunData.uid, 0)
    if luckyChallengeGuideIndex ~= nil and luckyChallengeGuideIndex > 0 and guideIndex <= 0 then
        gLobalDataManager:setNumberByField("LCGuide" .. globalData.userRunData.uid, luckyChallengeGuideIndex)
    end

    -- 获取extra并保存是否点击take按钮数据
    G_GetMgr(ACTIVITY_REF.Bingo):initBingoExtraData(BingoExtraData)

    -- 获取extra并保存是否点击take按钮数据
    local coinPusher = G_GetMgr(ACTIVITY_REF.CoinPusher):getRunningData()
    if CoinPusherGuide and coinPusher then
        coinPusher:initCoinPusherGuideData(CoinPusherGuide)
    end

    -- 获取extra并保存是否点击take按钮数据
    local newCoinPusher = G_GetMgr(ACTIVITY_REF.NewCoinPusher):getRunningData()
    if NewCoinPusherGuide and newCoinPusher then
        newCoinPusher:initNewCoinPusherGuideData(NewCoinPusherGuide)
    end

    if PassMissionRefreshGuide ~= nil then
        gLobalDailyTaskManager:setRefreshGuideId(PassMissionRefreshGuide)
    end
    if PassRewardSafeBoxGuide ~= nil then
        gLobalDailyTaskManager:setSafeBoxGuideId(PassRewardSafeBoxGuide)
    end

    if SidekicksGuideData ~= nil then
        G_GetMgr(G_REF.Sidekicks):parseGuideData(SidekicksGuideData)
    end

    globalData.isPuzzleGameBuyMore = isPuzzleGameBuyMore
    globalData.isPuzzleGameShowOver = isPuzzleGameShowOver
    globalData.puzzleGuideStepId = puzzleGuideStepId
    globalData.mergeGameGuideStepId = mergeGameGuideStepId
    globalData.QuestNewGuideId = QuestNewGuideId
    globalData.QuestNewGuideData = QuestNewGuideData
    globalData.PipeConnectGuideData = PipeConnectGuideData
    globalData.DiyFeatureGuideData = DiyFeatureGuideData
    globalData.DiyFeatureGuideData_AllOver = DiyFeatureGuideData_AllOver
    globalData.NewUserBlastPopData = NewUserBlastPopData
    globalData.MermaidOpNdata = MermaidOpNdata
    globalData.MermaidHgData = MermaidHgData
    globalData.MermaidFirstData = MermaidFirstData
    globalData.ZomBieBordData = ZomBieBordData
    globalData.ZomBieLineData = ZomBieLineData
    globalData.NDCGuideData = NDCGuideData
end

function NetWorkLogon:saveUserData()
    ------------------------------------- 用户 基础数据  优先解析 玩家数据 后边有活动可能需要玩家的这些数据 -------------------------------------
    local loginUserData = globalData.userRunData.loginUserData
    -- 服务器时间
    local serverTimeStamp = tonumber(loginUserData.timestamp)

    local userData = loginUserData.user
    -- local _coins = tonumber(userData.coins) >= 0 and tonumber(userData.coins) or tonumber(userData.coins) * -1
    local _coins = userData.coinsV2
    globalData.userRunData:setCoins(_coins)

    -- globalData.userRunData.gemNum = tonumber(userData.gems) >= 0 and tonumber(userData.gems) or tonumber(userData.gems) * -1
    if globalData.userRunData.setGems then
        globalData.userRunData:setGems(tonumber(userData.gems))
    else
        globalData.userRunData.gemNum = tonumber(userData.gems) >= 0 and tonumber(userData.gems) or 0
    end

    local newLevelNum = tonumber(userData.level)
    if newLevelNum then
        globalData.userRunData.levelNum = newLevelNum
    end
    local newExp = tonumber(userData.exp)
    if newExp then
        globalData.userRunData.currLevelExper = newExp
    end
    globalData.userRunData.createTime = tonumber(userData.createTime)
    globalData.userRunData.m_lastLoginTime = tonumber(serverTimeStamp)
    globalData.userRunData.uid = tonumber(userData.uid)
    globalData.userRunData.vipLevel = userData.vipLevel
    globalData.userRunData.vipPoints = userData.vipPoint
    globalData.userRunData.facebookBindingID = userData.facebookId
    globalData.userRunData.nickName = userData.nickName
    globalData.userRunData.mail = userData.mail
    globalData.userRunData.dataVersion = userData.version --之前更根据版本号大小保存数据 服务器修改后可以删除
    globalData.userRunData.rcId = userData.rcId
    ------------------------------------- 用户 基础数据 -------------------------------------

    if loginUserData:HasField("abTestGroupConfig") == true then
        local abTestGroupConfig = loginUserData.abTestGroupConfig
        globalData.GameConfig:syncABTestGroupConfig(abTestGroupConfig)
    end
    --ABTest
    globalData.userRunData.p_category = loginUserData.category
    globalData.userRunData.p_categoryNum = tonumber(loginUserData.categoryNum)
    if globalData.userRunData.p_categoryNum then
        release_print("user category = " .. globalData.userRunData.p_categoryNum)
    end

    -- 先同步时间
    globalData.userRunData:syncServerTime(serverTimeStamp)

    globalData.userRunData.loginOffset = loginUserData.offset

    ----------------- cxc 2021-05-28 11:49:39 abtest分组添加 ---------------
    -- 普通活动 配置信息
    local commonActivities = loginUserData.commonActivities
    if commonActivities and #commonActivities > 0 then
        globalData.GameConfig:parseActivityConfig(commonActivities, ACTIVITY_TYPE.COMMON)
    end
    -- 新手期配置
    G_GetMgr(G_REF.UserNovice):parseData(loginUserData)

    local commonConfig = loginUserData.config
    globalData.syncUserConfig(commonConfig, true)
    globalData.shopRunData:setLuckySpinLevel(loginUserData.luckySpinOffset)

    if loginUserData:HasField("pig") then
        local pig = loginUserData.pig
        globalData.syncPigCoin(pig)
    end

    if loginUserData:HasField("dailyTask") then
        local dailyTask = loginUserData.dailyTask
        globalData.syncMission(dailyTask)
    end
    ----------------- cxc 2021-05-28 11:49:39 abtest分组添加 ---------------
    --活动相关
    if loginUserData:HasField("activity") == true then
        -- 解析新手期普通活动配置（只在登陆时处理）
        globalData.commonActivityData:parseNoviceCommonActivitiesData()
        -- ======
        local data = loginUserData.activity
        globalData.syncActivityConfig(data, true)
    end

    if loginUserData:HasField("luckyStampV2") == true then
        globalData.syncLuckyStampData(loginUserData.luckyStampV2, true)
    end

    -- if loginUserData:HasField("cardGame") == true then
    --     globalData.playCardGame = loginUserData.cardGame
    -- end

    -- if loginUserData:HasField("gameCrazy") == true then
    --     local gameCrazy = loginUserData.gameCrazy
    --     globalData.syncGameCraze(gameCrazy)
    -- end

    --fb 绑定奖励
    if loginUserData:HasField("fbCoins") == true then
        local fbCoins = loginUserData.fbCoins
        globalData.userRunData:setFbBindReward(fbCoins)
    end

    -- 新手保护数据
    if loginUserData:HasField("newUserProtect") == true then
        local newUserProtect = loginUserData.newUserProtect
        self:parseNewUserProtect(newUserProtect)
    end

    -- 用户流失回归信息
    if loginUserData:HasField("churnReturn") == true then
        local churnReturn = loginUserData.churnReturn
        globalData.userRunData:setUserChurnReturnInfo(churnReturn)

        if churnReturn:HasField("returnVersion") and churnReturn.returnVersion == "V2" then
            if churnReturn:HasField("signV2") then
                G_GetMgr(G_REF.Return):parseData(churnReturn.signV2)
            end
        end
    end

    --广告相关
    if loginUserData.adConfig ~= nil and #loginUserData.adConfig > 0 then
        local adConfig = loginUserData.adConfig
        globalData.syncAdConfig(adConfig)
    end

    -- MiniGame
    if loginUserData:HasField("miniGame") == true then
        local miniGame = loginUserData.miniGame
        gLobalMiniGameManager:parseData(miniGame, true)
    end

    if loginUserData.communication ~= nil then
        globalData.userRunData:setUserCommunication(loginUserData.communication)
    end

    -- RateUs数据解析
    if loginUserData:HasField("rate") then
        globalData.rateUsData:parseData(loginUserData.rate)
    end

    -- 巅峰竞技场奖杯数据
    if loginUserData.trophy and #loginUserData.trophy > 0 then
        globalData.userRunData:parseLeagueTrophyData(loginUserData.trophy)
    end

    -- 关卡分类推荐
    -- if loginUserData:HasField("gameGroups") then
    local levelNodeData = require("views.lobby.LevelRecmd.LevelRecmdData")
    levelNodeData:getInstance():parseLevelRecmdData(loginUserData.gameGroups)
    -- end

    if loginUserData.specialTickets ~= nil and #loginUserData.specialTickets > 0 then
        local _mgr = G_GetMgr(G_REF.MSCRegister)
        if _mgr then
            _mgr:parseData(loginUserData.specialTickets)
        end
    end

    -- 手机绑定信息
    if loginUserData:HasField("phoneInfo") == true then
        G_GetMgr(G_REF.BindPhone):parseData(loginUserData.phoneInfo)
    end

    -- 登陆给的集卡基础数据信息，掉落界面新增章节信息需要登陆时的数据支持
    if loginUserData:HasField("cardsSimpleInfo") == true then
        CardSysRuntimeMgr:parseLoginSimpleData(loginUserData.cardsSimpleInfo)
    end
    
    
    -- ======
    --额外存储的数据
    self:saveExtraData()

    --按照new hot关卡排序
    globalData.slotRunData:sortMachineDatas()
    --根据abtest修改关卡id
    globalData.GameConfig:changeABTestLevelJson()

    --保存邮件模板附加内容
    local current_user_udid = globalData.userRunData.userUdid
    local current_user_displayUid = globalData.userRunData.uid
    gLobalDataManager:setStringByField("current_user_udid", current_user_udid)
    gLobalDataManager:setStringByField("current_user_displayUid", current_user_displayUid)

    --读取配置的开关
    globalData.openDebugCode = gLobalDataManager:getNumberByField("openDebugCode", 0)

    --注册 AIHelp 监听
    globalPlatformManager:checkAIHelpNewMessage()

    -- 刷新动态资源的ABTest数据
    globalDynamicDLControl:initABTestDynamicZipTable(loginUserData.noviceNewQuest)
    -- 初始化活动部分数据
    globalData.commonActivityData:initActivitiesData()
    -- 弹板CD数据
    globalData.popCdData:loadLocalData()
    -- 启动促销定时器
    globalData.saleRunData:startUpdate()
end

---
-- 发送登录请求
--
-- @param isFacebookLogin bool 是否fb登录
function NetWorkLogon:loginGame(isFacebookLogin, isAppleLogin)
    self:updatePlatFormType()
    if isFacebookLogin == nil or isFacebookLogin == false then
        isFacebookLogin = false
        globalData.userRunData.isFbLogin = false
        globalData.userRunData.userUdid = gLobalSendDataManager:getDeviceUuid()
        gLobalBuglyControl:setId(globalData.userRunData.userUdid)
    end

    local httpSender = xcyy.HttpSender:createSender()

    local data = LoginProto_pb.LoginRequest()

    data.productId = PRODUCTID

    if isFacebookLogin == true then
        data.udid = globalData.userRunData.fbUdid
        globalData.userRunData.userUdid = globalData.userRunData.fbUdid
        gLobalBuglyControl:setId(globalData.userRunData.userUdid)
        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():setLoginType("FB")
    elseif isAppleLogin == true then
        data.udid = globalData.userRunData.appleID
        globalData.userRunData.userUdid = globalData.userRunData.appleID
        gLobalBuglyControl:setId(globalData.userRunData.userUdid)
        gLobalSendDataManager:getLogGameLoad():setLoginType("APPLE")
        gLobalDataManager:setStringByField(APPLE_ID, globalData.userRunData.appleID)
    else
        data.udid = globalData.userRunData.userUdid -- 如果是访客模式，用设备ID
        --新GameLoadLog
        gLobalSendDataManager:getLogGameLoad():setLoginType("GUEST")
    end
    local _udid = data.udid
    data.platform = self.PlatFormType
    data.ip = globalPlatformManager:getIp() or ""
    data.imei = globalPlatformManager:getImei() or ""
    data.deviceId = globalPlatformManager:getDeviceId()
    data.osVersion = globalPlatformManager:getSystemVersion() or ""
    data.appVersion = util_getAppVersionCode() or ""
    data.resVersion = tostring(util_getUpdateVersionCode(false)) or ""
    data.dn = globalPlatformManager:getPhoneName() or ""
    data.dv = globalPlatformManager:getOsSystemVersion() or ""
    data.dm = xcyy.GameBridgeLua:getDeviceMemory()
    data.extra = globalDeviceInfoManager:getLogonExtraJsonData()
    -- adjust归因数据
    data.tracker = globalAdjustManager:getAdjustAttJsonStr()

    if isFacebookLogin then
        data.loginType = "Facebook"
    elseif isAppleLogin then
        data.loginType = "Apple"
    else
        data.loginType = "Game"
    end
    if device.platform == "android" then
        local androidID = gLobalSendDataManager:getDeviceId()
        local gpsID = globalPlatformManager:getGoogleAdvertisingID()
        data.android_id = androidID
        local adjustID = globalAdjustManager:getAdjustID()
        if adjustID ~= nil and adjustID ~= "" then
            data.adid = tostring(adjustID)
        end
        if gpsID ~= androidID then
            data.gps_adid = tostring(gpsID)
        end
        if MARKETSEL == AMAZON_MARKET then
            data.fire_adid = globalPlatformManager:getAmazonAdID()
        end
    elseif device.platform == "ios" then
        data.adid = globalAdjustManager:getAdjustID() or ""
        data.idfv = globalPlatformManager:getIDFV() or ""
        data.idfa = globalAdjustManager:getAdjustIDFA() or ""
    elseif device.platform == "mac" then
        data.adid = data.udid 
    end

    --获取网络状态
    if data.net then
        if globalDeviceInfoManager and globalDeviceInfoManager.getNetWorkType then
            data.net = globalDeviceInfoManager:getNetWorkType() or ""
        else
            data.net = ""
        end
    end

    local loginSuccess = function(responseTable)
        release_print("udidlog:loginSuccess udid = " .. _udid .. "|isFacebookLogin = " .. tostring(isFacebookLogin) .. "|fbLoginPos=".. tostring(self.m_fbLoginPos))
        if isFacebookLogin then
            globalData.userRunData.isFbLogin = true
            -- 保存udid
            gLobalSendDataManager:saveDeviceUuid(_udid)
            if self.m_fbLoginPos ~= LOG_ENUM_TYPE.BindFB_Login then
                httpSender:release()
                -- 保存udid
                -- gLobalSendDataManager:saveDeviceUuid(_udid)
                self:restartToLogin()
                return
            end
        end
        self:loginGameSuccessCallFun(isFacebookLogin, isAppleLogin, responseTable)
        httpSender:release()
    end

    local loginFailed = function(errorCode, errorData)
        globalData.userRunData.isFbLogin = false
        if isFacebookLogin == true then
            globalFaceBookManager:fbLogOut() --清空token
        end
        self:loginGameFailedCallFun(errorCode, errorData)
        -- 弹板提示登录失败
        httpSender:release()
    end

    local bodyData = data:SerializeToString()
    local url = DATA_SEND_URL .. RUI_INFO.LOGIN
    local serverTime = xcyy.SlotsUtil:getMilliSeconds() -- 登录时只能使用当前系统时间

    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(12)
    httpSender:sendLoginMessage(bodyData, url, serverTime, loginSuccess, loginFailed)
end

function NetWorkLogon:loginGameSuccessCallFun(isFacebookLogin, isAppleLogin, resultData)
    self.m_bLogin = true
    globalData.m_isLogin = self.m_bLogin
    local data = LoginProto_pb.LoginResponse()
    local responseStr = self:parseResponseData(resultData)
    data:ParseFromString(responseStr)
    local accountState = self:getAccountState(data)
    local bAccountBanned = self:checkAccountBannedState(data.accountCheckData)
    local dataIsLegality = self:checkLoginDataIsLegality(data)
    --封停
    if accountState == 1 then
        --账号恢复
        gLobalViewManager:showAccountClosureDialog()
    elseif accountState == 2 then
        gLobalViewManager:showRecoverDelAccountDialog(data)
    elseif bAccountBanned then
        if dataIsLegality then
            local ignoreCb = function()
                self:dealAcctountLoginLegality(data, isFacebookLogin, isAppleLogin)
            end
            gLobalViewManager:showAccountBannedDialog(data.accountCheckData, ignoreCb)
        else
            gLobalViewManager:showAccountBannedDialog(data.accountCheckData)
        end
    elseif dataIsLegality == true then
        self:dealAcctountLoginLegality(data, isFacebookLogin, isAppleLogin)
    else
        self:loginGameFailedCallFun()
    end
end

--[[--
    玩家 合法 可正常登录
]]
function NetWorkLogon:dealAcctountLoginLegality(data, isFacebookLogin, isAppleLogin)
    if not isAppleLogin then
        gLobalDataManager:setStringByField("luaappleuserid", "") -- 清除苹果登录标识
    end
    globalData.userRunData.loginUserData = data
    local udid = ""
    local userData = data.user
    if userData then
        udid = userData.udid or ""
    end

    if not isFacebookLogin and not isAppleLogin then
        --保存下服务器下发的udid
        if udid ~= nil and udid ~= "" then
            if gLobalSendDataManager.saveDeviceUuid ~= nil then
                gLobalSendDataManager:saveDeviceUuid(udid)
            end
            
            if DEBUG == 0 then
                -- 只有iOS 正式环境才会生效
                local idfv = string.split(udid, ":" .. gLobalSendDataManager.PRODUCTID)[1] -- 裁剪掉 之前拼上去的 :SlotNewCashLink
                globalPlatformManager:saveKeyChainValueForKey("udidservice", idfv)
            end
            globalData.userRunData.userUdid = gLobalSendDataManager:getDeviceUuid()
        end
    end

    if udid ~= "" then
        globalData.userRunData.userUdid = udid
    end

    self:saveUserData()

    -- id传给 Ads SDK
    local isAdsDebug = false
    if DEBUG ~= 0 then
        isAdsDebug = LoginMgr:getInstance():isAdsDebug()
    end
    gLobalAdsControl:sendUserIdToAds(globalData.userRunData.uid, isAdsDebug)

    gLobalSaleManager:resetVipInfo()
    gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_SUCCESS)
    --新手firebase打点
    globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.login)
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.Login)
    end
    globalFireBaseManager:sendFireBaseProperty()
    gLobalSendDataManager:getNetWorkFeature():sendSaveFirebaseToken()
    globalAdjustManager:sendAdjustKey("login")
    if globalData.userRunData.isFbLogin then
        gLobalSendDataManager:getNetWorkLogon():sendFacebookEmail()
    end

    --csc 2021-08-27 17:15:27 修改推送接口
    globalLocalPushManager:logonSuccessDoSomething()
    --开启后台下载
    if CC_DYNAMIC_DOWNLOAD == true then
        local isNewPlayer = globalData.GameConfig:isNewPlayer()
        if isNewPlayer then
            globalData.GameConfig:setNewPlayer(false)
            globalDynamicDLControl:startDownload(1, {0, 1})
        else
            globalDynamicDLControl:startDownload(1, 1)
        end
    end
end

function NetWorkLogon:getAccountState(data)
    if data ~= nil and data.code ~= nil then
        local code = data.code
        --检查是否封停用户
        if code == BaseProto_pb.CLOSURE_USER then
            --删除账号中，可恢复账号
            return 1
        elseif code == BaseProto_pb.ACCOUNT_DELETING or code == BaseProto_pb.ACCOUNT_DELETED then
            return 2
        end
    end
    return 0
end

--[[--
    检查 用户是否作弊被警告 或者 封号
]]
function NetWorkLogon:checkAccountBannedState(_accountCheckData)
    if _accountCheckData and (_accountCheckData.code == BaseProto_pb.ACCOUNT_WARNING or _accountCheckData.code == BaseProto_pb.ACCOUNT_BLOCKED) then
        return true
    end
    return false
end

--[[
    @desc: 检测登录请求的数据是否合法
    time:2019-04-12 16:22:59
    @return:
]]
function NetWorkLogon:checkLoginDataIsLegality(checkData)
    -- 如果请求返回的数据中，关卡列表数据为空， 则表明数据不合法
    if checkData.config.games ~= nil and #checkData.config.games > 0 then
        return true
    end
    return false
end

function NetWorkLogon:loginGameFailedCallFun(errorCode, errorData)
    gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD, {errorCode, errorData})
    --新GameLoadLog
    gLobalSendDataManager:getLogGameLoad():sendNewLog(99)
end

---- ---------------    登出操作   ---------------------

---
-- Game logout ,, 游客模式的退出
--
function NetWorkLogon:logoutGame()
    local url = DATA_SEND_URL .. RUI_INFO.LOGOUT
    local httpSender = xcyy.HttpSender:createSender()
    local logout_success_fun = function(responseTable)
        local logoutResponse = LoginProto_pb.LogoutResponse()
        local responseStr = self:parseResponseData(responseTable)

        logoutResponse:ParseFromString(responseStr)
        if logoutResponse.code == BaseProto_pb.SUCCEED then -- 登出成功
            self.m_bLogin = false
            globalData.m_isLogin = self.m_bLogin
            globalData.userRunData.isFbLogin = false
            gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGOUT, {true})

            self:restartToLogin()
        end
        httpSender:release()
    end
    local logout_faild_fun = function(errorCode, errorData)
        gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGOUT, false)

        httpSender:release()
    end
    local isFbLogin = globalData.userRunData.isFbLogin

    local requestData = LoginProto_pb.LogoutRequest()
    requestData.productId = PRODUCTID
    if isFbLogin == true then
        requestData.udid = globalData.userRunData.fbUdid
    else
        requestData.udid = globalData.userRunData.userUdid
    end

    local bodyData = requestData:SerializeToString()
    local offset = self:getOffsetValue()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime

    httpSender:sendMessage(bodyData, offset, token, url, serverTime, logout_success_fun, logout_faild_fun)
end

------------------  FB 登录相关   -----------------------
--[[
    @desc:  FB登录成功后 ， 获取了fb 用户id 信息， 之后才可以执行登录操作
    time:2018-07-17 15:12:40
    @return:
]]
---
-- 用fb 登录
--
function NetWorkLogon:FBLoginGame(fbPos)
    if fbPos then
        self.m_fbLoginPos = fbPos
    end
    release_print("FBLoginGame")
    self:updatePlatFormType()
    --这时候已经登录成功 读盘获取下fb信息
    globalData.userRunData.fbUdid = gLobalDataManager:getStringByField(FB_USERID)
    globalData.userRunData.fbToken = gLobalDataManager:getStringByField(FB_TOKEN)
    globalData.userRunData.fbName = gLobalDataManager:getStringByField(FB_NAME)
    globalData.userRunData.fbEmail = gLobalDataManager:getStringByField(FB_EMAIL, "")

    -- release_print("fbLgionSuccess %s %s %s", globalData.userRunData.fbName, globalData.userRunData.fbToken, tostring(globalData.userRunData.fbUdid))

    local httpSender = xcyy.HttpSender:createSender()

    local fbLgionSuccess = function(responseTable)
        release_print("fbLgionSuccess")

        self:fbLgionSuccessCallFun(responseTable)
        httpSender:release()
    end

    local fbLgionFailed = function(errorCode, errorData)
        release_print("fbLgionFailed")
        self:fbLgionFailedCallFun(errorCode, errorData)
        httpSender:release()
    end

    local requestData = LoginProto_pb.ConnectRequestV11()
    requestData.productId = PRODUCTID
    requestData.facebookToken = globalData.userRunData.fbToken
    requestData.facebookId = globalData.userRunData.fbUdid
    requestData.udid = globalData.userRunData.userUdid
    requestData.versionCode = self:convertAppCodeToNumber(xcyy.GameBridgeLua:getAppVersionCode()) -- 获取当前app的版本
    requestData.platform = self.PlatFormType
    requestData.facebookName = globalData.userRunData.fbName

    local bodyData = requestData:SerializeToString()

    local url = DATA_SEND_URL .. RUI_INFO.FACEBOOK_LOGIN
    local serverTime = globalData.userRunData.p_serverTime

    httpSender:sendLoginMessage(bodyData, url, serverTime, fbLgionSuccess, fbLgionFailed)
end

function NetWorkLogon:fbLgionSuccessCallFun(redultData)
    print("fbLgionSuccessCallFun")
    local data = LoginProto_pb.ConnectResponse()
    data:ParseFromString(redultData)
    if data.code == BaseProto_pb.SUCCEED then
        globalData.userRunData.fbUdid = data.user.udid
        self:loginGame(true, false)
        gLobalSendDataManager:getLogFeature():sendBindFB(self.m_fbLoginPos, 1)
    else
        -- login 失败
        gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD, {data.code, "FaceBook Login, Server Verify failure"})
        gLobalSendDataManager:getLogFeature():sendBindFB(self.m_fbLoginPos, 0)
    end
end

function NetWorkLogon:fbLgionFailedCallFun(errorCode, errorData)
    globalFaceBookManager:fbLogOut()
    gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD, {errorCode, errorData})
    gLobalSendDataManager:getLogFeature():sendBindFB(self.m_fbLoginPos, 0)
end

--apple登录
function NetWorkLogon:appleLoginGame(appleID, token)
    self:updatePlatFormType()
    local httpSender = xcyy.HttpSender:createSender()

    local function appleLoginSuccess(responseTable)
        local data = LoginProto_pb.ConnectResponse()
        data:ParseFromString(responseTable)
        if data.code == BaseProto_pb.SUCCEED then
            globalData.userRunData.appleID = data.user.udid
            self:loginGame(false, true)
        else
            -- login 失败
            gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD, {data.code, "Apple Login, Server Verify failure"})
        end
        httpSender:release()
        gLobalViewManager:removeLoadingAnima()
    end

    local function appleLoginFailed(errorCode, errorData)
        gLobalNoticManager:postNotification(HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD, {errorCode, errorData})
        httpSender:release()
        gLobalViewManager:removeLoadingAnima()
    end

    local requestData = LoginProto_pb.ConnectAppleIdRequest()
    requestData.appleId = appleID
    requestData.identityToken = token
    requestData.udid = globalData.userRunData.userUdid
    requestData.productId = PRODUCTID
    requestData.versionCode = self:convertAppCodeToNumber(xcyy.GameBridgeLua:getAppVersionCode()) -- 获取当前app的版本
    requestData.platform = self.PlatFormType

    local bodyData = requestData:SerializeToString()
    local url = DATA_SEND_URL .. RUI_INFO.APPLE_LOGIN
    local serverTime = globalData.userRunData.p_serverTime
    httpSender:sendLoginMessage(bodyData, url, serverTime, appleLoginSuccess, appleLoginFailed)
end

--获取全局配置
function NetWorkLogon:reqGameGlobalConfig(resMode, successCallFunc, failedCallFunc)
    local httpSender = xcyy.HttpSender:createSender()

    local globalConfigSuccess = function(responseTable)
        -- self:globalConfigSuccessCallFun(responseTable)
        local data = BaseProto_pb.GameGlobalConfig()

        local responseStr = self:parseResponseData(responseTable)
        data:ParseFromString(responseStr)
        if data.timestamp ~= nil then
            globalData.userRunData:syncServerTime(tonumber(data.timestamp))
        end

        if successCallFunc then
            successCallFunc(data)
        end

        httpSender:release()
    end

    local globalConfigFailed = function(errorCode, errorData)
        -- self:globalConfigFailedCallFun(errorCode, errorData)
        if failedCallFunc then
            failedCallFunc(errorCode, errorData)
        end

        httpSender:release()
    end

    self:updatePlatFormType()
    local data = GameProto_pb.GameGlobalConfigRequest()
    local _udid = ""
    _udid = gLobalSendDataManager:getDeviceUuid()
    release_print("udidlog:reqGameGlobalConfig udid = " .. _udid)
    -- if gLobalSendDataManager.getCacheUdid then
    --     _udid = gLobalSendDataManager:getCacheUdid()
    -- else
    --     _udid = gLobalSendDataManager:getDeviceUuid()
    -- end
    data.udid = tostring(_udid)
    data.adid = tostring(globalAdjustManager:getAdjustID())
    data.res = resMode

    local _platformType = self.PlatFormType
    if _platformType == 1 then
        data.platform = "Android"
    elseif _platformType == 2 then
        data.platform = "iOS"
    elseif _platformType == 3 then
        data.platform = "Amazon"
    end
    local _platform = device.platform
    if _platform == "mac" then
        data.adid = data.udid
        data.version = "1.1.1"
    else
        data.version = util_getAppVersionCode() or ""
    end

    local bodyData = data:SerializeToString()
    local url = DATA_SEND_URL .. RUI_INFO.GAME_GLOBAL_CONFIG
    if DEBUG == 2 and LoginMgr:getInstance().checkIsTestOnlineRes and LoginMgr:getInstance():checkIsTestOnlineRes() then
        -- 线上资源测试(配置拉取线上的) 最新服务器
        url = LinkConfig.Online.dataUrl .. RUI_INFO.GAME_GLOBAL_CONFIG
    end 
    release_print("reqGameGlobalConfig url = " .. url)
    local serverTime = xcyy.SlotsUtil:getMilliSeconds()

    httpSender:sendLoginMessage(bodyData, url, serverTime, globalConfigSuccess, globalConfigFailed)
end

--登录扩展请求
function NetWorkLogon:sendLoginExtendRequest(paramMap, callBack)
    -- gLobalViewManager:addLoadingAnima()
    local udid = globalData.userRunData.userUdid
    local commonQueryRequest = GameProto_pb.CommonQueryRequest()
    commonQueryRequest.udid = udid
    if paramMap ~= nil then
        local fblinkCode = paramMap["fblinkCode"]
        if fblinkCode ~= nil then
            commonQueryRequest.code = fblinkCode
        end
    end
    if globalFireBaseManager.testFireBaseForecast and commonQueryRequest.fireBasePurchaseTag then
        local user_churn = globalFireBaseManager:testFireBaseForecast(1, "user_churn")
        local user_spend = globalFireBaseManager:testFireBaseForecast(1, "user_spend")
        print("testFireBaseForecastLua---------" .. tostring(user_churn) .. "===" .. tostring(user_spend))
        if user_spend ~= nil then
            commonQueryRequest.fireBasePurchaseTag = user_spend
        end
        if user_churn ~= nil then
            commonQueryRequest.fireBaseLostTag = user_churn
        end
    end
    local bodyData = commonQueryRequest:SerializeToString()
    local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. RUI_INFO.EXTEND_LOGIN_REQUEST -- 拼接url 地址
    -- 发送消息
    local success_call_fun = function(responseTable)
        -- gLobalViewManager:removeLoadingAnima()
        local extendResponse = GameProto_pb.ExtendResponse()
        local strResponse = self:parseResponseData(responseTable)
        extendResponse:ParseFromString(strResponse)
        globalData.userRunData.loginExtendData = extendResponse

        if extendResponse:HasField("simpleUser") == true then
            globalData.syncSimpleUserInfo(extendResponse.simpleUser)
        end

        httpSender:release()
        if callBack then
            callBack(true)
        end
    end

    local faild_call_fun = function(errorCode, errorData)
        -- gLobalViewManager:removeLoadingAnima()
        httpSender:release()
        if callBack then
            callBack(false)
        end
    end
    local offset = self:getOffsetValue()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime
    httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
end

-- otpDeepLink跳转请求
function NetWorkLogon:sendOtpRequest(otpCode, succFunc, failedFunc)
    -- gLobalViewManager:addLoadingAnima()
    local udid = globalData.userRunData.userUdid
    local actionData = self:getSendActionData(ActionType.OtpDeepLink)
    local params = {}
    params.code = otpCode
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, succFunc, failedFunc)
end

-- 新手保护数据
function NetWorkLogon:parseNewUserProtect(_newUserProtect)
    _newUserProtect = _newUserProtect or {}

    -- 新用户金币不足奖励
    local newUserProtectCoins = _newUserProtect.coins
    globalData.userRunData:setNewUserReward(newUserProtectCoins)
end

-- facebook 登录之后发送email 存盘
function NetWorkLogon:sendFacebookEmail()
    -- 区分版本号
    local bVersion = util_isSupportVersion("1.4.5")
    if device.platform == "android" then
        bVersion = util_isSupportVersion("1.4.1")
    end
    if bVersion then
        if globalData.userRunData.fbEmail then
            --.....
            local successCallFun = function(target, result)
                release_print("---- send email success")
            end

            local failedCallFun = function()
                release_print("---- send email failed")
            end

            local actionData = self:getSendActionData(ActionType.UserFacebookMail)
            local params = {}
            params["facebookId"] = gLobalDataManager:getStringByField(FB_USERID)
            params["mail"] = gLobalDataManager:getStringByField(FB_EMAIL, "")
            actionData.data.params = json.encode(params)
            self:sendMessageData(actionData, successCallFun, failedCallFun)
        end
    end
end

-- 用户流失回归奖励
function NetWorkLogon:sendChurnReturnReq(_successCB, _failedCB)
    local actionData = self:getSendActionData(ActionType.ChurnReturnReward)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, _successCB, _failedCB)
end

-- 游客用户绑定token 进行数据转移
function NetWorkLogon:sendGuestBindTokenReq(_token)
    if not _token or #_token < 0 then
        return
    end

    -- message DownAppRequest {
    --     optional string udid = 1;
    --     optional Platform platform = 2;
    --     optional string clientVersion = 3;
    --     optional string versionCode = 4;
    --     optional string token = 5; // 恢复token
    --   }

    --   message DownAppResponse {
    --     optional string token = 1;
    --     optional string udid = 2;// 旧APP的udid
    --     optional string status = 3; // 状态：success、格式不对、已被占用
    --   }

    gLobalViewManager:addLoadingAnima()
    self:updatePlatFormType()
    local request = ExtendProto_pb.DownAppRequest()
    request.udid = globalData.userRunData.userUdid
    request.platform = self.PlatFormType
    request.clientVersion = tostring(util_getUpdateVersionCode(false))
    request.versionCode = tostring(self:getVersionNum())
    request.token = _token

    local bodyData = request:SerializeToString()

    local httpSender = xcyy.HttpSender:createSender()

    local url = DATA_SEND_URL .. RUI_INFO.RESTORE_TOKEN -- 拼接url 地址
    local success_call_fun = function(responseTable)
        release_print("---- bind token sueecss")
        gLobalViewManager:removeLoadingAnima()
        httpSender:release()

        local downAppReponse = ExtendProto_pb.DownAppResponse()
        local responseStr = self:parseResponseData(responseTable)
        downAppReponse:ParseFromString(responseStr)

        if downAppReponse.status and downAppReponse.status == "ErrorFormat" then
            -- 格式不对
            local view = util_createView("views.dialogs.TokenLoginFailLayer", true)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            return
        elseif downAppReponse.status and downAppReponse.status == "RepeatRestore" then
            -- token已经被占用
            local view = util_createView("views.dialogs.TokenLoginFailLayer")
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            return
        end

        if downAppReponse.udid and #downAppReponse.udid > 0 then
            gLobalSendDataManager:saveDeviceUuid(downAppReponse.udid)
            gLobalNoticManager:postNotification(ViewEventType.GUEST_USER_BIND_TOKEN_SUCCESS, downAppReponse.udid)

            self:restartToLogin()
        end
    end

    local faild_call_fun = function(errorCode, errorData)
        release_print("---- bind token failed")
        gLobalViewManager:removeLoadingAnima()
        httpSender:release()
    end

    local offset = self:getOffsetValue()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime
    httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
end

-- 获取默认头像
function NetWorkLogon:getDefaultHeadName()
    local uid = tonumber(globalData.userRunData.uid) or 1
    local idx = (uid % #self.m_defaultHeadNameList) + 1
    local headName = self.m_defaultHeadNameList[idx] or 1
    return headName
end

function NetWorkLogon:restartToLogin()
    if gLobalGameHeartBeatManager then
        gLobalGameHeartBeatManager:stopHeartBeat()
    end
    util_restartGame()
end

--回复删除账号
function NetWorkLogon:sendRecoverAccount(udid)
    gLobalViewManager:addLoadingAnima()
    local httpSender = xcyy.HttpSender:createSender()

    local function successCallBack(responseData)
        httpSender:release()
        gLobalViewManager:removeLoadingAnima()
        util_restartGame()
    end

    local function failedCallBack(errorCode, errorData)
        httpSender:release()
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect(false, false, {errorCode = errorCode, errorMsg = errorData})
    end

    local data = GameProto_pb.GameGlobalConfigRequest()
    data.udid = udid
    data.res = ""

    local _platformType = self.PlatFormType
    if _platformType == 1 then
        data.platform = "Android"
    elseif _platformType == 2 then
        data.platform = "iOS"
    elseif _platformType == 3 then
        data.platform = "Amazon"
    end
    
    local _platform = device.platform
    if _platform == "mac" then
        data.version = "1.1.1"
    else
        data.version = util_getAppVersionCode() or ""
    end

    local bodyData = data:SerializeToString()
    local url = DATA_SEND_URL .. RUI_INFO.RECOVER_DELETE_ACCOUNT
    local serverTime = xcyy.SlotsUtil:getMilliSeconds()
    httpSender:sendLoginMessage(bodyData, url, serverTime, successCallBack, failedCallBack)
end

return NetWorkLogon

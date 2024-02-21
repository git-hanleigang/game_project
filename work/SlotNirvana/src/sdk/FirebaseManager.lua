--[[
	Fire Base 管理类
]]
-- FIX IOS 139
local FirebaseManager = class("AdjustManager")

FirebaseManager.m_instance = nil

--FireBase打点key 必须写到这里
GD.FireBaseLogType = {
    -- 安装/更新app后第一次启动
    custom_first_open = "custom_first_open",
    --点击钱袋子视频
    bag_ads_click_times = "bag_ads_click_times",
    --钱袋子视频成功播放
    bag_ads_playfinish_times = "bag_ads_playfinish_times",
    --轮盘视频出现
    wheel_ads_trigger_times = "wheel_ads_trigger_times",
    --轮盘视频点击次数
    wheel_ads_click_times = "wheel_ads_click_times",
    --轮盘视频成功播放
    wheel_ads_playfinish_times = "wheel_ads_playfinish_times",
    --触发luckyvideo
    luckyvideo_trigger_times = "luckyvideo_trigger_times",
    --点击观看luckyVideo
    luckyvideo_click_times = "luckyvideo_click_times",
    --luckyvideo播放成功
    luckyvideo_playfinish_times = "luckyvideo_playfinish_times",
    --点击关卡界面钱袋子
    themebag_ads_click_times = "themebag_ads_click_times",
    --关卡界面钱袋子播放成功
    themebag_ads_playfinish_times = "themebag_ads_playfinish_times",
    --点击购买单无购买弹出视频
    aftersales_trigger_times = "aftersales_trigger_times",
    --点击观看
    aftersales_click_times = "aftersales_click_times",
    --完成
    aftersales_playfinish_times = "aftersales_playfinish_times",
    --后台返回游戏
    returnads_trigger_times = "returnads_trigger_times",
    --
    returnads_click_times = "returnads_click_times",
    --
    returnads_playfinish_times = "returnads_playfinish_times",
    --关卡返回游戏
    themereturn_trigger_times = "themereturn_trigger_times",
    --
    themereturn_click_times = "themereturn_click_times",
    --
    themereturn_playfinish_times = "themereturn_playfinish_times",
    --每次登陆app弹出的激励视频
    login_trigger_times = "login_trigger_times",
    --
    login_click_times = "login_click_times",
    --
    login_playfinish_times = "login_playfinish_times",
    --银库加速
    vault_trigger_times = "vault_trigger_times",
    vault_click_times = "vault_click_times",
    vault_playfinish_times = "vault_playfinish_times",
    --每日任务加倍
    mission_trigger_times = "mission_trigger_times",
    mission_click_times = "mission_click_times",
    -- (csc 2020.10.27 好像没用到,只是用来记录)
    mission_playfinish_times = "mission_playfinish_times",
    InboxReward_trigger_times = "InboxReward_trigger_times",
    InboxReward_click_times = "InboxReward_click_times",
    InboxReward_playfinish_times = "InboxReward_playfinish_times",
    CloseSale_trigger_times = "CloseSale_trigger_times",
    CloseSale_click_times = "CloseSale_click_times",
    CloseSale_playfinish_times = "CloseSale_playfinish_times",
    NoCoinsToSpinDouble_trigger_times = "NoCoinsToSpinDouble_trigger_times", --破产翻倍广告场景出现
    NoCoinsToSpinDouble_click_times = "NoCoinsToSpinDouble_click_times", --用户点击破产翻倍广告
    --破产翻倍广告观看成功
    NoCoinsToSpinDouble_playfinish_times = "NoCoinsToSpinDouble_playfinish_times",
    InboxFreeSpin_trigger_times = "InboxFreeSpin_trigger_times", --inbox内送freespin广告出现
    InboxFreeSpin_click_times = "InboxFreeSpin_click_times", --点击inbox内送freespin
    InboxFreeSpin_playfinish_times = "InboxFreeSpin_playfinish_times", --inbox内送freespin广告观看成功
    --插屏  (csc 2020.10.27 好像没用到,只是用来记录)
    lobby_interstitial_appearing_times = "lobby_interstitial_appearing_times",
    lobby_interstitial_actual_times = "lobby_interstitial_actual_times",
    lobby_interstitial_click_times = "lobby_interstitial_click_times",
    login_interstitial_appearing_times = "login_interstitial_appearing_times",
    login_interstitial_actual_times = "login_interstitial_actual_times",
    login_interstitial_click_times = "login_interstitial_click_times",
    freespin_interstitial_appearing_times = "freespin_interstitial_appearing_times",
    freespin_interstitial_actual_times = "freespin_interstitial_actual_times",
    freespin_interstitial_click_times = "freespin_interstitial_click_times",
    BigWinClose_interstitial_appearing_times = "BigWinClose_interstitial_appearing_times",
    BigWinClose_interstitial_actual_times = "BigWinClose_interstitial_actual_times",
    BigWinClose_interstitial_click_times = "BigWinClose_interstitial_click_times",
    LevelUp_interstitial_appearing_times = "LevelUp_interstitial_appearing_times",
    LevelUp_interstitial_actual_times = "LevelUp_interstitial_actual_times",
    LevelUp_interstitial_click_times = "LevelUp_interstitial_click_times",
    CloseInbox_interstitial_appearing_times = "CloseInbox_interstitial_appearing_times",
    CloseInbox_interstitial_actual_times = "CloseInbox_interstitial_actual_times",
    CloseInbox_interstitial_click_times = "CloseInbox_interstitial_click_times",
    all_interstitial_appearing_times = "all_interstitial_appearing_times",
    all_interstitial_actual_times = "all_interstitial_actual_times",
    all_interstitial_click_times = "all_interstitial_click_times",
    return_interstitial_appearing_times = "return_interstitial_appearing_times",
    return_interstitial_actual_times = "return_interstitial_actual_times",
    return_interstitial_click_times = "return_interstitial_click_times",
    --次数统计
    return_appearing_times = "return_appearing_times",
    lobby_appearing_times = "lobby_appearing_times",
    login_appearing_times = "login_appearing_times",
    freespin_appearing_times = "freespin_appearing_times",
    all_reward_click_times = "all_reward_click_times",
    all_reward_actual_times = "all_reward_actual_times",
    all_ads_actual_times = "all_ads_actual_times",
    all_ads_click_times = "all_ads_click_times",
    --玩家主动点击进入商城
    click_shop = "click_shop",
    --玩家主动点击小猪
    click_pig = "click_pig",
    --玩家点击常规促销
    click_NormalSale = "click_NormalSale",
    --玩家主动点击hot today
    click_HotToday = "click_HotToday",
    --玩家点击进入关卡
    click_theme = "click_theme",
    --玩家主动点击进入cash bonus
    click_CashBonus = "click_CashBonus",
    --玩家主动点击进入每日任务
    click_DailyQuest = "click_DailyQuest",
    --玩家点击任意付费点购买按钮
    click_buy = "click_buy",
    --玩家主动点击收件箱
    click_inbox = "click_inbox",
    --玩家主动点击进入VIP
    click_vip = "click_vip",
    --领取商城免费金币
    Free_ShopGift = "Free_ShopGift",
    --领取CASH_BONUS银库
    Free_CashBonusSliver = "Free_CashBonusSliver",
    --领取CASH_BONUS金库
    Free_CashBonusGold = "Free_CashBonusGold",
    --进行MEGA VAULT游戏
    Free_MefaVault = "Free_MefaVault",
    --进行每日转盘奖励
    Free_Wheel = "Free_Wheel",
    --领取每日任务奖励1
    Free_dailyquest_1 = "Free_dailyquest_1",
    --领取每日任务奖励2
    Free_dailyquest_2 = "Free_dailyquest_2",
    --领取每日任务奖励3
    Free_dailyquest_3 = "Free_dailyquest_3",
    --领取INBOX免费金币
    Free_inbox = "Free_inbox",
    --成功购买商城
    purchase_shop = "purchase_shop",
    --成功购买付费轮盘
    purchase_wheel = "purchase_wheel",
    --成功购买小猪
    purchase_pig = "purchase_pig",
    --成功购买BOOST
    purchase_boost = "purchase_boost",
    --成功购买常规促销
    purchase_NomalSale = "purchase_NomalSale",
    --成功购买没钱促销
    purchase_NoCoinSale = "purchase_NoCoinSale",
    --成功购买多档促销
    purchase_ChoiceSale = "purchase_ChoiceSale",
    --成功购买Lucky Spin
    purchase_LuckySpin = "purchase_LuckySpin",
    --成功购买连续充值
    purchase_ComboSale = "purchase_ComboSale",
    --成功购买bingo促销
    purchase_BingoSale = "purchase_BingoSale",
    --成功购买find促销
    purchase_FindSale = "purchase_FindSale",
    --成功购买quest促销
    purchase_QuestSale = "purchase_QuestSale",
    --成功购买大富翁促销
    purchase_RichManSale = "purchase_RichManSale",
    --玩家支付失败事件
    purchase_failed = "purchase_failed",
    --登陆游戏（firebase的SDK自带）事件
    Login = "Login",
    --绑定FB事件
    BindFB = "BindFB",
    --玩家付费事件（SDK自带）
    Spend = "Spend",
    --下载关卡事件
    GameDownload = "GameDownload",
    --进入关卡事件
    EnterTheme = "EnterTheme",
    --玩家升级事件
    Levelup = "Levelup",
    --玩家触发特殊奖事件（Free、Bonus、Respin），50倍以上
    SpecialAward_50 = "SpecialAward_50",
    --玩家触发特殊奖事件（Free、Bonus、Respin），100倍以上
    SpecialAward_100 = "SpecialAward_100",
    --玩家触发特殊奖事件（Free、Bonus、Respin），200倍以上
    SpecialAward_200 = "SpecialAward_200",
    AdjustBetBig = "AdjustBetBig", --调大bet事件
    AdjustBetSmall = "AdjustBetSmall", --调小bet事件
    GenPoolEnd = "GenPoolEnd", --生成付费保护奖池事件
    NoCoins = "NoCoins", --Spin没钱事件
    spin_nomal = "spin_nomal", --spin后自动停止
    spin_auto = "spin_auto", --auto spin
    spin_stop = "spin_stop", --spin后手动停止
    Spartacus_Pop_Show = "Spartacus_Pop_Show", --新关弹窗弹出
    Spatacus_Pop_Click = "Spatacus_Pop_Click", --点击新关弹框
    --------------------------特殊打点-----------
    --欢迎弹板
    NewGuide_Welcome = "NewGuide_Welcome",
    --樱桃关卡指引
    NewGuide_CherryGuide = "NewGuide_CherryGuide",
    --paytable提示
    NewGuide_PayTableShow = "NewGuide_PayTableShow",
    --paytable点击
    NewGuide_PayTableClick = "NewGuide_PayTableClick",
    --spin提示第一次
    NewGuide_FirstSpinTip = "NewGuide_FirstSpinTip",
    --升到2级弹窗
    NewGuide_Level2 = "NewGuide_Level2",
    NewGuide_MAXBET = "NewGuide_MAXBET",
    NewGuide_NewGame = "NewGuide_NewGame",
    NewGuide_NormalSale = "NewGuide_NormalSale",
    --10次spin完成弹板
    NewGuide_FinishSpin10 = "NewGuide_FinishSpin10",
    --升到5级完成弹板
    NewGuide_Level5 = "NewGuide_Level5",
    --升级两次完成弹板
    NewGuide_LevelUpTwice = "NewGuide_LevelUpTwice",
    --每日任务解锁弹板
    NewGuide_DailyMissionUnlock = "NewGuide_DailyMissionUnlock",
    --升到10级完成弹板
    NewGuide_Level10 = "NewGuide_Level10",
    --升到15级完成弹板
    NewGuide_Level15 = "NewGuide_Level15",
    --集卡开放弹板
    NewGuide_CardOpen = "NewGuide_CardOpen",
    --跳转集卡点击
    NewGuide_JumpCard = "NewGuide_JumpCard",
    --link卡挑战弹板
    NewGuide_LinkChallenge = "NewGuide_LinkChallenge",
    --新手小猪折扣
    NewGuide_PigNewUser = "NewGuide_PigNewUser",
    --升到20级完成弹板
    NewGuide_Level20 = "NewGuide_Level20",
    --大厅有提示打开
    InboxLobbyTipOpen = "InboxLobbyTipOpen",
    --大厅没有提示打开
    InboxLobbyNotipOpen = "InboxLobbyNotipOpen",
    --关卡有提示打开
    InboxGameTipOpen = "InboxGameTipOpen",
    --关卡没有提示打开
    InboxGameNotipOpen = "InboxGameNotipOpen",
    --关卡没有提示打开
    CashBonusGuide = "CashBonusGuide",
    --关卡没有提示打开
    CashBonusGuideLobby = "CashBonusGuideLobby",
    --关卡没有提示打开
    CashBonusInterface = "CashBonusInterface",
    --关卡没有提示打开
    CashBonusInterfaceThreeHours = "CashBonusInterfaceThreeHours",
    --每日轮盘spin
    RouletteSpin = "RouletteSpin",
    --每日轮盘免费金币领取
    RouletteFreeCollect = "RouletteFreeCollect",
    --每日轮盘付费购买1
    RoulettePaymentOrder1 = "RoulettePaymentOrder1",
    --每日轮盘付费关闭1
    RoulettePaymentClose1 = "RoulettePaymentClose1",
    --每日轮盘付费购买2
    RoulettePaymentOrder2 = "RoulettePaymentOrder2",
    --每日轮盘付费关闭2
    RoulettePaymentClose2 = "RoulettePaymentClose2",
    Roulette_purchase_failed1 = "Roulette_purchase_failed1",
    Roulette_purchase_failed2 = "Roulette_purchase_failed2",
    --弹板1
    Popup1 = "Popup1",
    --弹板2
    Popup2 = "Popup2",
    --弹板3
    Popup3 = "Popup3",
    --弹板4
    Popup4 = "Popup4",
    --弹板5
    Popup5 = "Popup5",
    InboxMailClick = "InboxMailClick",
    InboxLobbyTipClick = "InboxLobbyTipClick",
    InboxLobbyNotipClick = "InboxLobbyNotipClick",
    InboxGameTipClick = "InboxGameTipClick",
    InboxGameNotipClick = "InboxGameNotipClick",
    --游戏推送打开
    PushGameOpen = "PushGameOpen",
    -- rate打点
    RatingLuckyorNot_1st = "RatingLuckyorNot_1st",
    RatingLuckyorNot_2nd = "RatingLuckyorNot_2nd",
    RatingLuckyorNot_3rd = "RatingLuckyorNot_3rd",
    Rating1star = "Rating1star",
    Rating2star = "Rating2star",
    Rating3star = "Rating3star",
    Rating4star = "Rating4star",
    Rating5star = "Rating5star",
    RatingSure = "RatingSure",
    --看广告的任务 领取任务档位 需要接档位
    AD_Challenge_Finish = "adchallenge_finish_",
    adbonuscoin_trigger_times = "adbonuscoin_trigger_times",
    adbonuscoin_click_times = "adbonuscoin_click_times",
    adbonuscoin_playfinish_times = "adbonuscoin_playfinish_times",
    LevelUp_trigger_times = "LevelUp_trigger_times",
    LevelUp_click_times = "LevelUp_click_times",
    LevelUp_playfinish_times = "LevelUp_playfinish_times",
    CardStoreCd_trigger_times = "CardStoreCd_trigger_times",
    CardStoreCd_click_times = "CardStoreCd_click_times",
    CardStoreCd_playfinish_times = "CardStoreCd_playfinish_times",
    HighLimitMergeGame_trigger_times = "HighLimitMergeGame_trigger_times",
    HighLimitMergeGame_click_times = "HighLimitMergeGame_click_times",
    HighLimitMergeGame_playfinish_times = "HighLimitMergeGame_playfinish_times"
}

function FirebaseManager:getInstance()
    if FirebaseManager.m_instance == nil then
        FirebaseManager.m_instance = FirebaseManager.new()
    end
    return FirebaseManager.m_instance
end

function FirebaseManager:ctor()
    -- 打点记录
    self.m_logFbase = {}
end

function FirebaseManager:addLog(type, key)
    local _date = os.date("*t", os.time())
    local _hms = string.format("%02d:%02d:%02d", _date.hour, _date.min, _date.sec)
    local _strLog = "[" .. _hms .. "] " .. type .. "->" .. key
    table.insert(self.m_logFbase, _strLog)
end

function FirebaseManager:getLog()
    return self.m_logFbase
end

function FirebaseManager:clearLog()
    self.m_logFbase = {}
end

function FirebaseManager:showLogLayer()
    if DEBUG ~= 2 then
        return
    end

    local fbaseLayer = gLobalViewManager:getViewByName("FirebaseTestLayer")
    if not fbaseLayer then
        fbaseLayer = util_createView("sdk.FirebaseTestLayer")
        fbaseLayer:setName("FirebaseTestLayer")
        gLobalViewManager:showUI(fbaseLayer, ViewZorder.ZORDER_NETWORK, false)
    end
end

-- 安装后第一次登录打点
function FirebaseManager:firstLaunchLog()
    if device.platform == "mac" then
        return
    end

    local _xcField = xcyy.XcyyField:getInstance()
    if _xcField then
        -- 保存的上一次打点整包版本号
        local lastLogVer = _xcField:getStringForKey("firstLaunchVer", "")
        -- 当前整包版本号
        local curSysVer = tostring(globalPlatformManager:getSystemVersion())
        if lastLogVer ~= curSysVer then
            -- 发送打点
            self:sendFireBaseLogDirect(FireBaseLogType.custom_first_open)
            xcyy.XcyyField:getInstance():setStringForKey("firstLaunchVer", curSysVer)
        end
    end
end

--[[
    @desc: 检测关卡内发送log
    time:2020-07-01 14:53:07
    @return:
]]
function FirebaseManager:checkFireBaseLog()
    if not globalData.slotRunData or not globalData.slotRunData.lastWinCoin then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = globalData.slotRunData.lastWinCoin / lTatolBetNum
    if winRatio >= 200 then
        if self.sendFireBaseLogDirect then
            self:sendFireBaseLogDirect(FireBaseLogType.SpecialAward_200)
        end
    elseif winRatio >= 100 then
        if self.sendFireBaseLogDirect then
            self:sendFireBaseLogDirect(FireBaseLogType.SpecialAward_100)
        end
    elseif winRatio >= 50 then
        if self.sendFireBaseLogDirect then
            self:sendFireBaseLogDirect(FireBaseLogType.SpecialAward_50)
        end
    end

    -- cxc 2021-12-09 10:51:22 去掉spin_normal、spin_auto、spin_stop这几个firebase打点
    -- if globalData.slotRunData.isClickQucikStop then
    --     if self.sendFireBaseLogDirect then
    -- 	    self:sendFireBaseLogDirect(FireBaseLogType.spin_stop)
    -- 	end
    -- else
    --     if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
    -- 	    if self.sendFireBaseLogDirect then
    -- 		    self:sendFireBaseLogDirect(FireBaseLogType.spin_auto)
    -- 	    end
    --     else
    -- 	    if self.sendFireBaseLogDirect then
    -- 		    self:sendFireBaseLogDirect(FireBaseLogType.spin_nomal)
    -- 	    end
    --     end
    -- end
end

--将后台打点信息传入firebase 1.data 后台log  2.msg 位置信息  3.status 状态信息 都可以配置为空
function FirebaseManager:checkSendFireBaseLog(data, msg, status)
    if not data then
        data = {taskOpenSite = "", adTaskStatus = ""}
    end
    if not msg then
        msg = ""
    end
    if not status then
        status = "trigger"
    end
    if data.taskOpenSite == PushViewPosType.DialyBonus then
        msg = "wheel_ads_"
    elseif data.taskOpenSite == PushViewPosType.CloseStore then
        msg = "aftersales_"
    elseif data.taskOpenSite == PushViewPosType.LoginToLobby then
        msg = "login_"
    elseif data.taskOpenSite == PushViewPosType.NoCoinsToSpin then
        msg = "luckyvideo_"
    elseif data.taskOpenSite == PushViewPosType.ReturnApp then
        msg = "returnads_"
    elseif data.taskOpenSite == PushViewPosType.LevelToLobby then
        msg = "themereturn_"
    elseif data.taskOpenSite == PushViewPosType.LobbyPos then
        msg = "bag_ads_"
    elseif data.taskOpenSite == PushViewPosType.GamePos then
        msg = "themebag_ads_"
    elseif data.taskOpenSite == PushViewPosType.VaultSpeedup then
        msg = "vault_"
    elseif data.taskOpenSite == PushViewPosType.DoubleMission then
        msg = "mission_"
    elseif data.taskOpenSite == PushViewPosType.BigMegaWinClose then
        msg = "BigWinClose_"
    elseif data.taskOpenSite == PushViewPosType.LevelUp then
        msg = "LevelUp_"
    elseif data.taskOpenSite == PushViewPosType.CloseInbox then
        msg = "CloseInbox_"
    elseif data.taskOpenSite == PushViewPosType.InboxReward then
        msg = "InboxReward_"
    elseif data.taskOpenSite == PushViewPosType.CloseSale then
        msg = "CloseSale_"
    elseif data.taskOpenSite == PushViewPosType.NoCoinsToSpinDouble then
        msg = "NoCoinsToSpinDouble_"
    elseif data.taskOpenSite == PushViewPosType.InboxFreeSpin then
        msg = "InboxFreeSpin_"
    elseif data.taskOpenSite == PushViewPosType.AdMission then
        msg = "adbonuscoin_"
    elseif data.taskOpenSite == PushViewPosType.CardStoreCd then
        msg = "CardStoreCd_"
    elseif data.taskOpenSite == PushViewPosType.HighLimitMergeGame then
        msg = "HighLimitMergeGame_"
    end

    if data.adTaskStatus == "Full" then
        status = "playfinish"
    end
    self:sendFireBaseLog(msg, status)
end

--firebase统计 后缀为_times的
function FirebaseManager:sendFireBaseLog(msg, status)
    local key = msg .. status .. "_times"
    if DEBUG == 2 then
        release_print("newMsg key = " .. key)
    end
    if not FireBaseLogType[key] then
        if DEBUG == 2 then
            release_print("not newMsg !!!")
        end
        return
    end
    --从key切换成实际值
    local newMsg = FireBaseLogType[key]
    self:sendBaseFirebaseLog(newMsg)
end

--发送firebase事件
function FirebaseManager:sendBaseFirebaseLog(eventKey, value)
    --是否可以发送打点日志
    if not CC_IS_PLATFORM_SENDLOG then
        return
    end

    if DEBUG == 2 then
        self:addLog("PriceEvent", eventKey .. " | " .. tostring(value))
    end

    value = tonumber(value)
    value = value or 0 --美金价值
    if value > 0 and util_isSupportVersion("1.3.7") then
        --新包添加有价值打点
        if device.platform == "android" then
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/XcyyUtil"
            local sig = "(Ljava/lang/String;F)V"
            local ok, ret = luaj.callStaticMethod(className, "fireBaseLogPriceEvent", {tostring(eventKey), value}, sig)
            if not ok then
                return false
            else
                return ret
            end
        elseif device.platform == "ios" then
            local ok, ret = luaCallOCStaticMethod("AppController", "fireBaseLogPriceEvent", {eventName = tostring(eventKey), eventValue = value})
            if not ok then
                return false
            else
                return ret
            end
        end
    else
        --无价值打点
        if device.platform == "android" then
            local luaj = require("cocos.cocos2d.luaj")
            local className = "org/cocos2dx/lua/XcyyUtil"
            local ok, ret = luaj.callStaticMethod(className, "fireBaseLogEvent", {tostring(eventKey)})
            if not ok then
                return false
            else
                return ret
            end
        elseif device.platform == "ios" then
            local ok, ret = luaCallOCStaticMethod("AppController", "fireBaseLogEvent", {eventName = tostring(eventKey)})
            if not ok then
                return false
            else
                return ret
            end
        end
    end
end

--firebase 测试 预测付费
function FirebaseManager:testFireBaseForecast(type, msgKey)
    --是否可以发送打点日志
    if not CC_IS_PLATFORM_SENDLOG then
        return
    end

    local msgType = "stringType"
    if type == 1 then
        msgType = "stringType"
    elseif type == 2 then
        msgType = "intType"
    elseif type == 3 then
        msgType = "boolType"
    end

    if DEBUG == 2 then
        release_print("testFireBaseForecast2 key = " .. msgKey)
        self:addLog("Forecast", msgType .. " | " .. msgKey)
    end

    if device.platform == "android" then
        local sig = "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"
        local ok, ret = luaj.callStaticMethod(className, "testFireBaseForecast", {msgType, msgKey}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "testFireBaseForecast", {eventType = msgType, eventKey = msgKey})
        if not ok then
            return ""
        else
            return ret
        end
    end

    if device.platform == "mac" then
        return "TestMac"
    end
end

--firebase统计  isInLogType -- true 必须在注册列表注册 false 不需要在注册列表
function FirebaseManager:sendFireBaseLogDirect(logKey, isInLogType)
    --是否可以发送打点日志
    if not CC_IS_PLATFORM_SENDLOG then
        return
    end
    if isInLogType == nil then
        isInLogType = true
    end
    if not logKey or logKey == "" then
        return
    end
    if DEBUG == 2 then
        release_print("newMsg key = " .. logKey)
    end
    if isInLogType then
        if not FireBaseLogType[logKey] then
            if DEBUG == 2 then
                release_print("not newMsg !!!")
            end
            return
        end
    end

    --从key切换成实际值
    local newMsg = logKey
    if isInLogType then
        newMsg = FireBaseLogType[logKey]
    end

    if DEBUG == 2 then
        self:addLog("logEvent", tostring(newMsg))
    end

    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"
        local ok, ret = luaj.callStaticMethod(className, "fireBaseLogEvent", {tostring(newMsg)})
        if not ok then
            return false
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "fireBaseLogEvent", {eventName = tostring(newMsg)})
        if not ok then
            return false
        else
            return ret
        end
    end

    if device.platform == "mac" then
    end
end

-- FireBase email转化测量
function FirebaseManager:setFireBaseCnvMeasEmail(email, isInLogType)
    --是否可以发送打点日志
    if not CC_IS_PLATFORM_SENDLOG then
        return
    end

    if not util_isSupportVersion("1.7.7", "mac") then
        return
    end

    if isInLogType == nil then
        isInLogType = true
    end

    local _saveEmail = gLobalDataManager:getStringByField("FIR_CNV_MEAS_EMAIL")

    if not email or email == "" or (email == _saveEmail) then
        return
    end

    if DEBUG == 2 then
        release_print("FIR email = " .. email)
    end

    if device.platform == "android" then
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "setFIRCnvMeasEmail", {email = tostring(email)})
        if not ok then
            return false
        else
            return ret
        end
    end

    if device.platform == "mac" then
    end

    gLobalDataManager:setStringByField("FIR_CNV_MEAS_EMAIL", email)
end

function FirebaseManager:sendFireBaseProperty()
    -- 历史充值总额|历史付费次数|平均付费金额|累计spin次数|平均bet
    self:setFireBaseUserProperty("udid", globalData.userRunData.userUdid)
    self:setFireBaseUserProperty("uid", globalData.userRunData.uid)
    self:setFireBaseUserProperty("coins", globalData.userRunData.coinNum)
    self:setFireBaseUserProperty("level", globalData.userRunData.levelNum)
    self:setFireBaseUserProperty("exp", globalData.userRunData.currLevelExper)
    self:setFireBaseUserProperty("vipLevel", globalData.userRunData.vipLevel)
    self:setFireBaseUserProperty("vipPoints", globalData.userRunData.vipPoints)
    self:setFireBaseUserProperty("createTime", globalData.userRunData.createTime)
    if globalData.userRunData.isFbLogin then
        self:setFireBaseUserProperty("loginType", "facebook")
    else
        self:setFireBaseUserProperty("loginType", "game")
    end

    self:setFireBaseUserProperty("abTest", globalData.userRunData.p_category)

    -- self:setFireBaseUserProperty("category",globalData.userRunData.uid)----用户群组	category	普通玩家=1，黑名单=9，白名单=0
    local extra = globalData.userRunData.loginUserData.extra
    if extra then
        local serverProper = util_string_split(extra, "|")
        if serverProper and serverProper[1] then
            self:setFireBaseUserProperty("TotalSpendAmount", serverProper[1])
        end
        if serverProper and serverProper[2] then
            self:setFireBaseUserProperty("TotalSpendTime", serverProper[2])
        end
        if serverProper and serverProper[3] then
            self:setFireBaseUserProperty("AvgSpendAmount", serverProper[3])
        end

        if serverProper and serverProper[4] then
            self:setFireBaseUserProperty("TotalSpinTimes", serverProper[4])
        --累计spin次数
        end
        if serverProper and serverProper[5] then
            self:setFireBaseUserProperty("AvgBet", serverProper[5])
        --累计spin次数
        end
    end
    -- self:setFireBaseUserProperty("TotalLoginTime",globalData.userRunData.uid) --历史登陆天数
    -- self:setFireBaseUserProperty("TotalRewardTime",globalData.userRunData.uid)--累积触发特殊奖次数
    -- self:setFireBaseUserProperty("LoginDaysContinus",globalData.userRunData.uid)--连续登陆天数
    -- self:setFireBaseUserProperty("NoLoginDaysContinus",globalData.userRunData.uid)--历史最长未登录天数
    -- self:setFireBaseUserProperty("DownloadTheme",globalData.userRunData.uid)--已下载关卡数
    -- self:setFireBaseUserProperty("GameTime",globalData.userRunData.p_serverTime)--游戏内时间
end

--firebase统计
function FirebaseManager:setFireBaseUserProperty(key, value)
    --是否可以发送打点日志
    if not CC_IS_PLATFORM_SENDLOG then
        return
    end
    if not key or not value then
        return
    end
    if DEBUG == 2 then
        release_print("FireBaseUserProperty key = " .. key .. "-value = " .. value)
        self:addLog("UserProperty", key .. " | " .. tostring(value))
    end

    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"
        local ok, ret = luaj.callStaticMethod(className, "setUserProperty", {key, tostring(value)})
        if not ok then
            return false
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "setUserPropertyString", {key = tostring(key), value = tostring(value)})
        if not ok then
            return false
        else
            return ret
        end
    end

    if device.platform == "mac" then
    end
end

--获得fcm token 单独给某个用户发后台推送使用
function FirebaseManager:getFireBaseToken()
    local token = globalPlatformManager:getPlatformInfo(globalPlatformManager.INFO_FIREBASE_TOKEN)
    return token
end

return FirebaseManager

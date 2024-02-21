---
-- logon 进入后启动游戏
-- 进入到这里后表明 已经检测完毕热更新了 ios fix 1
local GameStart = class("GameStart")
GameStart.m_instance = nil

GD.glActivityResVers = nil

globalData:initGameData()

-- GD.G_GetMgr(G_REF.Inbox) = require("manager.InboxManager"):getInstance()
GD.gLobalIAPManager = require("manager.IAPManager"):getInstance()
GD.gLobalSaleManager = require("manager.SaleManager"):getInstance()

GD.globalNotifyNodeManager = require("manager.NotifyManager"):getInstance()
GD.gLobalSysRewardManager = require("manager.SysRewardManager"):getInstance()

GD.globalNoviceGuideManager = require("manager.NoviceGuideManager"):getInstance()
GD.globalTestDataManager = require("manager.TestDataManager"):getInstance()

GD.globalNewbieTaskManager = require("manager.NewbieTaskManager"):getInstance()

GD.gLobalGameHeartBeatManager = require("manager.GameHeartBeatManager"):getInstance()

-- 全部初始化完毕了在初始化游戏内常量值
local DataConfig = require "data.DataConfig"
local SlotsConfig = require "data.slotsdata.SlotsConfig"

GD.gLobaLevelDLControl = util_require("common.LevelDLControl"):create()

-- 业务模块的导入
GD.globalMachineController = require("Levels.MachineController"):getInstance()
GD.gLobalDebugReelTimeManager = require("manager.DebugReelTimeManager"):getInstance()

-- 弹板模块
-- require("PopProgram.PushViewManager")
-- GD.PopUpManager = require("data.popUp.PopUpManager"):getInstance()
--弹框控制器
GD.gLobalPopViewManager = require("manager.PopViewManager"):getInstance()
GD.gLobalPushViewControl = require("common.PushViewControl"):getInstance()

-- 引导
GD.gGuideMgr = require("GameModule.Guide.GuideMgr"):getInstance()
--活动管理器
GD.gLobalActivityManager = require("common.ActivityManager"):getInstance()
util_require("common.ActivityManagerExSlotLeft")
util_require("common.ActivityManagerExSlotRight")
GD.gLobalBattlePassManager = require("manager.BattlePassManager"):getInstance()
GD.gLobalChristmasMTManager = require("manager.ChristmasMagicTourManager"):getInstance()
-- GD.gLobalMulLuckyStampManager = require("manager.System.MulLuckyStampManager"):getInstance() -- 多次盖戳
GD.gLobalItemManager = require("manager.ItemManager"):getInstance()
GD.gLobalDailyTaskManager = require("manager.System.DailyTaskManager"):getInstance()
GD.gLobalAdChallengeManager = require("manager.System.AdChallengeManager"):getInstance()

GD.gLobalLevelRushManager = require("manager.LevelRushManager"):getInstance()
GD.globalDeluxeManager = require("manager.Activity.ActivityDeluxeManager"):getInstance()
GD.gLobalMiniGameManager = require("manager.System.MiniGameManager"):getInstance()
GD.gLobalLanguageChangeManager = require("manager.Language.LanguageChangeManager"):getInstance()
GD.gLobalPlistMap = {}

require("GameInit.InitManage")

GameStart.m_enterBackground = nil --false

function GameStart:getInstance()
    -- body
    if GameStart.m_instance == nil then
        --todo
        GameStart.m_instance = GameStart.new()
    end

    return GameStart.m_instance
end

function GameStart:ctor()
end

function GameStart:initGame()
    globalDynamicDLControl:initDynamicConfigAddSearchPath()
    globalCardsDLControl:initCardsConfigAddSearchPath()
    self:initTime()
    self:initLevslsInfo()
    self:initFb()
    self:initCsvDatas()
    self:registerEvents()
end

function GameStart:initTime()
    globalData.userRunData:syncServerTime(xcyy.SlotsUtil:getMilliSeconds())
end

function GameStart:registerEvents()
    -- local customEventDispatch = cc.Director:getInstance():getEventDispatcher()
    -- customEventDispatch:removeCustomEventListeners("APP_ENTER_BACKGROUND_EVENT")
    -- local listenerCustomBackGround =
    --     cc.EventListenerCustom:create(
    --     "APP_ENTER_BACKGROUND_EVENT",
    --     function()
    --         release_print("--切换到后台--")
    --         self:commonBackGround()
    --         gLobalNoticManager:postNotification(ViewEventType.APP_ENTER_BACKGROUND_EVENT)
    --     end
    -- )
    -- customEventDispatch:addEventListenerWithFixedPriority(listenerCustomBackGround, 1)

    -- 切换到后台
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:commonBackGround()
        end,
        ViewEventType.APP_ENTER_BACKGROUND_EVENT
    )

    -- customEventDispatch:removeCustomEventListeners("APP_ENTER_FOREGROUND_EVENT")
    -- local listenerCustomForeGround =
    --     cc.EventListenerCustom:create(
    --     "APP_ENTER_FOREGROUND_EVENT",
    --     function()
    --         release_print("--切换到前台--")
    --         self:commonForeGround()
    --         gLobalNoticManager:postNotification(ViewEventType.APP_ENTER_FOREGROUND_EVENT)
    --     end
    -- )
    -- customEventDispatch:addEventListenerWithFixedPriority(listenerCustomForeGround, 1)
    --切换到前台
    gLobalNoticManager:addObserver(
        self,
        function()
            self:commonForeGround()
        end,
        ViewEventType.APP_ENTER_FOREGROUND_EVENT
    )
end

--通用进入后台方法
function GameStart:commonBackGround()
    local nowTime = os.time()
    gLobalDataManager:setNumberByField("CommonBackgroundTime", nowTime)
    self.m_enterBackground = true
    release_print("------commonBackGround---------")

    globalLocalPushManager:commonBackGround()
    gLobalMiniGameManager:commonBackGround()
    gLobalGameHeartBeatManager:commonBackGround()
    G_GetMgr(G_REF.OperateGuidePopup):saveGuideArchiveData()
    -- 音效管理器
    if gLobalSoundManager then
        gLobalSoundManager:setInBackstage(true)
    end

    local NetworkLog = util_require("network.NetworkLog")
    if NetworkLog ~= nil and NetworkLog.saveLogToFile ~= nil then
        NetworkLog.saveLogToFile()
    end
end
--通用进入前台方法
function GameStart:commonForeGround()
    globalPlatformManager:enterForegroundLogic()
    globalLocalPushManager:commonForeGround()
    gLobalMiniGameManager:commonForeGround()
    gLobalGameHeartBeatManager:commonForeGround()
    if G_GetMgr(ACTIVITY_REF.Zombie) then
        G_GetMgr(ACTIVITY_REF.Zombie):commonForeGround()
    end
    -- 音效管理器
    if gLobalSoundManager then
        gLobalSoundManager:setInBackstage(false)
    end

    gLobalNoticManager:postNotification(ViewEventType.COMMON_FORE_GROUND)

    release_print("------------------------------commonForeGround init")
    if gLobalAdsControl ~= nil and gLobalAdsControl.getPlayAdFlag ~= nil then
        if gLobalAdsControl:getPlayAdFlag() then
            release_print("------------------------------commonForeGround pauseAudio")
            -- gLobalAdsControl:setPlayAdType(nil)--不知道因为bug是否是这里
            ccexp.AudioEngine:pauseAll()
        end
    end
    release_print("------------------------------commonForeGround enter")
    if not self.m_enterBackground then
        return
    end
    self.m_enterBackground = nil

    if not globalData.skipForeGround then
        globalFireBaseManager:sendFireBaseLog("return_", "appearing")
    end

    release_print("------------------------------commonForeGround time")

    local nowTime = os.time()
    local lastTime = gLobalDataManager:getNumberByField("CommonBackgroundTime", nowTime)
    gLobalDataManager:setNumberByField("CommonBackgroundTime", nowTime)
    if (nowTime - lastTime) >= RESET_GAME_TIME then
        --不是因为广告 邮件等操作进入后台
        if not globalData.skipForeGround then
            -- util_restartGame()
            return
        end
    end

    util_nextFrameFunc(
        function()
            local platform = device.platform
            if platform == "ios" then
                gLobalNoticManager:postNotification(
                    ViewEventType.NOTIFY_CHECK_FBLINK_REWARD,
                    function()
                        release_print("------------------------------commonForeGround fblink")
                        globalLocalPushManager:readNotifyRewardData()
                    end
                )
            elseif platform == "android" then
                -- 1.5.8的版本支持全局函数调用
                if not util_isSupportVersion("1.5.8") then
                    gLobalNoticManager:postNotification(
                        ViewEventType.NOTIFY_CHECK_FBLINK_REWARD,
                        function()
                            release_print("------------------------------commonForeGround fblink")
                            globalLocalPushManager:readNotifyRewardData()
                        end
                    )
                end
            end
            -- 检测付费异常状态
            if gLobalIAPManager ~= nil then
                gLobalIAPManager:checkSdkCallback()
            end
        end,
        0.1
    )

    -- 检测当前是否应该弹出工会界面
    util_nextFrameFunc(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHECK_FBLINK_CLANID)
            --监听解析代码,后续移到工会 manager上进行监听解析读取
            globalPlatformManager:parseFacebookShareClanId()
            globalPlatformManager:parseCommonLink()
        end,
        0.1
    )

    release_print("------------------------------commonForeGround ads")
    --如果处于暂停中不弹广告
    if globalData.slotRunData.gameRunPause then
        return
    end

    release_print("------------------------------commonForeGround check")
    --是否尝试播放广告
    if not globalData.skipForeGround and globalData.adsRunData.p_isNull == false and globalData.adsRunData.p_haveCashBonusWheel == false then
        gLobalSendDataManager:getLogAds():createPaySessionId()
        gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.ReturnApp)
        gLobalSendDataManager:getLogAds():setOpenType("PushOpen")

        gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.ReturnApp)

        util_afterDrawCallBack(
            function()
                --如果有插屏广告优先播放
                if globalData.adsRunData:isPlayAutoForPos(PushViewPosType.ReturnApp, nil, true) then
                    release_print("------------------------------commonForeGround check auto")
                    gLobalSendDataManager:getLogAdvertisement():setOpenType("InterstitialPush")
                    gLobalAdsControl:playAutoAds(PushViewPosType.ReturnApp)
                elseif globalData.adsRunData:isPlayRewardForPos(PushViewPosType.ReturnApp, nil, true) 
                        and not gLobalPushViewControl:isPushingView()
                        and not gLobalViewManager:getHasShowUI()
                        and (gLobalViewManager:isLevelView() or gLobalViewManager:isLobbyView()) then -- 当前没有弹窗的情况下才能弹出
                    release_print("------------------------------commonForeGround check vedio")
                    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
                    gLobalAdsControl:playVideo(AdsRewardDialogType.Normal, PushViewPosType.ReturnApp)
                end
            end
        )
    else
        --进入前台还原状态
        globalData.skipForeGround = nil
        release_print("------------------------------commonForeGround check clear")
    end
    release_print("------------------------------commonForeGround check end")
end

function GameStart:initCsvDatas()
    self:parseNotify()
    self:parseLevelUp()
end

function GameStart:initLevslsInfo(_bDealLevelOrder, _groupType, _firstGame)
    local levelsInfo = globalData.GameConfig.levelsData
    globalData.slotRunData:parseLevelConfigs(levelsInfo["levels"], levelsInfo["config"])

    -- 删除Dynamic文件夹下的关卡静态资源图
    local headKey = {"deluxe", "small"}
    local tbDelPng = {
        "_level_GameScreenMrCash.png",
        "_level_GameScreenMrCashGo.png",
        "_level_GameScreenMrJokerCash.png"
    }
    local isDeled = false
    for k = 1, #headKey do
        for i = 1, #tbDelPng do
            local path = "newIcons/Order/" .. headKey[k] .. "/".. headKey[k] .. tbDelPng[i]
            local fullpath = cc.FileUtils:getInstance():fullPathForFilename(path) or ""
            -- print("levelFullpath" .. tostring(fullpath))
            if fullpath ~= "" then
                local st, ed = string.find(fullpath, "Dynamic/")
                if st then
                    cc.FileUtils:getInstance():removeFile(fullpath)
                    isDeled = true
                end
            end
        end
    end
    if isDeled then
        cc.FileUtils:getInstance():purgeCachedEntries()
    end
end

--[[
    @desc: 调整新手期ABTest下关卡排序
    --@_levelsInfo: level配置文件
	--@_groupType: 当前 ABTest 第几版
    cxc:
    第二期 NoviceGroup_C 下 
    -- C组 2021年07月28日20:22:54   玩家 GameScreenCharms 和 GameScreenClassicRapid2 关卡掉个个
    csc：
    @return:
]]
-- function GameStart:preDealLevelsData(_levelsInfo, _groupType, _firstGame)
--     -- csc 2021-08-25 配置一下当前组别对应的关卡排序
--     -- 组别 关卡 排序
--     local groupConfig = {
--         ["NoviceGroup_C"] = {
--             [1] = {levelName = "GameScreenCharms", showOrder = 3},
--             [2] = {levelName = "GameScreenClassicRapid2", showOrder = 1}
--         },
--         ["Season_3"] = {
--             [1] = {levelName = "GameScreenReelRocks", showOrder = 1},
--             [2] = {levelName = "GameScreenCharms", showOrder = 3},
--             [3] = {levelName = "GameScreenClassicRapid2", showOrder = 92}
--         },
--         ["Season_4"] = {
--             -- 4.0 开始不再使用老字段,4.0之后的新关排序只需要修改下面的 A B C 分组
--             ["A"] = {
--                 -- 矮人金矿 跟 第一关 淘金 互换位置
--                 [1] = {levelName = "GameScreenReelRocks", showOrder = 1},
--                 [2] = {levelName = "GameScreenCharms", showOrder = 92}
--             },
--             ["B"] = {
--                 -- 正常淘金第一关
--                 [1] = {levelName = "GameScreenCharms", showOrder = 1}
--             },
--             ["C"] = {
--                 -- 推币机 跟 第一关 淘金 互换位置
--                 [1] = {levelName = "GameScreenEaster", showOrder = 1},
--                 [2] = {levelName = "GameScreenCharms", showOrder = 14}
--             }
--         }
--     }
--     -- 写一个默认值
--     local groupType = _groupType or "NoviceGroup_C"
--     local currConfig = groupConfig[groupType]
--     if _firstGame then -- 如果当前采用了新的分组模式
--         currConfig = currConfig[_firstGame] -- 根据分组模式再取到正确的数值
--     end

--     -- csc 更新新的关卡ABTest 排序写法
--     local levels = _levelsInfo["levels"]
--     local dealCount = 0
--     for i = 1, #levels do
--         local levelData = levels[i]
--         for j = 1, #currConfig do
--             local configData = currConfig[j]
--             if levelData.levelName == configData.levelName then
--                 levelData.showOrder = configData.showOrder
--                 dealCount = dealCount + 1
--             end
--         end
--         if dealCount >= #currConfig then
--             break
--         end
--     end
-- end

function GameStart:parseNotify()
    local content = gLobalResManager:parseCsvDataByName("Csv/name.csv")
    globalNotifyNodeManager:parseData(content)
end

function GameStart:parseLevelUp()
    local content = util_checkJsonDecode("Csv/LevelUpPopupConfig.json")
    if content then
        globalData.userRunData:parseRewardOrderData(content)
    end
end

function GameStart:initFb()
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" then
        supportVersion = "1.6.6"
    elseif platform == "android" then
        supportVersion = "1.5.8"
    end

    if supportVersion ~= nil and util_isSupportVersion(supportVersion) then
    else
        xcyy.HandlerIF:registerFbCallFun(
            function(isLoginStatus) -- 登录
                printInfo("xcyy : Fb 登录 ")
                gLobalNoticManager:postNotification(GlobalEvent.FB_LoginStatus, isLoginStatus)
            end,
            function(isLogoutStatus) -- 登出
                gLobalNoticManager:postNotification(GlobalEvent.FB_LogoutStatus, isLogoutStatus)
            end
        )
    end

    xcyy.HandlerIF:registerIAPCallFun(
        function(buyType, isSuccess, sdkCode) -- 购买类型，  是否成功
            if DEBUG == 2 then
                if sdkCode then
                    print("sdkCode = " .. sdkCode)
                    release_print("sdkCode = " .. sdkCode)
                end
            end
            gLobalNoticManager:postNotification(GlobalEvent.IAP_BuyResult, {buyType, isSuccess, sdkCode})
        end,
        function(isSuccess, sdkCode) -- 是否成功
            gLobalNoticManager:postNotification(GlobalEvent.IAP_ConsumeResult, {isSuccess, sdkCode})
        end
    )
end
--
-- 进入游戏
--
function GameStart:gotoGame()
    -- globalDynamicDLControl:initDynamicConfigAddSearchPath()
    -- globalCardsDLControl:initCardsConfigAddSearchPath()
    gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
    gLobalSendDataManager:getLogGameLoad():sendNewLog(13)
    globalLocalPushManager:gotoGame()
end

return GameStart

local AdsControl = class("AdsControl")
local ShopItem = util_require("data.baseDatas.ShopItem")
-- FIX IOS 139
function AdsControl:ctor()
    self.m_attBigWinData = {}
    self.m_attBigWinData["spinTimes"] = gLobalDataManager:getNumberByField("checkATTrackingBigWinSpinTimes", 0)
    self.m_isAgainRequest = nil
    --激励视频加载标志
    self.rewardLoadFlag = self:getRewardVideoStatus()
end
--关闭广告回调
function AdsControl:closeAdsCallback()
    print("closeAdsCallback")
    gLobalViewManager:removeLoadingAnima()
    self:removeAdTimerHandler()
    gLobalNoticManager:postNotification("ads_vedio")
    if not globalData.adsRunData then
        return
    end
    local adsInfo = globalData.adsRunData:getCurrAdsInfo()
    if not adsInfo or not adsInfo.p_position then
        return
    end
    if not self.m_strSuccess or self.m_strSuccess ~= "success" and self.m_strSuccess ~= "fail" then
        if adsInfo.p_position == PushViewPosType.DoubleMission then
        end
    end
end

-- 阻止广告弹出的情况 目前只有bingo比赛需要阻止广告弹出
function AdsControl:checkIsForbid(type, position)
    if not type or not position then
        return false
    end
    if type == AdsRewardDialogType.Reward and position == PushViewPosType.ReturnApp then
        if gLobalViewManager:getViewByExtendData("BingoRushHallUI") then
            return true
        elseif gLobalViewManager:getViewByExtendData("BingoRushLevelUI") then
            return true
        elseif gLobalViewManager:getViewByExtendData("BingoRushMatchUI") then
            return true
        elseif gLobalViewManager:getViewByExtendData("BingoRushLoadingUI") then
            return true
        end
    end
    return false
end

--弹出播放广告UI
function AdsControl:playVideo(type, position)
    if gLobalViewManager:getViewByExtendData("AdsRewardLayer") == nil then
        local curAdsInfo = globalData.adsRunData:getAdsInfoForPos(position)
        if curAdsInfo ~= nil then
            local playCfgTimes = curAdsInfo.p_playTimes or -1
            local playTimes = gLobalAdsControl:getADSWacthTime()
            if playCfgTimes == -1 or playTimes < playCfgTimes then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADSTASK_FORCE_CLOSE)
                self:showAdsRewardLayer(type, position)
            else
                --弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "configPushAds")
            end
        else
            --弹窗逻辑执行下一个事件
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "configPushAds")
        end
    end
end

function AdsControl:showAdsRewardLayer(_type, _position)
    local okFunc = function()
        gLobalViewManager:addLoadingAnima()
        self:playRewardVideo(_position)
    end
    local closeFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "configPushAds")
        --弹窗逻辑执行下一个事件
    end

    local popLayerName = "views.dialogs.AdsRewardLayer"
    --csc 2021-12-14 需要check 当前点位是否要弹出另外的板子
    if _position == PushViewPosType.NoCoinsToSpin then
        popLayerName = "views.dialogs.AdsBrokenLayer"
    end
    local view = util_createView(popLayerName, _type, _position, okFunc, closeFunc)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
    -- 激励视频展示时一定要记录
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = _position})
end
---
-- MoPub 广告

function AdsControl:adjustEventTrack(eventID, data)
    --是否可以发送打点日志
    if not CC_IS_PLATFORM_SENDLOG then
        return
    end
    eventID = tostring(eventID)
    data = tostring(data)
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "JniAdjustEventTrack", {eventID, data})
        if not ok then
            return false
        else
            return ret
        end
    end

    if device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "JniAdjustEventTrack", {eventID = eventID, data = data})
        if not ok then
            return false
        else
            return ret
        end
    end

    if device.platform == "mac" then
    end
end

-- 设置广告SDK userID
function AdsControl:sendUserIdToAds(uid, isAdsDebug)
    if DEBUG ~= 0 and (not isAdsDebug) then
        return
    end

    uid = tostring(uid)
    if util_isSupportVersion("1.8.0", "android") then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local sig = "(Ljava/lang/String;)V"
        local ok, ret = luaj.callStaticMethod(className, "jniSendUserIdToAds", {uid}, sig)
        if not ok then
            return false
        else
            return ret
        end
    end

    if util_isSupportVersion("1.8.5", "ios") then
        local ok, ret = luaCallOCStaticMethod("AppController", "sendUserIdToAds", {UID = uid})
        if not ok then
            return false
        else
            return ret
        end
    end
end

-- 判断是否适用GDPR的地区
function AdsControl:isUserGDPR()
    if device.platform == "mac" then
        return true
    end

    if util_isSupportVersion("1.8.2", "android") then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local sig = "()Z"
        local ok, ret = luaj.callStaticMethod(className, "getIsUserGDPR", {}, sig)
        if not ok then
            return false
        else
            return ret
        end
    end

    if util_isSupportVersion("1.8.7", "ios") then
        local ok, ret = luaCallOCStaticMethod("AppController", "getIsUserGDPR", {})
        if not ok then
            return false
        else
            return ret
        end
    end
    return false
end

-- 重新check GDRP选择
function AdsControl:checkConsentFlow()
    if util_isSupportVersion("1.8.1", "android") then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "checkConsentFlow", {})
        if not ok then
            return false
        else
            return ret
        end
    end

    if util_isSupportVersion("1.8.6", "ios") then
        local ok, ret = luaCallOCStaticMethod("AppController", "checkConsentFlow", {})
        if not ok then
            return false
        else
            return ret
        end
    end
end

--调用加载广告逻辑
function AdsControl:playRewardVideo(position, logPosition)
    self.m_strSuccess = nil
    globalData.adsRunData:setCurrAdsInfo(position)
    if logPosition then
        gLobalSendDataManager:getLogAds():setOpenSite(logPosition)
        gLobalSendDataManager:getLogAdvertisement():setOpenSite(logPosition, true)
        gLobalSendDataManager:getLogAdvertisement():setStatus(nil)
        gLobalSendDataManager:getLogAdvertisement():setrewardCoins(nil)
    else
        gLobalSendDataManager:getLogAds():setOpenSite(position)
        gLobalSendDataManager:getLogAdvertisement():setOpenSite(position, true)
    end
    gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
    gLobalSendDataManager:getLogAdvertisement():setadStatus("Start")
    gLobalSendDataManager:getLogAdvertisement():setadType("Broadcast")
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()

    globalData.skipForeGround = true
    release_print("------------------------------displayMediationRewardVideo")
    xcyy.GameBridgeLua:displayMediationRewardVideo()
    globalAdjustManager:sendAdjustKey("showalladstime")
    scheduler.performWithDelayGlobal(
        function()
            gLobalViewManager:removeLoadingAnima()
            self.rewardLoadFlag = self:getRewardVideoStatus()
        end,
        5
    )
    self:createAdTimerHandler("rewardAd", nil)
    local curAdsInfo = globalData.adsRunData:getAdsInfoForPos(position)
    if curAdsInfo ~= nil then
        local playCfgTimes = curAdsInfo.p_playTimes or -1
        if playCfgTimes ~= -1 then
            self:addADSWacthTime()
        end
    end

    if device.platform == "mac" then
        self:rewardVideoCallback("success")
    end
end
--获取插屏视频
function AdsControl:getVideoStatus()
    if device.platform == "mac" then
        return true
    elseif device.platform == "ios" then
        return xcyy.GameBridgeLua:getMediationVideoStatus()
    else
        release_print("------------------------------getVideoStatus")
        return xcyy.GameBridgeLua:getMediationVideoStatus()
    end
end
--获得激励视频
function AdsControl:getRewardVideoStatus()
    if device.platform == "mac" then
        return true
    else
        return xcyy.GameBridgeLua:getMediationRewardVideoStatus()
    end
end

function AdsControl:getRewardLoadFlag()
    local platform = device.platform
    if platform == "android" then
        return self.rewardLoadFlag
    else
        return self:getRewardVideoStatus()
    end
end

function AdsControl:removeAdTimerHandler()
    self:setPlayAdType(nil)
    if self.adTimerHander ~= nil then
        scheduler.unscheduleGlobal(self.adTimerHander)
        self.adTimerHander = nil
    end
end

function AdsControl:createAdTimerHandler(adType, time)
    self:removeAdTimerHandler()
    self:setPlayAdType(adType)
    self.adTimerHander =
        scheduler.scheduleGlobal(
        function()
            self:removeAdTimerHandler()
        end,
        time or 60
    )
end

function AdsControl:playAutoAds(position)
    self.m_strSuccess = nil
    globalData.adsRunData:setCurrAdsInfo(position, true)
    gLobalSendDataManager:getLogAds():setOpenSite(position)

    gLobalSendDataManager:getLogAdvertisement():setOpenSite(position, true)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("InterstitialPush")
    gLobalSendDataManager:getLogAdvertisement():setType("Interstitial")
    gLobalSendDataManager:getLogAdvertisement():setadType("Push")

    local function playAd()
        local posInfo = globalData.adsRunData:getCurrAutoAdsPos()
        if posInfo ~= nil then
            globalFireBaseManager:sendFireBaseLog(posInfo, "appearing")
        -- globalFireBaseManager:sendFireBaseLog(posInfo, "actual")
        end
        globalFireBaseManager:sendFireBaseLog("all_interstitial_", "appearing")
        globalData.skipForeGround = true
        release_print("------------------------------displayMediationAds")
        xcyy.GameBridgeLua:displayMediationAds()
        local adsInfo = globalData.adsRunData:getCurrAdsInfo()
        if adsInfo then
            -- adsInfo.p_showTime = os.time() + adsInfo.p_cdTime
            globalData.adsRunData:updateAutoAdsShowTime(adsInfo.p_position, os.time() + adsInfo.p_cdTime)
            -- self.m_iterstitialCDTime  = os.time() + adsInfo.p_cdTime
            -- 公用cd时间改为 统一值
            self.m_iterstitialCDTime = os.time() + globalData.adsRunData:getPublicAdsCD()
        end
        self:createAdTimerHandler("autoAd", nil)
    end
    if self:getVideoStatus() then
        gLobalSendDataManager:getLogAdvertisement():setStatus("Success")
        -- self:addTodayPlayAdTimes()
        self:addOnePosTodayPlayAdTimes(position)
        playAd()
    else
        gLobalSendDataManager:getLogAdvertisement():setStatus("Fail")
        self:removeAdTimerHandler()
    end
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
end

function AdsControl:getTodayPlayAdTimes()
    if self.m_playAdTimes and self.m_playAdTimes >= 3 then
        return 100
    else
        local playAdTimes = gLobalDataManager:getStringByField("AdsControl_PlayAdTimes", "") --self:getSeverDateStr()
        if playAdTimes == "" then
            self.m_playAdTimes = 0
            return 0
        else
            local todayDate = self:getSeverDateStr()
            local playAdList = util_split(playAdTimes, "_")
            if playAdList and #playAdList == 2 then
                local writeDownDate = playAdList[1]
                if writeDownDate and writeDownDate == todayDate then
                    local cout = playAdList[2] or "0"
                    self.m_playAdTimes = tonumber(cout)
                    return self.m_playAdTimes
                else
                    self.m_playAdTimes = 0
                    gLobalDataManager:setStringByField("AdsControl_PlayAdTimes", todayDate .. "_" .. self.m_playAdTimes)
                    return 0
                end
            else
                self.m_playAdTimes = 0
                gLobalDataManager:setStringByField("AdsControl_PlayAdTimes", todayDate .. "_" .. self.m_playAdTimes)
                return 0
            end
        end
    end
end

function AdsControl:addTodayPlayAdTimes()
    if self.m_playAdTimes and self.m_playAdTimes >= 3 then
        return
    else
        if self.m_playAdTimes == nil then
            self.m_playAdTimes = self:getTodayPlayAdTimes()
        end
        self.m_playAdTimes = self.m_playAdTimes + 1
        local todayDate = self:getSeverDateStr()
        gLobalDataManager:setStringByField("AdsControl_PlayAdTimes", todayDate .. "_" .. self.m_playAdTimes)
    end
end

function AdsControl:getOnePosTodayPlayAdTimes(pos)
    local playAdTimes = gLobalDataManager:getStringByField("AdsControl_PlayAdTimes" .. pos, "") --self:getSeverDateStr()
    if playAdTimes == "" then
        return 0
    else
        local todayDate = self:getSeverDateStr()
        local playAdList = util_split(playAdTimes, "_")
        if playAdList and #playAdList == 2 then
            local writeDownDate = playAdList[1]
            if writeDownDate and writeDownDate == todayDate then
                local cout = playAdList[2] or "0"
                local playTime = tonumber(cout)
                return playTime
            else
                gLobalDataManager:setStringByField("AdsControl_PlayAdTimes" .. pos, todayDate .. "_0")
                return 0
            end
        else
            gLobalDataManager:setStringByField("AdsControl_PlayAdTimes" .. pos, todayDate .. "_0")
            return 0
        end
    end
    return 0
end

function AdsControl:addOnePosTodayPlayAdTimes(pos)
    local playAdTimes = self:getOnePosTodayPlayAdTimes(pos)
    playAdTimes = playAdTimes + 1
    local todayDate = self:getSeverDateStr()
    gLobalDataManager:setStringByField("AdsControl_PlayAdTimes" .. pos, todayDate .. "_" .. playAdTimes)
end

function AdsControl:resetTodayPlayAdTimes()
    self.m_playAdTimes = 0
    local todayDate = self:getSeverDateStr()
    gLobalDataManager:setStringByField("AdsControl_PlayAdTimes", todayDate .. "_" .. self.m_playAdTimes)
end

function AdsControl:getSeverDateStr()
    local nowTime = tonumber(globalData.userRunData.p_serverTime / 1000)
    local serverTM = util_UTC2TZ(nowTime, -8)
    return serverTM.year .. serverTM.month .. serverTM.day
end

--激励视频是否加载成功
function AdsControl:adsLoadSuccess()
    self.rewardLoadFlag = true
    gLobalNoticManager:postNotification("ads_vedio")
end
-- 激励视频播放完成回调
function AdsControl:rewardVideoCallback(success)
    gLobalNoticManager:postNotification("ads_vedio")
    gLobalViewManager:removeLoadingAnima()
    self:removeAdTimerHandler()
    if not globalData.adsRunData then
        return
    end
    local adsInfo = globalData.adsRunData:getCurrAdsInfo()
    if not adsInfo or not adsInfo.p_position then
        return
    end
    self.m_strSuccess = success
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADCHALLENGE_LOAD_STATE, success)
    release_print("Mopub    " .. adsInfo.p_position)
    if adsInfo.p_position == PushViewPosType.DialyBonus then
        release_print("Mopub    " .. success)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASHBONUS_VIDEO_REWARD, {success})
    else
        local function addNetWorkFunc(funcOk, funcFail)
            gLobalViewManager:addLoadingAnima()
            local firstPlay = nil
            if globalData.adsRunData:getGuideAds() then
                firstPlay = 1
            end
            local messageData = {id = adsInfo.p_id, position = adsInfo.p_position, type = adsInfo.p_type, firstPlay = firstPlay}
            gLobalSendDataManager:getNetWorkFeature():sendWatchViodeMessage(messageData, funcOk, funcFail)
        end
        if success == "success" then
            globalData.adsRunData:setGuideAds(nil)
            if globalData.adsRunData:isGuidePlayAds() then
                globalData.adsRunData.p_leadTimes = 1
                globalData.adsRunData:setGuideAds(true)
            end
            -- csc 2021-12-07 看完激励视频,插屏的公用CD需要重新计时
            if globalData.adsRunData:isInterstitialAds() then
                self.m_iterstitialCDTime = os.time() + globalData.adsRunData:getPublicAdsCD()
            end

            self:addOnePosTodayPlayAdTimes(adsInfo.p_position)

            local needSendCoins = true
            if adsInfo.p_position == PushViewPosType.DoubleMission then
                needSendCoins = false
                addNetWorkFunc(
                    function(target, resultData)
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)
                        if resultData and resultData:HasField("simpleUser") == true then
                            globalData.syncSimpleUserInfo(resultData.simpleUser)
                        end
                        -- csc 2021-07-06 广告看完之后先不用刷新最新金币 通过后续rewardlayer界面再次刷新
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_DOUBLEMISSION, {"success"})
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                    end,
                    function()
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_DOUBLEMISSION, {"fail"})
                    end
                )
            elseif adsInfo.p_position == PushViewPosType.VaultSpeedup then
                needSendCoins = false
                addNetWorkFunc(
                    function()
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)

                        local currentTime = util_getCurrnetTime()
                        gLobalDataManager:setNumberByField("isPlayBronzeVedio_collectSilverTime", currentTime)

                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_VAULTSPEEDUP, {"success"})
                        if gLobalAdChallengeManager:isShowMainLayer() then
                            gLobalAdChallengeManager:showMainLayer()
                        end
                    end,
                    function()
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_VAULTSPEEDUP, {"fail"})
                    end
                )
            elseif adsInfo.p_position == PushViewPosType.InboxReward then
                -- 看完inbox 中的激励视需要通知刷新inbox
                gLobalViewManager:removeLoadingAnima()

                local success = function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_REWARD_VIDEO_COMPLETE)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_PAGE)
                end

                local failed = function()
                    gLobalViewManager:removeLoadingAnima()
                end
                G_GetMgr(G_REF.Inbox):getDataMessage(success, failed)

                -- 其余看广告的地方，都需要先跟服务器通信 在弹出奖励板子
                local successfunc = function()
                    gLobalViewManager:removeLoadingAnima()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)

                    scheduler.performWithDelayGlobal(
                        function()
                            local view =
                                util_createView(
                                "views.dialogs.AdsRewardLayer",
                                AdsRewardDialogType.Reward,
                                adsInfo.p_position,
                                function()
                                    if gLobalAdChallengeManager:isShowMainLayer() then
                                        gLobalAdChallengeManager:showMainLayer()
                                    end
                                end
                            )
                            gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
                        end,
                        0.1
                    )
                end
                local failedfunc = function()
                    gLobalViewManager:removeLoadingAnima()
                end
                addNetWorkFunc(successfunc, failedfunc)
            elseif adsInfo.p_position == PushViewPosType.NoCoinsToSpin then
                local success = function(target, resData)
                    gLobalViewManager:removeLoadingAnima()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)
                    if resData:HasField("result") == true then
                        local rewardCoins = resData.result
                        if rewardCoins then
                            globalData.adsRunData.p_noCoinsRealCoins = tonumber(rewardCoins)
                        end

                        -- csc 2021-12-14 新需求
                        -- 需要检测当前是否加载到了下一个激励视频
                        -- 需要检测当前是否能够弹出 nocoin double 的界面
                        local canDouble = self:canShowBrokenDoubleLayer()
                        if canDouble then
                            local currentWatchCount = globalData.AdChallengeData:getCurrentWatchCount()
                            globalData.AdChallengeData:setLastWatchCount(currentWatchCount)
                            scheduler.performWithDelayGlobal(
                                function()
                                    local view = util_createView("views.dialogs.AdsBrokenDoubleLayer")
                                    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                                end,
                                0.1
                            )
                        else
                            scheduler.performWithDelayGlobal(
                                function()
                                    local view =
                                        util_createView(
                                        "views.dialogs.AdsRewardLayer",
                                        AdsRewardDialogType.Reward,
                                        adsInfo.p_position,
                                        function()
                                            if gLobalAdChallengeManager:isShowMainLayer() then
                                                gLobalAdChallengeManager:showMainLayer()
                                            end
                                        end
                                    )
                                    gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
                                end,
                                0.1
                            )
                        end
                    end
                end
                local failed = function()
                    gLobalViewManager:removeLoadingAnima()
                end
                addNetWorkFunc(success, failed)
            elseif adsInfo.p_position == PushViewPosType.NoCoinsToSpinDouble then
                local success = function(target, resData)
                    gLobalViewManager:removeLoadingAnima()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)
                    if resData:HasField("result") == true then
                        local rewardCoins = resData.result
                        if rewardCoins then
                            if globalData.adsRunData.p_noCoinsRealCoins then
                                globalData.adsRunData.p_noCoinsRealCoins = globalData.adsRunData.p_noCoinsRealCoins + tonumber(rewardCoins)
                            end
                        end

                        scheduler.performWithDelayGlobal(
                            function()
                                local view =
                                    util_createView(
                                    "views.dialogs.AdsRewardLayer",
                                    AdsRewardDialogType.Reward,
                                    adsInfo.p_position,
                                    function()
                                        if gLobalAdChallengeManager:isShowMainLayer() then
                                            gLobalAdChallengeManager:showMainLayer()
                                        end
                                    end
                                )
                                gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
                            end,
                            0.1
                        )
                    end
                end
                local failed = function()
                    gLobalViewManager:removeLoadingAnima()
                end
                addNetWorkFunc(success, failed)
            elseif adsInfo.p_position == PushViewPosType.InboxFreeSpin then
                -- 设置一次当前看视频广告的时间
                gLobalDataManager:setStringByField("inboxAddFreeGameAdsWatchTimeCd", tostring(globalData.userRunData.p_serverTime))
                --.... freespin 不用弹板
                local networkSuccess = function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)
                    -- 请求最新的inbox数据
                    local success = function()
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_REWARD_VIDEO_COMPLETE)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_PAGE)
                    end
                    local failed = function()
                        gLobalViewManager:removeLoadingAnima()
                    end
                    G_GetMgr(G_REF.Inbox):getDataMessage(success, failed)
                end

                local netwrokFailed = function()
                    gLobalViewManager:removeLoadingAnima()
                end

                addNetWorkFunc(networkSuccess, netwrokFailed)
            elseif adsInfo.p_position == PushViewPosType.LevelUp then
                addNetWorkFunc(
                    function(target, resultData)
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)
                        if resultData and resultData:HasField("simpleUser") == true then
                            globalData.syncSimpleUserInfo(resultData.simpleUser)
                        end
                        -- csc 2021-07-06 广告看完之后先不用刷新最新金币 通过后续rewardlayer界面再次刷新
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_DOUBLELEVELUP, {"success"})
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                    end,
                    function()
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_DOUBLELEVELUP, {"fail"})
                    end
                )
            elseif adsInfo.p_position == PushViewPosType.CardStoreCd then
                needSendCoins = false
                addNetWorkFunc(
                    function(target, resultData)
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)
                        if resultData and resultData:HasField("simpleUser") == true then
                            globalData.syncSimpleUserInfo(resultData.simpleUser)
                        end
                        -- csc 2021-07-06 广告看完之后先不用刷新最新金币 通过后续rewardlayer界面再次刷新
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_CARDSTORECD, {"success"})
                        if gLobalAdChallengeManager:isShowMainLayer() then
                            gLobalAdChallengeManager:showMainLayer()
                        end
                    end,
                    function()
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_CARDSTORECD, {"fail"})
                    end
                )
            elseif adsInfo.p_position == PushViewPosType.HighLimitMergeGame then
                needSendCoins = false
                addNetWorkFunc(
                    function(target, resultData)
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)
                        if resultData:HasField("result") == true then
                            local rewards = self:parseReward(cjson.decode(resultData.result))
                            local propsBagList = rewards.propsBagList
                            if propsBagList and #propsBagList > 0 then
                                local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                                mergeManager:popMergePropsBagRewardPanel(
                                    propsBagList,
                                    function()
                                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshBottom = true})
                                        if gLobalAdChallengeManager:isShowMainLayer() then
                                            gLobalAdChallengeManager:showMainLayer()
                                        end
                                    end
                                )
                            end
                        end
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_MERGEGAME, {"success"})
                    end,
                    function()
                        gLobalViewManager:removeLoadingAnima()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_MERGEGAME, {"fail"})
                    end
                )
            else
                -- 其余看广告的地方，都需要先跟服务器通信 在弹出奖励板子
                local success = function()
                    gLobalViewManager:removeLoadingAnima()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END, {adsInfo.p_position})
                    scheduler.performWithDelayGlobal(
                        function()
                            local view =
                                util_createView(
                                "views.dialogs.AdsRewardLayer",
                                AdsRewardDialogType.Reward,
                                adsInfo.p_position,
                                function()
                                    if gLobalAdChallengeManager:isShowMainLayer() then
                                        gLobalAdChallengeManager:showMainLayer()
                                    end
                                end
                            )
                            gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
                        end,
                        0.1
                    )
                end
                local failed = function()
                    gLobalViewManager:removeLoadingAnima()
                end
                addNetWorkFunc(success, failed)
            end
            gLobalSendDataManager:getLogAds():setadTaskStatus("Full")
            gLobalSendDataManager:getLogAds():setrewardCoins(adsInfo.p_coins)
            gLobalSendDataManager:getLogAds():sendAdsLog()

            gLobalSendDataManager:getLogAdvertisement():setadType("Close")
            gLobalSendDataManager:getLogAdvertisement():setadStatus("FullClose")
            gLobalSendDataManager:getLogAdvertisement():setStatus("Success")

            if needSendCoins == true then
                gLobalSendDataManager:getLogAdvertisement():setrewardCoins(adsInfo.p_coins)
            end
            gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
        else
            --弹窗逻辑执行下一个事件
            --每日任务失败也算成功
            if adsInfo.p_position == PushViewPosType.DoubleMission then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_DOUBLEMISSION_FAILE)
            end
            gLobalSendDataManager:getLogAds():setadTaskStatus("Return")
            gLobalSendDataManager:getLogAds():sendAdsLog()

            gLobalSendDataManager:getLogAdvertisement():setadType("Close")
            gLobalSendDataManager:getLogAdvertisement():setadStatus("MidwayClose")
            gLobalSendDataManager:getLogAdvertisement():setStatus("Fail")
            gLobalSendDataManager:getLogAdvertisement():sendAdsLog()

            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "configPushAds")
        end
    end
end
--检测背景音乐是否需要暂停
function AdsControl:setPlayAdFlag(flag)
    self.playAdFlag = flag
end
--检测背景音乐是否需要暂停
function AdsControl:getPlayAdFlag()
    return self.playAdFlag
end
--设置当前播放着的广告类型解决同时弹广告问题
function AdsControl:setPlayAdType(flag)
    self.playAdType = flag
end
--设置当前播放着的广告类型解决同时弹广告问题
function AdsControl:getPlayAdType()
    return self.playAdType
end
--ios使用音乐暂停相关
function AdsControl:setPlayingAdFlag(flag)
    self.playingAdFlag = flag
end
--ios使用音乐暂停相关
function AdsControl:getPlayingAdFlag()
    return self.playingAdFlag
end

--[[
    @desc:有关att的控制
    --@_pos: 检测点位
	--@_version: 检测版本
]]
function AdsControl:getCheckATTFlag(_pos, _version)
    -- 根据两个不同的点位,返回不同的判断
    local flag = false

    -- 总开关 判断
    if not CC_ATTRACKING_FLAG then
        return false
    end
    -- 平台+版本 判断
    if device.platform == "ios" then
        if not util_isSupportVersion(_version) then -- 2021年08月23日 更新代码,不同调用地方版本号不同
            return false
        end
        -- 2021-08-23 修改写法
        local osVersion = globalPlatformManager:getOsSystemVersion() -- "14.x.x"
        release_print("----csc osVersion = " .. osVersion)
        local tempVer_tab = util_string_split(osVersion, ".", true)
        if next(tempVer_tab) and table.nums(tempVer_tab) >= 2 then
            local realOsVersion = tempVer_tab[1] * 10 + tempVer_tab[2]
            release_print("----csc realOsVersion = " .. realOsVersion)
            if realOsVersion < CC_ATTRACKING_LIMIT_VERSION then
                release_print("----csc realOsVersion < " .. CC_ATTRACKING_LIMIT_VERSION .. " return false")
                return false
            end
        else
            return false
        end
    else
        return false
    end
    -- ATT 是否已经不再弹出 只要请求过att系统弹板 都不再弹出
    if gLobalDataManager:getBoolByField("checkATTrackingOver", false) then
        release_print("----csc checkATTrackingOver = true ")
        return false
    end
    -- 传入的点位 判断
    if _pos == "loading" then
        -- 确保ATT loading阶段检测只走一遍
        if not gLobalDataManager:getBoolByField("checkATTrackingLoadingStatus", false) then
            gLobalDataManager:setBoolByField("checkATTrackingLoadingStatus", true)
            flag = true
        else
            flag = false
        end
    elseif _pos == "levelup" then
        flag = self:checkLevelUpAttV2()
    elseif _pos == "setting" then
        -- 如果需要玩家跳转 setting界面
        if gLobalDataManager:getBoolByField("AtTTrackingNeedGotoSetting", true) then
            gLobalDataManager:setBoolByField("AtTTrackingNeedGotoSetting", false)
            flag = self:checkSettingGuideAttV2()
        else
            flag = false
        end
    elseif _pos == "bigwin" then
        flag = self:checkBigWinAtt()
    end
    return flag
end

-- 用来更新与 ATT 相关的spin数据
function AdsControl:updateATTBigWinData()
    local currSpinTimes = gLobalDataManager:getNumberByField("checkATTrackingBigWinSpinTimes", 0)
    currSpinTimes = currSpinTimes + 1
    gLobalDataManager:setNumberByField("checkATTrackingBigWinSpinTimes", currSpinTimes)
end

function AdsControl:createATTLayer(_pos)
    -- 2021-03-17 11:29:22 暂时不需要一级弹板,直接调用到系统ATT请求
    -- 2021-08-23 14:19:08 重新启用一级弹板
    if _pos == "levelup" or _pos == "bigwin" then
        local view = util_createView("views.dialogs.ATTrackingLevelUpLayer", _pos)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
    elseif _pos == "setting" then
        local view = util_createView("views.dialogs.ATTrackingGoSettingLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
    end
end

function AdsControl:getInterstitialCDTime()
    return self.m_iterstitialCDTime or 0
end

--[[
    @desc: 新版本levelup2时的 att逻辑
    author:csc
    time:2021-10-20 14:36:16
]]
function AdsControl:checkLevelUpAttV2()
    -- 已经经历过这个阶段的不需要再判断
    if gLobalDataManager:getBoolByField("checkATTrackingLevelUpStatus", false) then
        return false
    end
    gLobalDataManager:setBoolByField("checkATTrackingLevelUpStatus", true)
    -- 如果当前玩家属于 1.5.9 之前使用 max 申请att权限的 老用户但是没升过级 已经操作过 att 弹板选项了
    local oldVersionUser = false
    if gLobalDataManager:getBoolByField("checkATTrackingLoadingStatus", false) == true then
        -- 默认返回false，需要再做一层判断
        oldVersionUser = true
    end
    -- release_print("---csc checkLevelUpAttV2 oldVersionUser = "..tostring(oldVersionUser))
    local pop = false
    if self:getAttSwitch() or oldVersionUser then -- 记录下来的 att总开关状态
        -- release_print("---csc checkLevelUpAttV2 getAttSwitch = true")
        if self:getAttStatus() then -- 用户当前 att开启状态
            -- release_print("---csc checkLevelUpAttV2 getAttStatus = true")
            -- 正常弹出 2级请求面板,点击next后请求ATT权限 ， 设置不需要弹出setting引导
            gLobalDataManager:setBoolByField("AtTTrackingNeedGotoSetting", false)
            if not oldVersionUser then -- max老版本的用户如果获取的是开启的状态,不需要再弹出板子
                -- release_print("---csc checkLevelUpAttV2 pop = true")
                pop = true
            end
        else
            --不弹出，设置需要弹出setting引导 ， 同时需要更新 setAttSwitch() = false
            -- release_print("---csc checkLevelUpAttV2 getAttStatus = false")
            gLobalDataManager:setBoolByField("AtTTrackingNeedGotoSetting", true)
            self:setAttSwtich(false)
        end
    else
        --用户当前att总开关是关闭的状态 不弹出，设置8级需要弹出setting引导 考虑到用户可能在2-8期间打开了总开关,以便后续能重新做一次 att 请求
        -- release_print("---csc checkLevelUpAttV2 getAttSwitch = false")
        gLobalDataManager:setBoolByField("AtTTrackingNeedGotoSetting", true)
    end

    return pop
end

--[[
    @desc: 新版本 8级点位检测是否要弹出 setting 点位
    author:csc
    time:2021-10-20 15:25:03
]]
function AdsControl:checkSettingGuideAttV2()
    release_print("---csc checkSettingGuideAttV2 ")
    if self:getAttSwitch() then -- 记录下来的 att总开关状态
        if self:getAttStatus() then
            local attCode = tonumber(globalPlatformManager:getATTrackingStatusCode())
            if attCode == globalPlatformManager.ATTSTATUS_CODE.ATT_NOTDETERMINED then
                self.m_isAgainRequest = true
                -- release_print("---csc checkSettingGuideAttV2 当前用户没有请求过 att 需要请求一次")
                return true
            else
                -- 当前att状态是开启的,认为用户已经允许了，不需要再弹出
                -- release_print("---csc checkSettingGuideAttV2 当前att状态是开启的,认为用户已经允许了，不需要再弹出")
            end
            return false
        else
            --弹出setting 引导面板 引导用户去 隐私-跟踪-turn on
            -- release_print("---csc checkSettingGuideAttV2 弹出setting 引导面板 引导用户去 隐私-跟踪-turn on")
            return true
        end
    else
        if self:getAttStatus() then
            -- 如果当前用户当前 att 没有请求过,重新让用户请求一次
            -- release_print("---csc checkSettingGuideAttV2 如果当前用户当前 att 没有请求过,重新让用户请求一次")
            local attCode = tonumber(globalPlatformManager:getATTrackingStatusCode())
            if attCode == globalPlatformManager.ATTSTATUS_CODE.ATT_NOTDETERMINED then
                self.m_isAgainRequest = true
                -- release_print("---csc checkSettingGuideAttV2 self.m_isAgainRequest = true")
                return true
            end
            return false
        else
            --不弹出，正常继续游戏
            -- release_print("---csc false false 不弹出，正常继续游戏")
            return false
        end
    end
end

--[[
    @desc: 新版本 bigwin 关闭时的 att逻辑
    author:csc
    time:2021-11-19 15:27:02
]]
function AdsControl:checkBigWinAtt()
    -- 如果当前是已经经历过 2级点位弹出的用户,直接跳转这个阶段
    if gLobalDataManager:getBoolByField("checkATTrackingLevelUpStatus", false) then
        return false
    end
    -- 已经经历过这个阶段的不需要再判断
    if gLobalDataManager:getBoolByField("checkATTrackingBigWinStatus", false) then
        return false
    end
    gLobalDataManager:setBoolByField("checkATTrackingBigWinStatus", true)
    -- 如果当前玩家属于 1.5.9 之前使用 max 申请att权限的 老用户但是没升过级 已经操作过 att 弹板选项了
    local oldVersionUser = false
    if gLobalDataManager:getBoolByField("checkATTrackingLoadingStatus", false) == true then
        -- 默认返回false，需要再做一层判断
        oldVersionUser = true
    end
    release_print("---csc checkBigWinAtt oldVersionUser = " .. tostring(oldVersionUser))
    local pop = false
    if self:getAttSwitch() or oldVersionUser then -- 记录下来的 att总开关状态
        -- release_print("---csc checkBigWinAtt getAttSwitch = true")
        if self:getAttStatus() then -- 用户当前 att开启状态
            -- release_print("---csc checkBigWinAtt getAttStatus = true")
            -- 正常弹出 2级请求面板,点击next后请求ATT权限 ， 设置不需要弹出setting引导
            gLobalDataManager:setBoolByField("AtTTrackingNeedGotoSetting", false)
            if not oldVersionUser then -- max老版本的用户如果获取的是开启的状态,不需要再弹出板子
                -- release_print("---csc checkBigWinAtt pop = true")
                pop = true
            end
        else
            --不弹出，设置需要弹出setting引导 ， 同时需要更新 setAttSwitch() = false
            -- release_print("---csc checkBigWinAtt getAttStatus = false")
            gLobalDataManager:setBoolByField("AtTTrackingNeedGotoSetting", true)
            self:setAttSwtich(false)
        end
    else
        --用户当前att总开关是关闭的状态 不弹出，设置8级需要弹出setting引导 考虑到用户可能在2-8期间打开了总开关,以便后续能重新做一次 att 请求
        -- release_print("---csc checkBigWinAtt getAttSwitch = false")
        gLobalDataManager:setBoolByField("AtTTrackingNeedGotoSetting", true)
    end

    return pop
end

--[[
    @desc: 返回att状态 
    author:csc
    time:2021-10-20 11:06:16
    return: true开启 false关闭
]]
function AdsControl:getAttStatus()
    local attStatus = false
    if device.platform == "mac" then
        return attStatus
    end
    local attCode = tonumber(globalPlatformManager:getATTrackingStatusCode())
    if attCode == globalPlatformManager.ATTSTATUS_CODE.ATT_NOTDETERMINED then
        attStatus = true
    elseif attCode == globalPlatformManager.ATTSTATUS_CODE.ATT_RRESTRICTED then
        attStatus = true
    elseif attCode == globalPlatformManager.ATTSTATUS_CODE.ATT_DENIED then
        attStatus = false
    elseif attCode == globalPlatformManager.ATTSTATUS_CODE.ATT_AUTHORIZED then
        attStatus = true
    end
    release_print("---csc getAttStatus  attCode = " .. attCode .. "   attStatus = " .. tostring(attStatus))
    return attStatus
end

function AdsControl:setAttSwtich(_flag)
    gLobalDataManager:setBoolByField("ATTrackingSwitchFlag", _flag)
end

function AdsControl:getAttSwitch()
    return gLobalDataManager:getBoolByField("ATTrackingSwitchFlag", false)
end

--[[
    @desc:是否需要重新请求att权限
    author:csc
    time:2021-10-20 15:59:12
]]
function AdsControl:isAgainRequestATTracking()
    return self.m_isAgainRequest
end

function AdsControl:checkBrokenDoubleCDTime()
    local oldTime = tonumber(gLobalDataManager:getStringByField("noCoinsToSpinsDoubleCd", "0"))
    if oldTime == 0 then
        -- 今天还没弹出过,不需要检测
        printInfo("----csc checkBrokenDoubleCDTime 今天还没弹出过,不需要检测")
        return
    end

    if util_getTimeIsNewDay(oldTime) then
        -- 如果当前跨天了，清空这个cd值
        gLobalDataManager:setStringByField("noCoinsToSpinsDoubleCd", "0")
    end
end
function AdsControl:canShowBrokenDoubleLayer()
    -- 检测每日必弹cd
    self:checkBrokenDoubleCDTime()
    local lastPopTimeCD = tonumber(gLobalDataManager:getStringByField("noCoinsToSpinsDoubleCd", "0"))
    local randomPop = math.random(0, 1)
    -- 需要每日第一次必弹，之后 只有50%的概率弹
    if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.NoCoinsToSpinDouble) and (lastPopTimeCD == 0 or randomPop > 0) then
        -- 打点
        gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.NoCoinsToSpinDouble)
        gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
        gLobalSendDataManager:getLogAds():createPaySessionId()
        gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.NoCoinsToSpinDouble)
        gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
        -- 记录当前弹出的时间
        if lastPopTimeCD == 0 then
            local curTime = globalData.userRunData.p_serverTime
            gLobalDataManager:setStringByField("noCoinsToSpinsDoubleCd", tostring(curTime))
        end
        return true
    end
    return false
end
function AdsControl:getADSWacthTime()
    local result = 0
    local curTime = globalData.userRunData.p_serverTime / 1000
    local oldTM = os.date("!*t", (curTime - 8 * 3600))
    local timeStr = "" .. oldTM.month .. "-" .. oldTM.day
    local str = gLobalDataManager:getStringByField("adsRewardPlayCount", timeStr .. "_0")
    local playAdList = util_split(str, "_")
    if playAdList and #playAdList == 2 then
        local writeStr = playAdList[1]
        if timeStr ~= writeStr then
            gLobalDataManager:setStringByField("adsRewardPlayCount", timeStr .. "_0")
        else
            result = tonumber(playAdList[2])
        end
    else
        gLobalDataManager:setStringByField("adsRewardPlayCount", timeStr .. "_0")
    end
    return result
end

function AdsControl:addADSWacthTime()
    local curTime = globalData.userRunData.p_serverTime / 1000
    local oldTM = os.date("!*t", (curTime - 8 * 3600))
    local timeStr = "" .. oldTM.month .. "-" .. oldTM.day
    local str = gLobalDataManager:getStringByField("adsRewardPlayCount", timeStr .. "_0")
    local playAdList = util_split(str, "_")
    if playAdList and #playAdList == 2 then
        local writeStr = playAdList[1]
        if timeStr ~= writeStr then
            gLobalDataManager:setStringByField("adsRewardPlayCount", timeStr .. "_0")
        else
            gLobalDataManager:setStringByField("adsRewardPlayCount", timeStr .. "_" .. (tonumber(playAdList[2]) + 1))
        end
    else
        gLobalDataManager:setStringByField("adsRewardPlayCount", timeStr .. "_0")
    end
end

function AdsControl:parseReward(data)
    local rewards = {}
    ------------- 检索合成福袋 zkk-------------
    if type(data) == "number" then
        return rewards
    end

    local rewardItems = {}
    if data and data.rewards then
        for i = 1, #data.rewards do
            local shopItem = ShopItem:create()
            shopItem:parseData(data.rewards[i], true)
            rewardItems[i] = shopItem
        end
    end

    local propsBagList = {}
    for _, data in ipairs(rewardItems) do
        if string.find(data.p_icon, "Pouch") then
            table.insert(propsBagList, data)
        end
    end
    if #propsBagList > 0 then
        rewards.propsBagList = propsBagList
    end
    return rewards
end

return AdsControl

--更新广告状态
GD.adsLoadSuccess = function()
    release_print("------------------------------adsLoadSuccess start")
    util_afterDrawCallBack(
        function()
            if gLobalAdsControl ~= nil then
                gLobalAdsControl:adsLoadSuccess()
            end
        end
    )
    release_print("------------------------------adsLoadSuccess end")
end

GD.closeAdsCallback = function()
    release_print("------------------------------closeAdsCallback start")
    util_afterDrawCallBack(
        function()
            if gLobalAdsControl ~= nil then
                gLobalAdsControl:closeAdsCallback()
            end
        end
    )
    release_print("------------------------------closeAdsCallback end")
end

GD.adsTryPlayVedio = function()
    return 0
end

--回调java方法
GD.updateJavaCallFuncMsg = function(msg)
    release_print("------------------------------updateJavaCallFuncMsg start", msg)
    util_afterDrawCallBack(
        function()
            if msg == "pauseAudio" then
                --暂停音乐
                if gLobalAdsControl ~= nil then
                    if gLobalAdsControl.setPlayAdFlag then
                        gLobalAdsControl:setPlayAdFlag(true)
                    end
                    if gLobalAdsControl.setPlayingAdFlag then
                        gLobalAdsControl:setPlayingAdFlag(true)
                    end
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
                ccexp.AudioEngine:pauseAll()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_BEGIN)
            elseif msg == "resumeAudio" then
                --恢复音乐
                if gLobalAdsControl ~= nil then
                    if gLobalAdsControl.setPlayAdFlag then
                        gLobalAdsControl:setPlayAdFlag(false)
                    end
                    if gLobalAdsControl.removeAdTimerHandler then
                        gLobalAdsControl:removeAdTimerHandler()
                    end
                    if gLobalAdsControl.setPlayingAdFlag then
                        gLobalAdsControl:setPlayingAdFlag(false)
                    end
                end
                if gLobalViewManager:isPauseAndResumeMachine() then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                end
                if not gLobalViewManager:getHasShowUI() then
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "configPushView")
                end
                if gLobalSoundManager ~= nil then
                    gLobalSoundManager:resumeBgMusic()
                end
                if globalData.adsRunData then
                    local adsInfo = globalData.adsRunData:getCurrAdsInfo()
                    if adsInfo ~= nil and adsInfo.p_cdTime > 0 then
                        adsInfo.p_showTime = os.time() + adsInfo.p_cdTime
                    end
                end
                ccexp.AudioEngine:resumeAll()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_END)
            end
        end
    )
    release_print("------------------------------updateJavaCallFuncMsg end")
end


--获取 每小时 奖励 剩余时间
GD.getHourRewardLeftTime = function()
    local iWaitTime = 0
    if gLobalViewManager:isLogonView() then
        iWaitTime = HOUR_REWARDTIME
    else
        local currentTime = os.time()
        local rewardTime = globalData.rewardTime
        if currentTime > rewardTime then
            iWaitTime = HOUR_REWARDTIME / 4
        else
            iWaitTime = rewardTime - currentTime
        end
    end

    if DEBUG == 2 then
        iWaitTime = 10 --测试代码
    end
    return iWaitTime
end

GD.rewardVideoCallback = function(success)
    release_print("------------------------------rewardVideoCallback start")
    util_afterDrawCallBack(
        function()
            if gLobalAdsControl ~= nil then
                gLobalAdsControl:rewardVideoCallback(success)
            end
        end
    )
    release_print("------------------------------rewardVideoCallback end")
end

GD.autoVideoFireBase = function(status)
    if not gLobalSendDataManager:isLogin() then
        return
    end

    release_print("------------------------------autoVideoFireBase start")
    util_afterDrawCallBack(
        function()
            local msg = globalData.adsRunData:getCurrAutoAdsPos()
            if msg ~= nil then
                globalFireBaseManager:sendFireBaseLog(msg, status)
                globalFireBaseManager:sendFireBaseLog("all_interstitial_", status)

                -- 插屏广告日志
                if status and status == "click" then
                    gLobalSendDataManager:getLogAdvertisement():setadType("Broadcast")
                    gLobalSendDataManager:getLogAdvertisement():setadStatus("Click")
                    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
                end
            else
                -- 激励视频广告
                globalFireBaseManager:sendFireBaseLog("all_reward_", status)

                if status and status == "click" then
                    gLobalSendDataManager:getLogAdvertisement():setadType("Broadcast")
                    gLobalSendDataManager:getLogAdvertisement():setadStatus("Click")
                    globalData.adsRunData:getRewardVieoPlayTimes()
                    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
                end
            end
            globalFireBaseManager:sendFireBaseLog("all_ads_", status)
        end
    )
    release_print("------------------------------autoVideoFireBase end")
end

-- MAX 广告 GDPR flow 设置
GD.onFlowCompleted = function(isCompleted)
end

GD.checkAIHelpNewMessage = function(jsonData)
    release_print("------------------------------getAIHelpNewMessage start")
    release_print(" jsonData = " .. jsonData)

    local newVersionAIhelp = false
    if device.platform == "android" then
        if util_isSupportVersion("1.4.0") then
            newVersionAIhelp = true
        end
    end
    -- 新版本 aihelp 返回的是消息数量
    if newVersionAIhelp then
        globalData.newMessageNums = tonumber(jsonData)
        if globalData.newMessageNums == 0 then
            globalData.newMessageNums = nil
        end
        if globalData.newMessageNums and globalData.newMessageNums >= 1 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHECK_NEWMESSAGE)
        end
    else
        local data = cjson.decode(jsonData)
        globalData.newMessageNums = data["data"]["cs_message_count"]
        if globalData.newMessageNums == 0 then
            globalData.newMessageNums = nil
        end
        if data["flag"] and data["data"]["cs_message_count"] >= 1 then
            -- release_print("csc 当前有未读消息")
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHECK_NEWMESSAGE)
        end
    end

    release_print("------------------------------getAIHelpNewMessage end")
end

GD.iapPaymentFaildCallback = function(jsonData)
    release_print("------------------------------iapPaymentFaildCallback start")
    release_print(" jsonData = " .. jsonData)
    if util_isSupportVersion("1.7.8", "ios") then
        -- iOS 1.7.8报错兼容
        local errS, errE = string.find(jsonData, "\"errorCode\":.-%d+")
        local _str = string.sub(jsonData, errS, errE)
        jsonData = "{" .. _str .. "}"
    end
    local data = cjson.decode(jsonData)
    if tolua.type(data) == "table" and data["errorCode"] then
        local errorCode = data["errorCode"]
        local errorMsg = data["errorMsg"] -- 这里就算发送的errorMsg 是 nil 也不会有问题
        -- 发送信息给iapmanager进行sdkcode的赋值
        gLobalNoticManager:postNotification(GlobalEvent.IAP_BuyResult, {tonumber(errorCode), errorMsg})
    else
        gLobalNoticManager:postNotification(GlobalEvent.IAP_BuyResult, {data})
    end
    release_print("------------------------------iapPaymentFaildCallback end")
end

GD.iapPurchasingCallback = function(jsonData)
    release_print("------------------------------iapPurchasingCallback start")
    release_print(" ----csc iapPurchasingCallback 重新触发补单流程")
    if gLobalIAPManager ~= nil then
        gLobalIAPManager:stopCheckPendingSchdule()
        gLobalIAPManager:iapQueryPurchases()
    end
    release_print("------------------------------iapPurchasingCallback end")
end

GD.iapPaymentStepLog = function(jsonData)
    release_print("------------------------------iapPaymentStepLog start")
    release_print(" jsonData = " .. jsonData)
    if gLobalIAPManager ~= nil then
        gLobalIAPManager:sendBuglyLog(jsonData)
    end

    release_print("------------------------------iapPaymentStepLog end")
end

GD.iapPaymentGroundBack = function()
    release_print("------------------------------iapPaymentGroundBack start")
    -- 检测付费异常状态 amazon 专用
    if device.platform == "android" then
        if MARKETSEL == AMAZON_MARKET then
            if gLobalIAPManager ~= nil then
                gLobalNoticManager:postNotification(GlobalEvent.IAP_BuyResult, {tonumber(1), "home back cancel"})
            end
        end
    end
    release_print("------------------------------iapPaymentGroundBack end")
end

--下载zip相关log
GD.sendSplunkDownLoadLog = function(strLog)
    if strLog and gLobalSendDataManager and gLobalSendDataManager.getLogGameLoad and gLobalSendDataManager:getLogGameLoad().sendLoadZipLog then
        gLobalSendDataManager:getLogGameLoad():sendLoadZipLog(strLog)
    end
end

-- 更新fb email
GD.saveFaceBookEmail = function(_email)
    -- 因为获取邮箱信息是额外发送的请求，跟登录可能不是同时回调的,所以单独写一个方法回调
    release_print("------------------------------saveFaceBookEmail start email == " .. tostring(_email))
    globalData.userRunData.fbEmail = _email or ""
    gLobalDataManager:setStringByField(FB_EMAIL, globalData.userRunData.fbEmail)
    release_print("------------------------------saveFaceBookEmail end")
end

local platform = device.platform
if platform == "android" then
    -- Android onResume线程执行结束后的逻辑
    GD.androidOnResumeThreadOver = function(param)
        util_afterDrawCallBack(
            function()
                --FB 短链接领奖
                gLobalNoticManager:postNotification(
                    ViewEventType.NOTIFY_CHECK_FBLINK_REWARD,
                    function()
                        release_print("androidOnResumeThreadOver")
                        globalLocalPushManager:readNotifyRewardData()
                    end
                )
            end
        )
    end
end

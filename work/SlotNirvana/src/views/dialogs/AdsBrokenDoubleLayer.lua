----
-- 没钱广告弹窗 双倍界面
--
local AdsBrokenDoubleLayer = class("AdsBrokenDoubleLayer", BaseLayer)

function AdsBrokenDoubleLayer:ctor()
    AdsBrokenDoubleLayer.super.ctor(self)
    self:setLandscapeCsbName("ads/Ads_broken_new_2.csb")

    self:setPauseSlotsEnabled(true)
end

function AdsBrokenDoubleLayer:initUI()
    AdsBrokenDoubleLayer.super.initUI(self)

    local labelCoins = self:findChild("lb_coin")
    labelCoins:setString(util_formatCoins(tonumber(globalData.adsRunData.p_noCoinsRealCoins), 30))
    self:updateLabelSize({label = labelCoins}, 480)

    --计算金币的位置
    local sprCoins = self:findChild("sp_coin")
    local curPos = cc.p(labelCoins:getPosition())
    local lens = labelCoins:getContentSize()
    local scale = labelCoins:getScale()
    local newPos = cc.p(curPos.x - (lens.width / 2 * scale) - sprCoins:getContentSize().width / 2 , curPos.y - 10)
    sprCoins:setPosition(newPos)

    -- 触发破产翻倍广告场景出现 打点
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.NoCoinsToSpinDouble)
    gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.NoCoinsToSpinDouble)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
    gLobalSendDataManager:getLogAdvertisement():setadType("Push")
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.NoCoinsToSpinDouble})
end

function AdsBrokenDoubleLayer:onKeyBack()
    --点击其他按钮回调
    if self.m_layerType ~= AdsRewardDialogType.Reward then
        gLobalSendDataManager:getLogAds():setOpenStatus("Refuse")
        gLobalSendDataManager:getLogAds():sendAdsLog()

        self.m_touchEnable = false
        self:closeUI(self.m_closeFunc)
    end
end

function AdsBrokenDoubleLayer:closeUI(func)
    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "configPushView")
        if func then
            func()
        end
        if gLobalAdChallengeManager:isShowMainLayer() then
            gLobalAdChallengeManager:showMainLayer()
        end
    end

    AdsBrokenDoubleLayer.super.closeUI(self, callback)
end

function AdsBrokenDoubleLayer:clickFunc(sender)
    if self.m_touchEnable == false then
        return
    end
    self.m_touchEnable = false
    local name = sender:getName()
    local tag = sender:getTag()
    -- 尝试重新连接 network
    if name == "btn_collect" then
        if self.m_layerType ~= AdsRewardDialogType.Reward then
            gLobalNoticManager:postNotification("hide_vedio_icon")
        end
        --点击OK按钮回调
        if self.m_layerType ~= AdsRewardDialogType.Reward then
            gLobalSendDataManager:getLogAds():setOpenStatus("Allow")
            globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = gLobalSendDataManager:getLogAds().m_taskOpenSite}, nil, "click")
        end
        -- 播放激励视频
        local playVideo =  function ()
            gLobalViewManager:addLoadingAnima()
            gLobalAdsControl:playRewardVideo(PushViewPosType.NoCoinsToSpinDouble)
        end
        self:closeUI(playVideo)
    else
        gLobalSendDataManager:getLogAds():setOpenStatus("Refuse")
        gLobalSendDataManager:getLogAds():sendAdsLog(true)
        -- 弹出结算界面
        local rewardLayer = function()
            local view=util_createView("views.dialogs.AdsRewardLayer",  AdsRewardDialogType.Reward,PushViewPosType.NoCoinsToSpin,nil)
            gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
        end
        self:closeUI(rewardLayer)
    end
end

function AdsBrokenDoubleLayer:onShowedCallFunc()
    self:runCsbAction("idle",true, nil, 60)
    self:startButtonAnimation("btn_collect", "breathe")
end


return AdsBrokenDoubleLayer

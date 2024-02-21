----
-- 没钱广告弹窗
--
local AdsBrokenLayer = class("AdsBrokenLayer", BaseLayer)

function AdsBrokenLayer:ctor(uiType, position, okFunc, closeFunc, selfCsbPath)
    AdsBrokenLayer.super.ctor(self)
    self:setLandscapeCsbName("ads/Ads_broken_new.csb")

    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(position)
    gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(position)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
    gLobalSendDataManager:getLogAdvertisement():setadType("Push")
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
    self.m_layerType = uiType
    self.m_position = position
    self.m_okFunc = okFunc
    self.m_closeFunc = closeFunc
    self.m_touchEnable = true

    self:setPauseSlotsEnabled(true)
end

function AdsBrokenLayer:initUI(uiType, position, okFunc, closeFunc, selfCsbPath)
    AdsBrokenLayer.super.initUI(self)

    self.addRewardCoin = 0
    local adsInfo = globalData.adsRunData:getAdsInfoForPos(self.m_position)
    --真实金额
    local m_lb_coins = self:findChild("lb_coin")
    self.m_lb_coins = m_lb_coins
    if m_lb_coins and adsInfo then
        self.addRewardCoin = adsInfo.p_coins
        if self.m_position == PushViewPosType.NoCoinsToSpin and uiType == AdsRewardDialogType.Normal then
            --没钱spin视频
            self.addRewardCoin = globalData.adsRunData.p_noCoinsMaxCoins
        end
        if uiType == AdsRewardDialogType.Reward then
            if self.m_position == PushViewPosType.NoCoinsToSpin then
                self.addRewardCoin = globalData.adsRunData.p_noCoinsRealCoins or self.addRewardCoin
            end
            m_lb_coins:setString(util_formatCoins(tonumber(self.addRewardCoin), 30))
        else
            self:jumpCoins(m_lb_coins, self.addRewardCoin)
        end
        self:updateLabelSize({label = m_lb_coins}, 673)
    end

    self:setExtendData("AdsBrokenLayer")
end

--金币跳动
function AdsBrokenLayer:jumpCoins(lb, coins)
    local coins = tonumber(coins)
    local ratio = 0
    local time = 1.5
    local baseCoins = coins * ratio
    local addValue = coins * (1 - ratio) * time / 60
    local lbs_jump = self:findChild("lb_baseCoins")
    lb:setString(util_formatCoins(coins, 30))
    util_jumpNum(lb, baseCoins, coins, addValue, time / 60, {30})
end

function AdsBrokenLayer:onKeyBack()
    --点击其他按钮回调
    if self.m_layerType ~= AdsRewardDialogType.Reward then
        gLobalSendDataManager:getLogAds():setOpenStatus("Refuse")
        gLobalSendDataManager:getLogAds():sendAdsLog()

        self.m_touchEnable = false
        self:closeUI(self.m_closeFunc)
    end
end

function AdsBrokenLayer:closeUI(func)
    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "configPushView")
        if func then
            func()
        end
    end

    AdsBrokenLayer.super.closeUI(self, callback)
end

function AdsBrokenLayer:clickFunc(sender)
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
        self:closeUI(self.m_okFunc)
    else
        gLobalSendDataManager:getLogAds():setOpenStatus("Refuse")
        gLobalSendDataManager:getLogAds():sendAdsLog(true)
        --点击其他按钮回调
        self:closeUI(self.m_closeFunc)
    end
end

function AdsBrokenLayer:onShowedCallFunc()
    self:runCsbAction("idle",true, nil, 60)
    self:startButtonAnimation("btn_collect", "breathe")
end


return AdsBrokenLayer

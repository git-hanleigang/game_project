-- 卡牌商城 免费礼品

local CardStoreGift = class("CardStoreGift", BaseView)

local STATE = {
    NONE = "NONE",
    LOGO = "LOGO",
    GIFT = "GIFT"
}

function CardStoreGift:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    if p_config and p_config.Gift then
        return p_config.Gift
    end
end

function CardStoreGift:initDatas(title_type)
    self.title_type = title_type
    self.store_data = G_GetMgr(G_REF.CardStore):getRunningData()
    self.state = STATE.NONE
end

function CardStoreGift:initUI()
    CardStoreGift.super.initUI(self)

    self.node_logo = self:findChild("node_logo")
    self.sp_ad = self:findChild("sp_ad")
    
    self:onReset()
end

--function CardStoreGift:initCsbNodes()
--    self.node_reward = self:findChild("node_item")
--end

function CardStoreGift:changeState(state)
    if self.state and self.state == state then
        return
    end
    self.sp_ad:setVisible(false)
    self.m_useAD = false

    self.state = state
    
    if self.state == STATE.NONE then
        self:runCsbAction("idle_logo", true)
    end

    if state == STATE.LOGO then
        if self.state == STATE.GIFT then
            self:runCsbAction(
                "act_2",
                false,
                function()
                    if self:hasAD() then
                        self:runCsbAction("idle_gift", true)
                        self.sp_ad:setVisible(true)
                        self:logADPush()
                        self.m_useAD = true
                    else
                        self:runCsbAction("idle_logo", true)
                    end
                end
            )
        else
            if self:hasAD() then
                self:runCsbAction("idle_gift", true)
                self.sp_ad:setVisible(true)
                self:logADPush()
                self.m_useAD = true
            else
                self:runCsbAction("idle_logo", true)
            end
        end
    elseif state == STATE.GIFT then
        if self.state == STATE.LOGO then
            self:runCsbAction(
                "act_1",
                false,
                function()
                    if self:hasAD() then
                        self:runCsbAction("idle_gift", true)
                        self.sp_ad:setVisible(true)
                        self:logADPush()
                        self.m_useAD = true
                    else
                        self:runCsbAction("idle_logo", true)
                    end
                end
            )
        else
            self:runCsbAction("idle_gift", true)
            self.sp_ad:setVisible(false)
            self.m_useAD = false
        end
    end
end

--function CardStoreGift:resetGift()
--    local rewards = self.store_data:getGiftData()
--    if not rewards then
--        return
--    end
--    self.node_reward:removeChildByName("rewardItem")

--    if rewards.coins and rewards.coins > 0 then
--        local item_info = gLobalItemManager:createLocalItemData("Coins", rewards.coins, {p_limit = 3})
--        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
--        if item then
--            item:setName("rewardItem")
--            item:addTo(self.node_reward)
--        end
--    elseif rewards.gems and rewards.gems > 0 then
--        local item_info = gLobalItemManager:createLocalItemData("Gem", rewards.gems, {p_limit = 3})
--        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
--        if item then
--            item:setName("rewardItem")
--            item:addTo(self.node_reward)
--        end
--    elseif rewards.items and table.nums(rewards.items) > 0 then
--        local item_info = rewards.items[1]
--        local item = gLobalItemManager:createRewardNode(item_info, ITEM_SIZE_TYPE.REWARD)
--        if item then
--            item:setName("rewardItem")
--            item:addTo(self.node_reward)
--        end
--    end
--end

function CardStoreGift:onRefresh()
    local state = STATE.LOGO
    if self.store_data:getCanGiftCollect() then
        state = STATE.GIFT
    end
    self:changeState(state)
end

function CardStoreGift:onReset()
    --self:resetGift()
    self.store_data = G_GetMgr(G_REF.CardStore):getRunningData()
    self:onRefresh()
end

function CardStoreGift:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_free" then
        if self.m_useAD then
            gLobalViewManager:addLoadingAnima()
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:logADClick()
            gLobalAdsControl:playRewardVideo(PushViewPosType.CardStoreCd)
        else
            -- 领取免费礼品
            G_GetMgr(G_REF.CardStore):sendToCollect()
        end
    elseif name == "btn_tip" then
        self:showTip()
    end
end

function CardStoreGift:showTip()
    if not self.timer_tip then
        local timer_tip = util_createView("GameModule.Card.CardStore.views.CardStoreTimerTip")
        if timer_tip then
            timer_tip:addTo(self.node_logo)
            timer_tip:onShow()
            self.timer_tip = timer_tip
        end
    else
        self.timer_tip:onShow()
    end
end

function CardStoreGift:hasAD()
    if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.CardStoreCd) then
        return true
    end
    return false
end

function CardStoreGift:logADPush()
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.CardStoreCd)
    gLobalSendDataManager:getLogAds():setOpenType("TapOpen")
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.CardStoreCd})

    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.CardStoreCd)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
    gLobalSendDataManager:getLogAdvertisement():setadType("Push")
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
end

function CardStoreGift:logADClick()
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.CardStoreCd)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.CardStoreCd)
    gLobalSendDataManager:getLogAds():setOpenType("TapOpen")
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.CardStoreCd}, nil, "click")
end

return CardStoreGift

----
-- 激励视频弹窗
-- 包含三个状态
-- 激励视频看完回调
-- 激励视频弹窗
-- 每日免费轮盘again广告
--
local AdsRewardLayer = class("AdsRewardLayer", BaseLayer)

function AdsRewardLayer:ctor(uiType, position, okFunc, closeFunc, selfCsbPath)
    AdsRewardLayer.super.ctor(self)

    local csb_path = ""
    self.m_isGuideAds = false --是否展示引导
    -- 每日轮盘 again 处理
    if uiType == AdsRewardDialogType.DailyBonus then
        -- 正常弹出激励视频
        if selfCsbPath then
            csb_path = selfCsbPath
        else
            csb_path = "ads/Video_DailyBonus.csb"
        end
        gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
        gLobalSendDataManager:getLogAdvertisement():setadType("Push")
        gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
    elseif uiType == AdsRewardDialogType.Normal then
        -- 看完领奖
        csb_path = "ads/Video_Dialog.csb"
        if position == PushViewPosType.LoginToLobby then
            csb_path = "ads/Ads_login_new.csb"
        end
        if globalData.adsRunData:isGuidePlayAds() then
            self.m_isGuideAds = true
        end
        gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
        gLobalSendDataManager:getLogAdvertisement():setadType("Push")
        gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
    elseif uiType == AdsRewardDialogType.Reward then
        csb_path = "ads/Video_collect.csb"
        if globalData.adsRunData:getGuideAds() then
            self.m_isGuideAds = true
        end
    end

    self:setLandscapeCsbName(csb_path)

    gLobalSendDataManager:getLogAds():setOpenSite(position)
    self.m_layerType = uiType
    self.m_position = position
    self.m_okFunc = okFunc
    self.m_closeFunc = closeFunc
    self.m_touchEnable = true

    self:setPauseSlotsEnabled(true)
end

function AdsRewardLayer:initView()
    if self.m_layerType == AdsRewardDialogType.Normal then
        self:startButtonAnimation("btn_ok", "breathe")
    end
end

function AdsRewardLayer:initUI(uiType, position, okFunc, closeFunc, selfCsbPath)
    AdsRewardLayer.super.initUI(self)
    --第一次引导
    self.m_node_guide = self:findChild("node_guide")
    if self.m_node_guide then
        self.m_node_guide:setVisible(false)
    end
    local touch_guide = self:findChild("touch_guide")
    if touch_guide then
        self:addClick(touch_guide)
    end

    --没钱弹窗
    local sp_noCoinsTitle = self:findChild("sp_noCoinsTitle")
    if sp_noCoinsTitle then
        sp_noCoinsTitle:setVisible(false)
    end

    local node_spine = self:findChild("Node_spine")
    if node_spine then 
        local spine = util_spineCreate("ads/spine/Vedio_npc",false,true, 1)
        node_spine:addChild(spine)
        util_spinePlay(spine, "idle", true)
    end

    local nodeSpine = self:findChild("node_spine_dialog")
    if nodeSpine then 
        local spine = util_spineCreate("ads/spine/juese",false,true, 1)
        nodeSpine:addChild(spine)
        util_spinePlay(spine, "idle", true)
    end

    self.addRewardCoin = 0
    local adsInfo = globalData.adsRunData:getAdsInfoForPos(self.m_position)
    --真实金额
    local m_lb_coins = self:findChild("m_lb_coins")
    self.m_lb_coins = m_lb_coins
    if m_lb_coins and adsInfo then
        self.addRewardCoin = adsInfo.p_coins
        if self.m_isGuideAds and globalData.adsRunData.p_firstCoins then
            --第一次引导
            self.addRewardCoin = globalData.adsRunData.p_firstCoins
        elseif self.m_position == PushViewPosType.NoCoinsToSpin and uiType == AdsRewardDialogType.Normal then
            --没钱spin视频
            self.addRewardCoin = globalData.adsRunData.p_noCoinsMaxCoins
        end
        if uiType == AdsRewardDialogType.Reward then
            if self.m_position == PushViewPosType.NoCoinsToSpin or self.m_position == PushViewPosType.NoCoinsToSpinDouble then
                self.addRewardCoin = globalData.adsRunData.p_noCoinsRealCoins or self.addRewardCoin
            end
            m_lb_coins:setString(util_formatCoins(tonumber(self.addRewardCoin), 30))
            local uiList = {
                {node = self:findChild("sp_coin")},
                {node = m_lb_coins, alignY = 0}
            }
            util_alignCenter(uiList)
        else
            self:jumpCoins(m_lb_coins, self.addRewardCoin)
        end
        self:updateLabelSize({label = m_lb_coins, sx = m_lb_coins:getScaleX(), sy = m_lb_coins:getScaleY()}, 673)
    end
    --第一次引导
    if self.m_isGuideAds then
        local firstPlayRewardVedio = gLobalDataManager:getNumberByField("firstPlayRewardVedio", 0)
        if firstPlayRewardVedio == 0 and self.m_node_guide then
            gLobalDataManager:setNumberByField("firstPlayRewardVedio", 1)
            self.m_node_guide:setVisible(true)
        end
    end

    if uiType == AdsRewardDialogType.Normal then
        local btn_close = self:findChild("btn_close")
        if btn_close then
            btn_close:setVisible(false)
            performWithDelay(
                self,
                function()
                    btn_close:setVisible(true)
                    btn_close:setScale(0.01)
                    btn_close:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(25 / 60, 1)))
                end,
                1.5
            )
        end
    end
    self:setExtendData("AdsRewardLayer")
end

--金币跳动
function AdsRewardLayer:jumpCoins(lb, coins)
    local coins = tonumber(coins)
    local ratio = 0
    local time = 1.5
    local baseCoins = coins * ratio
    local addValue = coins * (1 - ratio) * time / 60
    local lbs_jump = self:findChild("lb_baseCoins")
    lb:setString(util_formatCoins(coins, 30))
    util_jumpNum(
        lb,
        baseCoins,
        coins,
        addValue,
        time / 60,
        {30},
        nil,
        nil,
        nil,
        function()
            local uiList = {
                {node = self:findChild("sp_coin")},
                {node = lb, alignX = 5, alignY = 7}
            }
            util_alignCenter(uiList)
        end
    )
end

function AdsRewardLayer:onKeyBack()
    -- if self.m_touchEnable == false then
    --     return
    -- end

    --点击其他按钮回调
    if self.m_layerType ~= AdsRewardDialogType.Reward then
        gLobalSendDataManager:getLogAds():setOpenStatus("Refuse")
        gLobalSendDataManager:getLogAds():sendAdsLog()

        -- self.m_touchEnable = false
        -- self:closeUI(self.m_closeFunc)
        AdsRewardLayer.super.onKeyBack(self, self.m_closeFunc)
    end
end

function AdsRewardLayer:closeUI(func)
    if self.isClose then
        return
    end
    self.isClose = true

    if self.m_node_guide then
        self.m_node_guide:setVisible(false)
    end

    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "configPushView")
        if func then
            func()
        end
    end

    AdsRewardLayer.super.closeUI(self, callback)
end

--点击监听
function AdsRewardLayer:clickStartFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_ok" then
        if self.m_layerType == AdsRewardDialogType.Normal then
            self:pauseForIndex(130)
        end
    end
end

function AdsRewardLayer:clickEndFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_ok" then
        if not self.isClose then
            if self.m_layerType == AdsRewardDialogType.Normal then
                self:runCsbAction("idle", true, nil, 60)
            end
        end
    end
end

function AdsRewardLayer:onClickOk(sender)
    if not sender then
        return
    end

    if not self.isClose then
    -- gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    end
    if self.m_layerType ~= AdsRewardDialogType.Reward then
        gLobalNoticManager:postNotification("hide_vedio_icon")
    end
    --点击OK按钮回调
    if self.m_layerType ~= AdsRewardDialogType.Reward then
        gLobalSendDataManager:getLogAds():setOpenStatus("Allow")
        globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = gLobalSendDataManager:getLogAds().m_taskOpenSite}, nil, "click")
    end
    if not self.isClose and self.m_layerType == AdsRewardDialogType.Reward and self.m_lb_coins ~= nil then
        local startPos = sender:getParent():convertToWorldSpace(cc.p(sender:getPosition()))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount

        gLobalViewManager:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            tonumber(self.addRewardCoin),
            function()
                self:closeUI(self.m_okFunc)
            end
        )
    else
        self:closeUI(self.m_okFunc)
    end
end

function AdsRewardLayer:onClickMask()
    if self.m_touchEnable == false or self.m_layerType ~= AdsRewardDialogType.Reward then
        return
    end
    self.m_touchEnable = false

    local sender = self:findChild("btn_ok")
    self:onClickOk(sender)
end

function AdsRewardLayer:clickFunc(sender)
    if self.m_touchEnable == false then
        return
    end
    self.m_touchEnable = false
    local name = sender:getName()
    local tag = sender:getTag()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- 尝试重新连接 network
    if name == "btn_ok" then
        self:onClickOk(sender)
    elseif name == "touch_guide" then
        self.m_touchEnable = true
        sender:setTouchEnabled(false)
        if self.m_node_guide then
            self.m_node_guide:setVisible(false)
        end
    else
        if not self.isClose then
        -- gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
        gLobalSendDataManager:getLogAds():setOpenStatus("Refuse")
        gLobalSendDataManager:getLogAds():sendAdsLog(true)
        --点击其他按钮回调
        self:closeUI(self.m_closeFunc)
    end
end

-- 重写动画
function AdsRewardLayer:playShowAction()
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
                self:runCsbAction("idle", true, nil, 60)
            end,
            60
        )
    end
    AdsRewardLayer.super.playShowAction(self, userDefAction)
end

return AdsRewardLayer

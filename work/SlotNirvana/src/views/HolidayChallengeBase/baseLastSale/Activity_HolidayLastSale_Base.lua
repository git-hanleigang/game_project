--[[
    @desc: 圣诞节聚合挑战-最后一天促销
    time:2021-11-10 17:50:42
]]
local Activity_HolidayLastSale_Base = class("Activity_HolidayLastSale_Base", BaseLayer)

function Activity_HolidayLastSale_Base:ctor()
    Activity_HolidayLastSale_Base.super.ctor(self)

    self:setLandscapeCsbName(self:getSelfCsbName())
end

function Activity_HolidayLastSale_Base:getSelfCsbName()
    local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    return  config.RESPATH.HOLIDAY_LASTSALE_LAYER
end

function Activity_HolidayLastSale_Base:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self:startButtonAnimation("btn_start", "sweep", true) 
    self.m_spTime = self:findChild("sp_today")
end

function Activity_HolidayLastSale_Base:initView()
    self.m_djsLabel = self:findChild("lb_time2")
    local saleData = G_GetMgr(ACTIVITY_REF.ChallengePassLastSale):getRunningData()
    if saleData then
        self.m_goodsInfo = saleData:getGoodsInfo()
        self:setButtonLabelContent("btn_start", "$"..self.m_goodsInfo.price)

        if saleData:getPay() then
            self:setButtonLabelContent("btn_start", "WOW!")
        end
        if self.m_djsLabel then
            self:showDownTimer()
        end
    end
end

--显示倒计时
function Activity_HolidayLastSale_Base:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function Activity_HolidayLastSale_Base:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function Activity_HolidayLastSale_Base:updateLeftTime()
    local gameData = G_GetMgr(ACTIVITY_REF.ChallengePassLastSale):getRunningData()
    if gameData ~= nil then
        local leftTime = math.max(gameData:getExpireAt(), 0)
        local strLeftTime = util_daysdemaining(leftTime)
        self.m_djsLabel:setString(strLeftTime)
    else
        self:stopTimerAction()
    end
end

function Activity_HolidayLastSale_Base:onKeyBack()
    -- 手机点击返回按钮也会调用这里
    self:closeUI(function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end)
end

-- 重写父类方法 
function Activity_HolidayLastSale_Base:onShowedCallFunc( )
    -- 展开动画
    self:runCsbAction("idle", true, nil, 60)
end

function Activity_HolidayLastSale_Base:playShowAction()
    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    Activity_HolidayLastSale_Base.super.playShowAction(self, userDefAction)
end

function Activity_HolidayLastSale_Base:onEnter()
    Activity_HolidayLastSale_Base.super.onEnter(self)

    if self.m_spTime then
        if not self:isShowActionEnabled() then
            self.m_spTime:setVisible(false)
        end
    end
    
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.ChallengePassLastSale then
                self:closeUI(function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end
function Activity_HolidayLastSale_Base:onExit()
    self:stopTimerAction()
    Activity_HolidayLastSale_Base.super.onExit(self)
end

function Activity_HolidayLastSale_Base:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_start" then
        local saleData = G_GetMgr(ACTIVITY_REF.ChallengePassLastSale):getRunningData()
        if saleData then
            if saleData:getPay() then
                gLobalSoundManager:playSound(SOUND_ENUM.SOUND_HIDE_VIEW)
                self:closeUI(function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end)
            else
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                -- 购买
                self:buySale()
            end
        end
    elseif senderName == "btn_close" then
        self:closeUI(function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end)
    end
end

function Activity_HolidayLastSale_Base:buySale()
    if self.m_purchasing then
        return 
    end
    self.m_purchasing = true

    self:sendIapLog()
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.CHALLENGEPASS_LASTSALE,
        self.m_goodsInfo.keyId,
        self.m_goodsInfo.price,
        0,
        0,
        function()
            self.m_purchasing = false
            if self.buySuccess ~= nil then
                self:buySuccess()
            end
        end,
        function()
            self.m_purchasing = false
            if self.buyFailed ~= nil then
                self:buyFailed()
            end
        end
    )
end

function Activity_HolidayLastSale_Base:buySuccess()
    local closeFunc = function()
        gLobalViewManager:checkBuyTipList(function() 
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end)
    end

    self:closeUI(closeFunc)
end

function Activity_HolidayLastSale_Base:buyFailed()
    self.m_purchasing = false
end

function Activity_HolidayLastSale_Base:sendIapLog()
    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "HolidayLastSale"
    goodsInfo.goodsId = self.m_goodsInfo.keyId
    goodsInfo.goodsPrice = self.m_goodsInfo.price
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "HolidayLastSale"
    purchaseInfo.purchaseStatus = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getProgressString()

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end


return Activity_HolidayLastSale_Base

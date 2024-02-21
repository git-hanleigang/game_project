--[[
    独立日新版聚合挑战 规则弹板
    author:csc
    time:2021-05-31
]]
local HolidayChallenge_BaseSaleLayer = class("HolidayChallenge_BaseSaleLayer", BaseLayer)

function HolidayChallenge_BaseSaleLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.UNLOCKPAY_LAYER)
    self:setExtendData("HolidayChallengeSaleLayer")
end

function HolidayChallenge_BaseSaleLayer:initCsbNodes()
    -- 界面上的奖励点
    self.m_nodeRewardItem = {}
    self.m_nodeRewardItem_high = {}

    for i = 1,5 do
        local node = self:findChild("node_reward"..i)
        table.insert(self.m_nodeRewardItem,node)

        local node_h = self:findChild("node_reward1"..i)
        table.insert(self.m_nodeRewardItem_high,node_h)
    end

    self.m_btn_unlock = self:findChild("btn_unlock")
    self.m_btn_double = self:findChild("btn_double")
    self.m_sp_done = self:findChild("sp_done1")

    self.m_lb_right_unlock = self:findChild("lb_right_unlock")
    self.m_lb_double = self:findChild("lb_double")

    local key = "" .. G_GetMgr(ACTIVITY_REF.HolidayChallenge):getThemeName() .."SendLayer:btn_go"
    local lbString = gLobalLanguageChangeManager:getStringByKey(key) or "CAN'T WAIT"
    self:setButtonLabelContent("btn_go", lbString)
end

function HolidayChallenge_BaseSaleLayer:initView()
    local data = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    if data then
        self.m_bUnlocked = data:getUnlocked()
        self.m_bHighUnlocked = data:getHighUnlocked()
        self.m_btn_unlock:setVisible(not self.m_bUnlocked)
        self.m_sp_done:setVisible(self.m_bUnlocked)

        if not self.m_bUnlocked then 
            self:startButtonAnimation("btn_unlock", "sweep", true) 
        end

        self.m_lb_right_unlock:setVisible(not self.m_bUnlocked)
        self.m_lb_double:setVisible(self.m_bUnlocked)

        self:startButtonAnimation("btn_double", "sweep", true) 

        self.m_payInfo = data:getPayInfo()
        self:setButtonLabelContent("btn_unlock", "$"..self.m_payInfo.price)
    
        self.m_highPayInfo = data:getHighPriceSaleData()
        self:setButtonLabelContent("btn_double", "$"..self.m_highPayInfo.m_price)

        for i = 1 ,5 do
            --加载购买可解锁的道具
            local nodeItem = self.m_nodeRewardItem[i]
            local nodeItem_h = self.m_nodeRewardItem_high[i]
            local payRewardData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getPayRewardDataByIndex(i)
            local itemNode = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getItemNode(payRewardData,ITEM_SIZE_TYPE.REWARD,true,true)
            if itemNode then
                nodeItem:addChild(itemNode)
            end

            local itemNode_h = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getItemNode(payRewardData,ITEM_SIZE_TYPE.REWARD,true,true)
            if itemNode_h then
                nodeItem_h:addChild(itemNode_h)
            end

            if self.m_bUnlocked then 
                local boardNode = self:findChild("sp_board"..i)
                if  boardNode then
                    local sprLock = boardNode:getChildByName("sp_lock")
                    if sprLock then
                        sprLock:setVisible(false)
                    end
                end

                local boardNode = self:findChild("sp_star"..i)
                if  boardNode then
                    local sprLock = boardNode:getChildByName("sp_x2")
                    if sprLock then
                        sprLock:setVisible(false)
                    end
                end
            end
        end
    end  
    
    if data and data:getUnlocked() then
        self:runCsbAction("idle2", true, nil, 60)
    else
        self:runCsbAction("idle", true, nil, 60)
    end

    self:updateBtnBuck()
end

function HolidayChallenge_BaseSaleLayer:updateBtnBuck()
    local buyType = BUY_TYPE.CHALLENGEPASS_UNLOCK
    self:setBtnBuckVisible(self:findChild("btn_unlock"), buyType)
    self:setBtnBuckVisible(self:findChild("btn_double"), buyType)
end

-- 重写父类方法 
function HolidayChallenge_BaseSaleLayer:onEnter()
    HolidayChallenge_BaseSaleLayer.super.onEnter(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.HolidayChallenge then
                self:removeFromParent()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function HolidayChallenge_BaseSaleLayer:onExit()
    HolidayChallenge_BaseSaleLayer.super.onExit(self)
end

function HolidayChallenge_BaseSaleLayer:clickFunc(sender)
    if self.m_isIncAction then
        return
    end
    self.m_isIncAction = true

    local name = sender:getName()
    if name == "btn_unlock" then
        --购买
        if self.m_bUnlocked then
            if gLobalViewManager:getViewLayer():getChildByName("HolidayChallengeMainLayer")then
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            end
            self:closeUI(function (  )
                -- 需要打开界面
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
            end)
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:buyUnlock()
        end
    elseif name == "btn_double" then
        if self.m_bHighUnlocked then
            if gLobalViewManager:getViewLayer():getChildByName("HolidayChallengeMainLayer")then
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            end
            self:closeUI(function (  )
                -- 需要打开界面
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
            end)
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:buyHighUnlock()
        end
    elseif name == "btn_close" then
        self:closeUI(function (  )
            -- 需要打开界面
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
        end)
    end
end

-- 购买解锁
function HolidayChallenge_BaseSaleLayer:buyUnlock()
    if self.m_purchasing then
        return 
    end

    local actData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if not actData then
        return
    end
    self.m_purchasing = true
    self:sendIapLog(1)
    gLobalSaleManager:purchaseActivityGoods(
        actData:getActivityID(),
        "1",
        BUY_TYPE.CHALLENGEPASS_UNLOCK,
        self.m_payInfo.keyId, 
        self.m_payInfo.price, 
        0, 
        0, 
        function()
            self.m_purchasing = false
            if self.buySuccess ~= nil then
                self:buySuccess(1)
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

function HolidayChallenge_BaseSaleLayer:buyHighUnlock()
    if self.m_purchasing then
        return 
    end
    
    local actData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if not actData then
        return
    end
    self.m_purchasing = true
    self:sendIapLog(actData:getUnlocked() and 2 or 3)
    gLobalSaleManager:purchaseActivityGoods(
        actData:getActivityID(),
        "2",
        BUY_TYPE.CHALLENGEPASS_UNLOCK,
        self.m_highPayInfo.m_keyId, 
        self.m_highPayInfo.m_price, 
        0, 
        0, 
        function()
            self.m_purchasing = false
            if self.buySuccess ~= nil then
                self:buySuccess(2)
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

function HolidayChallenge_BaseSaleLayer:buySuccess(buyType)
    local closeFunc = function()
        gLobalViewManager:checkBuyTipList(function() 
            if CardSysManager:needDropCards("Purchase") == true then
                CardSysManager:doDropCards("Purchase", function()
                    -- 需要打开界面
                    G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_BUYSUCCESS)
                    if buyType == 2 then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_BUY_DOUBLE_REWARD)
                    end
                end)
            else
                -- 需要打开界面
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_BUYSUCCESS)
                if buyType == 2 then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_BUY_DOUBLE_REWARD)
                end
            end 
        end)
    end

    self:closeUI(closeFunc)
end

function HolidayChallenge_BaseSaleLayer:buyFailed()
    self.m_isIncAction = false
end

function HolidayChallenge_BaseSaleLayer:sendIapLog(type)
    -- 商品信息
    local goodsInfo = {}
    local saleData = self.m_payInfo
    goodsInfo.goodsTheme = "HolidaySale"
    goodsInfo.goodsId = self.m_payInfo.keyId
    goodsInfo.goodsPrice = self.m_payInfo.price
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    
    if type == 1 then
        purchaseInfo.purchaseName = "HolidayPassSale"
    elseif type == 2 then
        purchaseInfo.purchaseName = "HolidayDoubleSale"
    else
        purchaseInfo.purchaseName = "HolidayAllSale"
    end
    purchaseInfo.purchaseStatus = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getProgressString()

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end

return HolidayChallenge_BaseSaleLayer

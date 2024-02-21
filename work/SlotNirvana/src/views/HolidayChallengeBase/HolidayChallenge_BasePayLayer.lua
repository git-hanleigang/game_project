--[[
    独立日新版聚合挑战 规则弹板
    author:csc
    time:2021-05-31
]]
local HolidayChallenge_BasePayLayer = class("HolidayChallenge_BasePayLayer", BaseLayer)

function HolidayChallenge_BasePayLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.UNLOCKPAY_LAYER)
end

function HolidayChallenge_BasePayLayer:initCsbNodes()
    -- 界面上的奖励点
    self.m_nodeRewardItem = {}
    self.m_nodeRewardStarNum = {}
    for i = 1,5 do
        local node = self:findChild("node_reward"..i)
        table.insert(self.m_nodeRewardItem,node)

        local labStar = self:findChild("lb_star"..i)
        table.insert(self.m_nodeRewardStarNum,labStar)
    end

    self:startButtonAnimation("btn_pay", "sweep", true) 

    local key = "" .. G_GetMgr(ACTIVITY_REF.HolidayChallenge):getThemeName() .."SendLayer:btn_go"
    local lbString = gLobalLanguageChangeManager:getStringByKey(key) or "CAN'T WAIT"
    self:setButtonLabelContent("btn_go", lbString)
end

function HolidayChallenge_BasePayLayer:initView()
    local data = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    if data then
        --加载进度
        -- self.m_labProgress:setString(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getProgressString())

                --
        self.m_bUnlocked = data:getUnlocked()
        if self.m_bUnlocked == false then 
            self.m_payInfo = data:getPayInfo()
            self:setButtonLabelContent("btn_pay", "$"..self.m_payInfo.price)
        else
            self:setButtonLabelContent("btn_pay", "GO FOR IT")
        end 

        for i = 1 ,5 do
            --加载购买可解锁的道具
            local nodeItem = self.m_nodeRewardItem[i]
            local payRewardData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getPayRewardDataByIndex(i)
            local itemNode = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getItemNode(payRewardData,ITEM_SIZE_TYPE.REWARD,true,true)
            if itemNode then
                nodeItem:addChild(itemNode)
            end

            --加载可获得奖励的数量
            local nodeLab = self.m_nodeRewardStarNum[i]
            nodeLab:setString(payRewardData:getPoints())
            
            --csc 2021年12月14日17:27:01 新需求隐藏锁
            if self.m_bUnlocked then 
                local boardNode = self:findChild("sp_board"..i)
                if  boardNode then
                    local sprLock = boardNode:getChildByName("sp_lock")
                    if sprLock then
                        sprLock:setVisible(false)
                    end
                end
            end
        end
    end   

    self:updateBtnBuck()
end

function HolidayChallenge_BasePayLayer:updateBtnBuck()
    local buyType = BUY_TYPE.CHALLENGEPASS_UNLOCK
    self:setBtnBuckVisible(self:findChild("btn_pay"), buyType)
end

-- 重写父类方法 
function HolidayChallenge_BasePayLayer:onShowedCallFunc()
    -- 展开动画
    self:runCsbAction("idle", true, nil, 60)
end

-- 重写父类方法 
function HolidayChallenge_BasePayLayer:onEnter()
    HolidayChallenge_BasePayLayer.super.onEnter(self)

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

function HolidayChallenge_BasePayLayer:onExit()
    HolidayChallenge_BasePayLayer.super.onExit(self)
end

function HolidayChallenge_BasePayLayer:clickFunc(sender)
    if self.m_isIncAction then
        return
    end
    self.m_isIncAction = true

    local name = sender:getName()
    if name == "btn_pay" then
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
    elseif name == "btn_close" then
        self:closeUI(function (  )
            -- 需要打开界面
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
        end)
    end
end

-- 购买解锁
function HolidayChallenge_BasePayLayer:buyUnlock()
    if self.m_purchasing then
        return 
    end
    self.m_purchasing = true

    self:sendIapLog()
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.CHALLENGEPASS_UNLOCK,
        self.m_payInfo.keyId,
        self.m_payInfo.price,
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

function HolidayChallenge_BasePayLayer:buySuccess()
    local closeFunc = function()
        gLobalViewManager:checkBuyTipList(function() 
            if CardSysManager:needDropCards("Purchase") == true then
                CardSysManager:doDropCards("Purchase", function()
                    -- 需要打开界面
                    G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_BUYSUCCESS)
                end)
            else
                -- 需要打开界面
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_BUYSUCCESS)
            end 
        end)
    end

    self:closeUI(closeFunc)
end

function HolidayChallenge_BasePayLayer:buyFailed()
    self.m_isIncAction = false
end

function HolidayChallenge_BasePayLayer:sendIapLog()
    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "HolidaySale"
    goodsInfo.goodsId = self.m_payInfo.keyId
    goodsInfo.goodsPrice = self.m_payInfo.price
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "HolidaySale"
    purchaseInfo.purchaseStatus = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getProgressString()

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
end

return HolidayChallenge_BasePayLayer

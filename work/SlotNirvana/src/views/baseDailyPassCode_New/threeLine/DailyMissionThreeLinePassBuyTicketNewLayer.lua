--[[
    --新版每日任务pass主界面 新版 buyticket 界面
    csc 2021年09月06日
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseLayer = util_require("base.BaseLayer")
local DailyMissionThreeLinePassBuyTicketNewLayer = class("DailyMissionThreeLinePassBuyTicketNewLayer", BaseLayer)

function DailyMissionThreeLinePassBuyTicketNewLayer:initCsbNodes()
    -- left
    self.m_labNewPriceLeft = self:findChild("lb_newPrice_Left")
    self.m_labNewPriceMiddle = self:findChild("lb_newPrice_middle")
    self.m_labNewPriceRight = self:findChild("lb_newPrice_Right")

    self.m_node_buyRight = self:findChild("node_buy3")

    self.m_spHasLeft = self:findChild("sp_dui1")
    self.m_spHasMiddle = self:findChild("sp_dui2")

    
    self.m_labRightPriceDiscount = self:findChild("Text_15")
    self.m_spRightPriceDiscount = self:findChild("tag_27")

    self.m_nodeNewPriceRight = self:findChild("node_3newPrice_left")

    self.m_labTotoalValueLeft = self:findChild("txt_desc1_worth")
    self.m_labMorePointMiddle = self:findChild("lb_2morePoints")
    self.m_labTotoalValueMiddle = self:findChild("lb_2totalValue")
    
    self.m_node_user = self:findChild("node_user")
    self.m_node_normal = self:findChild("node_normal")
end

function DailyMissionThreeLinePassBuyTicketNewLayer:initDatas(data)
    DailyMissionThreeLinePassBuyTicketNewLayer.super.initDatas(self)
    self.m_fromPop = false 
    if data then
        self.m_fromPop = data.fromPop
    end
    self.m_tagNodes = {}

    -- 设置横屏csb
    self:setLandscapeCsbName(DAILYPASS_RES_PATH.DailyMissionPass_BuyTicketNewLayer_ThreeLine)
    self:setPortraitCsbName(DAILYPASS_RES_PATH.DailyMissionPass_BuyTicketNewLayer_Vertical_ThreeLine)

    self:setPauseSlotsEnabled(true)
end

function DailyMissionThreeLinePassBuyTicketNewLayer:initView()
    local newPassData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not newPassData then
        return
    end
    self.m_goodInfo = G_GetMgr(ACTIVITY_REF.NewPassBuy):getPayPassTicketInfo()
    if not self.m_goodInfo then
        return
    end

    self.m_spHasLeft:setVisible(newPassData:isUnlocked())
    self.m_spHasMiddle:setVisible(newPassData:getCurrIsPayHigh())
    self:findChild("btn_buy1"):setVisible(not newPassData:isUnlocked())
    self:findChild("btn_store1"):setVisible(not newPassData:isUnlocked())
    self:findChild("btn_buy2"):setVisible(not newPassData:getCurrIsPayHigh())
    self:findChild("btn_store2"):setVisible(not newPassData:getCurrIsPayHigh())

    local isNewUser = gLobalDailyTaskManager:isWillUseNovicePass()
    self.m_node_user:setVisible(isNewUser)
    self.m_node_normal:setVisible(not isNewUser)

    if newPassData:getCurrIsPayHigh() or newPassData:isUnlocked() then
        self.m_node_buyRight:setVisible(false) 
        self:runCsbAction("idle2", true, nil, 60)
    else
        self:runCsbAction("idle", true, nil, 60)
    end

    local passTime = newPassData:getExpireAt()
    local saveTime = gLobalDataManager:getNumberByField("passCoupon", 0)
    local smallPrice = 0
    local leftData = self.m_goodInfo[1]
    if leftData then
        local goodsInfo = leftData:getGoodsInfo()
        self.m_labNewPriceLeft:setString("$" .. goodsInfo.price)
        self.m_labTotoalValueLeft:setString("$" .. leftData:getWorthDisPlay())
        local saleData = {p_price = goodsInfo.price, p_vipPoint = goodsInfo.vipPoints}
        self.m_item = gLobalItemManager:checkAddLocalItemList(saleData, nil, "BattlePass")

        local node = self:findChild("node_tag1")
        local beforePrice = leftData:getBeforePrice()
        if beforePrice ~= "" and node then
            local discount = math.floor((1 - tonumber(goodsInfo.price) / tonumber(beforePrice)) * 100)
            local tag = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuySaleTag, discount)
            node:addChild(tag)
            table.insert(self.m_tagNodes, {tag = tag, num = goodsInfo.price, label = self.m_labNewPriceLeft})
            
            if passTime > saveTime then
                self.m_labNewPriceLeft:setString("$" .. beforePrice)
                self.m_hasCoupon = true
            else
                tag:playIdle2()
            end

            smallPrice = smallPrice + tonumber(beforePrice)
        else
            smallPrice = smallPrice + tonumber(goodsInfo.price) 
        end
    end

    local middleData = self.m_goodInfo[2]
    if middleData then
        local goodsInfo = middleData:getGoodsInfo()
        self.m_labNewPriceMiddle:setString("$" .. goodsInfo.price)
        self.m_labTotoalValueMiddle:setString("$" .. middleData:getWorthDisPlay())
        self.m_labMorePointMiddle:setString("" .. middleData:getExpPercent() .."%")
        
        local saleData = {p_price = goodsInfo.price, p_vipPoint = goodsInfo.vipPoints}
        self.m_item_middle = gLobalItemManager:checkAddLocalItemList(saleData, nil, "BattlePass")

        local node = self:findChild("node_tag2")
        local beforePrice = middleData:getBeforePrice()
        if beforePrice ~= "" and node then
            local discount = math.floor((1 - tonumber(goodsInfo.price) / tonumber(beforePrice)) * 100)
            local tag = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuySaleTag, discount)
            node:addChild(tag)
            table.insert(self.m_tagNodes, {tag = tag, num = goodsInfo.price, label = self.m_labNewPriceMiddle})
            
            if passTime > saveTime then
                self.m_labNewPriceMiddle:setString("$" .. beforePrice)
                self.m_hasCoupon = true
            else
                tag:playIdle2()
            end

            smallPrice = smallPrice + tonumber(beforePrice)
        else
            smallPrice = smallPrice + tonumber(goodsInfo.price) 
        end
    end

    local rightData = self.m_goodInfo[3]
    if rightData then
        local goodsInfo = rightData:getGoodsInfo()
        self.m_labNewPriceRight:setString("$" .. goodsInfo.price)
        
        local saleData = {p_price = goodsInfo.price, p_vipPoint = goodsInfo.vipPoints}
        self.m_ritem = gLobalItemManager:checkAddLocalItemList(saleData, nil, "BattlePass")

        local node = self:findChild("node_tag3")
        local beforePrice = rightData:getBeforePrice()
        if beforePrice ~= "" and node then
            self.m_spRightPriceDiscount:setVisible(false)
            local discount = math.floor(((1 - (tonumber(goodsInfo.price) / smallPrice))) * 100)
            local tag = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuySaleTag, discount)
            node:addChild(tag)
            table.insert(self.m_tagNodes, {tag = tag, num = goodsInfo.price, label = self.m_labNewPriceRight})
            
            if passTime > saveTime then
                self.m_labNewPriceRight:setString("$" .. beforePrice)
                self.m_hasCoupon = true
            else
                tag:playIdle2()
            end
        else
            local discount = math.floor((1 - (tonumber(goodsInfo.price) / smallPrice)) * 100) 
            self.m_spRightPriceDiscount:setVisible(discount > 0)
            self.m_labRightPriceDiscount:setString("-" .. math.floor(discount) .."%")
        end
    end

    self:updateBtnBuck()
end

function DailyMissionThreeLinePassBuyTicketNewLayer:updateBtnBuck()
    local buyType = BUY_TYPE.TRIPLEXPASS_PASSTICKET
    if gLobalDailyTaskManager:isWillUseNovicePass() then
        buyType = BUY_TYPE.TRIPLEXPASS_PASSTICKET_NOVICE
    end    
    local offsetX = 0
    -- if globalData.slotRunData.isPortrait then
    --     offsetX = 18
    -- end
    self:setBtnBuckVisible(self:findChild("btn_buy1"), buyType, nil, {{node = self:findChild("node_1newPrice_left"), addX = offsetX}})
    self:setBtnBuckVisible(self:findChild("btn_buy2"), buyType, nil, {{node = self:findChild("node_2newPrice_left"), addX = offsetX}})
    self:setBtnBuckVisible(self:findChild("btn_buy3"), buyType, nil, {{node = self:findChild("node_3newPrice_left"), addX = offsetX}})
end

function DailyMissionThreeLinePassBuyTicketNewLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_buy1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buyGoods(1)
    elseif name == "btn_buy2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buyGoods(2)
    elseif name == "btn_buy3" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buyGoods(3)
    elseif name == "btn_store1" then
        if not self.m_item or #self.m_item == 0 then
            return
        end
        G_GetMgr(G_REF.PBInfo):showPBInfoLayer(nil, self.m_item)
    elseif name == "btn_store2" then
         if not self.m_item_middle or #self.m_item_middle == 0 then
            return
        end
        G_GetMgr(G_REF.PBInfo):showPBInfoLayer(nil, self.m_item_middle)
    elseif name == "btn_store3" then
        if not self.m_ritem or #self.m_ritem == 0 then
           return
       end
       G_GetMgr(G_REF.PBInfo):showPBInfoLayer(nil, self.m_ritem)
    end
end

-- 购买等级
function DailyMissionThreeLinePassBuyTicketNewLayer:buyGoods(_index)
    if not self.m_goodInfo then
        return
    end
    if self.m_purchasing then
        return
    end
    self.m_purchasing = true

    local goodsInfo = self.m_goodInfo[_index]:getGoodsInfo()

    self:sendIapLog(goodsInfo, _index)
    G_GetMgr(ACTIVITY_REF.NewPass):checkDoUnlockGuide()

    local buyType = BUY_TYPE.TRIPLEXPASS_PASSTICKET
    if gLobalDailyTaskManager:isWillUseNovicePass() then
        buyType = BUY_TYPE.TRIPLEXPASS_PASSTICKET_NOVICE
    end

    gLobalSaleManager:purchaseGoods(
        buyType,
        goodsInfo.key,
        goodsInfo.price,
        0,
        0,
        function()
            self.m_purchasing = false
            if self.buySuccess ~= nil then
                self:buySuccess()
            else
            end
        end,
        function()
            self.m_purchasing = false
            if self.buyFailed ~= nil then
                self:buyFailed()
            else
            end
        end
    )
end

function DailyMissionThreeLinePassBuyTicketNewLayer:buySuccess(oldLevel)
    gLobalBattlePassManager:removeInfoPbNode(self.m_pbNode1)
    gLobalBattlePassManager:removeInfoPbNode(self.m_pbNode2)
    gLobalSendDataManager:getLogIap():setLastEntryType()
    local closeFunc = function()
        if not tolua.isnull(self) then
            self:closeUI(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_BUY_PASSTICKET, {success = true})
                end
            )
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_BUY_PASSTICKET, {success = true})
        end
    end
    gLobalViewManager:checkBuyTipList(closeFunc)
end

function DailyMissionThreeLinePassBuyTicketNewLayer:buyFailed()
    local key = DAILYPASS_EXTRA_CONFIG.DailyMissionPass_CloseBuyTicketLayerPopUnlock
    local currTime = math.floor(globalData.userRunData.p_serverTime / 1000)
    gLobalDataManager:setNumberByField(key, currTime + 10*60)
end

-- 客户端打点
function DailyMissionThreeLinePassBuyTicketNewLayer:sendIapLog(_goodsInfo, _index)
    if _goodsInfo ~= nil then
        -- 商品信息
        local goodsInfo = {}

        goodsInfo.goodsTheme = "GloryPassTicket"
        goodsInfo.goodsId = _goodsInfo.key
        goodsInfo.goodsPrice = _goodsInfo.price
        goodsInfo.discount = 0
        goodsInfo.totalCoins = 0

        -- 购买信息
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "LimitBuy"
        purchaseInfo.purchaseName = "GloryPassTicket"
        if _index == 2 then
            purchaseInfo.purchaseName = "GloryPassAdvance"
        elseif _index == 3 then
            purchaseInfo.purchaseName = "GloryPassAll"
        end
        local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        if not actData then
            return
        end
        purchaseInfo.purchaseStatus = actData:getLevel()
        gLobalSendDataManager:getLogIap():setEntryType("GloryPass")
        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end

function DailyMissionThreeLinePassBuyTicketNewLayer:onEnter()
    DailyMissionThreeLinePassBuyTicketNewLayer.super.onEnter(self)

    -- 促销到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.NewPass then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_DAILY_TASK_UI_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self.m_purchasing = false
        end,
        ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE
    )

    -- csc 特殊补单逻辑,执行购买成功的动画
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self.m_purchasing = false
            if self.buySuccess ~= nil then
                self:buySuccess()
            end
        end,
        IapEventType.IAP_RetrySuccess
    )

    -- 折扣动画
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            for i,v in ipairs(self.m_tagNodes) do
                v.tag:playStart()
                v.label:setString("$" .. v.num)
            end
        end,
        ViewEventType.NOTIFY_PASS_DISCOUNT_EF_END
    )
end

-- 重写父类close ui
function DailyMissionThreeLinePassBuyTicketNewLayer:closeUI(callfun)
    if self:isShowing() or self:isHiding() then
        return
    end

    -- 判断是否能够弹出 购买门票解锁奖励的弹板 
    local callback = function ()
        if callfun then
            callfun()
        end
        if self.m_fromPop then
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
        local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        if not actData then
            return
        end
        if G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():isUnlocked() and G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getCurrIsPayHigh() then
            return
        end
        local key = DAILYPASS_EXTRA_CONFIG.DailyMissionPass_CloseBuyTicketLayerPopUnlock
        local value = actData:getPopUpCd() 
        

        if ((actData:getPopUpDisplay() ~= nil and #actData:getPopUpDisplay() > 0) or(actData:getPopUpTriplexDisplay() ~= nil and #actData:getPopUpTriplexDisplay() > 0)) and gLobalDailyTaskManager:checkPopViewCD(key, value) then
            G_GetMgr(ACTIVITY_REF.NewPass):showBuyTicketRewardLayer(true)
        end
    end
    DailyMissionThreeLinePassBuyTicketNewLayer.super.closeUI(self, callback)
end

function DailyMissionThreeLinePassBuyTicketNewLayer:onShowedCallFunc()
    if self.m_hasCoupon then
        local newPassData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        if newPassData then
            local passTime = newPassData:getExpireAt()
            gLobalDataManager:setNumberByField("passCoupon", passTime)
        end
        local efLayer = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuySaleTagEf)
        gLobalViewManager:showUI(efLayer, ViewZorder.ZORDER_UI)
    end
end

return DailyMissionThreeLinePassBuyTicketNewLayer

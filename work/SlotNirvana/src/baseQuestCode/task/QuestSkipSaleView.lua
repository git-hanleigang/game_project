-- Quest 购买直接完成quest任务

local QuestSkipSaleView = class("QuestSkipSaleView", BaseLayer)

function QuestSkipSaleView:initDatas()
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestSkipSaleView)
    self:setPortraitCsbName(QUEST_RES_PATH.QuestSkipSaleProView)

    self:setPauseSlotsEnabled(true)
end

function QuestSkipSaleView:initUI(isGameEffect, isAutoClose)
    self.m_isGameEffect = isGameEffect
    self.m_isAutoClose = isAutoClose or false
    QuestSkipSaleView.super.initUI(self)

    local config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if config then
        self.skipSale = config:getSkipSaleDate()
    end

    self:initLuckyStampNode(
        function()
            self:initBPInfoNode()
        end
    )

    self:initViews()
end

function QuestSkipSaleView:initViews()
    if not self.skipSale then
        return
    end
    local lalbelCoins = self:findChild("coins_label")

    lalbelCoins:setString(util_formatMoneyStr(tostring(self.skipSale.p_coins)))

    local btn_start = "QuestSkipSaleView:btn_start"
    local labelString = gLobalLanguageChangeManager:getStringByKey(btn_start)

    self.lb_buy_num = self:findChild("lb_buy_num")
    if not tolua.isnull(self.lb_buy_num) then
        self.lb_buy_num:setString(labelString .. self.skipSale.p_price)
    end

    -- price pre
    self.m_lb_fakePrice = self:findChild("lb_pricePre")
    if not tolua.isnull(self.m_lb_fakePrice) then
        local sp_line = self:findChild("sp_line")
        if not tolua.isnull(sp_line) then
            sp_line:setVisible(false)
        end
        self.m_lb_fakePrice:setVisible(false)
        if self.skipSale.p_fakePrice and self.skipSale.p_fakePrice ~= "" then
            self.m_lb_fakePrice:setVisible(true)
            if not tolua.isnull(sp_line) then
                sp_line:setVisible(true)
            end
            local string = gLobalLanguageChangeManager:getStringByKey("QuestSkipSaleView:lb_pricePre")
            self.m_lb_fakePrice:setString(string .. self.skipSale.p_fakePrice)
        end
    end

    -- 自动关闭
    self:initAutoClose()

    self:updateBtnBuck()
end

function QuestSkipSaleView:updateBtnBuck()
    local buyType = BUY_TYPE.QUEST_SKIPSALE
    self:setBtnBuckVisible(self:findChild("btn_start"), buyType, nil, {
        {node = self:findChild("lb_pricePre"), addX = 20},
        {node = self:findChild("sp_line"), addX = 20},
        {node = self:findChild("lb_buy_num"), addX = 20},
    })
end

function QuestSkipSaleView:initAutoClose()
    self.m_lb_close = self:findChild("lb_close")
    if not self.m_lb_close then
        return
    end
    self.m_lb_close:setVisible(self.m_isAutoClose)
    if self.m_isAutoClose then
        local onTick = function(sec)
            self.m_lb_close:setString(string.format("CLOSING IN %d S...", sec))
        end
        self:setAutoCloseUI(nil, onTick, handler(self, self.closeUI))
    end
end

function QuestSkipSaleView:stopAutoCloseUITimer()
    if self.m_lb_close then
        self.m_lb_close:setVisible(false)
    end
    QuestSkipSaleView.super.stopAutoCloseUITimer(self)
end

function QuestSkipSaleView:initLuckyStampNode(callback)
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if not data then
        if callback then
            callback()
        end
        return
    end
    local tipNode = G_GetMgr(G_REF.LuckyStamp):createLuckyStampTip(callback)
    if tipNode then
        local node_info = self:findChild("desc_node")
        node_info:setScale(0.75)
        node_info:addChild(tipNode)
    end
end

------------新增提示功能
function QuestSkipSaleView:initBPInfoNode()
    --常规促销默认没有道具
    local itemlist = {}
    --获得根据支付金额生成赠送的集卡道具
    local saleData = self.skipSale
    if saleData ~= nil then
        --商品附带道具
        if saleData.p_items ~= nil and #saleData.p_items > 0 then
            for k, v in ipairs(saleData.p_items) do
                table.insert(itemlist, v)
            end
        end
        --创建提示节点
        local infoPBnode = gLobalItemManager:createInfoPBNode(saleData, itemlist)
        if infoPBnode then
            local node_info = self:findChild("desc_node")
            node_info:addChild(infoPBnode)
        end
    end
end

function QuestSkipSaleView:onShowedCallFunc()
    self:runCsbAction("idle")
end

function QuestSkipSaleView:playShowAction()
    QuestSkipSaleView.super.playShowAction(self, "show", false)
end

function QuestSkipSaleView:onEnter()
    QuestSkipSaleView.super.onEnter(self)

    local skipSale = self.skipSale
    if skipSale ~= nil then
        local goodsInfo = {}
        local quest_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if quest_data:getThemeName() == "Activity_QuestIsland" then
            goodsInfo.goodsTheme = "islandQuestSkipSale"
        else
            goodsInfo.goodsTheme = "QuestFinishSale"
        end
        goodsInfo.goodsId = skipSale.p_storeKey
        goodsInfo.goodsPrice = skipSale.p_price
        goodsInfo.discount = skipSale.p_discounts
        goodsInfo.totalCoins = skipSale.p_coins
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "limitBuy"
        if quest_data:getThemeName() == "Activity_QuestIsland" then
            purchaseInfo.purchaseName = "islandQuestSkipSale"
        else
            purchaseInfo.purchaseName = "QuestFinishSale"
        end

        local questData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if questData then
            if quest_data:getThemeName() == "Activity_QuestIsland" then
                purchaseInfo.purchaseStatus = "islandQuestSkipSale" .. questData.p_round .. "-" .. questData:getPhaseIdx()
            else
                purchaseInfo.purchaseStatus = questData.p_round .. "-" .. questData:getPhaseIdx() .. "-" .. questData:getStageIdx()
            end
        end
        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end

function QuestSkipSaleView:playHideAction()
    QuestSkipSaleView.super.playHideAction(self, "over", false)
end

function QuestSkipSaleView:onKeyBack()
    if self.m_isGameEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end

    self:closeUI()
end

function QuestSkipSaleView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_start" then
        self:stopAutoCloseUITimer()
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buySale()
        sender:setTouchEnabled(false)
    elseif name == "btn_close" then
        if self.m_isGameEffect then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
        end
        self:closeUI()
        sender:setTouchEnabled(false)
    end
end

function QuestSkipSaleView:closeUI(isSkipNotify)
    if self.isClose then
        return
    end
    self.isClose = true

    local callback = function()
        if not isSkipNotify then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CHOICE_VIEW_CLOSE)
        end
    end
    QuestSkipSaleView.super.closeUI(self, callback)
end

function QuestSkipSaleView:buySale()
    if self.isClose then
        return
    end
    local rate = 0

    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(self.skipSale, self.skipSale.p_items)
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.QUEST_SKIPSALE,
        self.skipSale.p_storeKey,
        self.skipSale.p_price,
        self.skipSale.p_coins,
        rate,
        function(_result)
            if self.buySuccess ~= nil then
                self:buySuccess(_result)
            else
                if self.m_isGameEffect then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
                end
            end
        end,
        function()
            if self.buyFailed ~= nil then
                self:buyFailed()
            else
                if self.m_isGameEffect then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
                end
            end
        end
    )
end

function QuestSkipSaleView:buySuccess(_result)
    --购买成功
    -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
    -- globalData.slotRunData.m_isAutoSpinAction = false

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_SKIP_BUY_SUC, {result = _result})

    --购买成功提示界面
    local levelUpNum = gLobalSaleManager:getLevelUpNum()
    local view = util_createView("GameModule.Shop.BuyTip")
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_letsgo", DotUrlType.UrlName, false)
    end
    view:initBuyTip(BUY_TYPE.QUEST_SKIPSALE, self.skipSale, self.skipSale.p_coins, levelUpNum)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    view:setOverFunc(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CHOICE_VIEW_CLOSE)
        end
    )
    self:closeUI(true)
end

function QuestSkipSaleView:buyFailed()
    if self.m_isGameEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end
    self:closeUI()
end

return QuestSkipSaleView

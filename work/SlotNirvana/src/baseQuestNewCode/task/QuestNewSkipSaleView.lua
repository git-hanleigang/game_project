-- QuestNew 购买直接完成quest任务

local QuestNewSkipSaleView = class("QuestNewSkipSaleView", BaseLayer)

function QuestNewSkipSaleView:initDatas()
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestNewSkipSaleView)
    self:setPortraitCsbName(QUEST_RES_PATH.QuestNewSkipSaleProView)

    self:setPauseSlotsEnabled(true)
end

function QuestNewSkipSaleView:initUI(isGameEffect)
    self.m_isGameEffect = isGameEffect
    QuestNewSkipSaleView.super.initUI(self)

    local config = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
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

function QuestNewSkipSaleView:initViews()
    local lalbelCoins = self:findChild("coins_label")

    lalbelCoins:setString(util_formatMoneyStr(tostring(self.skipSale.p_coins)))

    local btn_start = "QuestNewSkipSaleView:btn_start"
    local labelString = gLobalLanguageChangeManager:getStringByKey(btn_start)

    self:setButtonLabelContent("btn_start", labelString .. self.skipSale.p_price)

    self:updateBtnBuck()
end

function QuestNewSkipSaleView:updateBtnBuck()
    local buyType = BUY_TYPE.QUEST_SKIPSALE
    self:setBtnBuckVisible(self:findChild("btn_start"), buyType) -- 这里没有only文案不用偏移
end

function QuestNewSkipSaleView:initLuckyStampNode(callback)
    if not globalData.luckyStampData or not globalData.luckyStampData.p_isParseData then
        if callback then
            callback()
        end
        return
    end
    local tipNode = util_createView("views.dialogs.LuckyStampTipView", callback)
    if tipNode then
        local node_info = self:findChild("desc_node")
        node_info:setScale(0.75)
        node_info:addChild(tipNode)
    end
end

------------新增提示功能
function QuestNewSkipSaleView:initBPInfoNode()
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

function QuestNewSkipSaleView:onShowedCallFunc()
    self:runCsbAction("idle")
end

function QuestNewSkipSaleView:playShowAction()
    QuestNewSkipSaleView.super.playShowAction(self, "show", false)
end

function QuestNewSkipSaleView:onEnter()
    QuestNewSkipSaleView.super.onEnter(self)

    local skipSale = self.skipSale
    if skipSale ~= nil then
        local goodsInfo = {}
        local quest_data = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
        if quest_data:getThemeName() == "Activity_QuestNewIsland" then
            goodsInfo.goodsTheme = "islandQuestNewSkipSale"
        else
            goodsInfo.goodsTheme = "QuestNewFinishSale"
        end
        goodsInfo.goodsId = skipSale.p_storeKey
        goodsInfo.goodsPrice = skipSale.p_price
        goodsInfo.discount = skipSale.p_discounts
        goodsInfo.totalCoins = skipSale.p_coins
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "limitBuy"
        if quest_data:getThemeName() == "Activity_QuestNewIsland" then
            purchaseInfo.purchaseName = "islandQuestNewSkipSale"
        else
            purchaseInfo.purchaseName = "QuestNewFinishSale"
        end

        local questData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
        if questData then
            if quest_data:getThemeName() == "Activity_QuestNewIsland" then
                purchaseInfo.purchaseStatus = "islandQuestNewSkipSale" .. questData.p_round .. "-" .. questData:getPhaseIdx()
            else
                purchaseInfo.purchaseStatus = questData.p_round .. "-" .. questData:getPhaseIdx() .. "-" .. questData:getStageIdx()
            end
        end
        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end

function QuestNewSkipSaleView:playHideAction()
    QuestNewSkipSaleView.super.playHideAction(self, "over", false)
end

function QuestNewSkipSaleView:onKeyBack()
    if self.m_isGameEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end

    self:closeUI()
end

function QuestNewSkipSaleView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_start" then
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

function QuestNewSkipSaleView:closeUI(isSkipNotify)
    if self.isClose then
        return
    end
    self.isClose = true

    local callback = function()
        if not isSkipNotify then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CHOICE_VIEW_CLOSE)
        end
    end
    QuestNewSkipSaleView.super.closeUI(self, callback)
end

function QuestNewSkipSaleView:buySale()
    if self.isClose then
        return
    end
    local rate = 0

    local questConfig = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
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

function QuestNewSkipSaleView:buySuccess(_result)
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

function QuestNewSkipSaleView:buyFailed()
    if self.m_isGameEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end
    self:closeUI()
end

return QuestNewSkipSaleView

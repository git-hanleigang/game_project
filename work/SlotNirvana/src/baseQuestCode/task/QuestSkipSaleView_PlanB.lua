-- Quest 购买直接完成quest任务

local QuestSkipSaleView_PlanB = class("QuestSkipSaleView_PlanB", BaseLayer)

function QuestSkipSaleView_PlanB:initDatas()
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestSkipSaleView_PlanB)
    self:setPortraitCsbName(QUEST_RES_PATH.QuestSkipSaleProView_PlanB)

    self:setPauseSlotsEnabled(true)
end

function QuestSkipSaleView_PlanB:initUI(isGameEffect)
    self.m_isGameEffect = isGameEffect
    QuestSkipSaleView_PlanB.super.initUI(self)

    local config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if config then
        self.skipSale = config:getSkipSaleDate_PlanB()
    end
    self.m_activityData = config
    self:initLuckyStampNode(
        function()
            self:initBPInfoNode()
        end
    )

    self:initViews()
end

function QuestSkipSaleView_PlanB:initViews()
    if not self.skipSale then
        return
    end
    self:refreshView()

    self:updateBtnBuck()
end

function QuestSkipSaleView_PlanB:updateBtnBuck()
    local buyType = BUY_TYPE.QUEST_SKIPSALE_PlanB
    self:setBtnBuckVisible(self:findChild("btn_start"), buyType)
end

function QuestSkipSaleView_PlanB:refreshView()
    local haveNum = self.m_activityData:getLeftSkipItemCount()
    local needNum = self.skipSale:getSkipThisStageItemCost()
    local buyNum = self.skipSale:getBuySkipItemCount()

    local lb_need = self:findChild("lb_need")
    lb_need:setString("" .. needNum)

    self.lalbelCoins = self:findChild("coins_label")
    self.lalbelCoins:setString(util_formatMoneyStr(tostring(self.skipSale.p_coins)))

    local btn_skip = self:findChild("btn_skip")
    local btn_start = self:findChild("btn_start")
    self:setButtonLabelContent("btn_skip","SKIP")
    self.node_num = self:findChild("node_num")
    self.lb_buy_num = self:findChild("lb_buy_num")
    if not tolua.isnull(self.lb_buy_num) then
        self.lb_buy_num:setString("ONLY $" .. self.skipSale.p_price)
    end
    self.lb_left = self:findChild("lb_left")
    self.lb_left:setString("LEFT:" .. haveNum)

    if haveNum >= needNum then
        self.lalbelCoins:setVisible(false)
        self.node_num:setVisible(false)
        self.lb_buy_num:setVisible(false)
        btn_skip:setVisible(true)
        btn_start:setVisible(false)
    else
        btn_start:setVisible(true)
        btn_skip:setVisible(false)
        self.lb_buy_num:setVisible(true)
    end

    self.lb_Item_num = self:findChild("lb_Num")
    self.lb_Item_num:setString("x" .. buyNum)

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
            local string = gLobalLanguageChangeManager:getStringByKey("QuestSkipSaleView_PlanB:lb_pricePre")
            self.m_lb_fakePrice:setString(string .. self.skipSale.p_fakePrice)
        end
    end
end

function QuestSkipSaleView_PlanB:initLuckyStampNode(callback)
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
function QuestSkipSaleView_PlanB:initBPInfoNode()
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

function QuestSkipSaleView_PlanB:onShowedCallFunc()
    self:runCsbAction("idle")
end

function QuestSkipSaleView_PlanB:playShowAction()
    QuestSkipSaleView_PlanB.super.playShowAction(self, "show", false)
end

function QuestSkipSaleView_PlanB:onEnter()
    QuestSkipSaleView_PlanB.super.onEnter(self)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
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

    --选择难度成功
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:useItemSuccess(params)
        end,
        ViewEventType.NOTIFY_QUEST_SkIP_STAGE_BY_ITEM
    )
end

function QuestSkipSaleView_PlanB:playHideAction()
    QuestSkipSaleView_PlanB.super.playHideAction(self, "over", false)
end

function QuestSkipSaleView_PlanB:onKeyBack()
    if self.m_isGameEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end

    self:closeUI()
end

function QuestSkipSaleView_PlanB:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_start" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buySale()
        sender:setTouchEnabled(false)
    elseif name == "btn_skip" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:useSkipItems()
        self:closeUI()
    elseif name == "btn_close" then
        if self.m_isGameEffect then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
        end
        self:closeUI()
        sender:setTouchEnabled(false)
    end
end

function QuestSkipSaleView_PlanB:closeUI(isSkipNotify)
    if self.isClose then
        return
    end
    self.isClose = true

    local callback = function()
        if not isSkipNotify then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CHOICE_VIEW_CLOSE)
        end
    end
    QuestSkipSaleView_PlanB.super.closeUI(self, callback)
end

function QuestSkipSaleView_PlanB:buySale()
    if self.isClose then
        return
    end
    local rate = 0

    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(self.skipSale, self.skipSale.p_items)
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.QUEST_SKIPSALE_PlanB,
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

function QuestSkipSaleView_PlanB:buySuccess(_result)
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
            if not tolua.isnull(self) then
                local btn_start = self:findChild("btn_start")
                btn_start:setTouchEnabled(true)
                self:refreshView()
            end
        end
    )
end

function QuestSkipSaleView_PlanB:buyFailed()
    if self.m_isGameEffect then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_QUEST_DONE)
    end
    self:closeUI()
end


function QuestSkipSaleView_PlanB:useSkipItems()
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestUseItemSkipStage()
end

function QuestSkipSaleView_PlanB:useItemSuccess(_result)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CHOICE_VIEW_CLOSE)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_DONE_VIEW_AFTER_BUY)
    self:closeUI(not not _result)
end

return QuestSkipSaleView_PlanB

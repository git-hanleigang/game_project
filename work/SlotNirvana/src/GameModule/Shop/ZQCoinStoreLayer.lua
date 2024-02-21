--[[
    --he 8-19 - 2020
    --商城代码重写 xxx
]]
local ZQCoinStoreLayer = class("ZQCoinStoreLayer", BaseLayer)

ZQCoinStoreLayer.m_data = nil
ZQCoinStoreLayer.m_headIcon = nil
ZQCoinStoreLayer.m_coinsData = nil
ZQCoinStoreLayer.m_gemsData = nil
ZQCoinStoreLayer.m_rootNode = nil

ZQCoinStoreLayer.m_bgPanel = nil
ZQCoinStoreLayer.m_titleSp = nil
ZQCoinStoreLayer.m_closeBtn = nil
ZQCoinStoreLayer.m_vipNode = nil
ZQCoinStoreLayer.m_bonusNode = nil
ZQCoinStoreLayer.m_luckyStampNode = nil
ZQCoinStoreLayer.m_darkImage = nil
ZQCoinStoreLayer.m_storeItemT = nil
ZQCoinStoreLayer.m_selfScale = nil

ZQCoinStoreLayer.m_vipNextPointsView = nil
ZQCoinStoreLayer.shopBonusView = nil

ZQCoinStoreLayer.m_isTriggerCloseSale = nil --关闭商店是否触发促销

local STORE_RES_PATH = "Shop_Res/CoinStoreLayer.csb"
local STORE_RES_POR_PATH = "Shop_Res/CoinStoreLayerPortrait.csb"
local STORE_ITEM_COUNT = 6

function ZQCoinStoreLayer:initDatas()
    ZQCoinStoreLayer.super.initDatas(self)
    self.ActionType = "Curve"

    self:setLandscapeCsbName(STORE_RES_PATH)
    self:setPortraitCsbName(STORE_RES_POR_PATH)

    self:setPauseSlotsEnabled(true)
end

function ZQCoinStoreLayer:initUI(data, headIcon, notPushView)
    ZQCoinStoreLayer.super.initUI(self)
    if headIcon then
        self:upateStoreData(globalData.shopRunData:getShopItemDatasExchange(headIcon))
    else
        self:upateStoreData(globalData.shopRunData:getShopItemDatas())
    end

    local defaultIndex = 1
    if self.m_gemsData == nil then
        -- 如果没有钻石商店的数据，默认第一个页签
        defaultIndex = 1
    else
        if data and data.shopPageIndex then
            defaultIndex = data and data.shopPageIndex
        end
    end
    globalData.shopRunData:setShopPageIndex(defaultIndex)
    G_GetMgr(G_REF.Shop):setShopClosedFlag(false)

    self.m_isPushViewOpenShop = notPushView

    self:checkCardSmallGame()
    -- self:initStoreCsb()
    self:initStoreUI()
    self:initObservers()
    self:initLuckyStampNode()
    self:updateShopTitle()

    util_setCascadeOpacityEnabledRescursion(self, true)
    self:setExtendData("ZQCoinStoreLayer") -- 这行代码不能屏蔽
end

function ZQCoinStoreLayer:upateStoreData(coinsData, gemsData)
    self.m_coinsData = coinsData
    self.m_gemsData = gemsData
end

function ZQCoinStoreLayer:getStoreData()
    return self.m_coinsData, self.m_gemsData
end

function ZQCoinStoreLayer:getItemNode(index)
    return self:findChild("node_item" .. index)
end

function ZQCoinStoreLayer:initShopLog()
    local goodsInfo, purchaseInfo = G_GetMgr(G_REF.Shop):getLogShopData()
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

-- function ZQCoinStoreLayer:initStoreCsb()

--     local isAutoScale = nil

--     if CC_RESOLUTION_RATIO==3 then
--         isAutoScale = false
--     else
--         isAutoScale = true
--     end

--     local csbName   = nil
--     if globalData.slotRunData.isPortrait == true then
--         csbName     = STORE_RES_POR_PATH
--         isAutoScale = false
--     else
--         csbName     = STORE_RES_PATH
--     end

--     self:createCsbNode(csbName,isAutoScale)
--     util_portraitAdaptLandscape(self.m_csbNode)
-- end

function ZQCoinStoreLayer:initObservers()
    self:runCsbAction("idle")

    globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.piggyBank)
    globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.shopReward)
    if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.shopReward.id) and NOVICEGUIDE_ORDER.shopReward.levelNum <= globalData.userRunData.levelNum then
        globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.shopReward)
    end

    -- --优化
    -- if globalData.slotRunData.isPortrait == true and display.height < 1280 then
    --     local scale = display.height / 1280
    --     self.m_rootNode:setScale(self.m_rootNode:getScale()*scale)
    -- end
    self.m_selfScale = self.m_rootNode:getScale()

    -- self:curveShow(
    --     self.m_rootNode,
    --     function()
    --         if self.shopBonusView.btn_layout_option:isVisible() then
    --             globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.shopReward2)
    --         else
    --             if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.shopReward2.id) then
    --                 globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.shopReward2)
    --             end
    --         end
    --         self.isClose = false
    --     end
    -- )
end

function ZQCoinStoreLayer:initStoreUI()
    self.m_rootNode = self:findChild("root")
    self.m_bgPanel = self:findChild("Panel_bg")
    self.m_closeBtn = self:findChild("btn_close")
    self.m_vipNode = self:findChild("node_vip")
    self.m_bonusNode = self:findChild("node_storeBonus")
    self.m_darkImage = self:findChild("image_dark")
    self.m_shopTitleNode = self:findChild("node_shopTitle")
    self.m_btnCoins = self:findChild("btn_coins")
    self.m_btnGems = self:findChild("btn_gems")
    self.m_coinLayer = self:findChild("Panel_Coins")
    self.m_gemLayer = self:findChild("Panel_Gems")
    self.m_btnGemQuestion = self:findChild("btn_wenhao")
    self:addClick(self.m_coinLayer)
    self:addClick(self.m_gemLayer)

    self.buyShop = false

    self:updatePageTab()
    self:initStoreItem()
    self:initNextVipPoints()
    self:initShopGift()
end

function ZQCoinStoreLayer:updatePageTab()
    local shopType = globalData.shopRunData:getShopType()
    if shopType == "COIN" then
        self.m_btnCoins:setTouchEnabled(true)
        self.m_btnCoins:setBright(true)
        self.m_btnGems:setTouchEnabled(false)
        self.m_btnGems:setBright(false)
        if self.m_btnGemQuestion then
            self.m_btnGemQuestion:setVisible(false)
        end
    elseif shopType == "GEM" then
        self.m_btnCoins:setTouchEnabled(false)
        self.m_btnCoins:setBright(false)
        self.m_btnGems:setTouchEnabled(true)
        self.m_btnGems:setBright(true)
        if self.m_btnGemQuestion then
            self.m_btnGemQuestion:setVisible(true)
        end
    end
end

function ZQCoinStoreLayer:initStoreItem()
    if not self.m_storeItemT then
        self.m_storeItemT = {["COIN"] = {}, ["GEM"] = {}}
        self.m_initCoin = false
        self.m_initGem = false
    end
    local coinsData, gemsData = self:getStoreData()
    local shopType = globalData.shopRunData:getShopType()
    if shopType == "COIN" and not self.m_initCoin then
        for i = 1, STORE_ITEM_COUNT do
            -- 金币商城item
            local coinItem = util_createView("GameModule.Shop.shopItem.ZQCoinStoreItem", i, coinsData[i])
            table.insert(self.m_storeItemT.COIN, coinItem)
            self:getItemNode(i):addChild(coinItem)
            self:getItemNode(i):setLocalZOrder(100 - i)
        end
        self.m_initCoin = true
    end
    if shopType == "GEM" and not self.m_initGem then
        for i = 1, STORE_ITEM_COUNT do
            -- 钻石商城item
            if gemsData then
                local gemItem = util_createView("GameModule.Shop.shopItem.ZQGemStoreItem", i, gemsData[i])
                table.insert(self.m_storeItemT.GEM, gemItem)
                self:getItemNode(i):addChild(gemItem)
                self:getItemNode(i):setLocalZOrder(100 - i)
            end
        end
        self.m_initGem = true
    end
    self.m_darkImage:setLocalZOrder(100)
end

function ZQCoinStoreLayer:initShopGift()
    self.shopBonusView = util_createView("GameModule.Shop.ShopCollectNode")
    globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.shopReward2, self.shopBonusView)
    self.m_bonusNode:addChild(self.shopBonusView)
end

function ZQCoinStoreLayer:updateShopTitle()
    self.m_shopTitleNode:removeAllChildren()
    local shopTitle = nil
    local shopType = globalData.shopRunData:getShopType()
    if shopType == "COIN" then
        shopTitle = util_createView("GameModule.Shop.shopTitle.ZQCoinStoreTitle")
    elseif shopType == "GEM" then
        shopTitle = util_createView("GameModule.Shop.shopTitle.ZQGemStoreTitle")
    end
    if shopTitle ~= nil then
        self.m_shopTitleNode:addChild(shopTitle)
    end
end

function ZQCoinStoreLayer:initNextVipPoints()
    self.m_vipNextPointsView = util_createView("GameModule.Shop.VipNexrPoints")
    if self.m_vipNode then
        self.m_vipNode:addChild(self.m_vipNextPointsView)
        self.m_vipNextPointsView:updatePoints()
    end
end

function ZQCoinStoreLayer:initLuckyStampNode()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if not data then
        return
    end
    self.m_luckyStampNode = G_GetMgr(G_REF.LuckyStamp):createLuckyStampTip(nil, true)
    if self.m_luckyStampNode then
        self:addChild(self.m_luckyStampNode, 1)
        local luckySize = self.m_luckyStampNode:getContentSize()
        local luckyScale = self.m_luckyStampNode:getCsbNodeScale()
        local luckyHeight = luckySize.height * luckyScale
        self.m_luckyStampNode:setPosition(display.cx, luckyHeight / 2)

        if not globalData.slotRunData.isPortrait then
            self.m_luckyStampNode:setPosition(display.cx, luckyHeight / 2)
        else
            local size = self.m_bgPanel:getContentSize()
            local rootScale = self.m_selfScale
            local bgWidth = size.width * rootScale
            local bgHeight = size.height * rootScale

            --竖版做下适配
            local upBorder = 20 --极限情况上边界预留20像素
            local downLens = bgHeight / 2 + luckyHeight

            if downLens > display.cy then
                --超出下边界 整体向上移动
                local diff = downLens - display.cy
                if (diff + bgHeight + upBorder) > display.height - upBorder then
                    self:setPositionY(display.cy - bgHeight / 2 - upBorder)
                    self.m_luckyStampNode:setPosition(display.cx, luckyHeight / 2)
                else
                    self:setPositionY(luckyHeight / 2)
                    self.m_luckyStampNode:setPosition(display.cx, display.cy - bgHeight / 2 - luckyHeight / 2)
                end
            else
                self:setPositionY(luckyHeight / 2)
                self.m_luckyStampNode:setPosition(display.cx, display.cy - bgHeight / 2 - luckyHeight / 2)
            end
        end
    end
end

--集卡活动结束时 移除商店列表中的四叶草
function ZQCoinStoreLayer:checkCardSmallGame()
    if CardSysManager.canShopGiftCard and not CardSysManager:canShopGiftCard() then
        local storeData = self:getStoreData()
        for i = 1, #storeData do
            local disPlayList = storeData[i].p_displayList
            for j = 1, #disPlayList do
                if disPlayList[j].p_icon == "CardGem" then
                    table.remove(disPlayList, j)
                    break
                end
            end
        end
    end
end

--更新Vip显示信息
function ZQCoinStoreLayer:upDataVipShowInfo()
    if self.m_vipNextPointsView then
        self.m_vipNextPointsView:updatePoints()
    end
end

function ZQCoinStoreLayer:upStoreItem(isBuy)
    self:initStoreItem()
    local coinsData, gemsData = self:getStoreData()
    local shopType = globalData.shopRunData:getShopType()
    for i = 1, STORE_ITEM_COUNT do
        local coinItem = self.m_storeItemT.COIN[i]
        if coinItem and coinsData then
            if shopType == "COIN" or isBuy then
                coinItem:updateItemData(coinsData[i])
                if isBuy then
                    coinItem:updateItemInfo()
                end
            end
            coinItem:setVisible(shopType == "COIN")
        end

        local gemItem = self.m_storeItemT.GEM[i]
        if gemsData and gemItem then
            if shopType == "GEM" or isBuy then
                gemItem:updateItemData(gemsData[i])
                if isBuy then
                    gemItem:updateItemInfo()
                end
            end
            gemItem:setVisible(shopType == "GEM")
        end
    end
end

function ZQCoinStoreLayer:upStoreBonusInfo()
    if self.shopBonusView and self.shopBonusView.updateCollectStatus then
        self.shopBonusView:updateCollectStatus()
    end
end

function ZQCoinStoreLayer:clickFunc(sender)
    if self.isClose then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_close" then
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:closeUI(true)
    elseif name == "Panel_Coins" then
        local shopType = globalData.shopRunData:getShopType()
        if shopType == "COIN" then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        globalData.shopRunData:setShopPageIndex(1)
        self:updatePageTab()
        self:updateShopTitle()
        self:upStoreItem()
    elseif name == "Panel_Gems" then
        local shopType = globalData.shopRunData:getShopType()
        if shopType == "GEM" then
            return
        end
        if self.m_gemsData == nil then -- 没有数据不能切换
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        globalData.shopRunData:setShopPageIndex(2)
        self:updatePageTab()
        self:updateShopTitle()
        self:upStoreItem()
    elseif name == "btn_wenhao" then
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.Shop):createGemInfoLayerUI()
    end
end

function ZQCoinStoreLayer:showStoreItemTip(data)
    local itemIndex = data.index
    local itemSize = data.size
    local item = self:getItemNode(itemIndex)

    self.m_darkImage:setVisible(true)

    for i = 1, STORE_ITEM_COUNT do
        local iZorder = itemIndex == i and 1000 or 100 - i
        self:getItemNode(i):setLocalZOrder(iZorder)
    end

    local nodePos = cc.p(item:getPosition())
    local worldPos = item:getParent():convertToWorldSpace(nodePos)
    local rootPos = self.m_rootNode:convertToNodeSpace(worldPos)

    local coinData, gemData = self:getStoreData()
    local storeDatas = nil
    if data.type == "COIN" then
        storeDatas = coinData
    elseif data.type == "GEM" then
        storeDatas = gemData
    end
    if storeDatas then
        local view = util_createView("GameModule.Shop.ZQCoinStoreTipNew", storeDatas[itemIndex], itemIndex, itemSize, rootPos, data.type)
        self.m_rootNode:addChild(view)

        view:setCallFunc(
            function()
                if not tolua.isnull(self) then
                    self.m_darkImage:setVisible(false)
                    for i = 1, STORE_ITEM_COUNT do
                        self:getItemNode(i):setLocalZOrder(100 - i)
                    end
                end
            end
        )
    end
end

function ZQCoinStoreLayer:onShowedCallFunc()
    if self.shopBonusView.btn_layout_option:isVisible() then
        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.shopReward2)
    else
        if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.shopReward2.id) then
            globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.shopReward2)
        end
    end
    self.isClose = false
end

function ZQCoinStoreLayer:onEnter()
    ZQCoinStoreLayer.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    gLobalSoundManager:playSound("Sounds/Coinstore_open.mp3")
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    self:initShopLog()
    G_GetMgr(G_REF.FirstCommonSale):requestFirstSale()
    -- self:registerListener()

    -- self:curveShow(
    --     self.m_rootNode,
    --     function()
    --         if self.shopBonusView.btn_layout_option:isVisible() then
    --             globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.shopReward2)
    --         else
    --             if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.shopReward2.id) then
    --                 globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.shopReward2)
    --             end
    --         end
    --         self.isClose = false
    --     end
    -- )
end

function ZQCoinStoreLayer:registerListener()
    --更新vip信息
    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                self:upateStoreData(globalData.shopRunData:getShopItemDatas())
                self:upDataVipShowInfo()
                self:upStoreItem(true)
                self:upStoreBonusInfo()
            end
        end,
        ViewEventType.NOTIFY_BUYTIP_CLOSE
    )

    gLobalSendDataManager:getNetWorkFeature():sendQuerySaleConfig(
        function(isTrigger)
            self.m_isTriggerCloseSale = isTrigger
            if self.m_isTriggerCloseSale then
                --如果触发了先不刷新UI等关闭商店在刷新
                globalData.saleRunData:setShowTopeSale(false)
            end
        end
    )
    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                self.buyShop = true
            end
        end,
        ViewEventType.NOTIFY_BUYCOINS_SUCCESS
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if not tolua.isnull(self) and data then
                self:showStoreItemTip(data)
            end
        end,
        "showStoreItemInfo"
    )
end

-- function ZQCoinStoreLayer:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

function ZQCoinStoreLayer:onKeyBack()
    self:closeUI(true)
end

--移植
function ZQCoinStoreLayer:closeUI(isLog)
    if self.isClose then
        return
    end
    G_GetMgr(G_REF.Shop):setShopClosedFlag(true)
    if not tolua.isnull(self.m_luckyStampNode) then
        self.m_luckyStampNode:removeFromParent()
    end
    --清理引导log
    gLobalSendDataManager:getLogFeature().m_uiActionSid = nil
    self.isClose = true
    self:stopAllActions()

    local callback = function()
        if not tolua.isnull(self) then
            self:closeEndFunc(isLog)
        end
    end
    ZQCoinStoreLayer.super.closeUI(self, callback)

    -- local root = self:findChild("root")

    -- if root then
    --     self:commonHide(root,function()
    --         if not tolua.isnull(self) then
    --             self:closeEndFunc(isLog)
    --         end
    --     end)
    -- else
    --     self:runCsbAction("over",false,function()
    --         if not tolua.isnull(self) then
    --             self:closeEndFunc(isLog)
    --         end
    --     end,30)
    -- end
end

--移植
function ZQCoinStoreLayer:closeEndFunc(isLog)
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():removeUrlKey(self.__cname)
    end

    if isLog then
        if gLobalSendDataManager.getLogIap ~= nil then
            gLobalSendDataManager:getLogIap():closeIapLogInfo()
        end
    end

    if self.buyShop == false then
        if self.m_isPushViewOpenShop == true then
            --弹窗逻辑执行下一个事件
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "newGuideNewUser")
        else
            -- 如果当前是第二货币界面关闭,不弹出后续点位
            if globalData.shopRunData:getShopPageIndex() ~= 2 then
                gLobalPushViewControl:showView(PushViewPosType.CloseStore)
            end
        end

        if gLobalPushViewControl:isPushingView() then
            gLobalPushViewControl:setEndCallBack(
                function()
                    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "newGuideNewUser")
                    --弹窗逻辑执行下一个事件
                end
            )
        else
            --弹窗逻辑执行下一个事件
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "newGuideNewUser")
        end
    else
        --弹窗逻辑执行下一个事件
        if gLobalActivityManager.isShowActivity and gLobalActivityManager:isShowActivity() then
            --有开启的活动展示不回复暂停
        else
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_CLOSE_STORE)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS)
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "newGuideNewUser")
    end

    if globalData.shopRunData:getShpGiftCD() ~= 0 then
        globalNoviceGuideManager:removeQueue(NOVICEGUIDE_ORDER.shopReward3)
    end

    globalNoviceGuideManager:attemptShowRepetition()

    if self.m_isTriggerCloseSale then
        globalData.saleRunData:setShowTopeSale(true)
    end

    -- self:removeFromParent()
end

return ZQCoinStoreLayer

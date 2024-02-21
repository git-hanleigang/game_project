--[[
    新版商城下UI 按钮模块
]]
local ShopRecommendedPositionNode = class("ShopRecommendedPositionNode", util_require("base.BaseView"))
function ShopRecommendedPositionNode:initUI(isPortrait)
    self.m_isPortrait = isPortrait or false

    self:createCsbNode(self:getCsbName())

    self:updateView()
end

function ShopRecommendedPositionNode:getCsbName()
    if self.m_isPortrait then
        return SHOP_RES_PATH.RecommendedPosition_Vertical
    else
        return SHOP_RES_PATH.RecommendedPosition
    end
end

function ShopRecommendedPositionNode:initCsbNodes()
    -- 读取csb 节点
    self.m_nodeSalePic = self:findChild("node_salePic")
    self.m_nodeVip = self:findChild("node_vip")
    self.m_nodeStamp = self:findChild("node_stamp")
    self.m_nodeNumber = self:findChild("node_coinNumber")
    self.m_nodeItem = self:findChild("node_item")
    self.m_nodeExtra = self:findChild("node_extra")
    self.m_nodeTime = self:findChild("node_time")

    self.m_labExtra = self:findChild("lb_extra")

    self.m_nodePanel = self:findChild("node_panel_size")
end

function ShopRecommendedPositionNode:updateView()
    -- 添加vip节点
    self:addVipShow()
    -- 添加stamp 节点
    self:addLuckStampTips()
    --添加时间节点
    self:addTimeNode()
    -- 刷新推荐位信息
    self:updateUI()
end

function ShopRecommendedPositionNode:getShopData()
    local shopData = nil
    local shopDailySaleData = G_GetMgr(ACTIVITY_REF.ShopDailySale):getRunningData()
    if shopDailySaleData == nil then
        self.m_IsShowStorePrice = true
    else
        self.m_IsShowStorePrice = shopDailySaleData:getIsShowStorePrice()
    end

    if self.m_IsShowStorePrice then
        -- 数据需要换成商城的数据
        self.m_index = G_GetMgr(ACTIVITY_REF.ShopDailySale):getStoreJumpToViewIndex()
        local coinsData, gemsData = globalData.shopRunData:getShopItemDatas()
        shopData = coinsData[self.m_index]
    else
        shopData = shopDailySaleData:getBuyShopData()
    end
    return shopData
end

function ShopRecommendedPositionNode:refreshUI()
    -- 刷新vip展示
    self:updateVipInfo()
    -- 刷新整体ui
    self:updateUI(true)
end

function ShopRecommendedPositionNode:updateVipInfo()
    -- 刷新vip展示
    if self.m_vipNextPointsView then
        self.m_vipNextPointsView:updatePoints()
    end
end

function ShopRecommendedPositionNode:addVipShow()
    if self.m_nodeVip then
        self.m_vipNextPointsView = util_createView(SHOP_CODE_PATH.VipNode)
        self.m_nodeVip:addChild(self.m_vipNextPointsView)
    end
end

function ShopRecommendedPositionNode:addLuckStampTips()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if not data then
        return
    end
    self.m_luckyStampNode = G_GetMgr(G_REF.LuckyStamp):createLuckyStampTip(nil, true, false)
    if self.m_nodeStamp and self.m_luckyStampNode then
        self.m_nodeStamp:addChild(self.m_luckyStampNode)
    end
end

function ShopRecommendedPositionNode:addTimeNode()
    if self.m_nodeTime then
        self.m_timeNode = util_createView(SHOP_CODE_PATH.RecommendedTiemNode)
        self.m_nodeTime:addChild(self.m_timeNode)
    end
end

function ShopRecommendedPositionNode:updateUI(_immediately)
    local shopData = self:getShopData()
    -- 购买次数
    self:updatePayTimes()
    -- 价格
    self:setButtonLabelContent("btn_buy", "$" .. shopData.p_price)
    --添加背景图
    self:addBgNode()
    --添加 numbers节点信息
    if _immediately then
        self:updateNumber(shopData)
    else
        self:addNumberNode(shopData)
    end
    --添加道具
    self:addRewardItem()
    --刷新加成
    self:updateExtra()
    --根据当前数据切换时间线
    self:checkActionTimer()
    --
end

function ShopRecommendedPositionNode:updatePayTimes()
    self.m_timeNode:updatePayTimes()
end

function ShopRecommendedPositionNode:addBgNode()
    -- 添加 当前背景图
    if self.m_bgNode then
        self.m_bgNode:removeFromParent()
        self.m_bgNode = nil
    end
    if self.m_bgNode == nil then
        self.m_bgNode = util_createView(SHOP_CODE_PATH.RecommendedBgNode, self.m_IsShowStorePrice, self.m_isPortrait)
        self.m_nodeSalePic:addChild(self.m_bgNode)
    end
end

function ShopRecommendedPositionNode:addNumberNode(_shopData)
    -- local itemData = _shopData:getShopData() -- 为了保证结构与商城相同，好复用一套numnode 的结构
    if self.m_numbers == nil then
        self.m_numbers = util_createView(SHOP_CODE_PATH.ItemReCommendNumNode, _shopData, SHOP_VIEW_TYPE.RECOMMEND)
        self.m_nodeNumber:addChild(self.m_numbers)
    end
end

function ShopRecommendedPositionNode:updateNumber(_shopData)
    if self.m_numbers then
        self.m_numbers:updateItemData(_shopData)
    end
end

function ShopRecommendedPositionNode:addRewardItem()
    self.m_nodeItem:removeAllChildren()
    local spAdd = self:findChild("sp_add")
    spAdd:setVisible(true)
    if self.m_IsShowStorePrice then
        spAdd:setVisible(false)
        return
    end
    local shopDailySaleData = G_GetMgr(ACTIVITY_REF.ShopDailySale):getRunningData()
    local itemData = clone(shopDailySaleData:getRewards())
    local propNodeList = {}
    if itemData.coins and itemData.coins > 0 then
        local coinItemData = gLobalItemManager:createLocalItemData("Coins", tonumber(itemData.coins), {p_limit = 3})
        table.insert(propNodeList, coinItemData)
    end
    if itemData.items and #itemData.items > 0 then
        for i = 1, #itemData.items do
            local tempItemData = itemData.items[i]
            tempItemData = G_GetMgr(G_REF.Shop):getDescShopItemData(tempItemData)
            table.insert(propNodeList, tempItemData)
        end
    end
    if #propNodeList == 0 then
        spAdd:setVisible(false)
        return
    end
    local itemUIWidth = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    local propNode = gLobalItemManager:addPropNodeList(propNodeList, ITEM_SIZE_TYPE.TOP)
    local itemSizeWidth = itemUIWidth * #propNodeList

    self.m_nodeItem:addChild(propNode)
    -- 多个道具的情况下需要做适配
    local itemNodeList = {}
    local sprData = {node = spAdd, size = cc.size(spAdd:getContentSize().width, 0), anchor = cc.p(0.5, 0.5)}
    local nodeData = {node = self.m_nodeItem, size = cc.size(itemSizeWidth, 0), anchor = cc.p(0.5, 0.5)}
    itemNodeList[#itemNodeList + 1] = sprData
    itemNodeList[#itemNodeList + 1] = nodeData
    util_alignCenter(itemNodeList)
end

function ShopRecommendedPositionNode:updateExtra(_shopData)
    if _shopData then
        local value = 0
        if iskindof(_shopData, "ShopCoinsConfig") then
            value = _shopData:getDiscount()
        else
            value = _shopData.p_discount
        end
        if value > 0 then
            self.m_nodeExtra:setVisible(true)
            self.m_labExtra:setString("" .. value .. "%")
        else
            self.m_nodeExtra:setVisible(false)
        end
    else
        self.m_nodeExtra:setVisible(false)
    end
end

function ShopRecommendedPositionNode:checkActionTimer()
    -- 推荐位变为商城档位的时候,隐藏掉时间节点
    if self.m_IsShowStorePrice then
        self.m_timeNode:setVisible(false)
    end
    self.m_timeNode:checkActionTimer(self.m_IsShowStorePrice)
end

function ShopRecommendedPositionNode:getBuyType()
    if self.m_IsShowStorePrice then
        return BUY_TYPE.STORE_TYPE
    else
        return BUY_TYPE.SHOP_DAILYSALE
    end
end

function ShopRecommendedPositionNode:getFinalBuyData()
    local finalBuyData = self:getShopData()
    if self.m_IsShowStorePrice == false then
        local shopDailySaleData = G_GetMgr(ACTIVITY_REF.ShopDailySale):getRunningData()
        if shopDailySaleData then
            -- 先把金币道具组装进去
            local rewards = shopDailySaleData:getRewards()
            if table.nums(rewards) > 0 then
                if rewards.coins and rewards.coins > 0 then
                    local coinItemData = gLobalItemManager:createLocalItemData("Coins", tonumber(rewards.coins), {p_limit = 3})
                    table.insert(finalBuyData.p_displayList, coinItemData)
                    -- 再将金币值加进去
                    finalBuyData.p_coins = finalBuyData.p_coins + rewards.coins
                end
            end
        end
    end
    return finalBuyData
end

function ShopRecommendedPositionNode:clickFunc(_sender)
    local name = _sender:getName()

    if name == "btn_benefits_info" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local buyData = self:getShopData()
        local view = util_createView(SHOP_CODE_PATH.ItemBenefitBoardLayer, buyData, SHOP_VIEW_TYPE.COIN)
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    elseif name == "btn_buy" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- 发起购买
        self.m_preBuyShowData = self:getFinalBuyData()
        self:checkCouponSwitch()
        globalData.iapRunData.p_contentId = not G_GetMgr(G_REF.Shop):getPromomodeOpen()
        G_GetMgr(G_REF.Shop):requestBuyItem(self:getBuyType(), self.m_preBuyShowData, self.m_preBuyShowData.p_coins,
            function()
                if not tolua.isnull(self) then
                    self:buySuccess()
                end
            end,
            function()
                if not tolua.isnull(self) then
                    self:buyFailed()
                end
            end
        )
    end
end

function ShopRecommendedPositionNode:checkCouponSwitch()
    if not G_GetMgr(G_REF.Shop):getPromomodeOpen() then
        self.m_preBuyShowData.p_coins = self.m_preBuyShowData.p_originalCoins
        local couponData = G_GetMgr(ACTIVITY_REF.Coupon):getRunningData()
        if couponData then
            local itemData = {}
            local couponItems = couponData:getShopGifts()
            for i,v in ipairs(self.m_preBuyShowData.p_displayList) do
                local insert = true
                for k,n in ipairs(couponItems) do
                    if v.p_id == n.p_id then
                        insert = false
                        break
                    end
                end        
                if insert then
                    table.insert(itemData, v)
                end
            end
            self.m_preBuyShowData.p_displayList = itemData
        end
    end
end

function ShopRecommendedPositionNode:buySuccess()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYCOINS_SUCCESS)
    local buyShopData = self.m_preBuyShowData

    --打点
    self:sendIapLog(buyShopData)

    if self:getShowLuckySpinView() then
        local data = {}
        data.buyShopData = clone(buyShopData)
        data.buyIndex = self.m_index
        data.itemIndex = self.m_index
        data.closeCall = function(isResetShopLog)
            self:showBuyTip(isResetShopLog)
        end
        G_GetMgr(G_REF.LuckySpin):showMainLayer(data)
    else
        self:showBuyTip()
    end
end

function ShopRecommendedPositionNode:buyFailed()
end

-- 客户端打点
function ShopRecommendedPositionNode:sendIapLog(_goodsInfo)
    if _goodsInfo ~= nil and not self.m_IsShowStorePrice then
        -- 商品信息
        local goodsInfo = {}

        goodsInfo.goodsTheme = "RecommendSaleLayer"
        goodsInfo.goodsId = _goodsInfo.p_key
        goodsInfo.goodsPrice = _goodsInfo.p_price
        goodsInfo.discount = _goodsInfo.p_discount
        goodsInfo.totalCoins = _goodsInfo.p_coins

        -- 购买信息
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "StoreBuy"
        purchaseInfo.purchaseName = "RecommendSale"
        purchaseInfo.purchaseStatus = _goodsInfo.p_id
        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end

function ShopRecommendedPositionNode:getShowLuckySpinView()
    return globalData.luckySpinData:isExist() == true and ((self.m_index or 0) >= globalData.shopRunData:getLuckySpinLevel())
end

function ShopRecommendedPositionNode:showBuyTip()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_BUY_STORE_FINISH)

    local view = self:createBuyTipUI()
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_buy", DotUrlType.UrlName, false)
    end
end

function ShopRecommendedPositionNode:createBuyTipUI()
    local view = util_createView("GameModule.Shop.BuyTip")
    local buyType = BUY_TYPE.SHOP_DAILYSALE
    local buyDataBaseNums = self.m_preBuyShowData.p_baseCoins
    view:initBuyTip(
        buyType,
        self.m_preBuyShowData,
        buyDataBaseNums,
        gLobalSaleManager:getLevelUpNum(),
        function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        end
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ShopRecommendedPositionNode:getNodeFrameSize()
    return self.m_nodePanel:getContentSize()
end

-- 推荐位扫光
function ShopRecommendedPositionNode:playRecommendAction(_callback)
    if self.m_bgNode then
        self.m_bgNode:playRecommendAction(_callback)
    else
        if _callback then
            _callback()
        end
    end
end

-- 推荐位按钮扫光
function ShopRecommendedPositionNode:playRecommendBtnAction(_callback)
    self:runCsbAction(
        "idle3",
        false,
        function()
            if _callback then
                _callback()
            end
        end,
        60
    )
end

function ShopRecommendedPositionNode:onEnter()
    ShopRecommendedPositionNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params == "on" then
                self:updateExtra()
                self:runCsbAction("open", false, function ()
                    self:playRecommendBtnAction()
                end, 60)
            elseif params == "off" then
                self:runCsbAction("close", false, function ()
                    self:updateExtra()
                    self:playRecommendBtnAction()
                end, 60)
            end
        end,
        ViewEventType.NOTIFY_SHOP_PROMO_SWITCH
    )
end

return ShopRecommendedPositionNode

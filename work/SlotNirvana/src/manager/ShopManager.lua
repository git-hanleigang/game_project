--[[
    @desc: 新版本 ShopManager 管理改版
    author:csc
    time:2021-12-22
]]

local ShopManager = class("ShopManager", BaseGameControl)

-- csc 2021-12-23 新增商城路径
GD.SHOP_CODE_PATH = {}
GD.SHOP_RES_PATH = {}
GD.SHOP_VIEW_TYPE = {}

ShopManager.BASE_CONFIG_PATH = "GameModule/Shop2023/model/ShopCodeResConfig"
function ShopManager:ctor()
    ShopManager.super.ctor(self)
    self:setRefName(G_REF.Shop)

    -- 折扣开关
    self.m_promomodeOpen = true
    self.m_promomodeSound = true

    -- 注册监听
    self:registerObservers()
    -- 初始化商城配置
    self:initShopCodeResConfig()
end

function ShopManager:registerObservers()
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.VipBoost then
                -- 如果当前vipboost 活动结束 需要刷新一次商城数据
                gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig()
            end

            if params.name == ACTIVITY_REF.ShopDailySale then
                self:refreshSaleConfig()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function ShopManager:initShopCodeResConfig()
    self.m_configData = util_require(self.BASE_CONFIG_PATH)
    self:updateCodeInfo(self.m_configData.code)
    self:updateResInfo(self.m_configData.res)
    self:updateTypeInfo(self.m_configData.type)
end

function ShopManager:setShopClosedFlag(isClosed)
    self.m_shopClosed = isClosed
end

function ShopManager:getShopClosedFlag()
    return self.m_shopClosed
end

-- function ShopManager:isOpenCarnival()
--     -- 商城膨胀活动
--     local shopCarnival = G_GetMgr(ACTIVITY_REF.ShopCarnival)
--     if shopCarnival and shopCarnival:isRunning() then
--         return true
--     else
--         return false
--     end
-- end

function ShopManager:createGemBubble(_bubbleType, _clickCallBack)
    return util_createView("GameModule.Shop.shopOuterSys.shopOuterBubbleNode", _bubbleType, _clickCallBack)
end

function ShopManager:createGemButton(_bubbleType, _clickCallBack)
    return util_createView("GameModule.Shop.shopOuterSys.shopOuterButtonNode", _bubbleType, _clickCallBack)
end

function ShopManager:createGemPopUI(_bubbleType, _num, _index)
    local view = util_createView("GameModule.Shop.shopOuterSys.shopOuterPopUI", _bubbleType, _num, _index)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function ShopManager:createGemInfoLayerUI()
    local view = util_createView("GameModule.Shop.shopOuterSys.ZQGemInfoLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

--获得商店基础log
function ShopManager:getLogShopData(_type,_buyShopData)
    local goodsInfo = {}
    local purchaseInfo = {}
    goodsInfo.goodsTheme = "ZQCoinStoreLayer"
    purchaseInfo.purchaseType = "storeyBuy"
    _type = _type or BUY_TYPE.STORE_TYPE

    -- if globalData.shopRunData:getShopPageIndex() == 2 then
    if _type == BUY_TYPE.GEM_TYPE then
        purchaseInfo.purchaseName = "GemsBuy"
        purchaseInfo.purchaseStatus = "Normal"
    -- elseif globalData.shopRunData:getShopPageIndex() == 1 then
    elseif _type == BUY_TYPE.StorePet then
        purchaseInfo.purchaseName = "StorePetSale"
        local index = 1
        if _buyShopData.m_index then
            index = _buyShopData.m_index
        end
        purchaseInfo.purchaseStatus = purchaseInfo.purchaseName..index
    else
        if not globalData.shopRunData:isShopFirstBuyed() then
            purchaseInfo.purchaseStatus = "first"
        else
            purchaseInfo.purchaseStatus = "normal"
        end

        purchaseInfo.purchaseName = "store"
        local doubleCardData = G_GetActivityDataByRef(ACTIVITY_REF.DoubleCard)
        local cardStarData = G_GetActivityDataByRef(ACTIVITY_REF.CardStar)
        if doubleCardData and doubleCardData.isExist and doubleCardData:isExist() == true then
            purchaseInfo.purchaseName = "CardDoubleSale"
        elseif cardStarData and cardStarData.isExist and cardStarData:isExist() == true then
            purchaseInfo.purchaseName = "CardStarLevelSale"
        end
    end

    return goodsInfo, purchaseInfo
end

function ShopManager:requestBuyItem(_buyType, _buyShopData, _addCoinNum, buySuccess, buyFailed)
    local iapId = _buyShopData.p_key
    local price = _buyShopData.p_price
    local rate = _buyShopData.p_discount

    --商店折扣
    local goodsInfo, purchaseInfo = self:getLogShopData(_buyType,_buyShopData)
    goodsInfo.discount = _buyShopData.p_discount
    goodsInfo.goodsId = iapId
    goodsInfo.goodsPrice = price
    if _buyType == BUY_TYPE.GEM_TYPE then
        goodsInfo.totalGems = (_addCoinNum or 0)
    else
        goodsInfo.totalCoins = (_addCoinNum or 0)
    end
    if _buyShopData.m_hotSaleIcon then
        purchaseInfo.hotSaleIcon = _buyShopData.m_hotSaleIcon
    end
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    gLobalSendDataManager:getLogIap():setPurchaseInfo(purchaseInfo)
    local itemList = gLobalItemManager:checkAddLocalItemList(_buyShopData, _buyShopData.p_displayList)
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    -- 刷新存储池
    globalData.iapRunData.p_showData = _buyShopData

    -- 需要记录一下当前进入了购买状态
    self.m_buyStatus = true
    gLobalSaleManager:purchaseGoods(
        _buyType,
        iapId,
        price,
        _addCoinNum,
        rate,
        function()
            release_print("clickBuyBtn buySuccess")
            self.m_buyStatus = false
            if buySuccess then
                buySuccess()
            end
        end,
        function()
            release_print("clickBuyBtn buyFailed")
            self.m_buyStatus = false
            if buyFailed then
                buyFailed()
            end
        end
    )
    release_print("clickBuyBtn END")
end

-- 有关商城界面购买完毕掉卡的相关处理逻辑都放置到这块处理
function ShopManager:buySuccessDropCard(_dataList)
    -- 解析传入的必要数据
    local storeType = _dataList.storeType
    local buyData = _dataList.buyData

    -- saleRunData中的一些弹板
    local function dealSaleRunCouponGift()
        globalData.saleRunData:getCouponGift()
    end

    -- 50刀档位及以上，购买SuperSpin，中20倍的倍数，在所有弹版弹出之后，弹出
    local function showOperateGuidePopup()
        if _dataList.bLuckySpin then
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("SuperSpinWin")
            if view then
                view:setOverFunc(function()
                    -- 弹板关闭回调
                    dealSaleRunCouponGift()
                end)
            else
                dealSaleRunCouponGift()
            end
        else
            dealSaleRunCouponGift()
        end
    end

    -- 2023复活节聚合弹板
    local function openHolidayChallengeWheelLayer()
        if storeType == BUY_TYPE.STORE_TYPE or storeType == BUY_TYPE.GEM_TYPE then
            if G_GetMgr(ACTIVITY_REF.HolidayChallenge):checkShowWheel() then
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):createProgressLayer("holidayChallengeWhell", showOperateGuidePopup)
            else
                showOperateGuidePopup()
            end
        else
            showOperateGuidePopup()
        end
    end
    -- 商城充值送卡活动面板
    local function openShopRandomCardLayer()
        if G_GetMgr(ACTIVITY_REF.StoreSaleRandomCard):getLastPurchaseCardInfo() and buyData.p_shopCardDiscount and buyData.p_shopCardDiscount > 0 then -- 只有商城购买会掉落
            G_GetMgr(ACTIVITY_REF.StoreSaleRandomCard):createShopRandomCardLayer(true, openHolidayChallengeWheelLayer)
        else
            openHolidayChallengeWheelLayer()
        end
    end

    -- luckySpineLayer
    local bLuckySpin = _dataList.bLuckySpin
    local extraData = _dataList.extraData
    local function dealLuckSpinLayerActPop()
        -- Activity_LuckySpinRandomCard
        if not bLuckySpin or not extraData then
            openShopRandomCardLayer()
            return
        end

        if extraData == ACTIVITY_REF.LuckySpinRandomCard then
            -- local actData = G_GetActivityDataByRef(ACTIVITY_REF.LuckySpinRandomCard)
            local actData = G_GetMgr(ACTIVITY_REF.LuckySpinRandomCard):getRunningData()
            if actData and actData:isRunning() then
                -- 跨天要判断资源是否下载
                local ui = util_createFindView("Activity/Activity_LuckySpinRandomCard", {closeCB = dealSaleRunCouponGift})
                gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
                return
            end
        end

        openShopRandomCardLayer()
    end

    -- 常规促销 小游戏 cxc
    local function openSaleMiniGamesLayer()
        local miniGameUsd = 0
        if buyData["getMiniGameUsd"] then
            miniGameUsd = buyData:getMiniGameUsd()
        end
        if storeType ~= BUY_TYPE.SPECIALSALE and storeType ~= BUY_TYPE.NOCOINSSPECIALSALE then
            -- 不是 常规促销 或者 没钱促销 return
            dealLuckSpinLayerActPop()
            return
        end

        -- 促销 没有小游戏值
        if miniGameUsd <= 0 then
            dealLuckSpinLayerActPop()
            return
        end

        -- 给manager设置小游戏最高奖励的 金币价值
        local luckyChooseManager = util_require("manager/System/LuckyChooseManager"):getInstance()
        luckyChooseManager:popLuckyChooseLayer(dealLuckSpinLayerActPop)
    end

    local function nextOtherTips()
        if CardSysManager:needDropCards("Super Spin Card") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    openSaleMiniGamesLayer()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Super Spin Card")
        elseif CardSysManager:needDropCards("Super Spin Golden Card") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    openSaleMiniGamesLayer()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Super Spin Golden Card")
        elseif CardSysManager:needDropCards("Super Spin Guaranteed Card") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    openSaleMiniGamesLayer()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Super Spin Guaranteed Card")
        elseif CardSysManager:needDropCards("Lucky Spin New Card") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    openSaleMiniGamesLayer()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Lucky Spin New Card")
        else
            openSaleMiniGamesLayer()
        end
    end

    -- 神像双倍掉落buff
    local checkStatueBuffDoubleCard = function()
        if CardSysManager:needDropCards("Purchase Double Buff") == true then
            -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响 用完即时消除
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    nextOtherTips()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Purchase Double Buff")
        else
            nextOtherTips()
        end
    end

    local checkDropCards = function()
        if CardSysManager:needDropCards("Purchase") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    checkStatueBuffDoubleCard()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Purchase")
        else
            checkStatueBuffDoubleCard()
        end
    end

    -- 商城充值送卡活动面板
    local checkShopRandomCardDrop = function()
        if CardSysManager:needDropCards("Shop Absent Card") == true then
            -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响 用完即时消除
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    checkDropCards()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Shop Absent Card")
        else
            checkDropCards()
        end
    end

    -- 最新buytips掉落顺序
    -- 商城充值掉卡->普通卡包掉落->其他特殊卡包掉落->掉落猫粮->常规促销小游戏->LuckySpin随机卡活动->saleRunData中的一些弹板->商城充值送卡活动面板(会打开界面)
    --掉卡之前的提示
    if gLobalViewManager.checkAfterBuyTipList then
        gLobalViewManager:checkAfterBuyTipList(
            function()
                checkShopRandomCardDrop()
            end
        )
    else
        checkShopRandomCardDrop()
    end
end

--[[
    @desc: 独立的创建出 商城界面,方便一些外部调用的点去修改创建逻辑
]]
function ShopManager:createShopMainLayer(_shopPageIndex, _notPushView)
    local shopPageIndex = _shopPageIndex or 1
    local notPushView = _notPushView or false
    local view = nil
    if not gLobalViewManager:getViewByExtendData("ZQCoinStoreLayer") then
        -- local view = util_createView("GameModule.Shop.ZQCoinStoreLayer", {shopPageIndex = shopPageIndex},nil,notPushView)
        view = util_createView(SHOP_CODE_PATH.MainLayer, shopPageIndex, notPushView)
    end
    return view
end

-- 进入商店的默认page
function ShopManager:getEnterPageIdx()
    return self.m_shopEnterPageIdx or 1
end

--[[
    @desc: 外部统一调用的打开商城接口
    author:csc
    time:2021-12-22 
    --@_params: 参数 ，用来区分当前界面是否应该打点
]]
function ShopManager:showMainLayer(_params)
    _params = _params or {}
    local activityName = _params.activityName
    local log = _params.log
    local shopPageIndex = _params.shopPageIndex or 1
    self.m_shopEnterPageIdx = shopPageIndex
    local rootStartPos = _params.rootStartPos
    local notPushView = _params.notPushView
    -- 本地打点
    local dotKeyType = _params.dotKeyType
    local dotUrlType = _params.dotUrlType
    local dotIsPrep = _params.dotIsPrep
    local dotEntrySite = _params.dotEntrySite
    local dotEntryType = _params.dotEntryType
    -- 是否进行 firebase 打点
    if activityName and log then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(activityName .. "_PopupClick", false)
        end
        gLobalSendDataManager:getLogIap():setEnterOpen(nil, nil, activityName)
    end

    -- 注册代币引导
    G_GetMgr(G_REF.ShopBuck):getGuideMgr():onRegist()

    local view = self:createShopMainLayer(shopPageIndex, notPushView)
    -- 是否设置弹出坐标
    if view then
        if rootStartPos then
            view:setRootStartPos(rootStartPos)
        end
        -- 本地打点
        if dotKeyType then
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():addNodeDot(view, dotKeyType, dotUrlType, dotIsPrep, dotEntrySite, dotEntryType)
            end
        end
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

-- 说明界面
function ShopManager:showRulesLayer()
    if gLobalViewManager:getViewByExtendData("ShopRulesLayer") == nil then
        local layer = util_createView(SHOP_CODE_PATH.InfoLayer)
        if layer ~= nil then
            self:showLayer(layer, ViewZorder.ZORDER_UI)
        end
    end
end

--子类重写lua文件更新路径
function ShopManager:updateCodeInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            SHOP_CODE_PATH[key] = value
        end
    end
end
--子类修改资源路径
function ShopManager:updateResInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            SHOP_RES_PATH[key] = value
        end
    end
end

--子类修改资源路径
function ShopManager:updateTypeInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            SHOP_VIEW_TYPE[key] = value
        end
    end
end

-- 零点刷新 推荐位促销数据
function ShopManager:refreshSaleConfig()
    -- 需要考虑到当前是否处于购买过程中
    if self.m_buyStatus then
        return
    end
    -- 添加遮罩
    gLobalViewManager:addLoadingAnima()
    if self.m_schduleRefrsh == nil then
        self.m_schduleRefrsh =
            scheduler.performWithDelayGlobal(
            function()
                gLobalSendDataManager:getNetWorkFeature():sendQuerySaleConfig(
                    function()
                        if self.m_schduleRefrsh ~= nil then
                            scheduler.unscheduleGlobal(self.m_schduleRefrsh)
                            self.m_schduleRefrsh = nil
                        end
                        gLobalViewManager:removeLoadingAnima()
                        -- 通知去刷新界面
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWZEROUPDATE)
                    end
                )
            end,
            0
        )
    end
end

-- 创建商城单独的奖励预览道具,对特殊道具的道具信息进行处理
function ShopManager:getDescShopItemData(_rewardData)
    --这里默认取第一个道具显示
    if string.find(_rewardData.p_icon, "MiniGame_") then
        _rewardData:setTempData({p_num = 1}) --
    end
    if string.find(_rewardData.p_icon, "CashMoney") then
        _rewardData:setTempData({p_num = 1}) --
    end
    if string.find(_rewardData.p_icon, "DuckShot") then
        _rewardData:setTempData({p_num = 1}) --
    end
    if string.find(_rewardData.p_icon, "Poker_Recall") then
        _rewardData:setTempData({p_num = 1}) --
    end
    if string.find(_rewardData.p_icon, "DART_BALLON") then
        _rewardData:setTempData({p_num = 1}) --
    end
    if string.find(_rewardData.p_icon, "club_pass_") then -- 高倍场体验卡
        _rewardData:setTempData({p_num = 1}) --
        --设置mark 值
        _rewardData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_X_ITEM}}) -- 隐藏数量
    end
    if string.find(_rewardData.p_icon, "luckychallengerefresh") then
        _rewardData.p_itemInfo.p_name = "REFRESH TICKET"
    end
    if string.find(_rewardData.p_icon, "Sidekicks_levelUp") then
        _rewardData.p_itemInfo.p_name = "Pet Food"
    end
    if string.find(_rewardData.p_icon, "Sidekicks_starUp") then
        _rewardData.p_itemInfo.p_name = "Bells"
    end
    return _rewardData
end

function ShopManager:setPromomodeOpen(_flag)
    self.m_promomodeOpen = _flag
end

function ShopManager:getPromomodeOpen()
    return self.m_promomodeOpen
end

function ShopManager:setPromomodeSound(_flag)
    self.m_promomodeSound = _flag
end

function ShopManager:getPromomodeSound()
    return self.m_promomodeSound
end

return ShopManager

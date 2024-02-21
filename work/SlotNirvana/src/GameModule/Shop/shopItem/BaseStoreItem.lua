--[[
    he
    time:2020-08-19 15:53:48
]]
local BaseView = util_require("base.BaseView")
local BaseStoreItem = class("BaseStoreItem", BaseView)

BaseStoreItem.m_itemIndex = nil
BaseStoreItem.m_itemData = nil
BaseStoreItem.m_clickBtnName = nil
BaseStoreItem.m_tipNode = nil
BaseStoreItem.m_coinsNode = nil
BaseStoreItem.m_extraNode = nil
BaseStoreItem.m_extraLb = nil
BaseStoreItem.m_couponNode = nil
BaseStoreItem.m_dollarLb = nil
BaseStoreItem.m_bgImage = nil
BaseStoreItem.m_touchLayout = nil
BaseStoreItem.m_coinIconNode = nil
BaseStoreItem.m_btn_buy = nil

BaseStoreItem.m_couponView = nil
BaseStoreItem.m_coinsNumNode = nil

BaseStoreItem.m_mostBestTitleNode = nil
BaseStoreItem.m_mostBestTitleName = nil

local STORE_ITEM_COINSICON_COUNT = 6
local STORE_REWARD_COUNT = 3

-- 子类重写
function BaseStoreItem:getBuyType()
    return ""
end

-- 子类重写
function BaseStoreItem:getAddCoins()
    return 0
end

-- 子类重写
function BaseStoreItem:getCsbName()
    return "Shop_Res/CoinStoreCell.csb", "Shop_Res/CoinStoreCellPortrait.csb"
end

-- 子类重写
function BaseStoreItem:getSGCsbName()
    return "Shop_Res/ZQCoinStoreLayer_anniuSG.csb"
end

-- 子类重写
function BaseStoreItem:getNumLuaName()
    return "GameModule.Shop.shopItem.ZQCoinStoreItemNum"
end

-- 子类重写
function BaseStoreItem:getTicketLuaName()
    return ""
end

-- 子类重写
function BaseStoreItem:getCoinIconLuaName()
    return ""
end

-- 子类可重写
function BaseStoreItem:createBuyTipUI()
    local view = util_createView("GameModule.Shop.BuyTip")
    view:initBuyTip(
        BUY_TYPE.STORE_TYPE,
        self.m_preBuyShowData,
        self.m_preBuyShowData.p_baseCoins,
        gLobalSaleManager:getLevelUpNum(),
        function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        end
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 子类重写
function BaseStoreItem:getItemData()
    return {}
end

-- 子类重写
function BaseStoreItem:getCardData()
    return {}
end

function BaseStoreItem:initUI(itemIndex, itemData)
    self.m_itemIndex = itemIndex
    self:updateItemData(itemData)
    self:initItemCsb()
    self:initItemUI()
end

function BaseStoreItem:updateItemData(itemData)
    self.m_itemData = itemData
end

function BaseStoreItem:initItemCsb()
    local csbName = nil
    local path, pathPro = self:getCsbName()
    if globalData.slotRunData.isPortrait == true then
        csbName = pathPro
    else
        csbName = path
    end
    self:createCsbNode(csbName)
end

function BaseStoreItem:initItemUI()
    self.m_tipNode = self:findChild("node_tipNode")
    self.m_coinsNode = self:findChild("node_coins")

    -- node_extra和node_ticket只显示一个，且node_ticket优先级最高
    self.m_extraNode = self:findChild("node_extra")
    self.m_extraLb = self:findChild("lb_extra")

    self.m_couponNode = self:findChild("node_coupon")
    self.m_dollarLb = self:findChild("label_1")
    self.m_bgImage = self:findChild("img_bg")
    self.m_touchLayout = self:findChild("layout_touch")
    self.m_coinIconNode = self:findChild("node_coinIcon")
    self.m_btn_buy = self:findChild("btn_buy")

    self:addClick(self.m_touchLayout)
    self:initExtra()
    self:initExtraTips()
    self:initTicket()
    self:initCoinIcon()
    self:initStoreItemCoins()
    self:initRewardInfo()
    self:initShopPrice()
    --self:addBuyBtnFlash()  --缺少资源 一直报错 先注释掉
end

-- 子类重写：活动打折，位于金币右边
function BaseStoreItem:initExtra()
    if not self.m_itemData.getDiscount then
        if self.m_itemData.__cname then
            release_print("------------------ZQCoinStoreItem:initExtra itemData class name = " .. self.m_itemData.__cname)
        end
    end
    local value = self.m_itemData:getDiscount()
    if value > 0 then
        self.m_extraNode:setVisible(true)
        self.m_extraLb:setString(tostring(value) .. "%")
    else
        self.m_extraNode:setVisible(false)
    end
end

-- 子类重写：折扣道具，位于金币左边
function BaseStoreItem:initTicket()
    local hasSaleTicket = false
    if self.m_itemData.p_ticketDiscount and self.m_itemData.p_ticketDiscount > 0 then
        hasSaleTicket = true
    end

    if hasSaleTicket then
        if not self.m_ticketItem then
            self.m_ticketItem = util_createView(self:getTicketLuaName())
            self.m_couponNode:addChild(self.m_ticketItem)
        end
        if self.m_ticketItem then
            self.m_ticketItem:updateUI(self.m_itemData)
        end
    else
        if self.m_ticketItem then
            self.m_ticketItem:removeFromParent()
            self.m_ticketItem = nil
        end
    end
end

-- 子类重写: 额外的活动添加tips ，位于金币上
function BaseStoreItem:initExtraTips()
end

function BaseStoreItem:initStoreItemCoins()
    self.m_coinsNumNode = util_createView(self:getNumLuaName(), self.m_itemData)
    self.m_coinsNode:addChild(self.m_coinsNumNode)
end

function BaseStoreItem:initCoinIcon()
    self.m_coinIcon = util_createView(self:getCoinIconLuaName(), self.m_itemIndex)
    self.m_coinIconNode:addChild(self.m_coinIcon)
    self.m_coinIcon:setVisible(true)
end

--有集卡显示2项 没集卡显示三项
function BaseStoreItem:initRewardInfo()
    local cardData = self:getCardData()
    local rewardItemDatas = self:getItemData()
    local index = 1
    local offX = 0 --X偏移
    --有卡牌第一个位置放卡牌
    if cardData then
        local cardItem = self:createPropNode(cardData, 1)
        local benefitNode = self:getBenefitNode(index)
        if cardItem then
            benefitNode:addChild(cardItem)
            index = index + 1 --跳过一个
        end
        if globalData.slotRunData.isPortrait == true then
            offX = 0
        end
    end

    for i = 1, #rewardItemDatas do
        local data = rewardItemDatas[i]
        local propNode = self:createPropNode(data, 3)
        if propNode then
            local benefitNode = self:getBenefitNode(index)
            benefitNode:addChild(propNode)
            propNode:setPositionX(offX)
            if index == STORE_REWARD_COUNT then
                break
            end
            index = index + 1
        end
    end
end

function BaseStoreItem:updateRewardInfo()
    for i = 1, STORE_REWARD_COUNT do
        local node = self:getBenefitNode(i)
        node:removeAllChildren()
    end
    self:initRewardInfo()
end

function BaseStoreItem:createPropNode(data, index)
    if data == nil or data.p_icon == "Coupon" then
        return nil
    end
    if data.p_icon == "CashBack" then
        data:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}})
    end
    local propNode = gLobalItemManager:createRewardNode(data, ITEM_SIZE_TYPE.TOP)
    return propNode
end

function BaseStoreItem:getExtraPropList(storeData)
    if storeData.getExtraPropList ~= nil then
        return storeData:getExtraPropList()
    end

    --适配老版本
    local ret = {}
    for i = 1, #storeData.p_displayList do
        local shopItemData = self.m_itemData.p_displayList[i]
        if shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_COIN then
            ret[#ret + 1] = shopItemData
        end
    end

    return ret
end

function BaseStoreItem:initShopPrice()
    self.m_dollarLb:setString("$" .. self.m_itemData.p_price)
end

function BaseStoreItem:addBuyBtnFlash()
    if not globalData.slotRunData.isPortrait then
        local flash = util_createAnimation(self:getSGCsbName())
        self.m_btn_buy:addChild(flash)
        local size = self.m_btn_buy:getContentSize()
        flash:setPosition(cc.p(size.width / 2, size.height / 2))
        flash:setScale(0.9)
        flash:runCsbAction("idleframe", true)
    end
end

function BaseStoreItem:updateItemInfo()
    self.m_coinsNumNode:updateItemData(self.m_itemData)
    self.m_coinsNumNode:updataCoinsLb()
    self:initExtra()
    self:initTicket()
    self:updateRewardInfo()
    self:initShopPrice()
    self:initExtraTips()
end

function BaseStoreItem:getBenefitBtnName()
    return "btn_benefits_info"
end

function BaseStoreItem:getBuyBtnName()
    return "btn_buy"
end

function BaseStoreItem:getTouchLayoutName()
    return "layout_touch"
end

function BaseStoreItem:getBenefitNode(index)
    return self:findChild("node_benefit_" .. index)
end

function BaseStoreItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if G_GetMgr(G_REF.Shop):getShopClosedFlag() == true then
        return
    end

    self.m_clickBtnName = name
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == self:getBenefitBtnName() then
        self:showItemTip()
    elseif name == self:getBuyBtnName() then
        self:clickBuyBtn()
    elseif name == self:getTouchLayoutName() then
        self:showItemTip()
    end
end

function BaseStoreItem:showItemTip()
end

function BaseStoreItem:registerObserver()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.SaleTicket then
                self:initTicket()
            elseif params.name == ACTIVITY_REF.Coupon then
                self:initExtra()
            elseif params.name == ACTIVITY_REF.GemStoreSale then
                self:initExtra()
            elseif params.name == ACTIVITY_REF.GemCoupon then
                self:initExtra()
            elseif params.name == ACTIVITY_REF.StoreSaleRandomCard then
                self:initExtraTips()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function BaseStoreItem:onEnter()
    self:registerObserver()
end

function BaseStoreItem:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
-------------------------------------------------------------------------------------------------------------
----购买逻辑--------------------------------------------------------------------------------------------------
--搬运
function BaseStoreItem:clickBuyBtn()
    local buyShopData = self.m_itemData
    if buyShopData == nil then
        return
    end
    self.m_preBuyShowData = buyShopData
    G_GetMgr(G_REF.Shop):requestBuyItem(self:getBuyType(), buyShopData, self:getAddCoins(),
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

function BaseStoreItem:buyFailed()
    release_print("ShopBuy Failed")
end

function BaseStoreItem:getShowLuckySpinView()
    return true
end

function BaseStoreItem:buySuccess()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYCOINS_SUCCESS)

    --购买成功提示界面
    local buyShopData = self.m_preBuyShowData
    if self:getShowLuckySpinView() then
        local data = {}
        data.buyShopData = clone(buyShopData)
        data.buyIndex = self.m_buyIndex
        data.itemIndex = self.m_itemIndex
        data.closeCall = function(isResetShopLog)
            self:showBuyTip(isResetShopLog)
        end
        G_GetMgr(G_REF.LuckySpin):showMainLayer(data)
    else
        self:showBuyTip()
    end
end

function BaseStoreItem:showBuyTip(isResetShopLog)
    if isResetShopLog then
        --没有购买lucky重置log 修改位置了这里应该不需要先放着
        local goodsInfo,purchaseInfo = G_GetMgr(G_REF.Shop):getLogShopData()
        gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
        gLobalSendDataManager:getLogIap():setPurchaseInfo(purchaseInfo)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_BUY_STORE_FINISH)

    local view = self:createBuyTipUI()
    if gLobalSendDataManager.getLogPopub then
        if not self.m_clickBtnName then
            self.m_clickBtnName = "loseBtn"
        end
        gLobalSendDataManager:getLogPopub():addNodeDot(view, self.m_clickBtnName, DotUrlType.UrlName, false)
    end
end

----购买逻辑--------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
return BaseStoreItem

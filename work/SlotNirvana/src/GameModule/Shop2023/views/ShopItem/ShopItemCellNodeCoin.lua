--[[
    新版商城 滑动cell 金币节点
]]

local ShopBaseItemCellNode = util_require(SHOP_CODE_PATH.ShopBaseItemCellNode)
local ShopItemCellNodeCoin = class("ShopItemCellNodeCoin", ShopBaseItemCellNode)

function ShopItemCellNodeCoin:initCsbNodes()
    ShopItemCellNodeCoin.super.initCsbNodes(self)

    self.m_nodeNumberFirst = self:findChild("node_number_first") or self.m_nodeNumber -- 金币 、 钻石 数量
    self.m_nodeFirstPay = self:findChild("node_firstPay_banner") -- 首购显示标签

    self.m_nodeNumberPosList = {}
    if self.m_nodeNumber and self.m_nodeNumberFirst then
        self.m_nodeNumberPosList[1] = cc.p(self.m_nodeNumber:getPosition())
        self.m_nodeNumberPosList[2] = cc.p(self.m_nodeNumberFirst:getPosition())
    end

    self.m_nodeCardBoostFirst = self:findChild("node_cardBoost_firstPay") or self.m_nodeCardBoost -- cardBoost
    self.m_nodeCardBoostPosList = {}
    if self.m_nodeCardBoost and self.m_nodeCardBoostFirst then
        self.m_nodeCardBoostPosList[1] = cc.p(self.m_nodeCardBoost:getPosition())
        self.m_nodeCardBoostPosList[2] = cc.p(self.m_nodeCardBoostFirst:getPosition())
    end
end

-- 子类重写
function ShopItemCellNodeCoin:addItemIcon()
    local iconNode = util_createView(SHOP_CODE_PATH.ItemIconNode,SHOP_VIEW_TYPE.COIN,self.m_index)
    self.m_nodeIcon:addChild(iconNode)
end

-- 子类重写
function ShopBaseItemCellNode:addNumbersNode()
    local numbersNode = util_createView(SHOP_CODE_PATH.ItemCoinNumNode,self.m_itemData,self.m_type, self.m_index)
    self.m_nodeNumber:addChild(numbersNode)
    numbersNode:setName("numberNode")
end

-- 子类重写
function ShopItemCellNodeCoin:getCardData()
    local key = "CoinStoreItem"
    return gLobalItemManager:createCardDataForIap(self.m_itemData.p_keyId, nil, key)
end

function ShopItemCellNodeCoin:getItemData()
    local itemData = self.m_itemData:getExtraPropList()
    local key = "CoinStoreItem"
    --添加通用
    if globalData.saleRunData.checkAddCommonBuyItemTips then
        globalData.saleRunData:checkAddCommonBuyItemTips(itemData, key, self.m_itemData.p_price)
    end
    return itemData
end

-- 额外的tips 金币节点才有
function ShopItemCellNodeCoin:initExtraTips()
    -- 商城送卡活动是否展示标识
    if not G_GetMgr(ACTIVITY_REF.StoreSaleRandomCard):getShopRandomCardIsOpen() then
        if self.m_nodeBoostTips then
            self.m_nodeBoostTips:removeFromParent()
            self.m_nodeBoostTips = nil
        end
        return
    end
    if self.m_itemData.p_shopCardDiscount and self.m_itemData.p_shopCardDiscount > 0 then
        if not self.m_nodeBoostTips then
            self.m_nodeBoostTips = util_csbCreate(SHOP_RES_PATH.ItemIcon_Boost)
            self.m_nodeCardBoost:addChild(self.m_nodeBoostTips, 100)
        end
    else
        if self.m_nodeBoostTips then
            self.m_nodeBoostTips:removeFromParent()
            self.m_nodeBoostTips = nil
        end
    end
end

-- 子类重写
function ShopItemCellNodeCoin:getBuyType()
    return self.m_itemData:getBuyType()
end

-- 子类重写
function ShopItemCellNodeCoin:getAddCoins()
    return self.m_itemData.p_coins
end

-- 子类重写
function ShopItemCellNodeCoin:getShowLuckySpinView()
    return true
end

function ShopItemCellNodeCoin:getBuyDataBaseNums(_buyData)
    return _buyData.p_baseCoins
end


-- 子类重写：首购特殊标签
function ShopItemCellNodeCoin:initFirstBuyUI()
    if not self.m_nodeFirstPay then
        return
    end

    local firstBuyDisc = self.m_itemData:getFirstBuyDiscount()
    if firstBuyDisc > 0 and G_GetMgr(G_REF.Shop):getPromomodeOpen() then
        self.m_nodeNumber:setPosition(self.m_nodeNumberPosList[2])
        self.m_nodeCardBoost:setPosition(self.m_nodeCardBoostPosList[2])
        
        if not self.m_isPortrait then
            self.m_nodeIcon:setVisible(false)
        end
        self.m_nodeFirstPay:setVisible(true)
        self:initFirstBuyInfoUI(firstBuyDisc)
    else
        self.m_nodeNumber:setPosition(self.m_nodeNumberPosList[1])
        self.m_nodeCardBoost:setPosition(self.m_nodeCardBoostPosList[1])
        if not self.m_isPortrait then
            self.m_nodeIcon:setVisible(true)
        end
        self.m_nodeFirstPay:setVisible(false)
    end
end
function ShopItemCellNodeCoin:initFirstBuyInfoUI(_firstBuyDisc)
    -- 折扣金币信息
    local firstBuyDisc = self.m_itemData:getFirstBuyDiscount()
    local oriCoins = self.m_itemData.p_originalCoins or 0
    local firstAddCoins = math.floor(oriCoins * (firstBuyDisc / 100))
    local lbDisc = self:findChild("lb_discount_first_pay")
    -- local lbCoins = self:findChild("lb_first_pay_coins")
    lbDisc:setString("+" .. firstBuyDisc .. "%")
    -- lbCoins:setString("+" .. util_formatCoins(firstAddCoins, 9))
end

return ShopItemCellNodeCoin

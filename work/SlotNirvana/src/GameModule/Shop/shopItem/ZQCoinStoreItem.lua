local BaseStoreItem = util_require("GameModule.Shop.shopItem.BaseStoreItem")
local ZQCoinStoreItem = class("ZQCoinStoreItem", BaseStoreItem)

-- 子类重写
function ZQCoinStoreItem:getBuyType()
    return BUY_TYPE.STORE_TYPE
end

-- 子类重写
function ZQCoinStoreItem:getAddCoins()
    return self.m_itemData.p_coins
end

-- 子类重写
function ZQCoinStoreItem:getNumLuaName()
    return "GameModule.Shop.shopItem.ZQCoinStoreItemNum"
end

-- 子类重写
function ZQCoinStoreItem:getCoinIconLuaName()
    return "GameModule.Shop.shopItem.ZQCoinStoreItemIcon"
end

-- 子类重写
function ZQCoinStoreItem:getShowLuckySpinView()
    return globalData.luckySpinData:isExist() == true and self.m_itemIndex >= self.m_luckySpinLevel
end

function ZQCoinStoreItem:initItemUI()
    ZQCoinStoreItem.super.initItemUI(self)
    self.m_luckySpinNode = self:findChild("node_lucky_spin")
    self:initLuckySpin()
    self:setMostBestTitile()
end

-- 额外的tips
function ZQCoinStoreItem:initExtraTips()
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
            self.m_nodeBoostTips = util_createView("GameModule.Shop.shopItem.ZQCoinStoreItemBoost")
            self.m_coinIconNode:addChild(self.m_nodeBoostTips, 100)
        end
    else
        if self.m_nodeBoostTips then
            self.m_nodeBoostTips:removeFromParent()
            self.m_nodeBoostTips = nil
        end
    end
end

-- 子类重写
function ZQCoinStoreItem:getTicketLuaName()
    return "GameModule.Shop.shopItem.ZQCoinStoreItemTicket"
end

function ZQCoinStoreItem:initLuckySpin()
    if not self.m_luckySpinNode then
        return
    end
    self.m_luckySpinLevel = globalData.shopRunData:getLuckySpinLevel()
    if self.m_itemIndex >= self.m_luckySpinLevel then
        self.m_luckySpinNode:setVisible(true)
        if self.m_luckySpinNode:getChildByName("luckySpinTip") == nil then
            local luckySpinTip = util_createView("GameModule.Shop.shopLuckySpinTip")
            luckySpinTip:setName("luckySpinTip")
            self.m_luckySpinNode:addChild(luckySpinTip)
        end
    else
        self.m_luckySpinNode:setVisible(false)
    end
end

function ZQCoinStoreItem:setMostBestTitile()
    -- 有活动的时候不展示 most popu 标签
    if G_GetMgr(ACTIVITY_REF.StoreSaleRandomCard):getShopRandomCardIsOpen() then
        if self.m_itemData.p_shopCardDiscount and self.m_itemData.p_shopCardDiscount > 0 then
            if self.m_mostBestTitleNode then
                self.m_mostBestTitleNode:removeFromParent()
                self.m_mostBestTitleNode = nil
            end
            return
        end
    end

    local id = self:getMostBestTitleId()
    local csbName, tag = self:getMostBestCsbName(id)
    if csbName then
        if not self.m_mostBestTitleNode then
            self.m_mostBestTitleNode =
                util_createView(
                "GameModule.Shop.TittleLittleModular",
                csbName,
                tag,
                function()
                    self.m_coinIcon:setVisible(false)
                end
            )
            self.m_tipNode:addChild(self.m_mostBestTitleNode)

            -- 如果当前有创建 boost tips 需要隐藏掉
            if self.m_nodeBoostTips then
                self.m_nodeBoostTips:setVisible(false)
            end
        end
    else
        if self.m_mostBestTitleNode then
            self.m_mostBestTitleNode:removeFromParent()
            self.m_mostBestTitleNode = nil
        end
    end
end

function ZQCoinStoreItem:updateItemInfo()
    ZQCoinStoreItem.super.updateItemInfo(self)
    self:initLuckySpin()
end

-- 只有金币商店才有
function ZQCoinStoreItem:getMostBestTitleId()
    local tag = self.m_itemData.p_tag
    if tag and tag.p_id then
        return tag.p_id
    end
    return nil
end

function ZQCoinStoreItem:getMostBestCsbName(id)
    local nameStr = nil
    local tag = 0

    if id == TAGTYPE.TAGTYPE_MOST then
        tag = 2
        if globalData.slotRunData.isPortrait then
            nameStr = "shop_title/Tittle_mostPortrait.csb"
        else
            nameStr = "shop_title/Tittle_most.csb"
        end
    elseif id == TAGTYPE.TAGTYPE_BEST then
        tag = 1
        if globalData.slotRunData.isPortrait then
            nameStr = "shop_title/Tittle_bestPortrait.csb"
        else
            nameStr = "shop_title/Tittle_best.csb"
        end
    end
    return nameStr, tag
end

-- 子类重写
function ZQCoinStoreItem:getCardData()
    return gLobalItemManager:createCardDataForIap(self.m_itemData.p_keyId, nil, "CoinStoreItem")
end

function ZQCoinStoreItem:getItemData()
    local itemData = self:getExtraPropList(self.m_itemData)
    --添加通用
    if globalData.saleRunData.checkAddCommonBuyItemTips then
        globalData.saleRunData:checkAddCommonBuyItemTips(itemData, "CoinStoreItem")
    end
    return itemData
end

function ZQCoinStoreItem:showItemTip()
    local data = {index = self.m_itemIndex, size = self.m_bgImage:getContentSize(), type = "COIN"}
    gLobalNoticManager:postNotification("showStoreItemInfo", data)
end

return ZQCoinStoreItem

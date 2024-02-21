local BaseStoreItem = util_require("GameModule.Shop.shopItem.BaseStoreItem")
local ZQGemStoreItem = class("ZQGemStoreItem", BaseStoreItem)

-- 子类重写
function ZQGemStoreItem:getBuyType()
    return BUY_TYPE.GEM_TYPE
end

-- 子类重写
function ZQGemStoreItem:getAddCoins()
    return self.m_itemData.p_gems
end

-- 子类重写
function ZQGemStoreItem:getNumLuaName()
    return "GameModule.Shop.shopItem.ZQGemStoreItemNum"
end

-- 子类重写
function ZQGemStoreItem:getCoinIconLuaName()
    return "GameModule.Shop.shopItem.ZQGemStoreItemIcon"
end

-- 子类重写
function ZQGemStoreItem:getShowLuckySpinView()
    return false
end

-- 子类重写
function ZQGemStoreItem:getTicketLuaName()
    return "GameModule.Shop.shopItem.ZQCoinStoreItemTicket"
end

-- 子类可重写
function ZQGemStoreItem:createBuyTipUI()
    local view = util_createView("GameModule.Shop.BuyTip", BUY_TYPE.GEM_TYPE)
    view:initBuyTip(BUY_TYPE.GEM_TYPE, 
        self.m_preBuyShowData, 
        self.m_preBuyShowData.p_gems,
        gLobalSaleManager:getLevelUpNum(), 
        function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        end
    )
    gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    return view    
end

-- 子类重写
function ZQGemStoreItem:getCardData()
    return gLobalItemManager:createCardDataForIap(self.m_itemData.p_keyId, nil, "GemStoreItem")
end

function ZQGemStoreItem:getItemData()
    local itemData = self:getExtraPropList(self.m_itemData)
    --添加通用
    if globalData.saleRunData.checkAddCommonBuyItemTips then
        globalData.saleRunData:checkAddCommonBuyItemTips(itemData, "GemStoreItem")
    end
    return itemData
end

function ZQGemStoreItem:showItemTip()
    local data = {index = self.m_itemIndex, size = self.m_bgImage:getContentSize(), type = "GEM"}
    gLobalNoticManager:postNotification("showStoreItemInfo", data)
end

return ZQGemStoreItem
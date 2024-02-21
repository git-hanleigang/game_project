

local InboxItem_catFoodCoinRecycled = class("InboxItem_catFoodCoinRecycled", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_catFoodCoinRecycled:getCsbName()
    return "InBox/InboxItem_DeluxeClub_CatFootCoin.csb"
end

function InboxItem_catFoodCoinRecycled:initView()
    -- 金币
    local awards = self.m_mailData.awards or {}
    local lbCoins = self:findChild("label_coin")
    lbCoins:setString(util_formatCoins(tonumber(awards.coins or 0), 12))
    util_scaleCoinLabGameLayerFromBgWidth(lbCoins, 250)
end

return  InboxItem_catFoodCoinRecycled
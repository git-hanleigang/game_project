--[[
    appCharge商品数据
    author:{author}
    time:2023-10-24 18:26:44
]]

-- message AppChargeProduct {
--     optional int64 id = 1;
--     optional string price = 2;
--     optional string coins = 3; //玩家的金币奖励
--     repeated ShopItem items = 4;//玩家道具奖励
--     optional string buckNum = 6;//代币数量
-- }

local ShopItem = require("data.baseDatas.ShopItem")
local ShopCoinsConfig = require("data.baseDatas.ShopCoinsConfig")
local AppChargeProduct = class("AppChargeProduct")

function AppChargeProduct:ctor()
    self.p_id = ""
    self.p_price = "0"
    self.p_coins = "0"
    self.m_itemList = {}
    self.m_shopCoinConfig = nil
    self.m_buckNum = "0"
end

function AppChargeProduct:parseData(data)
    self.p_id = tostring(data.id or 0)
    self.p_price = tostring(data.price or "0")
    self.p_coins = tostring(data.coins or "0")
    if self.p_coins == "" then
        self.p_coins = "0"
    end

    self.m_itemList = {}
    for i = 1, #(data.items or {}) do
        local _item = ShopItem:create()
        _item:parseData(data.items[i])
        self.m_itemList[i] = _item
    end

    if not self.m_shopCoinConfig then
        self.m_shopCoinConfig = ShopCoinsConfig:create()
    end
    self.m_shopCoinConfig:parseData(data.shopCoins)
    self.m_shopCoinConfig.p_coins = self.p_coins
    self.m_buckNum = data.buckNum
end

function AppChargeProduct:getId()
    return self.p_id
end

function AppChargeProduct:getCoins()
    return self.p_coins
end

function AppChargeProduct:getItems()
    return self.m_itemList
end

function AppChargeProduct:getShopCoinsInfo()
    return self.m_shopCoinConfig
end

function AppChargeProduct:getBuckNum()
    return self.m_buckNum
end

return AppChargeProduct
--[[
    接水管特殊促销
    author:{author}
    time:2023-12-28 14:55:30
]]

-- message PipeConnectSpecialSale {
--     optional string key = 1; // 价格的档位
--     optional string price = 2; // 价钱
--     optional string keyId = 3; // 价钱的链接
--     optional string coins = 4;
--     repeated ShopItem items = 5;
--     optional int32 vipPoint = 6; //vip点数
-- }

local ShopItem = require("data.baseDatas.ShopItem")
local PipeConnectSpecialSaleItem = class("PipeConnectSpecialSaleItem")

function PipeConnectSpecialSaleItem:ctor()
    self.p_key = ""
    self.p_price = ""
    self.p_keyId = ""
    self.p_coins = toLongNumber(0)

    self.p_items = {}
    self.p_vipPoint = 0
end

function PipeConnectSpecialSaleItem:parseData(data)
    self.p_key = data.key or ""
    self.p_price = data.price or ""
    self.p_keyId = data.keyId or ""
    if (data.coins or "") ~= "" then
        self.p_coins:setNum(data.coins)
    end

    self.p_items = {}
    for i = 1, #(data.items or {}) do
        local _item = ShopItem:create()
        _item:parseData(data.items[i])
        table.insert(self.p_items, _item)
    end

    self.p_vipPoint = data.vipPoint or 0
end

function PipeConnectSpecialSaleItem:getItems()
    return self.p_items or {}
end

return PipeConnectSpecialSaleItem
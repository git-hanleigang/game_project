--[[
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local DiyFeatureNormalSaleData = class("DiyFeatureNormalSaleData", BaseActivityData)

-- message DiyFeatureSale {
--     optional string key = 1;
--     optional string keyId = 2;
--     optional string price = 3;
--     optional string coins = 4;
--     repeated ShopItem item = 5;
--     optional int64 buffExpireAt = 6; //buff过期时间
-- }

-- message DiyFeatureSaleConfig {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional DiyFeatureSale sale = 4; // 价格
-- }
function DiyFeatureNormalSaleData:parseData(_data)
    DiyFeatureNormalSaleData.super.parseData(self, _data)

    self.p_sale = nil
    if _data:HasField("sale") then
        self.p_sale = self:parseSale(_data.sale)
    end
end

function DiyFeatureNormalSaleData:parseSale(_sale)
    local saleData = {}
    saleData.p_key = _sale.key
    saleData.p_keyId = _sale.keyId
    saleData.p_price = _sale.price
    
    saleData.p_coins = toLongNumber(0)
    saleData.p_coins:setNum(_sale.coins)

    saleData.p_items = {}
    if _sale.item and #_sale.item > 0 then 
        for i,v in ipairs(_sale.item) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(saleData.p_items, tempData)
        end
    end

    saleData.p_buffExpireAt = tonumber(_sale.buffExpireAt) or 0
    return saleData
end

function DiyFeatureNormalSaleData:getSaleData()
    return self.p_sale
end

return DiyFeatureNormalSaleData
local BaseActivityData = require("baseActivity.BaseActivityData")
local EgyptCoinPusherSaleData = class("EgyptCoinPusherSaleData", BaseActivityData)
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local EgyptCoinPusherSalePackData = require("activities.Activity_EgyptCoinPusher.model.EgyptCoinPusherSalePackData")

function EgyptCoinPusherSaleData:ctor()
    EgyptCoinPusherSaleData.super.ctor(self)
end

--[[
    message CoinPusherV3SaleConfig {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional SaleItemConfig sale = 4; //常规促销
        optional CoinPusherV3SpecialSale specialSale = 5; //特殊促销
    }
]]
function EgyptCoinPusherSaleData:parseData(_data)
    EgyptCoinPusherSaleData.super.parseData(self, _data)
    if not self.p_sale then
        self.p_sale = SaleItemConfig:create()
    end
    self.p_sale:parseData(_data.sale)

    if not self.p_packSale then
        self.p_packSale = EgyptCoinPusherSalePackData:create()
    end
    self.p_packSale:parseData(_data.specialSale)
end

function EgyptCoinPusherSaleData:getSale()
    return self.p_sale or {}
end

function EgyptCoinPusherSaleData:getPackSale()
    return self.p_packSale or {}
end

return EgyptCoinPusherSaleData
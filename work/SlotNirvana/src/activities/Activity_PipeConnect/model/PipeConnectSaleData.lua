--[[
    接水管促销
    author:{author}
    time:2023-12-28 14:55:30
]]

-- message PipeConnectSaleConfig {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional SaleItemConfig sale = 4; //常规促销
--     optional PipeConnectSpecialSale specialSale = 5; //特殊促销
--   }

local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require "baseActivity.BaseActivityData"
local PipeConnectSpecialSaleItem = import(".PipeConnectSpecialSaleItem")
local PipeConnectSaleData = class("PipeConnectSaleData", BaseActivityData)

function PipeConnectSaleData:ctor()
    PipeConnectSaleData.super.ctor(self)

    self.m_sale = SaleItemConfig:create()
    self.m_specialSale = PipeConnectSpecialSaleItem:create()
end

function PipeConnectSaleData:parseData(data)
    PipeConnectSaleData.super.parseData(self, data)

    self.m_sale:parseData(data.sale)
    self.m_sale.p_coins = self.m_sale.p_coinsV2
    self.m_specialSale:parseData(data.specialSale)
end

function PipeConnectSaleData:getNormalSale()
    return self.m_sale
end

function PipeConnectSaleData:getSpecialSale()
    return self.m_specialSale
end

return PipeConnectSaleData
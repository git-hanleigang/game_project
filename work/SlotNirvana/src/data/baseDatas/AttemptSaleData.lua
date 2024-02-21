--[[
    多档促销
    author:{author}
    time:2020-07-21 10:52:08
]]
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require "baseActivity.BaseActivityData"
local AttemptSaleData = class("AttemptSaleData", BaseActivityData)

function AttemptSaleData:parseData(data)
    AttemptSaleData.super.parseData(self, data)

    self.p_expireAt = tonumber(data.expireAt)
end

function AttemptSaleData:parseSales(data)
    self.p_sales = {}
    if data ~= nil and #data > 0 then
        for i = 1, #data do
            local sale = SaleItemConfig:create()
            sale:parseData(data[i])
            -- 特殊处理
            sale:getRefName(ACTIVITY_REF.AttemptSale)

            table.insert(self.p_sales, sale)
        end
    end
end

function AttemptSaleData:getSalesData( )
    return self.p_sales
end

return AttemptSaleData

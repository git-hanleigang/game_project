--[[
    多档促销
    author:{author}
    time:2020-07-21 10:52:08
]]
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require "baseActivity.BaseActivityData"
local MultiSaleData = class("MultiSaleData", BaseActivityData)

function MultiSaleData:ctor(data)
    MultiSaleData.super.ctor(self)

    self.p_sales = {}
end

function MultiSaleData:parseData(data)
    -- 这里不调用基类方法
    -- MultiSaleData.super.parseData(self, data[1])
    self.p_open = true

    self.p_sales = {}
    if data ~= nil and #data > 0 then
        for i = 1, #data do
            local sale = SaleItemConfig:create()
            sale:parseData(data[i])

            table.insert(self.p_sales, sale)
        end
    end
end

function MultiSaleData:getSalesData()
    return self.p_sales
end

-- 继承重写活动是否执行方法
function MultiSaleData:isRunning()
    if not MultiSaleData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    return true
end

-- 检查完成条件
function MultiSaleData:checkCompleteCondition()
    if #self.p_sales > 0 then
        local _saleData = self.p_sales[1]
        if _saleData:getExpire() <= 0 then
            return true
        end
    end
    return false
end

return MultiSaleData

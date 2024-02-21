--[[
    促销券
    author:{author}
    time:2020-07-21 10:52:08
]]
-- FIX IOS 139
local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require "baseActivity.BaseActivityData"
local KeepRechargeData = class("KeepRechargeData", BaseActivityData)

function KeepRechargeData:parseData(data)
    KeepRechargeData.super.parseData(self, data)
    self.p_activityId = data.activityId
    self.p_buyAll = data.buyAll

    if data.status then
        self.p_status = {}
        for i=1,#data.status do
            table.insert(self.p_status, data.status[i])
        end
    end
    if data.type then
        self.p_types = {}
        for i=1,#data.type do
            table.insert(self.p_types, data.type[i])
        end
    end

    if data.sales ~= nil and #data.sales > 0 then
        self.p_sales = {}
        for k, v in ipairs(data.sales) do
            local saleItemCfg = SaleItemConfig:create()
            saleItemCfg:parseData(v)
            table.insert(self.p_sales, saleItemCfg)
        end
    end
end

-- 继承重写活动是否执行方法
function KeepRechargeData:isRunning()
    if not KeepRechargeData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    return true
end

-- 检查完成条件
function KeepRechargeData:checkCompleteCondition()
    if self.p_buyAll then
        return true
    end
    return false
end

function KeepRechargeData:getBuyAll()
    return self.p_buyAll
end

function KeepRechargeData:getTypes()
    return self.p_types
end

function KeepRechargeData:getStatus()
    return self.p_status
end

function KeepRechargeData:getSales()
    return self.p_sales
end

return KeepRechargeData

--[[
    4格连续充值
]]

local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local BaseActivityData = require "baseActivity.BaseActivityData"
local KeepRecharge4Data = class("KeepRecharge4Data", BaseActivityData)

-- message KeepRechargeFour {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     repeated string status = 3; //促销的状态 [CLOSED,AVAILABLE,LOCKED]
--     repeated SaleItemConfig sales = 4; //促销列表
--     optional string activityId = 5; //活动id
--     optional bool buyAll = 6; //购买了所有促销
--     repeated string type = 7; //促销商品内容free/pay标识
--   }
function KeepRecharge4Data:parseData(data)
    KeepRecharge4Data.super.parseData(self, data)
    self.p_activityId = data.activityId
    self.p_buyAll = data.buyAll

    self.p_status = {}
    if data.status then
        for i = 1, #data.status do
            table.insert(self.p_status, data.status[i])
        end
    end

    self.p_types = {}
    if data.type then
        for i = 1, #data.type do
            table.insert(self.p_types, data.type[i])
        end
    end

    self.p_sales = {}
    if data.sales ~= nil and #data.sales > 0 then
        for k, v in ipairs(data.sales) do
            local saleItemCfg = SaleItemConfig:create()
            saleItemCfg:parseData(v)
            table.insert(self.p_sales, saleItemCfg)
        end
    end
end

-- 继承重写活动是否执行方法
function KeepRecharge4Data:isRunning()
    if not KeepRecharge4Data.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    return true
end

-- 检查完成条件
function KeepRecharge4Data:checkCompleteCondition()
    if self.p_buyAll then
        return true
    end
    return false
end

function KeepRecharge4Data:getBuyAll()
    return self.p_buyAll
end

function KeepRecharge4Data:getTypes()
    return self.p_types
end

function KeepRecharge4Data:getStatus()
    return self.p_status
end

function KeepRecharge4Data:getSales()
    return self.p_sales
end

function KeepRecharge4Data:getCurStage()
    local stage = 1
    for i,v in ipairs(self.p_status) do
        if v == "AVAILABLE" then
            stage = i
            break
        end
    end
    return stage
end

return KeepRecharge4Data

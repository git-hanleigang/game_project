--[[--
    四个优惠券活动数据
]]
-- message SaleTicketData {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional string activityId = 3; //活动id
--     optional int32 activeIndex = 4;
--     repeated ShopItem activityTickets = 5;
--   }

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"

local SaleTicketData = class("SaleTicketData", BaseActivityData)

function SaleTicketData:parseData(data, isNetData)
    SaleTicketData.super.parseData(self, data, isNetData)

    -- 用来标记是否有数据变化的
    self.m_lastActiveIndex = self.m_lastActiveIndex == nil and data.activeIndex or self.m_lastActiveIndex

    self.p_activeIndex = data.activeIndex
    if data.activityTickets and #data.activityTickets > 0 then
        self.p_activityTickets = {}
        for i = 1, #data.activityTickets do
            self.p_activityTickets[i] = self:parseShopItem(data.activityTickets[i])
        end
    end
    self.p_finish = data.finish -- 最后一个折扣券使用完
    self.p_begin = data.begin -- 活动开始时间 打点用
end

function SaleTicketData:parseShopItem(data)
    local shopItem = ShopItem:create()
    shopItem:parseData(data)
    return shopItem:getData()
end

function SaleTicketData:getActiveIndex()
    return self.p_activeIndex
end

function SaleTicketData:getLastActiveIndex()
    return self.m_lastActiveIndex
end

function SaleTicketData:resetLastActiveIndex()
    self.m_lastActiveIndex = self.p_activeIndex
end

function SaleTicketData:isRunning()
    if not SaleTicketData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    local tickets = self:getTickets()
    if #tickets ~= 4 then
        return false
    end

    return true
end

-- 检查完成条件
function SaleTicketData:checkCompleteCondition()
    if self.p_finish ~= nil and self.p_finish == true then
        return true
    end
    return false
end

function SaleTicketData:getTickets()
    return self.p_activityTickets or {}
end

return SaleTicketData

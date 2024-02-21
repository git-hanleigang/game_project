--[[--
    钻石商城优惠券数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require "baseActivity.BaseActivityData"
local ShopGemCouponData = class("ShopGemCouponData", BaseActivityData)

-- message SaleTicketConfig {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional string activityId = 3; //活动id
--     optional int32 activeIndex = 4;
--     repeated ShopItem activityTickets = 5;
--     optional bool finish = 6; //是否全部消耗完
--     optional string begin = 7;
--     repeated int64 useTicketIds = 8; //使用过的道具id
--   }

-- 数据结构设计：支持多个优惠券且优惠力度不一样的情况
function ShopGemCouponData:parseData(data,isNetData)
    ShopGemCouponData.super.parseData(self,data,isNetData)

    self.p_activeIndex = data.activeIndex
    self.p_finish = data.finish -- 最后一个券使用完时为true
    self.p_begin = data.begin -- 活动开始时间 打点用

    if data.activityTickets and #data.activityTickets > 0 then
        self.p_activityTickets = {}
        for i=1,#data.activityTickets do
            self.p_activityTickets[i] = self:parseShopItem(data.activityTickets[i])
        end
    end

    self.p_useTicketIds = {}
    if data.useTicketIds and #data.useTicketIds > 0 then
        for i=1,#data.useTicketIds do
            table.insert(self.p_useTicketIds, data.useTicketIds[i])
        end
    end
end

function ShopGemCouponData:parseShopItem(data)
    local shopItem = ShopItem:create()
    shopItem:parseData(data)
    return shopItem:getData()
end

function ShopGemCouponData:getDiscount()
    if self.p_activityTickets and #self.p_activityTickets > 0 then
        return self.p_activityTickets[#self.p_activityTickets].p_num
    end
    return 0
end

function ShopGemCouponData:getActiveIndex()
    return self.p_activeIndex
end

function ShopGemCouponData:getCouponList()
    return self.p_activityTickets
end

function ShopGemCouponData:getUsedCouponList()
    return self.p_useTicketIds
end

function ShopGemCouponData:isRunning()
    if not ShopGemCouponData.super.isRunning(self) then
        return false
    end

    -- 完成条件后，活动关闭
    if self:isCompleted() then
        return false
    end
    return true

end

-- 检查完成条件
function ShopGemCouponData:checkCompleteCondition()
    if self.p_finish ~= nil and self.p_finish == true then
        return true
    end    
    return false
end

return ShopGemCouponData

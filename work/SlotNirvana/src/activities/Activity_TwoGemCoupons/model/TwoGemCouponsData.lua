
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local TwoGemCouponsData = class("TwoGemCouponsData", BaseActivityData)

-- message TwoGemCoupons {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated ShopItem saleTickets = 4;//优惠券
--   }
function TwoGemCouponsData:parseData(_data)
    TwoGemCouponsData.super.parseData(self, _data)

    self.p_expireAt = tonumber(_data.expireAt)
    self.p_saleTickets = self:parseTicketData(_data.saleTickets)
end

function TwoGemCouponsData:parseTicketData(_data)
    local tickets = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(tickets, tempData)
        end
    end
    return tickets
end

function TwoGemCouponsData:getSaleTickets()
    return self.p_saleTickets
end

return TwoGemCouponsData

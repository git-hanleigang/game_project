--[[--
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BucksBackData = class("BucksBackData", BaseActivityData)

-- message PaySendBuckResult {
--     optional string activityId = 1; // 活动的id
--     optional string activityName = 2;// 活动的名称
--     optional string begin = 3;// 活动的开启时间
--     optional int64 expireAt = 4; // 活动倒计时
--     optional bool paid = 5;//是否付费
--     optional string ratio = 6;// 比率
--   }
function BucksBackData:parseData(_data)
    BucksBackData.super.parseData(self, _data)

    self.p_paid = _data.paid
    self.p_ratio = _data.ratio
end

function BucksBackData:isPaid()
    return self.p_paid
end

function BucksBackData:getDiscount()
    local discount = tonumber(self.p_ratio or 0) * 100
    return discount
end

return BucksBackData
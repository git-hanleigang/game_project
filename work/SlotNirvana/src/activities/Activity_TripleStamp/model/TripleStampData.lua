--[[--
    3倍盖戳数据
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local TripleStampData = class("TripleStampData", BaseActivityData)

-- message TripleStamp {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional string activityId = 3; //活动id
--     optional string name = 4; // 活动名称
--     optional int32 multiple = 5; // 倍数
--     optional int32 limitTimes = 6; // 次数
--   }
function TripleStampData:parseData(data, isNetData)
    TripleStampData.super.parseData(self, data, isNetData)

    self.p_name = data.name
    self.p_multiple = data.multiple
    self.p_limitTimes = data.limitTimes
end

function TripleStampData:getMultiple()
    if self.p_limitTimes and self.p_limitTimes > 0 then
        return self.p_multiple
    end
end

function TripleStampData:getLimitTimes()
    return self.p_limitTimes or 0
end

function TripleStampData:getLeftTime()
    if not self.p_limitTimes or self.p_limitTimes <= 0 then
        return -1
    end

    return TripleStampData.super.getLeftTime(self)
end

return TripleStampData

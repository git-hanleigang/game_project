--[[--
    多次盖戳数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require "baseActivity.BaseActivityData"
local MulLuckyStampData = class("MulLuckyStampData", BaseActivityData)

-- message DoubleStamp {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional string activityId = 3; //活动id
--     optional string name = 4; // 活动名称
--     optional int32 multiple = 5; // 倍数
--   }
function MulLuckyStampData:parseData(data, isNetData)
    MulLuckyStampData.super.parseData(self, data, isNetData)

    self.p_name = data.name
    self.p_multiple = data.multiple
end

function MulLuckyStampData:getMultiple()
    return self.p_multiple
end

return MulLuckyStampData

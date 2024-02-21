
-- lucky stemp 送卡

local BaseActivityData = require("baseActivity.BaseActivityData")
local LuckyStampCardData = class("LuckyStampCardData", BaseActivityData)

--message LuckyStampCard {
--    optional int32 expire = 1; //剩余秒数
--    optional int64 expireAt = 2; //过期时间
--    optional string activityId = 3; //活动id
--    repeated ShopItem items = 4;//物品
--    optional bool active = 5;//奖励激活标识
--}
function LuckyStampCardData:parseData( data )
    BaseActivityData.parseData(self, data)
    self.active = data.active
    self:setRewards(data.items)
    -- 数据刷新事件
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.LuckyStampCard})
end

function LuckyStampCardData:setRewards( data )
    self.items = {}
    for index, value in ipairs(data) do
        table.insert(self.items, data[index])
    end
end

function LuckyStampCardData:getRewards()
    return self.items
end

function LuckyStampCardData:isActive()
    return self.active
end

return LuckyStampCardData
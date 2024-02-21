-- 打开推送通知送奖

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local NotificationData = class("NotificationData", BaseActivityData)

-- message MessagePush {
--     optional string activityId = 1; // 活动的id
--     optional string activityName = 2;// 活动的名称
--     optional string begin = 3;// 活动的开启时间
--     optional int64 expireAt = 4; // 活动倒计时
--     optional string type = 5;// 奖励类型
--     repeated ShopItem items = 6;// 道具
--     optional string coins = 7;// 金币
--     optional int64 cdExpired = 8;// cd过期时间
--     optional bool collected = 9;// 是否领取
--   }

function NotificationData:parseData(_data)
    NotificationData.super.parseData(self, _data)

    self.p_type = _data.type
    self.p_coins = _data.coins
    self.p_collected = _data.collected
    self.p_cdExpired = tonumber(_data.cdExpired)
    self.p_items = self:parseItemData(_data.items)
    self.p_openLevel = 20
end

function NotificationData:parseItemData(_items)
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function NotificationData:getCoins()
    return self.p_coins
end

function NotificationData:getItems()
    return self.p_items
end

function NotificationData:getCdExpired()
    return (self.p_cdExpired or 0) / 1000
end

function NotificationData:getCollected()
    return self.p_collected
end

function NotificationData:isRunning()
    local flag = NotificationData.super.isRunning(self)
    if not util_isSupportVersion("1.9.4", "android") and not util_isSupportVersion("1.9.9", "ios") then
        flag = false
    end

    return flag
end

return NotificationData

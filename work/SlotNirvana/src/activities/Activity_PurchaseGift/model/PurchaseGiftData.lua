--商城制定档位送道具
local BaseActivityData = require "baseActivity.BaseActivityData"
local ShopItem = util_require("data.baseDatas.ShopItem")
local PurchaseGiftData = class("PurchaseGiftData", BaseActivityData)
-- message PurchaseGiftConfig {
--   optional string activityId = 1;//活动id
--   optional int64 expireAt = 2;//活动过期时间戳
--   optional int32 expire = 3;//活动剩余秒数
--   optional string price = 4;//起始档位价格
--   repeated ShopItem reward = 5;//物品奖励
--   optional int32 upperTimes = 6;//领取上限
--   optional bool finish = 7;//是否结束 达到领取上限
-- }
function PurchaseGiftData:ctor()
    PurchaseGiftData.super.ctor(self)
end

function PurchaseGiftData:parseData(data)
    BaseActivityData.parseData(self, data)
    self.expire = data.expireAt
    self.upperTimes = data.upperTimes
    self.isFinish = data.finish
    self.m_price = data.price
    self.shop_item = self:parseItems(data.reward)
    if self.isFinish then
        self.p_open = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COMPLETED, {id = self:getID(), name = ACTIVITY_REF.PurchaseGift})
    end
end

function PurchaseGiftData:parseGiftData(_data)
    self.expire = _data.expireAt
    self.upperTimes = _data.upperTimes
    self.isFinish = _data.finish
    self.m_price = _data.price
    self.shop_item = self:parseItems(_data.reward)
end

function PurchaseGiftData:parseItems(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            if tempData.p_mark then
                tempData.p_mark[1] = ITEM_MARK_TYPE.NONE
            end
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function PurchaseGiftData:getExpire()
    return self.expire
end

function PurchaseGiftData:getUpperTimes()
    return self.upperTimes
end

function PurchaseGiftData:getIsFinish()
    return self.isFinish
end

function PurchaseGiftData:getPrice()
    return self.m_price
end

function PurchaseGiftData:getRewardItem()
    return self.shop_item
end
return PurchaseGiftData

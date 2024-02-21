--[[
    充值抽奖池
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local PrizeGameData = class("PrizeGameData",BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

-- message PrizeGame {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int32 prizePoolUsd = 4;//奖池美刀
--     optional int32 remainingTimes = 5;//剩余次数
--     repeated PrizeGameRecord recordList = 6;//中奖纪录
--     repeated PrizeGameSlot slotList = 7;//抽奖结果
--     repeated PrizeGameSale saleList = 8;//促销
--   }
function PrizeGameData:parseData(_data)
    PrizeGameData.super.parseData(self, _data)

    self.p_prizePoolUsd = _data.prizePoolUsd
    self.p_remainingTimes = _data.remainingTimes
    self.p_recordList = self:parseRecordData(_data.recordList)
    self.p_slotList = self:parseSlotData(_data.slotList)
    self.p_saleList = self:parseSaleData(_data.saleList)
end

-- message PrizeGameRecord {
--     optional string name = 1;
--     optional string winPercentage = 2; //中奖百分比 20% 5%
--   }
function PrizeGameData:parseRecordData(_data)
    local recordList = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_name = v.name
            tempData.p_winPercentage = v.winPercentage
            table.insert(recordList, tempData)
        end
    end
    return recordList
end

-- message PrizeGameSlot {
--     repeated int32 reels = 1;//老虎机中间信号
--     optional int64 coins = 2;//金币
--     repeated ShopItem items = 3;
--     optional int32 winPercentage = 4; //中奖百分比 20 5 0
--     optional int32 winUsd = 5;//赢取的美刀
--   }
function PrizeGameData:parseSlotData(_data)
    local SlotList = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_reels = v.reels
            tempData.p_coins = tonumber(v.coins)
            tempData.p_winPercentage = v.winPercentage
            tempData.p_winUsd = v.winUsd
            tempData.p_items = self:parseItemData(v.items)
            table.insert(SlotList, tempData)
        end
    end
    return SlotList
end

function PrizeGameData:parseItemData(_items)
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

-- message PrizeGameSale {
--     optional string key = 1;
--     optional string keyId = 2;
--     optional string price = 3;
--     optional int32 times = 4;
--   }
function PrizeGameData:parseSaleData(_data)
    local saleData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_key = v.key
            tempData.p_keyId = v.keyId
            tempData.p_price = v.price
            tempData.p_times = v.times
            table.insert(saleData, tempData)
        end
    end
    return saleData
end

function PrizeGameData:getPrizePoolUsd()
    return self.p_prizePoolUsd
end

function PrizeGameData:getRemainingTimes()
    return self.p_remainingTimes
end

function PrizeGameData:getRecordList()
    return self.p_recordList
end

function PrizeGameData:getSlotList()
    return self.p_slotList
end

function PrizeGameData:getSaleList()
    return self.p_saleList
end

return PrizeGameData

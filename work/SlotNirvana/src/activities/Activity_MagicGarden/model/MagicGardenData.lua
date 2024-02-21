--[[
    合成转盘
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local MagicGardenData = class("MagicGardenData", BaseActivityData)

-- message MagicGarden {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int32 drawTimes = 4;//剩余抽奖次数
--     repeated MagicGardenPrizePool prizePool = 5;//奖池
--     repeated MagicGardenStageBox stageBox = 6;//阶段宝箱
--     repeated MagicGardenSale saleList = 7;//促销
--     optional int32 currentPoints = 8;//当前宝箱点数
--     optional bool first = 9;//第一次
--   }
function MagicGardenData:parseData(_data)
    MagicGardenData.super.parseData(self, _data)

    self.p_first = _data.first
    self.p_drawTimes = _data.drawTimes
    self.p_currentPoints = _data.currentPoints
    self.p_prizePool = self:parsePrizePool(_data.prizePool)
    self.p_sale = self:parseSaleData(_data.saleList)
    self.p_stageBox = self:parseStageBox(_data.stageBox)
end

-- message MagicGardenPrizePool {
--     optional int32 index = 1;
--     optional int64 coins = 2;
--     repeated ShopItem items = 3;
--     optional bool bigReward = 4;//是否大奖
--     optional int32 points = 5;//积分（水滴数）
--     optional bool extracted = 6;//是否抽取
--     optional bool collected = 7;//是否领取
--   }
function MagicGardenData:parsePrizePool(_data)
    local rewardList = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.p_index = v.index
            tempData.p_coins = tonumber(v.coins)
            tempData.p_bigReward = v.bigReward
            tempData.p_extracted = v.extracted
            tempData.p_collected = v.collected
            tempData.p_points = v.points
            tempData.p_items = self:parseItems(v.items)
            table.insert(rewardList, tempData)
        end
    end
    return rewardList
end

-- message MagicGardenSale {
--     optional string price = 1;
--     optional string key = 2;
--     optional string keyId = 3;
--     optional int32 drawTimes = 4;
--   }
function MagicGardenData:parseSaleData(_data)
    local sale = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.p_key = v.key
            tempData.p_keyId = v.keyId
            tempData.p_price = v.price
            tempData.p_drawTimes = v.drawTimes
            table.insert(sale, tempData)
        end
    end
    return sale
end

-- message MagicGardenStageBox {
--     optional int32 index = 1;
--     optional int32 points = 2;
--     optional int64 coins = 3;
--     repeated ShopItem items = 4;
--   }
function MagicGardenData:parseStageBox(_data)
    local progress = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.p_index = v.index
            tempData.p_points = v.points
            tempData.p_coins = tonumber(v.coins)
            tempData.p_items = self:parseItems(v.items)
            table.insert(progress, tempData)
        end
    end
    return progress
end

function MagicGardenData:parseItems(_items)
    -- 通用道具
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

function MagicGardenData:isFirst()
    return self.p_first
end

function MagicGardenData:getCurrentPoints()
    return self.p_currentPoints
end

function MagicGardenData:getDrawTimes()
    return self.p_drawTimes
end

function MagicGardenData:getSaleData()
    return self.p_sale
end

function MagicGardenData:getStageBox()
    return self.p_stageBox
end

function MagicGardenData:getPrizePool()
    return self.p_prizePool
end

function MagicGardenData:getAllReward()
    local list = {}
    for i,v in ipairs(self.p_prizePool) do
        if not v.p_collected then
            table.insert(list, v)
        end
    end
    return list
end

function MagicGardenData:getNotCollectedTotal()
    local count = 0
    for i,v in ipairs(self.p_prizePool) do
        if not v.p_collected then
            count = count + 1
        end
    end
    return count
end

return MagicGardenData

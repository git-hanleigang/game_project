--[[
    新版常规促销
--]]

local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseGameModel = require("GameBase.BaseGameModel")
local RoutineSaleData = class("RoutineSaleData", BaseGameModel)
function RoutineSaleData:ctor()
    RoutineSaleData.super.ctor(self)

    self.p_expireAt = 0 
    self.p_wheelProgressCurrent = 0
    self.p_wheelProgressAll = 3
    self.p_wheelMaxUsd = 0
    self.p_wheelBaseCoins = 0
    self.p_leftPayTimes = 0
    self.p_wheelChunk = {}
    self.p_salePrices = {}
    self.p_wheelReward = nil

    self:setRefName(G_REF.RoutineSale)
end

-- message RoutineSale {
--     optional int64 expireAt = 1; // 促销结束时间
--     optional int32 wheelProgressCurrent = 2; // 轮盘进度
--     optional int32 wheelProgressAll = 3; // 轮盘目标进度
--     optional string wheelMaxUsd = 4; // 轮盘最大奖美刀值
--     optional int64 wheelBaseCoins = 5; // 轮盘基底
--     repeated RoutineSaleWheel wheelChunk = 6; // 轮盘块信息
--     repeated RoutineSalePrice salePrices = 7; // 促销价格
--     optional RoutineSaleWheelReward wheelReward = 8; // 轮盘待领奖
--     optional int32 leftPayTimes = 9; // 剩余购买次数
--   }
function RoutineSaleData:parseData(_data)
    RoutineSaleData.super.parseData(self, _data)

    self.p_expireAt = tonumber(_data.expireAt)
    self.p_wheelProgressCurrent = _data.wheelProgressCurrent
    self.p_wheelProgressAll = _data.wheelProgressAll
    self.p_wheelMaxUsd = _data.wheelMaxUsd
    self.p_wheelBaseCoins = _data.wheelBaseCoins
    self.p_leftPayTimes = _data.leftPayTimes
    self.p_wheelChunk = self:parseWheelChunk(_data.wheelChunk)
    self.p_salePrices = self:parseSaleData(_data.salePrices)
    self.p_wheelReward = self:parseWheelReward(_data.wheelReward)
end

-- message RoutineSaleWheel {
--     optional int32 index = 1; // 档位123
--     optional int32 multiple = 2; // 倍数
--   }
function RoutineSaleData:parseWheelChunk(_data)
    local tb = {}
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_multiple = v.multiple
            table.insert(tb, temp)
        end
    end
    return tb
end

-- message RoutineSalePrice {
--     optional string keyId = 1; // 档位标识 S1
--     optional string key = 2; // 付费唯一标识 0p99
--     optional string price = 3; // 价格 0.99
--     optional string coins = 4; // 金币
--     optional int32 index = 5; // 付费档位123
--     repeated ShopItem items = 6; // 道具
--     optional int32 buyTimes = 7; // 当前档位当日以购买次数
--     optional int32 buyLimit = 8; // 当前档位一天内购买上限
--     optional int32 discount = 9; // 折扣
--     optional int32 vipPoint = 10; // vip点数
--     repeated ShopItem displayList = 11; // 同商城显示道具
--   }
function RoutineSaleData:parseSaleData(_data)
    local tb = {}
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_keyId = v.keyId
            temp.p_key = v.key
            temp.p_price = v.price
            temp.p_coins = v.coins
            temp.p_index = v.index
            temp.p_buyTimes = v.buyTimes
            temp.p_buyLimit = v.buyLimit
            temp.p_discount = v.discount
            temp.p_vipPoint = v.vipPoint
            temp.p_items = self:parseItemsData(v.items)
            temp.p_displayList = self:parseItemsData(v.displayList)
            table.insert(tb, temp)
        end
    end
    return tb
end

function RoutineSaleData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

-- message RoutineSaleWheelReward {
--     optional int32 index = 1; // 命中轮盘位置索引012
--     optional int32 saleIndex = 2; // 档位123
--     optional int32 multiple = 3; // 倍数
--     optional string coins = 4; // 金币
--     optional bool reward = 5; // 是否已领奖
--   }
function RoutineSaleData:parseWheelReward(_data)
    local tb = nil
    if _data and (tonumber(_data.coins) or 0) > 0 then
        tb = {}
        tb.p_index = _data.index
        tb.p_coins = _data.coins
        tb.p_saleIndex = _data.saleIndex
        tb.p_multiple = _data.multiple
        tb.p_reward = _data.reward
    end
    return tb
end

function RoutineSaleData:getExpireAt()
    return self.p_expireAt * 0.001
end

function RoutineSaleData:getWheelCurPro()
    return self.p_wheelProgressCurrent
end

function RoutineSaleData:getWheelAllPro()
    return self.p_wheelProgressAll
end

function RoutineSaleData:getWheelBaseCoins()
    return self.p_wheelBaseCoins
end

function RoutineSaleData:getLeftPayTimes()
    return self.p_leftPayTimes
end

function RoutineSaleData:getWheelMaxUsd()
    return self.p_wheelMaxUsd
end

function RoutineSaleData:getWheelChunk()
    return self.p_wheelChunk
end

function RoutineSaleData:getSaleData()
    return self.p_salePrices
end

function RoutineSaleData:getWheelReward()
    return self.p_wheelReward
end

function RoutineSaleData:isRunning()
    local curTime = util_getCurrnetTime()
    if self:getExpireAt() <= curTime then
        return false
    end

    return true
end

function RoutineSaleData:hasWheelRward()
    if self.p_wheelReward and tonumber(self.p_wheelReward.p_coins) > 0 and not self.p_wheelReward.p_reward then
        return true
    end

    return false
end

function RoutineSaleData:hasBuyTimes()
    return self.p_leftPayTimes > 0
end

function RoutineSaleData:getLeftTime()
    return util_getLeftTime(self.p_expireAt)
end

return RoutineSaleData
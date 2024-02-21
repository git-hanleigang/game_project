--[[
]]
local ShopItem = require "data.baseDatas.ShopItem"

local HolidayGoodsData = class("HolidayGoodsData")
local HolidayTaskData = util_require("activities.Activity_HolidayNewChallenge.HolidayStore.model.HolidayTaskData")

-- message HolidayNewChallengeGoods {
--     optional int32 seq = 1;
--     optional int32 timesLimit = 2;// 次数限制
--     optional string type = 3;// 商品类型 COIN ITEM
--     repeated ShopItem items = 4;//道具
--     optional string coins = 5; //金币
--     optional int32 consumePoints = 6;// 消耗的点数
--     optional string goodsType = 7;// 商品的类型 分为普通跟高级 NORAM HIGH
--     optional HolidayNewChallengeGoldGoods goldGoods = 8;//特殊道具
--     optional int32 buyTimes = 9;//购买次数
--     optional string color = 10;//颜色
--   }

function HolidayGoodsData:parseData(_data)
    self.p_seq        = _data.seq                     --序号
    self.p_timesLimit = _data.timesLimit              --次数限制
    self.p_type       = _data.type                    --商品类型 COIN ITEM
    self.p_coins      = _data.coins                   --金币
    self.p_cash       = _data.consumePoints           --消耗的道具货币
    self.p_goodsType  = _data.goodsType               --商品类型 
    self.p_buyTimes   = _data.buyTimes                --购买次数
    self.p_color      = _data.color                   --颜色

    self:parseGoldGoodsTask(_data.goldGoods) --特殊道具 任务
    self.p_itemsList  = self:parseItemsList(_data.items)   --道具
    if self.p_goldGoods then
        
    end
end


function HolidayGoodsData:getSeq()
    return tonumber(self.p_seq)
end

function HolidayGoodsData:getLimit()
    return tonumber(self.p_timesLimit)
end

function HolidayGoodsData:getType()
    return self.p_type
end

function HolidayGoodsData:getCash()
    return tonumber(self.p_cash)
end

function HolidayGoodsData:getGoldGoodsTask()
    return self.p_goldGoods
end

function HolidayGoodsData:getBuyTimes()
    return tonumber(self.p_buyTimes)
end

function HolidayGoodsData:getCoins()
    return self.p_coins
end

function HolidayGoodsData:getItems()
    return self.p_itemsList
end

function HolidayGoodsData:getGoodsType()
    return self.p_goodsType
end

function HolidayGoodsData:getColor()
    return self.p_color
end

function HolidayGoodsData:isSellOut()
    if self:getBuyTimes() == self:getLimit() then
        return true
    else
        return false
    end
end

function HolidayGoodsData:parseItemsList(_items)
    local itemsList = {}
    if _items and #_items > 0 then
        for i, v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsList, tempData)
        end
    end
    return itemsList
end

function HolidayGoodsData:parseGoldGoodsTask(data)
    if nil == self.p_goldGoods then
        self.p_goldGoods = HolidayTaskData:create() 
    end
    self.p_goldGoods:parseData(data)
end

return HolidayGoodsData
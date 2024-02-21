--[[
]]
local ShopItem = require "data.baseDatas.ShopItem"
local ReturnWheelData = class("ReturnWheelData")

-- message BackWheel {
--     optional int32 leftTimes = 1;
--     repeated BackWheelPrizePool prizePool = 2;
--     optional int64 jackpotCoins = 3;
--   }
function ReturnWheelData:parseData(_data)
    self.p_leftTimes = _data.leftTimes
    self.p_jackpotCoins = tonumber(_data.jackpotCoins)
    self.p_prizePool = self:parsePrizePool(_data.prizePool)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RETURN_WHEEL_DATA_UPDATE)
end

-- message BackWheelPrizePool {
--     optional int32 index = 1;
--     optional int64 coins = 2;
--     repeated ShopItem items = 3;
--     optional bool jackpot = 4;//是否是jackpot
--     optional bool extracted = 5;//是否抽取
--   }
function ReturnWheelData:parsePrizePool(_data)
    local list = {}
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_coins = tonumber(v.coins)
            temp.p_jackpot = v.jackpot
            temp.p_extracted = v.extracted
            temp.p_items = self:parseItemData(v.items)
            table.insert(list, temp)
        end
    end
    return list
end

function ReturnWheelData:parseItemData(_items)
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

function ReturnWheelData:getLeftTimes()
    return self.p_leftTimes
end

function ReturnWheelData:getJackpotCoins()
    return self.p_jackpotCoins
end

function ReturnWheelData:getPrizePool()
    return self.p_prizePool
end

function ReturnWheelData:isAllCollect()
    local flag = true
    for i,v in ipairs(self.p_prizePool) do
        if not v.p_extracted then
            flag = false
        end
    end

    return flag
end

return ReturnWheelData

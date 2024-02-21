--[[
    三指针转盘促销
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local DIYWheelData = class("DIYWheelData",BaseActivityData)

-- message DiyWheel {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated DiyWheelSale saleList = 4;//促销
--     repeated DiyWheelJackpot jackpotList = 5;//jackpot
--     repeated DiyWheelReward wheelList = 6;//转盘
--     optional int32 remainingTimes = 7;//剩余次数
--   }
function DIYWheelData:parseData(_data)
    DIYWheelData.super.parseData(self,_data)

    self.p_remainingTimes  = _data.remainingTimes
    self.p_saleList = self:parseSaleList(_data.saleList)
    self.p_jackpotList = self:parseJackpotList(_data.jackpotList)
    self.p_wheelList = self:parseWheelList(_data.wheelList)
end

-- message DiyWheelSale {
--     optional int32 bet = 1;
--     optional string key = 2;
--     optional string keyId = 3;
--     optional string price = 4;
--   }
function DIYWheelData:parseSaleList(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_bet = v.bet
            temp.p_key = v.key
            temp.p_keyId = v.keyId
            temp.p_price = v.price
            table.insert(list, temp)
        end
    end
    return list
end

-- message DiyWheelJackpot {
--     optional int32 type = 1;//1.mini、2.minor、3.major、4.grand
--     optional int64 coins = 2;
--   }
function DIYWheelData:parseJackpotList(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_type = v.type
            temp.p_coins = tonumber(v.coins)
            table.insert(list, temp)
        end
    end
    return list
end

-- message DiyWheelReward {
--     optional int32 index = 1;
--     optional string usd = 2;
--     optional int64 coins = 3;
--     optional int32 type = 4;//1.mini、2.minor、3.major、4.grand、5.金币、6.美刀
--   }
function DIYWheelData:parseWheelList(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_usd = v.usd
            temp.p_coins = tonumber(v.coins)
            temp.p_type = v.type
            table.insert(list, temp)
        end
    end
    return list
end

function DIYWheelData:getRemainingTimes()
    return self.p_remainingTimes
end

function DIYWheelData:getSaleList()
    return self.p_saleList
end

function DIYWheelData:getJackpotList()
    return self.p_jackpotList
end

function DIYWheelData:getWheelList()
   return self.p_wheelList 
end

return DIYWheelData

--[[
    bingo连线
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local LineSaleData = class("LineSaleData",BaseActivityData)

-- message BingoLineSale {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated BingoLineSaleJackpot jackpots = 4;//（已弃用）
--     repeated BingoLineSaleLattice latticeList = 5;//格子数据
--     optional int64 coins = 6;
--     optional string discount = 7;//100%
--     optional string key = 8;
--     optional string keyId = 9;
--     optional string price = 10;
--     optional int64 jackpotCoins = 11;
--     optional int32 firstStampNum = 12;//首次付费盖戳数
--     optional bool first = 13;//是否首次
--   }
function LineSaleData:parseData(_data)
    LineSaleData.super.parseData(self, _data)

    self.p_coins = tonumber(_data.coins)
    self.p_discount = _data.discount
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_jackpotCoins = tonumber(_data.jackpotCoins)
    self.p_firstStampNum = _data.firstStampNum
    self.p_first = _data.first
    self.p_jackpotList = self:parseJackpot(_data.jackpots)
    self.p_latticeList = self:parseLattice(_data.latticeList)
end

-- message BingoLineSaleJackpot {
--     optional int32 jackpot = 1;//1.minor、2.major、3.grand
--     optional int32 count = 2;
--     optional int64 coins = 3;
--   }
function LineSaleData:parseJackpot(_data)
    -- 通用道具
    local jackpot = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_jackpot = v.jackpot
            tempData.p_count = v.count
            tempData.p_coins = tonumber(v.coins)
            table.insert(jackpot, tempData)
        end
    end
    return jackpot
end

-- message BingoLineSaleLattice {
--     optional int32 index = 1;
--     optional bool stamped = 2;//是否盖章
--     optional int32 jackpot = 3;//0.空格子1.minor、2.major、3.grand（已弃用）
--     optional string type = 4;//stamp、more
--     optional string value = 5;
--   }
function LineSaleData:parseLattice(_data)
    -- 通用道具
    local lattice = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_index = v.index
            tempData.p_stamped = v.stamped
            tempData.p_jackpot = v.jackpot
            tempData.p_type = v.type
            tempData.p_value = (tonumber(v.value) or 0) * (v.type == "more" and 100 or 1)
            table.insert(lattice, tempData)
        end
    end
    return lattice
end

function LineSaleData:getKeyId()
    return self.p_keyId
end

function LineSaleData:getPrice()
    return self.p_price
end

function LineSaleData:getCoins()
    return self.p_coins
end

function LineSaleData:getDiscount()
    return self.p_discount
end

function LineSaleData:getJackpotList()
    return self.p_jackpotList
end

function LineSaleData:getLatticeList()
    return self.p_latticeList
end

function LineSaleData:getJackpotCoins()
    return self.p_jackpotCoins
end

function LineSaleData:getFirstStampNum()
    return self.p_firstStampNum
end

function LineSaleData:isFirst()
    return self.p_first
end

function LineSaleData:getMoreTotal()
    local total = 0
    for i,v in ipairs(self.p_latticeList) do
        if v.p_type == "more" and v.p_stamped then
            total = total + v.p_value
        end
    end
    return total
end

function LineSaleData:getStampedLattice()
    local list = {}
    for i,v in ipairs(self.p_latticeList) do
        if v.p_stamped then
            table.insert(list, v)
        end
    end
    
    return list
end

return LineSaleData

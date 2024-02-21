-- word jackpot数据
local WordJackpotData = class("WordJackpotData")

-- message WordJackpot {
--     optional int32 jackpot = 1;// 1：Mini 2:Minor 3 :Major 4: Grand
--     optional int32 count = 2;// 当前收集数量
--     optional string desc = 3; // 描述
--     optional int64 coins = 4; // 金币
--     optional string coinsV2 = 5; // 金币
--   }
function WordJackpotData:parseData(_netData)
    self.p_jackpot = _netData.jackpot
    self.p_count = _netData.count
    self.p_desc = _netData.desc
    self.p_coins = _netData.coinsV2
end

function WordJackpotData:getJackpot()
    return self.p_jackpot
end

function WordJackpotData:getCount()
    return self.p_count
end

function WordJackpotData:getDesc()
    return self.p_desc
end

function WordJackpotData:getCoins()
    return self.p_coins
end

return WordJackpotData
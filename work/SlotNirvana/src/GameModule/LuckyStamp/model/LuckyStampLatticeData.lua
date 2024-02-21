--[[
]]
local LuckyStampLatticeData = class("LuckyStampV2Lattice")

-- message LuckyStampV2Lattice {
--     optional int32 index = 1; //位置
--     optional int64 coins = 2; //金币
--     optional string type = 3; //宝箱类型NORMAL,GOLDEN
--   }
function LuckyStampLatticeData:parseData(_netData)
    self.p_index = _netData.index
    self.p_coins = tonumber(_netData.coins)
    self.p_type = _netData.type
end

function LuckyStampLatticeData:getIndex()
    return self.p_index
end

function LuckyStampLatticeData:getCoins()
    return self.p_coins or 0
end

function LuckyStampLatticeData:getType()
    return self.p_type
end

return LuckyStampLatticeData

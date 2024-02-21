local PushCoin = class("PushCoin")
-- FIX IOS 139
PushCoin.p_type = nil
PushCoin.p_count = nil

function PushCoin:ctor(  ) 
end

--[[
    message CoinPusherV3Coin {
        optional string type = 1; //金币类型
        optional int32 count = 2; //数量
    }
]]
function PushCoin:parseData(_type, _count)
    self.p_type = _type
    self.p_count = _count
end

return PushCoin
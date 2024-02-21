local PushCoin = class("PushCoin")
-- FIX IOS 139
PushCoin.p_type = nil
PushCoin.p_count = nil

function PushCoin:ctor(  ) 
end

function PushCoin:parseData(data)
    self.p_type = data.type
    self.p_count = data.count
end

return PushCoin
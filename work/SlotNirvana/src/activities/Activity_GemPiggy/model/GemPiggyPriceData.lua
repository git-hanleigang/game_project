--[[
    价格
]]
local GemPiggyPriceData = class("GemPiggyPriceData")
function GemPiggyPriceData:ctor()
end

-- message PigGemsPrice{
--     optional string key = 1;
--     optional string keyId = 2;
--     optional string price = 3;
-- }
function GemPiggyPriceData:parseData(_netData)
    self.p_key = _netData.key
    self.p_keyId = _netData.keyId
    self.p_price = _netData.price
end

function GemPiggyPriceData:getKey()
    return self.p_key
end

function GemPiggyPriceData:getKeyId()
    return self.p_keyId
end

function GemPiggyPriceData:getPrice()
    return self.p_price
end

return GemPiggyPriceData
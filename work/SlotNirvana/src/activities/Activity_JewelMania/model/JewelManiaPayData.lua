--[[
]]
local JewelManiaPayData = class("JewelManiaPayData")

function JewelManiaPayData:ctor()
    self.m_payType = ""
end

-- message JewelManiaPay {
--     optional string key = 1;
--     optional string keyId = 2;
--     optional string price = 3;
--   }
function JewelManiaPayData:parseData(_netData)
    self.p_key = _netData.key
    self.p_keyId = _netData.keyId
    self.p_price = _netData.price
end

function JewelManiaPayData:getkeyId()
    return self.p_keyId
end

function JewelManiaPayData:getPrice()
    return self.p_price
end

function JewelManiaPayData:setPayType(_type)
    self.m_payType = _type    
end

function JewelManiaPayData:getPayType()
    return self.m_payType
end

return JewelManiaPayData
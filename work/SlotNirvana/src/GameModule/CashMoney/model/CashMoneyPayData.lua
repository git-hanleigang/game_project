--[[
]]
local CashMoneyPayData = class("CashMoneyPayData")

function CashMoneyPayData:ctor()
    
end

-- message CashMoneyPay {
--     optional string price = 1; //价格
--     optional string key = 2;
--     optional string keyId = 3;
--     optional int32 index = 4;
--     optional string maxCoins = 5;//最大金币
--     optional int32 maxMultiple = 6;//最大倍数
--     optional string payConfig = 7;//牌面
--     optional string payBase = 8;
--   }
function CashMoneyPayData:parseData(_data)
    self.p_price = _data.price
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_index = _data.index
    self.p_maxCoins = tonumber(_data.maxCoins)
    self.p_maxMultiple = _data.maxMultiple
    self.p_payConfig = util_split(_data.payConfig, ";")
    self.p_payBase = tonumber(_data.payBase)
end

function CashMoneyPayData:getPrice()
    return self.p_price
end

function CashMoneyPayData:getKey()
    return self.p_key
end

function CashMoneyPayData:getKeyId()
    return self.p_keyId
end

function CashMoneyPayData:getIndex()
    return self.p_index
end

function CashMoneyPayData:getMaxCoins()
    return self.p_maxCoins
end

function CashMoneyPayData:getMaxMultiple()
    return self.p_maxMultiple
end

function CashMoneyPayData:getPayConfig()
    return self.p_payConfig
end

function CashMoneyPayData:getPayBase()
    return self.p_payBase
end

return CashMoneyPayData
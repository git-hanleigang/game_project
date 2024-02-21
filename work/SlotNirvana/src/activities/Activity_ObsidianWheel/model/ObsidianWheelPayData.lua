--[[
    付费档位配置
]]
local ObsidianWheelPayData = class("ObsidianWheelPayData")

function ObsidianWheelPayData:ctor()
end

-- message ShortCardDrawPayConfig {
--     optional string price = 1; //1.99
--     optional string key = 2; //S2
--     optional string value = 3; // slots_casinocashlink_1p99
--   }

function ObsidianWheelPayData:parseData(_netData)
    self.p_price = _netData.price
    self.p_key = _netData.key
    self.p_value = _netData.value
end

function ObsidianWheelPayData:getPrice()
    return self.p_price
end

function ObsidianWheelPayData:getKey()
    return self.p_key
end

function ObsidianWheelPayData:getValue()
    return self.p_value
end

return ObsidianWheelPayData

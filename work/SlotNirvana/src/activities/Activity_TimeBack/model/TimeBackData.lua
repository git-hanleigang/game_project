
local BaseActivityData = require "baseActivity.BaseActivityData"
local TimeBackData = class("TimeBackData", BaseActivityData)

-- message TimeBack {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional string key = 4;
--     optional string keyId = 5;
--     optional string price = 6;
--     optional int64 coins = 7;
--     optional bool popup = 8;
--   }
function TimeBackData:parseData(_data)
    TimeBackData.super.parseData(self, _data)
    
    self.p_coins = tonumber(_data.coins)
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_popup = _data.popup
end

function TimeBackData:getKeyId()
    return self.p_keyId
end

function TimeBackData:getPrice()
    return self.p_price
end

function TimeBackData:getCoins()
    return self.p_coins
end

function TimeBackData:getPopup()
    return self.p_popup
end

return TimeBackData

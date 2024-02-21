--[[
    小猪 三合一促销数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local TrioPiggyData = class("TrioPiggyData", BaseActivityData)

function TrioPiggyData:ctor()
    TrioPiggyData.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChipPiggy)
end

-- 三只小猪打包价格
--[[
    message PigTrioSaleResult {
        optional string begin = 1;
        optional int64 expireAt = 2;
        optional string activityId = 3;
        optional string value = 4;
        optional string key = 5;
        optional string price = 6;
    }
]]
function TrioPiggyData:parseData(data)
    if not data then
        return
    end
    TrioPiggyData.super.parseData(self, data)
    self.p_value = data.value -- 购买的keyId
    self.p_key = data.key -- 购买的key（Sx）
    self.p_price = data.price -- 购买的价格
end

function TrioPiggyData:getKeyId()
    return self.p_value
end

function TrioPiggyData:getPrice()
    return self.p_price
end

return TrioPiggyData

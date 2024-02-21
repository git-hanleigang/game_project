--[[--
    集卡促销：商店购买双倍送卡活动
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DoubleCardData = class("DoubleCardData", BaseActivityData)
DoubleCardData.p_activityId = nil         
DoubleCardData.p_activityName = nil         
DoubleCardData.p_expireAt = nil
DoubleCardData.p_expire = nil        
DoubleCardData.p_isExist = nil

function DoubleCardData:ctor()
    DoubleCardData.super.ctor(self)
    self.p_isExist = false
end

function DoubleCardData:parseData( data )
    DoubleCardData.super.parseData(self, data)
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)  
    self.p_expire = tonumber(data.expire)  
    self.p_isExist = true
end

function DoubleCardData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function DoubleCardData:setExpire(t)
    self.p_expire = t
end
function DoubleCardData:getExpire()
    return self.p_expire
end

function DoubleCardData:isExist()
    if self.p_expire and self.p_expire > 0 then
        return true
    end
    return false
end

return DoubleCardData
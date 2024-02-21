--[[--
    集卡促销：商店购买集卡星级提升
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local CardStarData = class("CardStarData", BaseActivityData)
CardStarData.p_activityId = nil
CardStarData.p_activityName = nil
CardStarData.p_expireAt = nil
CardStarData.p_expire = nil
CardStarData.p_isExist = nil

function CardStarData:ctor()
    CardStarData.super.ctor(self)
    self.p_isExist = false
end

function CardStarData:parseData(data)
    CardStarData.super.parseData(self, data)
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)
    self.p_expire = tonumber(data.expire)
    self.p_isExist = true
end

function CardStarData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function CardStarData:setExpire(t)
    self.p_expire = t
end
function CardStarData:getExpire()
    return self.p_expire
end

function CardStarData:isExist()
    if self.p_expire and self.p_expire > 0 then
        return true
    end
    return false
end

return CardStarData

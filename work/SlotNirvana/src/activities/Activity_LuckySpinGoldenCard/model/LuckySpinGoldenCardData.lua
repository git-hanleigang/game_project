--[[
    des:luckyspin 掉落金卡活动 数据接收
    author:{author}
    time:2019-12-25 18:47:12
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local LuckySpinGoldenCardData = class("LuckySpinGoldenCardData", BaseActivityData)

LuckySpinGoldenCardData.p_activityId = nil         
LuckySpinGoldenCardData.p_activityName = nil         
LuckySpinGoldenCardData.p_expireAt = nil
LuckySpinGoldenCardData.p_expire = nil        
LuckySpinGoldenCardData.p_isExist = nil

function LuckySpinGoldenCardData:ctor()
    LuckySpinGoldenCardData.super.ctor(self)
    self.p_isExist = false
end

function LuckySpinGoldenCardData:parseData( data )  
    LuckySpinGoldenCardData.super.parseData(self, data)
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)  
    self.p_expire = tonumber(data.expire)  
    self.p_isExist = true
    self:getLeftTimeStr()
end

function LuckySpinGoldenCardData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function LuckySpinGoldenCardData:isExist()
    if self.p_expire and self.p_expire >0 then
        return true
    end
    return false
end

return LuckySpinGoldenCardData
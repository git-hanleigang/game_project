--[[
    des:superspin掉落卡牌活动数据接收
    author:{author}
    time:2019-12-05 18:47:12
]]

local LuckySpinCardData = class("LuckySpinCardData")

LuckySpinCardData.p_activityId = nil         
LuckySpinCardData.p_activityName = nil         
LuckySpinCardData.p_expireAt = nil
LuckySpinCardData.p_expire = nil        
LuckySpinCardData.p_isExist = nil

function LuckySpinCardData:ctor()
    self.p_isExist = false
end

function LuckySpinCardData:parseData( data )          
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)  
    self.p_expire = tonumber(data.expire)  
    self.p_isExist = true
end

function LuckySpinCardData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function LuckySpinCardData:isExist()
    if self.p_expire and self.p_expire >0 then
        return true
    end
    return false
end

return LuckySpinCardData
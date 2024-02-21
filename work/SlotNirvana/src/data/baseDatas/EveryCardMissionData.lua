--[[
    des: 每日任务每个任务都送卡活动数据
    author:{author}
    time:2019-12-17 14:35:08
]]

local EveryCardMissionData = class("EveryCardMissionData")
EveryCardMissionData.p_activityId = nil         
EveryCardMissionData.p_activityName = nil         
EveryCardMissionData.p_expireAt = nil
EveryCardMissionData.p_expire = nil        
EveryCardMissionData.p_isExist = nil

function EveryCardMissionData:ctor()
    self.p_isExist = false
end

function EveryCardMissionData:parseData( data )          
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)  
    self.p_expire = tonumber(data.expire)  
    self.p_isExist = true
end

function EveryCardMissionData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function EveryCardMissionData:isExist()
    return self.p_isExist
end

return EveryCardMissionData
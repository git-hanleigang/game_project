--[[
    des: 每日任务 4个任务活动数据
    author:{author}
    time:2019-12-10 14:35:08
]]

local PowerMissionData = class("PowerMissionData")
PowerMissionData.p_activityId = nil         
PowerMissionData.p_activityName = nil         
PowerMissionData.p_expireAt = nil
PowerMissionData.p_expire = nil        
PowerMissionData.p_isExist = nil

function PowerMissionData:ctor()
    self.p_isExist = false
end

function PowerMissionData:parseData( data )          
    self.p_activityId = data.activityId
    self.p_activityName = data.activityName
    self.p_expireAt = tonumber(data.expireAt)  
    self.p_expire = tonumber(data.expire)  
    self.p_isExist = true
end

function PowerMissionData:getLeftTimeStr()
    local strTime, isOver = util_daysdemaining(self.p_expireAt / 1000)
    self.p_isExist = isOver
    return strTime, isOver
end

function PowerMissionData:isExist()
    return self.p_isExist
end

return PowerMissionData
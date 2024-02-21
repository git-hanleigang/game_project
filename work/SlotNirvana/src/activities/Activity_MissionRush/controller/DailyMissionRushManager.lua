--[[
    
    author: csc
    time: 2022-02-21 
]]
local DailyMissionRushManager = class("DailyMissionRushManager", BaseActivityControl)

function DailyMissionRushManager:ctor()
    DailyMissionRushManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DailyMissionRush)
end

return DailyMissionRushManager

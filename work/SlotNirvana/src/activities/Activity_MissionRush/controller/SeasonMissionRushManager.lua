--[[
    
    author: csc
    time: 2022-02-21 
]]
local SeasonMissionRushManager = class("SeasonMissionRushManager", BaseActivityControl)

function SeasonMissionRushManager:ctor()
    SeasonMissionRushManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.SeasonMissionRush)
end

return SeasonMissionRushManager

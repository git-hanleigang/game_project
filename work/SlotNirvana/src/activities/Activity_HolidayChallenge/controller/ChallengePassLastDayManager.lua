--[[
    
    author: csc
    time: 2021-10-31 16:17:33
    聚合挑战最后一天 manager
]]
local ChallengePassLastDayManager = class("ChallengePassLastDayManager", BaseActivityControl)

function ChallengePassLastDayManager:ctor()
    ChallengePassLastDayManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChallengePassLastDay)
    self:addPreRef(ACTIVITY_REF.HolidayChallenge)
end


return ChallengePassLastDayManager

--[[
    
    author: csc
    time: 2021-10-31 16:17:33
    聚合挑战最后一天 manager
]]
local ChallengePassBoxManager = class("ChallengePassBoxManager", BaseActivityControl)

function ChallengePassBoxManager:ctor()
    ChallengePassBoxManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChallengePassBox)
    self:addPreRef(ACTIVITY_REF.HolidayChallenge)
end


return ChallengePassBoxManager

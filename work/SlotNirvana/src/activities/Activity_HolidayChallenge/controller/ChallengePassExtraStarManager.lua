--[[
    
    author: csc
    time: 2021-10-31 16:17:33
    聚合挑战额外一颗星 manager
]]
local ChallengePassExtraStarManager = class("ChallengePassExtraStarManager", BaseActivityControl)

function ChallengePassExtraStarManager:ctor()
    ChallengePassExtraStarManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChallengePassExtraStar)
    self:addPreRef(ACTIVITY_REF.HolidayChallenge)
end

return ChallengePassExtraStarManager

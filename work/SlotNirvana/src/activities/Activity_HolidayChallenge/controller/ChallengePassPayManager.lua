--[[
    
    author: csc
    time: 2021-10-31 16:17:33
    聚合挑战付费活动 manager
]]
local ChallengePassPayManager = class("ChallengePassPayManager", BaseActivityControl)

function ChallengePassPayManager:ctor()
    ChallengePassPayManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChallengePassPay)
    self:addPreRef(ACTIVITY_REF.HolidayChallenge)
end

return ChallengePassPayManager

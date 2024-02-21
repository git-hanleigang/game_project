--[[
    
    author: csc
    time: 2021-10-31 16:17:33
    聚合挑战 付费宣传 manager
]]
local HolidayChallengeSpecialManager = class("HolidayChallengeSpecialManager", BaseActivityControl)

function HolidayChallengeSpecialManager:ctor()
    HolidayChallengeSpecialManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.HolidayChallengeSpecial)
    self:addPreRef(ACTIVITY_REF.HolidayChallenge)
end

function HolidayChallengeSpecialManager:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

function HolidayChallengeSpecialManager:getRunningData(refName)
    local data = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if not data or not data:isRunning() or not data:isOverMax()  then
        return nil
    end

    return HolidayChallengeSpecialManager.super.getRunningData(self, refName)
end

function HolidayChallengeSpecialManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

return HolidayChallengeSpecialManager

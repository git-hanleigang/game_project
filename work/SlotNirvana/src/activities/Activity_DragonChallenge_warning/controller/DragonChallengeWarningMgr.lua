--[[
    组队boss预告
]]

local DragonChallengeWarningMgr = class("DragonChallengeWarningMgr", BaseActivityControl)

function DragonChallengeWarningMgr:ctor()
    DragonChallengeWarningMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.DragonChallengeWarning)
end

function DragonChallengeWarningMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function DragonChallengeWarningMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function DragonChallengeWarningMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return DragonChallengeWarningMgr

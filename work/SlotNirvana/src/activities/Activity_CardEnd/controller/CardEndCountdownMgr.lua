--[[

    author:{author}
    time:2021-09-28 14:22:08
]]
local CardEndCountdownMgr = class("CardEndCountdownMgr", BaseActivityControl)

function CardEndCountdownMgr:ctor()
    CardEndCountdownMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CardEndCountdown)
end

function CardEndCountdownMgr:getPopName()
    return self:getRefName()
end

function CardEndCountdownMgr:getHallName()
    return self:getRefName()
end

function CardEndCountdownMgr:getSlideName()
    return self:getRefName()
end

-- 从 Travel 和 Circus 主题开始，采用新的路径。
function CardEndCountdownMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. themeName
end

function CardEndCountdownMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. themeName .. "HallNode"
end

function CardEndCountdownMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. themeName .. "SlideNode"
end
return CardEndCountdownMgr

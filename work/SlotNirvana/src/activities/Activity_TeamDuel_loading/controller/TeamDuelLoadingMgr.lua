--[[
    3倍VIP点数
]]
local TeamDuelLoadingMgr = class("TeamDuelLoadingMgr", BaseActivityControl)

function TeamDuelLoadingMgr:ctor()
    TeamDuelLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.TeamDuel_Loading)
end

function TeamDuelLoadingMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName ..  "HallNode"
end

function TeamDuelLoadingMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName ..  "SlideNode"
end

function TeamDuelLoadingMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return TeamDuelLoadingMgr

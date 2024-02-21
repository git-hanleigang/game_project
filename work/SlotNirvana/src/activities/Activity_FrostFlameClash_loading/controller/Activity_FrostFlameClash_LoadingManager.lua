local Activity_FrostFlameClash_LoadingManager = class(" Activity_FrostFlameClash_LoadingManager", BaseActivityControl)

function Activity_FrostFlameClash_LoadingManager:ctor()
    Activity_FrostFlameClash_LoadingManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FrostFlameClash_Loading)
end
function Activity_FrostFlameClash_LoadingManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function Activity_FrostFlameClash_LoadingManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function Activity_FrostFlameClash_LoadingManager:getPopName()
    return "Activity_FrostFlameClash_Loading"
end

function Activity_FrostFlameClash_LoadingManager:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return Activity_FrostFlameClash_LoadingManager
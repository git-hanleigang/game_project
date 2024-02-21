--[[
    宠物-开启宣传
]]
local PetLoadingMgr = class(" PetLoadingMgr", BaseActivityControl)

function PetLoadingMgr:ctor()
    PetLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PetLoading)
end


function PetLoadingMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "HallNode"
end

function PetLoadingMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "SlideNode"
end

function PetLoadingMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return PetLoadingMgr

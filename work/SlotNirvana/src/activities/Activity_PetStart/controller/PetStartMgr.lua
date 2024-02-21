--[[
    宠物-开启宣传
]]
local PetStartMgr = class(" PetStartMgr", BaseActivityControl)

function PetStartMgr:ctor()
    PetStartMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PetStart)
end


function PetStartMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "HallNode"
end

function PetStartMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "SlideNode"
end

function PetStartMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return PetStartMgr

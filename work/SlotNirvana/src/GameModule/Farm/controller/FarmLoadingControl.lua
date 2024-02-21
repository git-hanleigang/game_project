--[[

]]
local FarmLoadingControl = class("FarmLoadingControl", BaseActivityControl)

function FarmLoadingControl:ctor()
    FarmLoadingControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FarmLoading)
end

function FarmLoadingControl:getHallPath(hallName)
    local theme = self:getThemeName()
    return theme .. "/" .. hallName .. "HallNode"
end

function FarmLoadingControl:getSlidePath(slideName)
    local theme = self:getThemeName()
    return theme .. "/" .. slideName .. "SlideNode"
end

function FarmLoadingControl:getPopPath(popName)
    local theme = self:getThemeName()
    return theme .. "/" .. popName
end

return FarmLoadingControl

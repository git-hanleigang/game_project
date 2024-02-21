--[[
    代币宣传
]]
local BucksLoadingMgr = class(" BucksLoadingMgr", BaseActivityControl)

function BucksLoadingMgr:ctor()
    BucksLoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Bucks_Loading)
end


function BucksLoadingMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "HallNode"
end

function BucksLoadingMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "SlideNode"
end

function BucksLoadingMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return BucksLoadingMgr

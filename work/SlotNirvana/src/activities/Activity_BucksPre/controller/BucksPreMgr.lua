--[[
    代币预热
]]
local BucksPreMgr = class(" BucksPreMgr", BaseActivityControl)

function BucksPreMgr:ctor()
    BucksPreMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BucksPre)
end


function BucksPreMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "HallNode"
end

function BucksPreMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. themeName .. "SlideNode"
end

function BucksPreMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return BucksPreMgr

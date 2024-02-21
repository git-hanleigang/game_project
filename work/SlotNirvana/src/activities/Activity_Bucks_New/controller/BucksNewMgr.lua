--[[
    代币系统-支持点位新增宣传
]]
local BucksNewMgr = class(" BucksNewMgr", BaseActivityControl)

function BucksNewMgr:ctor()
    BucksNewMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Bucks_New)
end


function BucksNewMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "HallNode"
end

function BucksNewMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "SlideNode"
end

function BucksNewMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return BucksNewMgr

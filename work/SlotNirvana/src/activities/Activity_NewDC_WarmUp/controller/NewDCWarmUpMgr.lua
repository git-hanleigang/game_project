--[[
    预热宣传
]]
local NewDCWarmUpMgr = class(" NewDCWarmUpMgr", BaseActivityControl)

function NewDCWarmUpMgr:ctor()
    NewDCWarmUpMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewDC_WarmUp)
end


function NewDCWarmUpMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "HallNode"
end

function NewDCWarmUpMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. themeName .. "SlideNode"
end

function NewDCWarmUpMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return NewDCWarmUpMgr

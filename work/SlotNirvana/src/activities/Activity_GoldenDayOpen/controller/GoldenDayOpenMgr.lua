--[[
]]
local GoldenDayOpenMgr = class("GoldenDayOpenMgr", BaseActivityControl)

function GoldenDayOpenMgr:ctor()
    GoldenDayOpenMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GoldenDayOpen)
end

return GoldenDayOpenMgr

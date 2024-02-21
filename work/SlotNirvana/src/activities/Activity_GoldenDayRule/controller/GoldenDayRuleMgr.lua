--[[
]]
local GoldenDayRuleMgr = class("GoldenDayRuleMgr", BaseActivityControl)

function GoldenDayRuleMgr:ctor()
    GoldenDayRuleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GoldenDayRule)
end

return GoldenDayRuleMgr

--[[
]]
local VipResetRuleMgr = class("VipResetRuleMgr", BaseActivityControl)

function VipResetRuleMgr:ctor()
    VipResetRuleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.VipResetRule)
end

return VipResetRuleMgr

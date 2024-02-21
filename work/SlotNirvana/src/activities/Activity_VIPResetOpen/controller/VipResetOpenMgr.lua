--[[
]]
local VipResetOpenMgr = class("VipResetOpenMgr", BaseActivityControl)

function VipResetOpenMgr:ctor()
    VipResetOpenMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.VipResetOpen)
end

return VipResetOpenMgr

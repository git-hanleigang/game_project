--[[
]]
local VipDoublePointMgr = class("VipDoublePointMgr", BaseActivityControl)

function VipDoublePointMgr:ctor()
    VipDoublePointMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.VipDoublePoint)
end

return VipDoublePointMgr

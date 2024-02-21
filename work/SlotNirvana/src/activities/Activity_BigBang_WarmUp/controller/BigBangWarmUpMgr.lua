--[[
    膨胀宣传-预热
]]
local BigBangWarmUpMgr = class(" BigBangWarmUpMgr", BaseActivityControl)

function BigBangWarmUpMgr:ctor()
    BigBangWarmUpMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BigBang_WarmUp)
end

return BigBangWarmUpMgr

--[[
    膨胀宣传-预热
]]
local MonsterWarmUpMgr = class(" MonsterWarmUpMgr", BaseActivityControl)

function MonsterWarmUpMgr:ctor()
    MonsterWarmUpMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Monster_WarmUp)
end

return MonsterWarmUpMgr

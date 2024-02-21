--[[
 规则宣传
]]
local ZombieRuleManager = class("ZombieRuleManager", BaseActivityControl)

function ZombieRuleManager:ctor()
    ZombieRuleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ZombieRule)
end

return ZombieRuleManager

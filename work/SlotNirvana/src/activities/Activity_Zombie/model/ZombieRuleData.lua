--行尸走肉主数据部分
local BaseActivityData = require "baseActivity.BaseActivityData"
local ZombieRuleData = class("ZombieRuleData", BaseActivityData)

function ZombieRuleData:ctor()
    ZombieRuleData.super.ctor(self)
    self.p_open = true
end

return ZombieRuleData

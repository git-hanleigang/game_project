--[[--
    PASS 双倍积分 空弹板
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DiyFeatureRuleData = class("DiyFeatureRuleData", BaseActivityData)

function DiyFeatureRuleData:ctor()
    DiyFeatureRuleData.super.ctor(self)
    self.p_open = true
end

return DiyFeatureRuleData
--[[
    minz rule宣传
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MinzRuleData = class("MinzRuleData", BaseActivityData)

function MinzRuleData:ctor()
    MinzRuleData.super.ctor(self)
    self.p_open = true
end

return MinzRuleData
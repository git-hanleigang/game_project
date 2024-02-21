--[[--
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local GoldenDayRuleData = class("GoldenDayRuleData", BaseActivityData)

function GoldenDayRuleData:ctor()
    GoldenDayRuleData.super.ctor(self)
    self.p_open = true
end

return GoldenDayRuleData

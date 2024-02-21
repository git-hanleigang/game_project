--[[
    钻石小猪-规则宣传
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local GemPiggyRuleData = class("GemPiggyRuleData", BaseActivityData)

function GemPiggyRuleData:ctor()
    GemPiggyRuleData.super.ctor(self)
    self.p_open = true
end

return GemPiggyRuleData
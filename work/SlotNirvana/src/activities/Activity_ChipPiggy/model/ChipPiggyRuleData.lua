--[[
    集卡小猪-规则宣传
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChipPiggyRuleData = class("ChipPiggyRuleData", BaseActivityData)

function ChipPiggyRuleData:ctor()
    ChipPiggyRuleData.super.ctor(self)
    self.p_open = true
end

return ChipPiggyRuleData
--[[
    宠物规则宣传
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local PetRuleData = class("PetRuleData", BaseActivityData)

function PetRuleData:ctor()
    PetRuleData.super.ctor(self)
    self.p_open = true
end

return PetRuleData
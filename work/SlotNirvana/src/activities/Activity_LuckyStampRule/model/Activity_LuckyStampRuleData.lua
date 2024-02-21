--[[
    盖戳宣传图
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local Activity_LuckyStampRuleData = class("Activity_LuckyStampRuleData", BaseActivityData)

function Activity_LuckyStampRuleData:ctor()
    Activity_LuckyStampRuleData.super.ctor(self)
    self.p_open = true
end

return Activity_LuckyStampRuleData

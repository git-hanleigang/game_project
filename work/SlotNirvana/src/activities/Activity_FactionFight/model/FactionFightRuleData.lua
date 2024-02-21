--[[--
    规则弹窗数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local FactionFightRuleData = class("FactionFightRuleData", BaseActivityData)

function FactionFightRuleData:ctor()
    FactionFightRuleData.super.ctor(self)
    self.p_open = true
end

return FactionFightRuleData
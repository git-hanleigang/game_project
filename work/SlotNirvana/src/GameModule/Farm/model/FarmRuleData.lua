local BaseActivityData = require("baseActivity.BaseActivityData")
local FarmRuleData = class("FarmRuleData", BaseActivityData)

function FarmRuleData:ctor()
    FarmRuleData.super.ctor(self)
    self.p_open = true
end

return FarmRuleData
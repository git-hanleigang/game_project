

local BaseActivityData = require("baseActivity.BaseActivityData")
local NewDiamondChallenge_RuleData = class("NewDiamondChallenge_RuleData", BaseActivityData)

function NewDiamondChallenge_RuleData:ctor()
    NewDiamondChallenge_RuleData.super.ctor(self)
    self.p_open = true
end

return NewDiamondChallenge_RuleData
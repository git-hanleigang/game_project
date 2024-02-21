

local BaseActivityData = require("baseActivity.BaseActivityData")
local DiamondChallenge_CountDownData = class("DiamondChallenge_CountDownData", BaseActivityData)

function DiamondChallenge_CountDownData:ctor()
    DiamondChallenge_CountDownData.super.ctor(self)
    self.p_open = true
end

return DiamondChallenge_CountDownData


local BaseActivityData = require("baseActivity.BaseActivityData")
local NewDiamondChallenge_EndData = class("NewDiamondChallenge_EndData", BaseActivityData)

function NewDiamondChallenge_EndData:ctor()
    NewDiamondChallenge_EndData.super.ctor(self)
    self.p_open = true
end

return NewDiamondChallenge_EndData
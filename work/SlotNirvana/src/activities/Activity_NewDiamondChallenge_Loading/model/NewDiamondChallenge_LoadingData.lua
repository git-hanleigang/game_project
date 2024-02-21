

local BaseActivityData = require("baseActivity.BaseActivityData")
local NewDiamondChallenge_LoadingData = class("NewDiamondChallenge_LoadingData", BaseActivityData)

function NewDiamondChallenge_LoadingData:ctor()
    NewDiamondChallenge_LoadingData.super.ctor(self)
    self.p_open = true
end

return NewDiamondChallenge_LoadingData
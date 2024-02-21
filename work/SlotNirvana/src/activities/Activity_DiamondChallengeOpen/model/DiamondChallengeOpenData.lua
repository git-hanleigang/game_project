--[[--
    
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DiamondChallengeOpenData = class("DiamondChallengeOpenData", BaseActivityData)

function DiamondChallengeOpenData:ctor()
    DiamondChallengeOpenData.super.ctor(self)
    self.p_open = true
end

return DiamondChallengeOpenData
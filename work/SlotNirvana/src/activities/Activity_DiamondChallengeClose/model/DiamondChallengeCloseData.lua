--[[--
    FB加好友活动 数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DiamondChallengeCloseData = class("DiamondChallengeCloseData", BaseActivityData)

function DiamondChallengeCloseData:ctor()
    DiamondChallengeCloseData.super.ctor(self)
    self.p_open = true
end

return DiamondChallengeCloseData
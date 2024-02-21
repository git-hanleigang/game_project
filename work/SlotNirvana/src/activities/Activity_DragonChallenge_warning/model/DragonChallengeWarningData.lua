--[[--
    组队boss预告
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DragonChallengeWarningData = class("DragonChallengeWarningData", BaseActivityData)

function DragonChallengeWarningData:ctor()
    DragonChallengeWarningData.super.ctor(self)
    self.p_open = true
end

return DragonChallengeWarningData
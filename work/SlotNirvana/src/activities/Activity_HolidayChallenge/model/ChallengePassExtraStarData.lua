--[[--  
    宣传弹板活动 空活动 
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChallengePassExtraStarData = class("ChallengePassExtraStarData", BaseActivityData)
function ChallengePassExtraStarData:ctor()
    -- 
    ChallengePassExtraStarData.super.ctor(self)
    self.p_open = true
end
return ChallengePassExtraStarData

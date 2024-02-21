--[[--  
    宣传弹板活动 空活动 
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChallengePassBoxData = class("ChallengePassBoxData", BaseActivityData)
function ChallengePassBoxData:ctor()
    -- 
    ChallengePassBoxData.super.ctor(self)
    self.p_open = true
end
return ChallengePassBoxData

--[[--  
    宣传弹板活动 空活动 
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChallengePassPayData = class("ChallengePassPayData", BaseActivityData)
function ChallengePassPayData:ctor()
    -- 
    ChallengePassPayData.super.ctor(self)
    self.p_open = true
end
return ChallengePassPayData

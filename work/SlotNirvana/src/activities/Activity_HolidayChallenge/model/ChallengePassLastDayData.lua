--[[--  
    宣传弹板活动 空活动 
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChallengePassLastDayData = class("ChallengePassLastDayData", BaseActivityData)
function ChallengePassLastDayData:ctor()
    -- 
    ChallengePassLastDayData.super.ctor(self)
    self.p_open = true
end
return ChallengePassLastDayData

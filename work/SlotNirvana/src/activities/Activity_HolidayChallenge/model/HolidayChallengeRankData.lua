--[[--  
    宣传弹板活动 空活动 
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local HolidayChallengeRankData = class("HolidayChallengeRankData", BaseActivityData)
function HolidayChallengeRankData:ctor()
    -- 
    HolidayChallengeRankData.super.ctor(self)
    self.p_open = true
end
return HolidayChallengeRankData

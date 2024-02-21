--[[--  
    宣传弹板活动 空活动 
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local HolidayChallengeSpecialData = class("HolidayChallengeSpecialData", BaseActivityData)
function HolidayChallengeSpecialData:ctor()
    -- 
    HolidayChallengeSpecialData.super.ctor(self)
    self.p_open = true
end
return HolidayChallengeSpecialData

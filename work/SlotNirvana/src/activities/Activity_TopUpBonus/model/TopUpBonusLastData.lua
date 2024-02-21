--[[--  
    宣传弹板活动 空活动 
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local TopUpBonusLastData = class("TopUpBonusLastData", BaseActivityData)
function TopUpBonusLastData:ctor()
    -- 
    TopUpBonusLastData.super.ctor(self)
    self.p_open = true
end
return TopUpBonusLastData

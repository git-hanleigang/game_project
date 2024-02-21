--[[--
    PASS 双倍积分 空弹板
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DiyFeatureLoadingData = class("DiyFeatureLoadingData", BaseActivityData)

function DiyFeatureLoadingData:ctor()
    DiyFeatureLoadingData.super.ctor(self)
    self.p_open = true
end

return DiyFeatureLoadingData
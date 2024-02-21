--[[
    代币宣传
]]
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local BucksLoadingData = class("BucksLoadingData", BaseActivityData)

function BucksLoadingData:ctor()
    BucksLoadingData.super.ctor(self)
    self.p_open = true
end

return BucksLoadingData

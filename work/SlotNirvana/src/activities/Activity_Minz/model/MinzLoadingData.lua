--[[
    minz loading宣传
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MinzLoadingData = class("MinzLoadingData", BaseActivityData)

function MinzLoadingData:ctor()
    MinzLoadingData.super.ctor(self)
    self.p_open = true
end

return MinzLoadingData
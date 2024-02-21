--[[
    钻石小猪-loading宣传
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local GemPiggyLoadingData = class("GemPiggyLoadingData", BaseActivityData)

function GemPiggyLoadingData:ctor()
    GemPiggyLoadingData.super.ctor(self)
    self.p_open = true
end

return GemPiggyLoadingData
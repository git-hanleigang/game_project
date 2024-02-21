--[[
    集卡小猪-loading宣传
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChipPiggyLoadingData = class("ChipPiggyLoadingData", BaseActivityData)

function ChipPiggyLoadingData:ctor()
    ChipPiggyLoadingData.super.ctor(self)
    self.p_open = true
end

return ChipPiggyLoadingData
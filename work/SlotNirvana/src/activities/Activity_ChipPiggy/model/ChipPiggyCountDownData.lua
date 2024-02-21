--[[
    集卡小猪 - 倒计时
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ChipPiggyCountDownData = class("ChipPiggyCountDownData", BaseActivityData)

function ChipPiggyCountDownData:ctor()
    ChipPiggyCountDownData.super.ctor(self)
    self.p_open = true
end

return ChipPiggyCountDownData
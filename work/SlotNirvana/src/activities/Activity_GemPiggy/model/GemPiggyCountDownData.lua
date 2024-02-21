--[[
    钻石小猪 - 倒计时
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local GemPiggyCountDownData = class("GemPiggyCountDownData", BaseActivityData)

function GemPiggyCountDownData:ctor()
    GemPiggyCountDownData.super.ctor(self)
    self.p_open = true
end

return GemPiggyCountDownData
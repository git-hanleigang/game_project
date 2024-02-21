--[[--
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local GoldenDayOpenData = class("GoldenDayOpenData", BaseActivityData)

function GoldenDayOpenData:ctor()
    GoldenDayOpenData.super.ctor(self)
    self.p_open = true
end

return GoldenDayOpenData

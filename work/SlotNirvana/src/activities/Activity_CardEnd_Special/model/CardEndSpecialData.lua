--[[
    集卡倒计时
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local CardEndSpecialData = class("CardEndSpecialData", BaseActivityData)

function CardEndSpecialData:ctor(_data)
    CardEndSpecialData.super.ctor(self, _data)

    self.p_open = true
end

return CardEndSpecialData

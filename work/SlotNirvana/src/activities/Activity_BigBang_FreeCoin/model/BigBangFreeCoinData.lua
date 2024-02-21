--[[
    膨胀宣传 免费金币
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BigBangFreeCoinData = class("BigBangFreeCoinData", BaseActivityData)

function BigBangFreeCoinData:ctor()
    BigBangFreeCoinData.super.ctor(self)
    self.p_open = true
end

return BigBangFreeCoinData
--[[
    膨胀宣传 主图
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BigBangStartData = class("BigBangStartData", BaseActivityData)

function BigBangStartData:ctor()
    BigBangStartData.super.ctor(self)
    self.p_open = true
end

return BigBangStartData
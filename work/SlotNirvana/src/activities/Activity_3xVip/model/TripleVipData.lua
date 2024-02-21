--[[
    3倍VIP点数
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local TripleVipData = class("TripleVipData", BaseActivityData)

function TripleVipData:ctor()
    TripleVipData.super.ctor(self)
    self.p_open = true
end

return TripleVipData
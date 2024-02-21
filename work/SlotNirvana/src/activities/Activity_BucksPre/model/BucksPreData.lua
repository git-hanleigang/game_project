--[[
    代币预热
]]
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local BucksPreData = class("BucksPreData", BaseActivityData)

function BucksPreData:ctor()
    BucksPreData.super.ctor(self)
    self.p_open = true
end

return BucksPreData

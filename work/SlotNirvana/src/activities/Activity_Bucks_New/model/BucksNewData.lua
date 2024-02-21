--[[
    代币系统-支持点位新增宣传
]]
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local BucksNewData = class("BucksNewData", BaseActivityData)

function BucksNewData:ctor()
    BucksNewData.super.ctor(self)
    self.p_open = true
end

return BucksNewData

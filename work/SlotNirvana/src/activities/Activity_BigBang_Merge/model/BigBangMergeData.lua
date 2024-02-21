--[[
    膨胀宣传 合成
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BigBangMergeData = class("BigBangMergeData", BaseActivityData)

function BigBangMergeData:ctor()
    BigBangMergeData.super.ctor(self)
    self.p_open = true
end

return BigBangMergeData
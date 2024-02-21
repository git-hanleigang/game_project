--[[
    盖戳宣传图
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local Activity_LuckyStampData = class("Activity_LuckyStampData", BaseActivityData)

function Activity_LuckyStampData:ctor()
    Activity_LuckyStampData.super.ctor(self)
    self.p_open = true
end

return Activity_LuckyStampData

--[[
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local LuckyFishData = class("LuckyFishData", BaseActivityData)

function LuckyFishData:ctor()
    LuckyFishData.super.ctor(self)
    self.p_open = true
end

return LuckyFishData
--[[
    3倍VIP点数
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local TeamDuelLoadingData = class("TeamDuelLoadingData", BaseActivityData)

function TeamDuelLoadingData:ctor()
    TeamDuelLoadingData.super.ctor(self)
    self.p_open = true
end

return TeamDuelLoadingData
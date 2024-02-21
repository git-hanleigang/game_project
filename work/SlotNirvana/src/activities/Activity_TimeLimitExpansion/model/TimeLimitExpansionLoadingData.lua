--[[
    3倍VIP点数
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local TimeLimitExpansionLoadingData = class("TimeLimitExpansionLoadingData", BaseActivityData)

function TimeLimitExpansionLoadingData:ctor()
    TimeLimitExpansionLoadingData.super.ctor(self)
    self.p_open = true
end

return TimeLimitExpansionLoadingData
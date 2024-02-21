--[[
    公会表情宣传
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local NewStickersLoadingData = class("NewStickersLoadingData", BaseActivityData)

function NewStickersLoadingData:ctor()
    NewStickersLoadingData.super.ctor(self)
    self.p_open = true
end

return NewStickersLoadingData
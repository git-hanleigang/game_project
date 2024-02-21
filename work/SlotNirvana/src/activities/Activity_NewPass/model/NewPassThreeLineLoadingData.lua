--[[--
    PASS 双倍积分 空弹板
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local NewPassThreeLineLoadingData = class("NewPassThreeLineLoadingData", BaseActivityData)

function NewPassThreeLineLoadingData:ctor()
    NewPassThreeLineLoadingData.super.ctor(self)
    self.p_open = true
end

return NewPassThreeLineLoadingData
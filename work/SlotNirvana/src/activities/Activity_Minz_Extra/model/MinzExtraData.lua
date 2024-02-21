--[[--
    MINZ：最后一天雕像增加
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local MinzExtraData = class("MinzExtraData", BaseActivityData)

function MinzExtraData:ctor()
    MinzExtraData.super.ctor(self)

    self.p_open = true
end

return MinzExtraData
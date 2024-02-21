--[[--
    PASS 双倍积分 空弹板
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local NewPassBuyShowTop = class("NewPassBuyShowTop", BaseActivityData)

function NewPassBuyShowTop:ctor()
    NewPassBuyShowTop.super.ctor(self)
    self.p_open = true
end

return NewPassBuyShowTop
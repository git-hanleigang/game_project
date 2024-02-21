--[[--
    PASS 双倍积分 空弹板
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local NewPassCountDownShowTop = class("NewPassCountDownShowTop", BaseActivityData)

function NewPassCountDownShowTop:ctor()
    NewPassCountDownShowTop.super.ctor(self)
    self.p_open = true
end

return NewPassCountDownShowTop
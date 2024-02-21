local BaseActivityData = require("baseActivity.BaseActivityData")
local OutsideCaveShowTopData = class("OutsideCaveShowTopData", BaseActivityData)

function OutsideCaveShowTopData:ctor()
    OutsideCaveShowTopData.super.ctor(self)
    self.p_open = true
end

return OutsideCaveShowTopData
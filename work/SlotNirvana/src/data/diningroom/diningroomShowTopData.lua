local BaseActivityData = require("baseActivity.BaseActivityData")
local diningroomShowTopData = class("diningroomShowTopData", BaseActivityData)

function diningroomShowTopData:ctor()
    diningroomShowTopData.super.ctor(self)
    self.p_open = true
end

function diningroomShowTopData:parseNormalActivityData(_data)
    diningroomShowTopData.super.parseNormalActivityData(self,_data)
    -- self.p_openLevel = 20
end

return diningroomShowTopData
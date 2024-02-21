local BaseActivityData = require("baseActivity.BaseActivityData")
local FarmLoadingData = class("FarmLoadingData", BaseActivityData)

function FarmLoadingData:ctor()
    FarmLoadingData.super.ctor(self)
    self.p_open = true
end

return FarmLoadingData
local BaseActivityData = require "baseActivity.BaseActivityData"
local DartsGameLoadingData = class("DartsGameLoadingData", BaseActivityData)

function DartsGameLoadingData:ctor()
    DartsGameLoadingData.super.ctor(self)
    self.p_open = true
end

return DartsGameLoadingData
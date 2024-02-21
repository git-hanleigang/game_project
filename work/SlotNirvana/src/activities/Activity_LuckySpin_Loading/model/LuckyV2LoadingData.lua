--jiaohua
local BaseActivityData = require "baseActivity.BaseActivityData"
local LuckyV2LoadingData = class("LuckyV2LoadingData", BaseActivityData)

function LuckyV2LoadingData:ctor(_data)
    LuckyV2LoadingData.super.ctor(self,_data)
    self.p_open = true
end

return LuckyV2LoadingData
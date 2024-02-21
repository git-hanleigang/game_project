--jiaohua
local BaseActivityData = require "baseActivity.BaseActivityData"
local FlowerLoadingData = class("FlowerLoadingData", BaseActivityData)

function FlowerLoadingData:ctor(_data)
    FlowerLoadingData.super.ctor(self,_data)
    self.p_open = true
end

return FlowerLoadingData
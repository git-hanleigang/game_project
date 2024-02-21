--jiaohua
local BaseActivityData = require "baseActivity.BaseActivityData"
local LegendaryWinData = class("LegendaryWinData", BaseActivityData)

function LegendaryWinData:ctor(_data)
    LegendaryWinData.super.ctor(self,_data)
    self.p_open = true
end

return LegendaryWinData
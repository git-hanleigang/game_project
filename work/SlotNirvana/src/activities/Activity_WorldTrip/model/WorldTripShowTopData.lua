-- 大富翁 排行榜数据

local BaseActivityData = require("baseActivity.BaseActivityData")
local WorldTripShowTopData = class("WorldTripShowTopData", BaseActivityData)

function WorldTripShowTopData:ctor()
    WorldTripShowTopData.super.ctor(self)
    self.p_open = true
end

return WorldTripShowTopData

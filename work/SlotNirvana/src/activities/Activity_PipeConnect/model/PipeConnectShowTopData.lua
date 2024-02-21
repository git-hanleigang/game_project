local BaseActivityData = require("baseActivity.BaseActivityData")
local PipeConnectShowTopData = class("PipeConnectShowTopData", BaseActivityData)

function PipeConnectShowTopData:ctor()
    PipeConnectShowTopData.super.ctor(self)
    self.p_open = true
end

return PipeConnectShowTopData
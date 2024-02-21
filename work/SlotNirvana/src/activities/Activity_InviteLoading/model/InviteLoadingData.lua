local BaseActivityData = require("baseActivity.BaseActivityData")
local InviteLoadingData = class("InviteLoadingData", BaseActivityData)

function InviteLoadingData:ctor(_data)
    InviteLoadingData.super.ctor(self,_data)
    self.p_open = true
end

return InviteLoadingData

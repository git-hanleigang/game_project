local BaseActivityData = require("baseActivity.BaseActivityData")
local MegaWinPartyLoadingData = class("MegaWinPartyLoadingData", BaseActivityData)

function MegaWinPartyLoadingData:ctor()
    MegaWinPartyLoadingData.super.ctor(self)
    self.p_open = true
end

return MegaWinPartyLoadingData
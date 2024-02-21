local BaseActivityData = require "baseActivity.BaseActivityData"
local Activity_DartsGame_LoadingData = class("Activity_DartsGame_LoadingData", BaseActivityData)

function Activity_DartsGame_LoadingData:ctor()
    Activity_DartsGame_LoadingData.super.ctor(self)
    self.p_open = true
end

return Activity_DartsGame_LoadingData
local BaseActivityData = require "baseActivity.BaseActivityData"
local Activity_FrostFlameClash_LoadingData = class("Activity_FrostFlameClash_LoadingData", BaseActivityData)

function Activity_FrostFlameClash_LoadingData:ctor()
    Activity_FrostFlameClash_LoadingData.super.ctor(self)
    self.p_open = true
end

return Activity_FrostFlameClash_LoadingData
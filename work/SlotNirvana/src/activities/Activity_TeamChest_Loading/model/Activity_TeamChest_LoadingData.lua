--jiaohua
local BaseActivityData = require "baseActivity.BaseActivityData"
local Activity_TeamChest_LoadingData = class("Activity_TeamChest_LoadingData", BaseActivityData)

function Activity_TeamChest_LoadingData:ctor(_data)
    Activity_TeamChest_LoadingData.super.ctor(self,_data)
    self.p_open = true
end

return Activity_TeamChest_LoadingData
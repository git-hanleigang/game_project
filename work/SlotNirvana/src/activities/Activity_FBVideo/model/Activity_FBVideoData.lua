local BaseActivityData = require "baseActivity.BaseActivityData"
local Activity_FBVideoData = class("Activity_FBVideoData", BaseActivityData)

function Activity_FBVideoData:ctor()
    Activity_FBVideoData.super.ctor(self)
    self.p_open = true
end

return Activity_FBVideoData
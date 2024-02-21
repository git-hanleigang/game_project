--[[--
    FB加好友活动 数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local FBCommunityData = class("FBCommunityData", BaseActivityData)

function FBCommunityData:ctor()
    FBCommunityData.super.ctor(self)
    self.p_open = true
end

return FBCommunityData
--[[--
    社区粉丝宣传活动 数据
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local FBAddFriendData = class("FBAddFriendData", BaseActivityData)

function FBAddFriendData:ctor()
    FBAddFriendData.super.ctor(self)
    self.p_open = true
end

return FBAddFriendData
-- 用户信息页 活动(只是一个弹板， 有这个活动open 就为true)
local BaseActivityData = require("baseActivity.BaseActivityData")
local UserInfomationData = class("UserInfomationData", BaseActivityData)

function UserInfomationData:ctor()
    UserInfomationData.super.ctor(self)
    self.p_open = true
end

return UserInfomationData



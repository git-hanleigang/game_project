-- vip特权 活动(只是一个弹板， 有这个活动open 就为true)
local BaseActivityData = require("baseActivity.BaseActivityData")
local VipPrivilegeData = class("VipPrivilegeData", BaseActivityData)

function VipPrivilegeData:ctor()
    VipPrivilegeData.super.ctor(self)
    self.p_open = true
end

return VipPrivilegeData


